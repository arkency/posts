---
title: "The === (case equality) operator in Ruby"
created_at: 2017-08-23 10:34:16 +0200
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'equality' ]
newsletter: arkency_form
---

Recently I've been working on adding more exercises to [DevMemo.io](https://devmemo.io) about Ruby's Enumerable module. And I try to balance learning most popular APIs (which you might already know) with some less popular but very useful.

And my attention was captured by `Enumerable#grep`.

<!-- more -->

```ruby
# grep(pattern) → array

# Returns an array of every element in enum
# for which Pattern === element.

(1..100).grep(38..44)
#=> [38, 39, 40, 41, 42, 43, 44]

names = %w(
  William
  Kate
  Adam
  Alexa
  James
  Natasha
)
names.grep(/am/)
# => %w(William Adam James)
```

As you can see it works with any class which implements `===` operator. So I was curious as to which classes implement it and in what way. Let's see.

## Class / Module

```ruby
mod === obj #→ true or false
```

`===` returns true if `obj` is an instance of `mod` or one of `mod`’s descendants. Of limited use for modules, but can be used to classify objects by class.

Basically implemented as

```ruby
obj.kind_of?(mod)
```

#### Example

```ruby
"text".class.ancestors
# => [String, Comparable, Object, Kernel, BasicObject]

String === "text"
# => true

Object === "text"
# => true

Comparable === "text"
# => true

Numeric === "text"
# => false
```

## Regexp

```ruby
rxp === str #→ true or false
```

Basically implemented as:

```
rxp =~ str >= 0
```

#### Example

```ruby

/^[a-z]*$/ === "HELLO"
#=> false

/^[A-Z]*$/ === "HELLO"
#=> true
```

## Range

```ruby
rng === obj #→ true or false
```

Returns true if `obj` is an element of the range, false otherwise.

#### Example

```ruby

(Date.new(2017, 8, 21)..Date.new(2017, 8, 27)) === Date.new(2017, 8, 27)
# => true

(Date.new(2017, 8, 21)..Date.new(2017, 8, 27)) === Date.new(2017, 8, 29)
# => false

("a".."z") === "a"
# => true

("a".."z") === "abc"
# => false
```

## Proc

```ruby
proc === obj # → result_of_proc
```

Invokes the block with `obj` as the `proc`'s parameter just like `#call`.

#### Example

```ruby
is_today = -> (date) { Date.current === date }

is_today === Date.current
# => true

is_today === Date.tomorrow
# => false

is_today === Date.yesterday
# => false

```

## Object

For most of other objects the behavior of `===` is the same as `==`.

## Your class

You can define your own class and it's own `===` which might be as complex (or as simple) as you want. And you can use instances of such class as matchers in `case..when` statements or as arguments to `Array#grep`.

```ruby
class State
  def initialize(expected_state)
    @expected_state = expected_state
  end

  def ===(obj)
    obj.state.to_s == @expected_state.to_s
  end
end

class Order < Struct.new(:id, :state, :customer_name)
end

p = Order.new(1, "placed",   "Robert")
v = Order.new(2, "verified", "Anne")
s = Order.new(3, "shipped",  "Kate")
orders = [p,v,s]

verified = State.new(:verified)
placed   = State.new(:placed)

verified === p
# => false

orders.grep(verified)
# => [#<struct Order id=2, state="verified", customer_name="Anne">]

message = case v
when verified
  "Your order has been verified and is awaiting shippment"
when placed
  "Please wait for verification"
else
  "---"
end
# => "Your order has been verified and is awaiting shippment"
```

Of course this is only for the cases when you don't feel that checking those conditions is a responsibility of the tested object and you don't want to implement it as a method in its class.

## Your object

As Ruby allows you to define singleton method which affect only a single object's behavior, you don't even need a class.

```ruby
VERIFIED = Object.new
def VERIFIED.===(obj)
  obj.state.to_s == "verified"
end

class Order < Struct.new(:id, :state, :customer_name)
end

VERIFIED === Order.new(1, "placed", "Robert")
# => false

VERIFIED === Order.new(2, "verified", "Rita")
# => true
```

But frankly, I would rather go with `Proc` in such case.

```ruby
VERIFIED = -> (obj){ obj.state.to_s == "verified" }
```

## P.S.

If you don't want to forget about `Enumerable#grep` try [DevMemo.io](https://devmemo.io). We've been recently working on a Beta version which includes scheduling flashcards repetitions and reminders.

Also, subscribe to [our newsletter](http://arkency.com/newsletter) to receive weekly free Ruby and Rails lessons.
