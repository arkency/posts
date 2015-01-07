---
title: "It's easy to miss a higher level concept in an app"
created_at: 2015-01-04 15:28:14 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

Just yesterday, I finished reading [Understanding the Four Rules of Simple Design](https://leanpub.com/4rulesofsimpledesign)
written by [Corey Haines](https://twitter.com/coreyhaines). I definitely
enjoyed reading it. The examples are small, understandable and a good starting point
for the small refactorings that follow. It's a short, inexpensive book, but dense with
compressed knowledge, and I can only recommend buying it. You can read it in a few hours, and contemplate it
for much longer.

One of the examples inspired me to write this blogpost about _higher level
concepts_. What does that even mean? Especially in terms of programming?

<!-- more -->

## Location

First, let's have a look at this example:

<a href="/assets/images/higher-level-concept/four_rules_of_simple_design_page_screenshot.png" rel="lightbox[rules]">
  <img src="/assets/images/higher-level-concept/four_rules_of_simple_design_page_screenshot-fit.png" width="100%">
</a>

Now you know a bit of the story related to the example from the book.

```
#!ruby
class Location
  attr_reader :x, :y
  def neighbors
    # calculate a list of locations
    # that are considered neighbors
  end
end
```

I looked at it and I was like: _hey, how would that even work?_...
This is not the right place for this method. It should be in `...` I won't tell
you yet, because I quickly realized that it could actually work...

This `Location` is basically just a [Value Object](http://martinfowler.com/bliki/ValueObject.html) 
and it could return all neighbour locations as value objects as well. Let's try to implement that.

```
#!ruby
class Location
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def neighbors
    return enum_for(:neighbors) unless block_given?
    (-1..1).each do |x_axis|
      (-1..1).each do |y_axis|
        next if x_axis == 0 and y_axis == 0
        yield Location.new(x + x_axis, y + y_axis)
      end
    end
  end

end
```

And you could use it like:

```
#!ruby
Location.new(0, 0).neighbors.to_a
# => [#<Location:0x00000000fde8a0 @x=-1, @y=-1>, #<Location:0x00000000fde878 @x=-1, @y=0>, #<Location:0x00000000fde850 @x=-1, @y=1>,
#     #<Location:0x00000000fde828 @x=0, @y=-1>,  #<Location:0x00000000fde7d8 @x=0, @y=1>,  #<Location:0x00000000fde7b0 @x=1, @y=-1>,
#     #<Location:0x00000000fde788 @x=1, @y=0>,   #<Location:0x00000000fde760 @x=1, @y=1>] 
```

This makes sense if you assume an infinite, 2-dimensional Map of square cells, which is the default for 
_Conway game of life_. But whenever you say _Game_ to me, first thing I think
about is _Civilization 5_ and its hexagonal Map.

<a href="/assets/images/higher-level-concept/civ5_map_hexes.jpg" rel="lightbox[civ5]">
  <img src="/assets/images/higher-level-concept/civ5_map_hexes-fit.jpg" width="100%">
</a>

When you say _Game_ to me, especially _board game_, I think _players,
maps, movements, rules_. Not all of those things make sense for _Conway game of life_ because
it is a _zero-player game_ but I think the intuition of Game still applies.

When discussing a different code example in the book, Corey reverses
the dependency between two objects. Instead of `Cell` knowing its location

```
#!ruby
class Cell
  attr_reader :location
end
```

Now the location can know what cell is on it, thus becoming a `Coordinate`:

```
#!ruby
class Coordinate
  attr_reader :x, :y
  attr_reader :cell
end
```

So when I think about location neighbors I start to wonder:

* should `Location` know about its neighbors, or
* should something else know what other locations are neighbors of a given location?
That something would be probably be a `Map` for me.

What is the better dependency direction here?

Did we miss the concept of `Map` perhaps? Could we gain something by adding
it? Would it be more or less intention-revealing? These are good questions
to ask.

I think games are particularly hard to implement _right_ because there are many rules
and behaviors that often require knowledge about pretty much anything else that's
happening in the Game. Corey explains it nicely at the beginning of the book when he
talks about the _better design_ concept.

## Month

A few months ago I wrote a blogpost that shows [how to implement a custom `YearMonth`
class in Ruby that would work with ruby Range](/2014/08/using-ruby-range-with-custom-classes/).

Basically `YearMonth` knows how to compute its successor, the next YearMonth. It also works nicely with iterating
and comparison.

```
#!ruby
range = YearMonth.new(2014, 1)..YearMonth.new(2014, 3)
# => #<struct YearMonth year=2014, month=1>..#<struct YearMonth year=2014, month=3>

range.each {|ym| puts ym.inspect }
# #<struct YearMonth year=2014, month=1>
# #<struct YearMonth year=2014, month=2>
# #<struct YearMonth year=2014, month=3>

YearMonth.new(2014, 1) <=> YearMonth.new(2014, 3)
# => -1
YearMonth.new(2014, 1) <=> YearMonth.new(2014, 1)
# => 0
YearMonth.new(2014, 3) <=> YearMonth.new(2014, 1)
# => 1
```

It was pointed out, however, that I was missing a higher level concept: a `Calendar`.
Days, Weeks, Months, and Years don't exist in a vacuum, but are parts of something
bigger: passing time, which we follow by using a Calendar.

And I agree. There are even different kind of calendars in use. I am not sure yet
if I have an intuition how to design a good `Calendar` class with a useful API.
And how would I do that so that all chunks of knowledge don't land in the `Calendar` class,
but only in one proper place?

## Employee

I was once writing an application for managing employees' holidays. In Europe you are allowed
a certain number of free days depending on how long have you been working, both in your life as a 
whole and for that particular employer (and other factors as well).

The application that I was working on was meant to be deployed separately to every company. So some of the queries
that I wrote were executed across entire sets in database, without scoping per company because
the data was meant to be for that one company. That made the code easier in some places, because I could
query things _globally_ when verifying the correctness of some business rules.

One pivot later, the product was an SaaS intended to be deployed in one place but to support
multiple companies. The concept that I was reluctant to introduce immediately became
necessary. Everything had to be scoped per company for each employee currently using the
system. It was a multi-tenant application.

Employees don't live in a vacuum either. There are parts of a company hiring them. I was writing
software for helping companies manage holidays for their employees and there was no concept
of the `Company` anywhere in the code. That was the higher-level concept I was missing.
