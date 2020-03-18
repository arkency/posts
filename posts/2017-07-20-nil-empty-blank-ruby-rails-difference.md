---
title: "nil?, empty?, blank? in Ruby on Rails - what's the difference actually?"
created_at: 2017-07-20 11:42:30 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'nil', 'empty', 'blank' ]
newsletter: arkency_form
---

There are plenty of options available. Let's evaluate their usefulness and potential problems that they bring to the table.

<!-- more -->

## `nil?`

* Provided by Ruby
* Can an be used on anything
* Will return `true` only for `nil`

```ruby

nil.nil?
# => true

false.nil?
# => false

0.nil?
# => false

"".nil?
# => false
```

## `empty?`

* Provided by Ruby
* Can be used on *collections* such as `Array`, `Hash`, `Set` etc. Returns true when they have no elements.

```ruby
[].empty?
# => true

{}.empty?
# => true

Set.new.empty?
# => true
```

* but it is not included in `Enumerable`. Not every object which iterates and returns values knows if if it has any value to return

    * Here you can [learn more about enumerators](http://blog.arkency.com/2014/01/ruby-to-enum-for-enumerator/)

```ruby
fib = Enumerator.new do |y|
  a = b = 1
  loop do
    y << a
    a, b = b, a + b
  end
end

fib.empty?
# NoMethodError: undefined method `empty?' for #<Enumerator:
```

* It can also be using on Strings (because you can think of String as a collection of bytes/characters)

```ruby
"".empty?
# => true

" ".empty?
# => false
```

* The problem with `empty?` is that you need to know the class of the object to be sure you won't get an exception. If you don't know if an object is an `Array` or `nil` then using `empty?` alone is not safe. You need tedious double protection.

```ruby
object = rand > 0.5 ? nil : array
object.empty? # can raise an exception

if !object.nil? && !object.empty? # doh...
  # do something
end
```

This is where Rails comes with ActiveSupport extensions and defines `blank?` Let's see how.

## `blank?`

* Provided by Rails
* `nil` and `false` are obviously blank.

```ruby
class NilClass
  def blank?
    true
  end
end

class FalseClass
  def blank?
    true
  end
end
```

* `true` obviously is not

```ruby
class TrueClass
  #   true.blank? # => false
  def blank?
    false
  end
end
```

* `Array` and `Hash` are `blank?` when they are `empty`? This is implemented using `alias_method`. You might wonder what about `Set`. This will be explained in a moment.

```ruby
class Array
  #   [].blank?      # => true
  #   [1,2,3].blank? # => false
  alias_method :blank?, :empty?
end

class Hash
  #   {}.blank?                # => true
  #   { key: 'value' }.blank?  # => false
  alias_method :blank?, :empty?
end
```

* `String#blank?` behavior was changed compared to what ruby does with `String#empty?` to account for whitespaces

```ruby
class String
  BLANK_RE = /\A[[:space:]]*\z/

  # A string is blank if it's empty or contains whitespaces only:
  #
  #   ''.blank?       # => true
  #   '   '.blank?    # => true
  #   "\t\n\r".blank? # => true
  #   ' blah '.blank? # => false
  #
  # Unicode whitespace is supported:
  #
  #   "\u00a0".blank? # => true
  #
  def blank?
    # The regexp that matches blank strings is expensive. For the case of empty
    # strings we can speed up this method (~3.5x) with an empty? call. The
    # penalty for the rest of strings is marginal.
    empty? || BLANK_RE.match?(self)
  end
end
```

This is convenient for web applications because you often want to reject or handle differently string which contain only invisible spaces.

* The logic for every other class is that if it implements `empty?` then that's what going to be used. It's interesting to see that the method and its behavior was documented fully here.

```ruby
class Object
  # An object is blank if it's false, empty, or a whitespace string.
  # For example, +false+, '', '   ', +nil+, [], and {} are all blank.
  #
  # This simplifies
  #
  #   !address || address.empty?
  #
  # to
  #
  #   address.blank?
  #
  # @return [true, false]
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
```

`!!empty?` - is just a double negation of `empty?`. This is useful in case `empty?` returned `nil` or a string or a number, something different than `true` or `false`. That way the returned value is always converted to a boolean value.

```ruby
!!true
# => true

!!false
# => false

!!nil
 => false

!!0
# => true

!!"abc"
# => true
```

If you implement your own class and define `empty?` method it will effortlessly work as well.

```ruby
class Car
  def initialize
    @passengers = []
  end

  def enter(passenger)
    @passengers << passenger
  end

  def empty?
    @passengers.empty?
  end

  def run
    # ...
  end
end

car = Car.new
car.blank?
# => true

car.enter("robert")

car.blank?
# => false
```

* No number or Time is blank. Frankly I don't know why these methods were implemented separately here and why the implementation from `Object` is not enough. Perhaps for speed of not checking if they have `empty?` method which they don't...

```ruby
class Numeric #:nodoc:
  #   1.blank? # => false
  #   0.blank? # => false
  def blank?
    false
  end
end

class Time #:nodoc:
  #   Time.now.blank? # => false
  def blank?
    false
  end
end
```

## `present?`

* Provided by Rails
* `present?` is just a negation of `blank?` and can be used on anything.

```ruby
class Object
  # An object is present if it's not blank.
  def present?
    !blank?
  end
end
```

## `presence`

Provided by Rails. Sometimes you would like to write a logic such as:

```ruby
params[:state] || params[:country] || 'US'
```

but because the parameters can come from forms, they might be empty (or whitespaced) strings and in such case you could get `''` as a result instead of `'US'`. This is where `presence` comes in handy.

Instead of

```ruby
state   = params[:state]   if params[:state].present?
country = params[:country] if params[:country].present?
region  = state || country || 'US'
```

you can write

```ruby
params[:state].presence || params[:country].presence || 'US'
```

The implementation is very simple:

```ruby
class Object
  def presence
    self if present?
  end
end
```

## So which one should you use?

If you are working in Rails I recommend using `present?` and/or `blank?`. They are available on all objects, work intuitively well (by following the principle of least surprise) and you don't need to manually check for `nil` anymore.

## Was this helpful?

If you liked this explanation please consider sharing this link on:

* your company's Slack or other chat - for the benefit of your coworkers
* Facebook & Twitter - for fellow developers who you are in touch with
