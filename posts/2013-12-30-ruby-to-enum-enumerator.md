---
title: "Don't be Enumerable, return enumerable Enumerator"
created_at: 2013-12-30 17:22:14 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby', 'to_enum', 'enumerator', 'enumerable' ]
---

Many times I have seen people including `Enumerable` module into their
classes. But I cannot stop thinking that in many cases having methods
such as [`each_with_index`](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-each_with_index)
or [`take_while`](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-take_while) or
[`minmax`](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-minmax) and many others
that are available in [`Enumerable`](http://ruby-doc.org/core-2.1.0/Enumerable.html) are not
core responsibility of the class that is including them itself.

<!-- more -->

In such case I prefer to go Java-way and provide external `Enumerator` for
those who need to call one of the many useful `Enumerable` methods on the
collection. I think that we need to ask ourselves a question: _Is that class a
collection?_. If it really is then it absolutely makes sense to
`include Enumerable`. If however it is not a collection, but rather a class
which happens contain something else, or providing a collection,
well then maybe external `Enumerator` is your solution.

## Standard library

If you call the most famous `Array#each` method without a block, you will see that
you get an enumerator in the response.

```
#!ruby

e = [1,2,3].each
# => #<Enumerator: [1, 2, 3]:each> 
```

You can manually fetch new elemens:

```
#!ruby
e.next
# => 1 

e.next
# => 2 

e.next
#=> 3 

e.next
# StopIteration: iteration reached an end
```

Or use one of the `Enumerable` method that `Enumerator` gladly provides for you

```
#!ruby

e = [1,2,3].each

e.partition{|x| x % 2 == 0}
# => [[2], [1, 3]] 
```

## Create `Enumerator`

There are 3 ways to create your own `Enumerator`:

* `Kernel#to_enum`
* `Kernel#enum_for`
* `Enumerator.new`

But if you look into MRI implemention you will notice that both `#to_enum` and
`#enum_for` are implemented in the same way:


```
#!cpp
rb_define_method(rb_mKernel, "to_enum", obj_to_enum, -1);
rb_define_method(rb_mKernel, "enum_for", obj_to_enum, -1);

rb_define_method(rb_cLazy, "to_enum", lazy_to_enum, -1);
rb_define_method(rb_cLazy, "enum_for", lazy_to_enum, -1);
```

You can check it out here:

* https://github.com/ruby/ruby/blob/520f0fec9519647e8ae1dfc15756b537fe580d6e/enumerator.c#L1994-1995
* https://github.com/ruby/ruby/blob/520f0fec9519647e8ae1dfc15756b537fe580d6e/enumerator.c#L2021-2022

And if you look into rubyspec you will also notice that they are supposed to
have identicial behavior, so I guess currently there is really no difference
between them

* https://github.com/rubyspec/rubyspec/blob/7fb7465aac1ec8e2beffdfa9053758fa39b443a5/core/enumerator/to_enum_spec.rb#L7
* https://github.com/rubyspec/rubyspec/blob/7fb7465aac1ec8e2beffdfa9053758fa39b443a5/core/enumerator/enum_for_spec.rb#7

Therfore whenever you see an example using one of them, you can just substitue
it with the other.

## `#to_enum` & `#enum_for`

What can `#to_enum` & `#enum_for` do for you? Well, they can create the
`Enumerator` based on any method which `yield`s arguments. Usually
the convention is to create the `Enumerator` based on method `#each`
(no surprise here).

```
#!ruby
a = [1,2,3]
enumerator = a.to_enum(:each)
```

We will see it in action later in the post.

## `Enumerator.new`

This way (contrary to the previous) has a [nice documentation in Ruby doc](http://www.ruby-doc.org/core-2.1.0/Enumerator.html#method-c-new)
which I am just gonna paste here:

_Iteration is defined by the given block, in which a “yielder” object, given as block parameter, can be used to yield a value_:

```
#!ruby
fib = Enumerator.new do |y|
  a = b = 1
  loop do
    y << a
    a, b = b, a + b
  end
end

fib.take(10) # => [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
```

_The optional parameter can be used to specify how to calculate the size in a lazy fashion. It can either be a value or a callable object._

Here is my example:

```
#!ruby
polish_postal_codes = Enumerator.new(100_000) do |y|
  100_000.times.each do |number|
    code    = sprintf("%05d", number)
    code[1] = code[1] + "-"
    y.yield(code)
  end
end

polish_postal_codes.size    # => 100000
polish_postal_codes.take(3) # => ["00-000", "00-001", "00-002"]
```


## What's in it for you, for your code

TODO: That's what I need to finish. Probably based on: https://gist.github.com/paneq/a11bb2e4453e43ae06c7#file-fee-rb-L53
