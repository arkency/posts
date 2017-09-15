---
title: "inject vs each_with_object"
created_at: 2017-08-29 13:30:53 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'enumerable' ]
newsletter: :arkency_form
img: "ruby-inject-each_with_object-comparison-vs/kitty-compares-inject-ruby-each_with_object.jpg"
---

Recently I've been adding new exercises to DevMemo.io and some of them were about `Enumerable#inject` (also available as aliased method `reduce`) and some of them were about `Enumberable#each_with_object`. And I've been thinking about a small guideline for when to use which.

<!-- more -->

## inject

* better for operations on mutable objects/collections which return a new value
* good for immutable primitives and value objects which return a new value when changed

## each\_with\_object

* better for mutable operations on objects/containers
  * especially such as Hash, Array
* it makes sense to use it if you provide a fresh object as a starting point and build it
  * not that useful if you want to modify an existing object

## Example 1

Let's see the differences with some examples. Imagine you have a collection of objects and you want to build a new Hash using them and perform some kind of mapping.

* You are building a new object (Hash `lower_to_upper`)
* There is a fresh, starting point `{}`

In such case, `each_with_object` is very convenient.

```ruby
lower = 'a'..'z'
lower_to_upper = lower.each_with_object({}) do |char, hash|
  hash[char] = char.upcase
end
```

On the other hand `inject` is less convenient:

```ruby
lower = 'a'..'z'
lower_to_upper = lower.inject({}) do |hash, char|
  hash[char] = char.upcase
  hash
end
```

because `inject` requires that the memoized value provided for subsequent block calls (`hash` which initially is `{}`) is returned by previous block calls. So even though you constantly operate on the same object, you always need to return it in the last line of the provided block.

`each_with_object` on the other hand always calls the block with the same initial object that was passed first as first argument to the method.

## Example 2

But let's say you already have an existing object that you would like to modify. In such case, it would be usually preferable to just use `each` over `each_with_object` but `each_with_object` can be a bit shorter if you still need to return the changed object.

All three versions below generate the same result.

```ruby
mapping = {'ż' => 'Ż', 'ó' => 'Ó'}
lower = 'a'..'z'
lower.each do |char|
  mapping[char] = char.upcase
end
return mapping # optionally
```

```ruby
mapping = {'ż' => 'Ż', 'ó' => 'Ó'}
lower = 'a'..'z'
lower.each_with_object(mapping) do |char, hash|
  hash[char] = char.upcase
end
```

```ruby
mapping = {'ż' => 'Ż', 'ó' => 'Ó'}
lower = 'a'..'z'
lower.each_with_object(mapping) do |char|
  mapping[char] = char.upcase
end
```

I would say that `each` is preferable if you mutate an existing collection, because usually you don't need to return it. After all, whoever gave you that object as an argument, wherever it comes from, that place in code probably still has reference to this object.

## Example 3

This time you are not mutating internal state of an object but rather always creating a new one. The operation that you use always returns a new object.

The most simple example can be `+` operator for numbers.

```ruby
a = 1
b = 2

a.frozen?
# => true
b.frozen?
# => true

c = a + b
# => 3
```

There is no way to change the Integer object referenced by variable `a` into `3`. The only thing you can do is assign a different object to variable `a` or `b` or `c`.

It's an obvious example. But `Date` is a less obvious one.

```ruby
require 'date'
d = Date.new(2017, 10, 10)
```

If you want a different date, you cannot change the existing `Date` instance. You need to create a new one.

```ruby
d.day=12
# => NoMethodError: undefined method `day=' for #<Date:

e = Date.new(2017, 10, 12)
```

So that was a small introduction. What does it have to do with `inject`. If your initial object is immutable, `inject` is the way to go.

```ruby
(5..10).inject(:+)
(5..10).inject(0, :+)
(5..10).inject{|sum, n| sum + n }

(5..10).inject(1, :*)
```

or

```ruby
starting_date = Date.new(2017,10,1)
result = [1, 10].inject(starting_date) do |date, delay|
  date + delay
end
# => Date.new(2017,10,12)
```

or

```ruby
# gem install money
require 'money'
[
  Money.new(100_00, "USD"),
  Money.new( 10_00, "USD"),
  Money.new(  1_00, "USD"),
].inject(:+)
# => #<Money fractional:11100 currency:USD>
```

## Example 4

This time we will be creating a new object every time but not because we can't change the internal state. This time it's because a certain method returns a new object.

```ruby
result = [
 {1 => 2},
 {2 => 3},
 {3 => 4},
 {1 => 5},
].inject(:merge)
# => {1=>5, 2=>3, 3=>4}
```

`Hash#merge` merges two hashes and returns a new one. That's why we can use it easily with `inject`.

Compare it with

```ruby
[
 {1 => 2},
 {2 => 3},
 {3 => 4},
 {1 => 5},
].each_with_object({}) {|element, hash| hash.merge!(element) }
# => {1=>5, 2=>3, 3=>4}
```

## Sidenote

Isn't it a bit irritating that the order of arguments passed to the block for `inject` and `each_with_object` is reversed?

```ruby
lower_to_upper = lower.each_with_object({}) do |char, hash|
  hash[char] = char.upcase
end

lower_to_upper = lower.inject({}) do |hash, char|
  hash[char] = char.upcase
  hash
end
```

## Learn more

Soon we will be launching Ruby's Enumerable course on [DevMemo.io](https://devmemo.io). [Try it](https://devmemo.io) and subscribe if you like it.
