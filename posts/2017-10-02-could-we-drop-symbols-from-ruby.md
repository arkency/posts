---
created_at: 2017-10-02 17:55:44 +0200
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'symbols' ]
newsletter: arkency_form
img: "ruby-symbols-strings/drop-symbols.jpeg"
---

# Could we drop Symbols from Ruby?

Don't know about you, but I personally have been hit a least a dozen times by bugs caused by strings vs symbols distinction. That happened in my own code, and it happened when using some other libraries as well. I like how symbols look in the code, but I don't like the specific distinction that is made between them and strings. In my (perhaps controversial opinion) they introduce more problems than they solve.

<!-- more -->

So I was thinking... Maybe we could drop them? Sounds radical right? But I don't think rewriting thousands of Ruby libraries to remove every `:symbol` is a viable strategy. So maybe there is a different option? Maybe symbol literals could become frozen, immutable strings. How could that work?

## Imagine a world in which...

It's hard for me to describe a solution very well in long paragraphs. So I thought I would rather try to demonstrate the properties that I imagine and let the code speak for itself. So... Imagine a world in which...

```ruby
:foo == :foo  # true
:foo == "foo" # true
```

This is what I started with. My goal. I don't want to care anymore if I have a string or symbol. Of course, nothing is that easy. We need more properties (test cases) to fully imagine how that could work.

Usually my use-case is about taking something out of a hash or putting into a hash. Let's express it.

```ruby
{"foo" => 1}[:foo] == 1 # true
{foo: 1}["foo"]    == 1 # true
```

That would make my life easier :)

For that we need:

```ruby
:foo.hash == "foo".hash # true
```

Whenever you put or get something out of a `Hash` (or `Set`) Ruby uses `Object#hash` as input to a hashing function. If two objects are equal they should return the same `hash`. Otherwise Ruby won't properly find objects in a Hash. Let me show you an example:

```ruby
class Something
  def initialize(val)
    @val == val
  end
  att_reader :val

  def ==(another)
    val == another.val
  end
end

a = Something.new(1)
b = Something.new(1)

hash = {a => "text"}
hash[a] # => "text"
hash[b] # => nil
```

You defined a Value Object. A class that is defined by its attributes (one or many) and which uses them for comparison. But because we haven't implemented `hash` method, Ruby doesn't know they can be used interchangeably as Hash keys.

```ruby
a.hash
# => 2172544926875462254

b.hash
# => 2882203462531734027
```

If two objects return the same `hash` on the other hand that does not mean they are equal. There is a limited number of hashes available so conflicts can rarely occur. But if two objects are equal, they should return the same hash.

```ruby
class Something
  BIG_VALUE = 0b111111000100000010010010110011101011000100010101001100100110000
  def hash
    [@val].hash ^ BIG_VALUE
  end
end
```

Usually, you compute the hash as hash of array of all attributes XORed with a big random value to avoid conflicts with that exact array of all attributes. In other words, we want:

```ruby
Something.new(1).hash != 1.hash
Something.new(1).hash != [1].hash
```

But that was a digression. Let's get back to the merit.

I would love:

```ruby
{"foo" => 1}[:foo] == 1 # true
{foo: 1}["foo"]    == 1 # true
```

And for that we would need:

```ruby
:foo.hash == "foo".hash # true
```

But here is the thing. It might be that [computing a Symbols's hash is 2-3 times faster than a String's hash right now](https://gist.github.com/hubertlepicki/dc7b69b457d9187033d0e0d7c79b19fd). I don't know why. Maybe Symbols, which are immutable have a pre-computed hash or can have a memoized hash value because it won't change. I am not sure. But if that's the reason, I can imagine that frozen, immutable Strings could have lazy-computed, memoized hash value as well.

I believe there is a lot of libraries and apps out there that rely on that fact:

```ruby
:foo.object_id == :foo.object_id
```

So obviously that should be preserved. But I believe if symbols were strings and Ruby would internally keep a unique list of them, just like doing it today for us, everything would work without a problem.

After all, the fact that you always get the same symbol is just a mapping somewhere in Ruby implementation from

```ruby
{"foo" => Symbol.new("foo")}
```

Historically, it was not even garbage-collected. Now it is.

So with:

```ruby
{"foo" => "foo".freeze}
```

somewhere there in Ruby internals, we could still get the same object when we ask for `:foo` :

```ruby
:foo.object_id == :foo.object_id # true
:foo.equal?(:foo)                # true
```

Let's continue this journey. Here is a problematic area:

```ruby
foo = "foo"
foo.equal?(foo.to_s) # true
```

`String#to_s` basically returns `self` in Ruby. So if Symbols were frozen strings this would break:

```ruby
foo = :foo
bar = foo.to_s
bar << " baz"
```

because `bar` would be the same object as `foo` instead of a new string (like it is right now for Symbols).

Here is another potential issue. There might be libraries out there checking if an object is a symbol.

```ruby
if var.is_a?(Symbol)
  # do something
else
  # do it differently or not at all
end
```

I was thinking how to solve it... How could we distinguish `:foo` from `"foo"` if we really needed.

I see two options. Make `Symbol` work like `String` without making it a `String` (either by adding all the methods or making it an alias `Symbol = String`).
And another option. Make `Symbol` inherit from `String` so `Symbol < String`.

With that

```ruby
:foo.is_a?(Symbol)
```

would be true. But...

```ruby
:foo.is_a?(String)
```

would also be true.

The difference could be that `Symbol#to_s` would be redefined to return new, identical, unfrozen String instead of the same one.

So maybe something like that.

```ruby
class Symbol < String
  def initialize(val)
    super
    freeze
  end

  def to_s
    "#{self}"
  end

  def hash
    @hash ||= super
  end
end
```

I doubt that's gonna happen. Probably too many corner cases right now to introduce such a change. But if we could drop `Fixnum` and `Bignum`, maybe we can drop `Symbol`?

Would we even want to? What's your opinion? Do you need `Symbol` class in your code? Or do you just like the symbol notation?

I will leave you with a [quote by Matz](https://bugs.ruby-lang.org/issues/7792)

> Symbols are taken from Lisp symbols, and they has been totally different beast from strings. They are not nicer (and faster) representation of strings. But as Ruby stepped forward its own way, the difference between symbols and strings has been less recognized by users.

And if you think that would be a bad idea, let me tell you that he tried but failed.

<blockquote class="twitter-tweet" data-cards="hidden" data-lang="en"><p lang="en" dir="ltr">We tried &amp; failed. <br>Link:  Could we drop Symbols from Ruby? | Arkency Blog <a href="https://t.co/um0xnWSpcQ">https://t.co/um0xnWSpcQ</a></p>&mdash; Yukihiro Matsumoto (@yukihiro_matz) <a href="https://twitter.com/yukihiro_matz/status/916083723589656576?ref_src=twsrc%5Etfw">October 5, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

I guess too many libraries out there rely on checking if an object is Symbol or not.

And in Smalltalk Symbols inherit from Strings:

<blockquote class="twitter-tweet" data-conversation="none" data-lang="en"><p lang="en" dir="ltr">Hey, Just a comment on the article: In Smalltalk, Symbols actually do inherit from string: <a href="https://t.co/YtQO91N0p7">pic.twitter.com/YtQO91N0p7</a></p>&mdash; Tobias (@krono) <a href="https://twitter.com/krono/status/916402697183535106?ref_src=twsrc%5Etfw">October 6, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
