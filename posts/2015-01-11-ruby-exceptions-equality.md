---
title: "Ruby Exceptions Equality"
created_at: 2015-01-11 12:19:04 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :arkency_form
tags: [ 'ruby', 'exceptions' ]
img: "/assets/images/ruby-exception-equality/ruby-exception-surprise-face-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/ruby-exception-equality/ruby-exception-surprise-face-fit.jpg" width="100%">
  </figure>
</p>

Few days ago my colleague was stuck for a moment when testing one service object.
The service object was responsible for a batch operation. Basically operating on
multiple objects and collecting the status of the action. Either it was successful
or failed with an exception. We couldn't get our equality assertion to work even
though at first glance everything looked ok. We had to dig deeper.

<!-- more -->

The problem boils down to exceptions equality in Ruby. And few tests in console
showed precisely how it works, later to be confirmed by the documentation.

Let's see a comparison case by case. But first, exception definition:

```
#!ruby
  RefundNotAllowed = Class.new(StandardError)
```

#### Does two instances of same exception equal?

```
#!ruby
RefundNotAllowed.new == RefundNotAllowed.new
# => true
```

Yes. That was our first test and it behaved according to our intution. So why did our
test fail if everything told us that we are comparing identical exceptions.

#### What about message?

```
#!ruby
RefundNotAllowed.new("one message") == RefundNotAllowed.new("another")
# => false

RefundNotAllowed.new("one message") == RefundNotAllowed.new("one message")
# => true
```

Ok, so apparently the message must be identical as well. But in our case the
message was equal and our exceptions were still non-equal. Bummer. Let's think
about one more aspect of exceptions: backtrace.

#### What about backtrace?

The backtrace of unthrown exception is...

```
#!ruby
RefundNotAllowed.new.backtrace
 => nil
```

Ok, I didn't excepted that. I imagined that the backtrace is assigned at the
moment of exception instantiation. But when you think deeper about it, you
might realize that it wouldn't make sense.

```
#!ruby
exception = RefundNotAllowed.new
raise exception
```

Would you like to know that the exception was raised at line `1` or rather
line `2` in that example? So obviously backtraces are assigned when
exception is actually raised, not merly instantiated.

But do they play any role in exception equality? Let's see.

```
#!ruby
def one_method
  raise RefundNotAllowed.new
rescue => x
  return x
end

def another_method
  raise RefundNotAllowed.new
rescue => x
  return x
end

one_method == one_method          # => true
another_method == another_method  # => true

one_method == another_method      # => false

exception_one = one_method
exception_two = one_method
exception_one == exception_two    # => false
```

Apparently for two exceptions to be equal they must have identical
backtrace. Even 1 line of difference makes them, well... , different.

#### What does the doc say?

[ruby `Exception#==` documentation](http://www.ruby-doc.org/core-2.2.0/Exception.html#method-i-3D-3D) says:
_If `obj` is not an Exception, returns false. Otherwise, returns true if `exc` and `obj` share same
class, messages, and backtrace._

In my original problem it lead me to realization that we were comparing
raised-and-catched exception (thus with stacktrace) with a newly
instantiated exception. That's why we couldn't get to make them equal.

When you use `assert_raises(RefundNotAllowed)` or
`expect{}.to raise_error(RefundNotAllowed)` these matchers take care of
the details for you:

* [minitest](https://github.com/seattlerb/minitest/blob/7298fce695b7a386392a293f23e6253576b05473/lib/minitest/assertions.rb#L301)
* [rspec](https://github.com/rspec/rspec-expectations/blob/1c877e07e6dda41f1cf124934cee7d02e4540c8b/lib/rspec/matchers/built_in/raise_error.rb#L32)

But when you check something like
`expect(result.first.error).to eq(RefundNotAllowed.new)` because your batch
process collected them for you, then you are on your own and this might not
be good enough and it won't work. You might wanna just compare manually
exception class and message.

#### What about custom exceptions with additional data?

Because they inherit from `Exception` (through `StandardError`) they share identical
logic as described in documentation.

```
#!ruby
class RefundNotAllowed < StandardError
  attr_reader :order_id
  def initialize(order_id)
    super("Refund not allowed")
    @order_id = order_id
  end
end

RefundNotAllowed.new(1) == RefundNotAllowed.new(2)
# => true
```

If you want something better you need to overwrite `==` operator yourself.

```
#!ruby
class RefundNotAllowed < StandardError
  attr_reader :order_id
  def initialize(order_id)
    super("Refund not allowed")
    @order_id = order_id
  end

  def ==(obj)
    super(obj) && order_id == obj.order_id
  end
end

RefundNotAllowed.new(1) == RefundNotAllowed.new(2) # false
RefundNotAllowed.new(2) == RefundNotAllowed.new(2) # true
```

### My opinion

I am personally not convinced about the usability of including backtrace in
exception equality logic because in reality one would almost never create
two exceptions with the exact same backtrace to compare them. Although maybe
for some usecases it is a nice way to determine if repeated attempt failed in
exactly same way and for the same reason.

But you can always overwrite `==` in a way that would not call `super` and
would completely ignore the backtrace, instead comparing only exception class, data,
and perhaps message.
