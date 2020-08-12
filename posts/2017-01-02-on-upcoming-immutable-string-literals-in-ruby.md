---
created_at: 2017-01-02 11:23:52 +0100
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'immutable', 'string' ]
newsletter: arkency_form
---

# On upcoming immutable string literals in Ruby

Today I checked one of the solutions made by our [Junior Rails Developer class](/junior-rails-developer/)
student. As part of the course they make Rails apps but also learn from smaller
code examples delivered by exercism.io.

I found there an opportunity for him to learn more about a few things...

<!-- more -->

That's his code which inspired me for a reflection.

```ruby
string = ''
string += 'Pling' if num % 3 == 0
string += 'Plang' if num % 5 == 0
string += 'Plong' if num % 7 == 0
string += num.to_s if string.empty?
string
```

I recommended reading about `#tap`; how one could use a Hash to remove some duplication.
I also thought it could be a good occasion to talk about how Ruby String's are mutable
but in some time [string literals will be immutable](https://bugs.ruby-lang.org/issues/11473)
. The keyword here is **literals**.


Let's focus on a very small part of the code:

```ruby
string = ''
string += 'Pling' if num % 3 == 0
```

We could easily refactor it to:

```ruby
string = ''
string << 'Pling' if num % 3 == 0
```

But not when string literals are enabled to be immutable.

```
rvm use ruby-2.3.0
RUBYOPT=--enable-frozen-string-literal irb
```

```ruby
s = ""

s.frozen?
# => true 

s << "asd"
# RuntimeError: can't modify frozen String
```

Obviously, because `s = ""` is a string literal.

In such case we would need to go with a less elegant solution probably:

```ruby
string = String.new
string << 'Pling' if num % 3 == 0
```

because

```ruby
s = String.new

s.frozen?
# => false

s << "asd"
# => "asd"
```

So just be aware that in upcoming Ruby versions `s = ""` and
`s = String.new` might not be equal. And in the case when you
are building a new string via multiple transformations or
concatenations the 2nd version might be preffered.

I wonder if some time later ruby (4 ?) will make all Strings
immutable (not only those created via literals) and introduce
`StringBuilder` class like .Net or Java has?

Happy 2017!
