---
title: "Hidden features of Ruby you may not know about"
created_at: 2014-07-24 19:54:59 +0200
kind: article
publish: true
author: Kamil Lelonek
tags: [ 'ruby', 'tips', 'tricks' ]
newsletter_inside: frontend_course
---

<p>
  <figure align="center">
    <img src="<%= src_fit("hidden-ruby-features/cherry_on_top.jpg") %>">
  </figure>
</p>

How well do you know the language you're using? What if I tell you that even you use it the whole day and every day it still can hide some tricks that you might not be aware of? I'd like to reveal some less or more known, but certainly **interesting parts of Ruby** to make you sure that you don't miss anything.

<!-- more -->

**Disclaimer**

Every example was run with:

    → ruby -v
    ruby 2.1.2p95 (2014-05-08 revision 45877) [x86_64-darwin13.0]

and

    → pry -v
    Pry version 0.10.0 on Ruby 2.1.2

## Binary numbers

```ruby
[1] pry(main)> 0b110111
=> 55

[2] pry(main)> "110111".to_i(2)
=> 55

[3] pry(main)> "%b" % 55
=> "110111"

[4] pry(main)> 55.to_s(2)
=> "110111"
```

## Because `== 0` is so mainstream

```ruby
[5] pry(main)> 0 == 0
=> true

[6] pry(main)> 0.zero?
=> true

[7] pry(main)> 0.nonzero?
=> nil

[8] pry(main)> 1.nonzero?
=> 1
```

[`nonzero?`](http://www.ruby-doc.org/core-2.1.2/Numeric.html#method-i-nonzero-3F) returns `self` unless number is zero, `nil` otherwise.


## Get some random date
```ruby
require 'active_support/core_ext'
def random_birth_date_with_age_between_20_and_30
  rand(30.years.ago..20.years.ago).to_date
end

[9] pry(main)> random_birth_date_with_age_between_20_and_30
=> Sun, 21 May 1989
```

## Call my name

```ruby
def introduce1
  __method__
end

def introduce2
  __callee__
end

[10] pry(main)> introduce1
=> :introduce1

[11] pry(main)> introduce2
=> :introduce2
```

<small>Thanks for <a href="http://blog.arkency.com/2014/07/hidden-features-of-ruby-you-may-dont-know-about/#comment-1502741048">Thiago A.</a></small>

## Hash from array(s)

```ruby
[12] pry(main)> ("a".."c").zip(1..3)
=> [["a", 1], ["b", 2], ["c", 3]]
[13] pry(main)> _.to_h
=> {"a"=>1, "b"=>2, "c"=>3}

[14] pry(main)> colors = ["cyan", "magenta", "yellow", "white"];
[15] pry(main)> Hash[*colors]
=> {"cyan"=>"magenta", "yellow"=>"white"}
```

Note that:

```ruby
[16] pry(main)> arr.count.even?
=> true
```

In the other case:

```ruby
[17] pry(main)> Hash[*['one', 'two', 'three']]
ArgumentError: odd number of arguments for Hash
```

## `%` notation
```ruby
%q[ ] # Non-interpolated String (except for \\ \[ and \])
%Q[ ] # Interpolated String (default)
%r[ ] # Interpolated Regexp (flags can appear after the closing delimiter)
%i[ ] # Non-interpolated Array of symbols, separated by whitespace
%I[ ] # Interpolated Array of symbols, separated by whitespace
%w[ ] # Non-interpolated Array of words, separated by whitespace
%W[ ] # Interpolated Array of words, separated by whitespace
%x[ ] # Interpolated shell command
```
Of course you can use other non-alpha-numeric character delimiters:

```ruby
%[including these]
%?or these?
%~or even these things~

%w what about spaces

%(parentheses)
%[square brackets]
%{curly brackets}
%<pointy brackets>
```

[Source and examples](http://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Literals#The_.25_Notation)

## 'Better' errors
```ruby
class MyCustomBadError < StandardError; end

MyCustomGoodError = Class.new(StandardError)
```

## Symbol to proc

```ruby
[18] pry(main)> (1..100).inject(:+)
=> 5050

[19] pry(main)> ("a".."e").map(&:upcase)
=> ["A", "B", "C", "D", "E"]
```

## Enumerators
```ruby
[20] pry(main)> enum = [1, 2, 3].each
=> #<Enumerator: ...>
[21] pry(main)> enum.next
=> 1
[22] pry(main)> enum.next
=> 2
[23] pry(main)> enum.next
=> 3
[24] pry(main)> enum.next
StopIteration: iteration reached an end
from (pry):17:in `next'
```

however

```ruby
[25] pry(main)> enum = [1, 2, 3].cycle
=> #<Enumerator: ...>
[26] pry(main)> enum.next
=> 1
[27] pry(main)> enum.next
=> 2
[28] pry(main)> enum.next
=> 3
[29] pry(main)> enum.next
=> 1
```

## Let's be lazy!
```ruby
[30] pry(main)> range = 1..Float::INFINITY
=> 1..Infinity
[31] pry(main)> range.map { |x| x+x }.first(10)
# infinite loop

[32] pry(main)> range.lazy.map { |x| x+x }.first(10)
=> [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
```

## Send a method
Here is nice trick to avoid tedious `{ |x| do_something_with(x) }`. This is a different case from symbol-to-proc, because we don't invoke method **on** `x` but call a method that takes `x`.

```ruby
[33] pry(main)> (1..5).each { |x| puts x }
1
2
3
4
5
=> 1..5

[34] pry(main)> (1..5).each &method(:puts)
1
2
3
4
5
=> 1..5
```

## Join my array
```ruby
[35] pry(main)> array = %w(this is an array)
=> ["this", "is", "an", "array"]
[36] pry(main)> array.join ', '
=> "this, is, an, array"
[37] pry(main)> array * ', '
=> "this, is, an, array"
```

## We have a ternary operator too
```ruby
def odd?(x)
  x % 2 == 0 ? 'NO' : 'YES'
end

[38] pry(main)> odd? 3
=> "YES"
[39] pry(main)> odd? 2
=> "NO"
```

## Rescue to the defaults
```ruby
[40] pry(main)> value = 1 / 0 rescue 0
=> 0
```

## Interpolate easier
```ruby
[41] pry(main)> @instance, @@class, $global = [ 'instance', 'class', 'global' ]
=> ["instance", "class", "global"]
[42] pry(main)> p "#@instance, #@@class, #$global";
instance, class, global
```

## Wrap a method
```ruby
def caller(block_or_method)
  block_or_method.call
end

def foo
  p 'foo'
end

[43] pry(main)> caller lambda { foo }
"foo"
=> "foo"
[44] pry(main)> caller -> { foo }
"foo"
=> "foo"
[45] pry(main)> caller method(:foo)
"foo"
=> "foo"
```

## Memoization
```ruby
fibbonacci = Hash.new do |accumulator, index|
  accumulator[index] = fibbonacci[index - 2] + fibbonacci[index - 1]
end.update(0 => 0, 1 => 1)

[46] pry(main)> fibbonacci[100]
=> 354224848179261915075
```

## Tap here
```ruby
class Foo
  attr_accessor :a, :b, :c
end

foo = Foo.new
foo.a = 'a'
foo.b = 'b'
foo.c = 'c'

Foo.new.tap do |foo|
  foo.a = 'a'
  foo.b = 'b'
  foo.c = 'c'
end
=> #<Foo:0x007fe1bd5f6210 @a="a", @b="b", @c="c">
```

## Nest some stuff
```ruby
[47] pry(main)> 
nested_hash = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
=> {}
[48] pry(main)> nested_hash[:x][:y][:z] = :xyz
=> :xyz
[49] pry(main)> nested_hash
=> {:x=>{:y=>{:z=>:xyz}}}
```

## Daemonize it
```ruby
# daemon.rb
Process.daemon
loop do
  sleep
end
```

    λ MacBook-Pro-Kamil Desktop → ruby daemon.rb
    λ MacBook-Pro-Kamil Desktop → ps aux | grep daemon
       kamil 41629 0.0 0.0 2472380 472 ?? S 11:45PM 0:00.00 ruby daemon.rb


## Candy shop
```ruby
require 'yaml/store'
store = YAML::Store.new 'candy.yml'

store.transaction do
  store['candy']    = "m&m's"
  store['lollipop'] = 'Chupa Chups'
end

store.transaction do
  store.abort # you can resign from buying
end

store.transaction do
  p store['candy']    # "m&m's"
  p store['lollipop'] # 'Chupa Chups'
end
```

## `Struct` on
```ruby
Struct.new('Tuple', :first, :second) do
  def pair
    "(#{first}, #{second})"
  end
end

[50] pry(main)> struct = Struct::Tuple.new('left', 'right')
=> #<struct Struct::Tuple first="left", second="right">
[51] pry(main)> struct.pair
=> "(left, right)"
```

## Have some defaults
```ruby
[52] pry(main)> zoo = Hash.new { |hash, key| hash[key] = 0 }
=> {}
[53] pry(main)> zoo.fetch :gorillas, 0
=> 0
[54] pry(main)> zoo.fetch :gorillas
=> 0
[55] pry(main)> zoo[:gorillas]
=> 0
```

And [many more](http://www.ruby-doc.org/core-2.1.2/Hash.html#method-i-default).

## Painless arrays
```ruby
# array of size 3 containing only 0s
[56] pry(main)> Array.new(3, 0)
=> [0, 0, 0]

# choose random number and "replicate" it 3 times
[57] pry(main)> Array.new(3, rand(10))
=> [8, 8, 8]

# build array of size 3 with random number on each index
[58] pry(main)> Array.new(3) { rand(100) }
=> [17, 99, 72]
```

## Play with URLs

```ruby
require 'uri'

[59] pry(main)> URI::HTTP.build(['kamil', 'arkency.com', 8080, '/path', 'query', 'fragment'])
=> #<URI::HTTP:0x007f8efd43a150 URL:http://kamil@arkency.com:8080/path?query#fragment>

require 'active_support/core_ext/object/to_query'

[60] pry(main)> 
"http://www.arkency.com?" + { language: "ruby", status: "professional" }.to_query
=> "http://www.arkency.com?language=ruby&status=professional"

require 'cgi'
[61] pry(main)> CGI::parse "language=ruby&status=awesome"
=> {"language"=>["ruby"], "status"=>["awesome"]}
```

## Access the hash

```ruby
require 'active_support/core_ext/hash/indifferent_access'

[62] pry(main)> 
rgb = { black: '#000000', white: '#FFFFFF' }.with_indifferent_access
=> {"black"=>"#000000", "white"=>"#FFFFFF"}
[63] pry(main)> rgb[:black]
=> "#000000"
[64] pry(main)> rgb['black']
=> "#000000"
```

## Expand range

```ruby
[65] pry(main)> p *(1..5)
1
2
3
4
5
=> [1, 2, 3, 4, 5]

[66] pry(main)> [*('a'..'e')]
 => ["a", "b", "c", "d", "e"]

[67] pry(main)> numbers = *('00'..'10')
 => ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10"]
```

## Less verbose with ;

Did you know that placing a semicolon at the very end of line hides its output? It may be helpful when some expression produces a lot of data, which we want to just assign to variable instead of directly printing in output.

```ruby
"a"..."z"
[68] pry(main)> alphabet = *('a'...'z')
[
  [ 0] "a",
  [ 1] "b",
  [ 2] "c",
  [ 3] "d",
  [ 4] "e",
  [ 5] "f",
  [ 6] "g",
  [ 7] "h",
  [ 8] "i",
  [ 9] "j",
  [10] "k",
  [11] "l",
  [12] "m",
  [13] "n",
  [14] "o",
  [15] "p",
  [16] "q",
  [17] "r",
  [18] "s",
  [19] "t",
  [20] "u",
  [21] "v",
  [22] "w",
  [23] "x",
  [24] "y"
]
[69] pry(main)> alphabet = *('a'...'z');
[70] pry(main)>
```

<small>Inspired by <a href="http://blog.arkency.com/2014/07/hidden-features-of-ruby-you-may-dont-know-about/#comment-1555213512">1jgjgjg</a></small>

## Call a proc

In how many ways can we call a proc? Actually in a few:

```ruby
[71] pry(main)> my_proc = -> argument { puts argument }
#<Proc:0x007fb1ebe9c1a0@(pry):7 (lambda)>
[72] pry(main)> my_proc.call('hello')
hello
nil
[73] pry(main)> my_proc.('hello')
hello
nil
[74] pry(main)> my_proc['hello']
hello
nil
```

<small>Thanks for <a href="http://blog.arkency.com/2014/07/hidden-features-of-ruby-you-may-dont-know-about/#comment-1554676190">Jordan Running</a></small>


# Summary
Impressed? If no, that's great! It means you are a trouper. Otherwise, it's good too, because you learned something new today and I hope you find this useful.

If you have your favourite tricks, you can share them in the comments below.

<%= show_product_inline(item[:newsletter_inside]) %>
