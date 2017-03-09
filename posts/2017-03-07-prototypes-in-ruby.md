---
title: "Prototypes in Ruby and the strange story of dup"
created_at: 2017-03-07 22:24:48 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby','rails','prototypes' ]
newsletter: :arkency_form
img: "prototypes-in-ruby-rails-active-record-dup-clone/prototypes_in_ruby_rails_header.png"
---

<%= img_fit("prototypes-in-ruby-rails-active-record-dup-clone/prototypes_in_ruby_rails_header.png") %>

Today I was working on a feature where I had to create a few similar
Active Record objects. I was creating a _read model_ for
some financial data. Most of the attributes of created objects were the
same but a few were different. In one refactoring step I removed the
duplication in passing attributes by using a prototype. Although at that
moment I haven't thought of the object in such way.

<!-- more -->

### Before

The code before refactoring looked similar to this:

```
#!ruby
Entry.create!(
  fact_id: fact.id,
  time: fact.metadata.fetch(:timestamp),
  level: order.level,
  order_id: order.id,
  column_a: something,
  column_b: something_else,
  column_c: another_computation,
  column_d: one_more,
  column_e: not_yet_finished,

  entry_number: 1,
  entry_type: "REVENUE",
  gross_value: BigDecimal.new("100.00"),
  vat: BigDecimal.new("13.05"),
)

Entry.create!(
  fact_id: fact.id,
  time: fact.metadata.fetch(:timestamp),
  level: order.level,
  order_id: order.id,
  column_a: something,
  column_b: something_else,
  column_c: another_computation,
  column_d: one_more,
  column_e: not_yet_finished,

  entry_number: 2,
  entry_type: "FEE_TYPE_1",
  gross_value: BigDecimal.new("-10.00"),
  vat: BigDecimal.new("-1.30"),
)
```

There were more columns and more entries
(betwen 2 and 5) being created for the financial ledger.

I could have extracted the common attributes into a Hash
but I decided to go with a slighthly different direction.

## After

```
#!ruby
base_entry = Entry.new(
  fact_id: fact.id,
  time: fact.metadata.fetch(:timestamp),
  level: order.level,
  order_id: order.id,
  column_a: something,
  column_b: something_else,
  column_c: another_computation,
  column_d: one_more,
  column_e: not_yet_finished,
)

base_entry.dup.update_attributes!(
  entry_number: 1,
  entry_type: "REVENUE",
  gross_value: BigDecimal.new("100.00"),
  vat: BigDecimal.new("13.05"),
)

base_entry.dup.update_attributes!(
  entry_number: 2,
  entry_type: "FEE_TYPE_1",
  gross_value: BigDecimal.new("-10.00"),
  vat: BigDecimal.new("-1.30"),
)
```

I used [dup](http://ruby-doc.org/core-2.4.0/Object.html#method-i-dup) method
which is available for every `Object` in Ruby. Including in
[ActiveRecord](http://api.rubyonrails.org/v5.0.1/classes/ActiveRecord/Core.html#method-i-dup) .
When using `dup` be aware of its differences from
[clone](http://ruby-doc.org/core-2.4.0/Object.html#method-i-clone),
especially in [ActiveRecord case](http://api.rubyonrails.org/v5.0.1/classes/ActiveRecord/Core.html#method-i-clone).
Those [semantics changed a few years ago in in Rails 3.1](http://guides.rubyonrails.org/3_1_release_notes.html#active-record).

The most important difference for me turns out to be the record identity.

```
#!ruby
User.last.dup.id
# => nil

User.last.clone.id
# => 4
```

`#dup` is like _I want a similar (in terms of attributes) but new record_ and `#clone` is like
_i want a copy pointing to the same db record_.

## Can I really, really clone/duplicate it?

It is true that every `Object` has `dup` implemented so you might be tempted to believe you
actually can duplicate every object.

```
#!ruby
a = BigDecimal.new("123")
# => #<BigDecimal:282cf60,'0.123E3',9(18)> 

b = BigDecimal.new("123").dup
# => #<BigDecimal:2834148,'0.123E3',9(18)> 

a.object_id
# => 21063600
b.object_id
# => 21078180

a = "text"
# => "text" 

b = a.dup
# => "text" 

a.object_id
# => 21085300 
b.object_id
# => 2106552
```

And so on, and so on... Unfortunately the truth is a bit more complicated.
There are so called [_immediate objects_ (or _immediate values_) in Ruby](https://www.ruby-forum.com/topic/50305) which
cannot be duplicated/cloned.

```
#!ruby
nil.clone
# TypeError: can't clone NilClass
nil.dup
# TypeError: can't dup NilClass

1.clone
# TypeError: can't clone Fixnum
1.dup
# TypeError: can't dup Fixnum

1.0.clone
# TypeError: can't clone Float
1.0.dup
# TypeError: can't dup Float

false.clone
# TypeError: can't clone FalseClass
false.dup
# TypeError: can't dup FalseClass
```

unless... you are on recently released ruby 2.4...

```
#!ruby
nil.clone
# => nil
nil.object_id
# => 8
nil.clone.object_id
# => 8

1.clone
# => 1
1.object_id
# => 3
1.clone.object_id
# => 3
```

in which you can call those methods but instead of returning actual duplicates
they return the same instances. Because there is only one instance of `nil`, `false`,
`true`, `1`, `1.0`, etc in your ruby app.

## ActiveSupport Object#duplicable?

Rails extends every `Object` with `duplicable?` method which tell if you can safely
call `dup` and not get an exception sometimes. It's
[interesting how `duplicable?` is implemented](https://github.com/rails/rails/blob/37770bc8d13c5c7af024e66539c79f966718aec0/activesupport/lib/active_support/core_ext/object/duplicable.rb).

First, they start by saying you can `dup` an `Object`.

```
#!ruby
class Object
  # Can you safely dup this object?
  #
  # False for method objects;
  # true otherwise.
  def duplicable?
    true
  end
end
```

And then it is dynamically checked if that's actually true for some known exceptions
such as `nil` etc.

```
#!ruby
class NilClass
  begin
    nil.dup
  rescue TypeError

    # +nil+ is not duplicable:
    #
    #   nil.duplicable? # => false
    #   nil.dup         # => TypeError: can't dup NilClass
    def duplicable?
      false
    end
  end
end
```

As can see the the return value of `nil.duplicable?` will actually depend on
the Ruby version you are running on. `true` or `false` is not hardcoded (what
I expected) but rather dynamically probed. In case of `TypeError` exception
the method is overwritten in a that specific class.

![Mindblown](/assets/images/ruby-rails-dup-clone-duplicable-prototype/mindblown.gif)

However for some reason for a few classes a different strategy is used
by explicitly returning `true` or `false` without such check.

```
#!ruby
class BigDecimal
  def duplicable?
    true
  end
end

class Method
  def duplicable?
    false
  end
end

class Complex
  def duplicable?
    false
  end
end
```

But the most interesting part is around `Symbol`.

```
#!ruby
class Symbol
  begin
    :symbol.dup # Ruby 2.4.x.
    "symbol_from_string".to_sym.dup # Some symbols can't `dup` in Ruby 2.4.0.
  rescue TypeError

    # Symbols are not duplicable:
    #
    #   :my_symbol.duplicable? # => false
    #   :my_symbol.dup         # => TypeError: can't dup Symbol
    def duplicable?
      false
    end
  end
end
```

Because Ruby 2.4 is a bit weird and a literal symbol can be duplicated
but dynamic one cannot. Unless the dynamic one is the same as a literal
one created before it... yep...

```
#!ruby

:literal_symbol.dup
# => :literal_symbol

"dynamic_symbol".to_sym.dup
# => TypeError: allocator undefined for Symbol

:dynamic_preceeded_with_literal
# => :dynamic_preceeded_with_literal 
"dynamic_preceeded_with_literal".to_sym.dup
# => :dynamic_preceeded_with_literal
```

Frankly, I am not sure if that's a bug or expected behavior.
I see no reason why the dynamic symbol could not return itself
as well. Maybe `dup` is suppose to presever some constraints
that I am not aware of...

I enjoyed reading the explanation why ActiveSupport even attempts to implement
those methods. Quoting the documentation itself.

_Most objects are cloneable, but not all. For example you can't dup methods:_

```
#!ruby
method(:puts).dup
# => TypeError: allocator undefined for Method
```

_Classes may signal their instances are not duplicable removing `dup`/`clone`
or raising exceptions from them. So, to dup an arbitrary object you normally
use an optimistic approach and are ready to catch an exception, say:_

```
#!ruby
arbitrary_object.dup rescue object
```

_Rails dups objects in a few critical spots where they are not that arbitrary.
That rescue is very expensive (like 40 times slower than a predicate), and it
is often triggered._

_That's why we hardcode the following cases and check duplicable? instead of
using that rescue idiom._


So it is a performance optimization inside the framwork's critical paths. Remember
that optimizing exceptions in you web application [most likely won't have any
meaningful impact](https://gist.github.com/paneq/a643b9a3cc694ba3eb6e).

### P.S. Looking for a way to get your first Ruby job?

Check out our [Junior Rails Developer](/junior-rails-developer/) course.

### Already a Ruby master?

You will enjoy our upcoming [Rails DDD Workshop](/ddd-training/) (25-26th May 2017, Thursday & Friday, Lviv, Ukraine. In English)
which teaches you techniques for maintaining large, complex Rails applications.
