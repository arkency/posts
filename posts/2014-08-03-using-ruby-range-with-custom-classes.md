---
title: "Using ruby Range with custom classes"
created_at: 2014-08-03 12:04:03 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter: skip
newsletter_inside: arkency_form
tags: [ 'ruby', 'Range', 'custom class', 'time' ]
---

<p>
  <figure align="center">
    <img src="<%= src_fit("range-custom-class/baloon.jpg") %>" width="100%">
  </figure>
</p>

**I am a huge fan of Ruby classes, their API and overall design**. It's still sometimes that
something surprises me a little bit. I raise my eyebrow and need to find answers.
What surprised me this time was `Range` class. But let's start from the beginning (even though it is
a long digression from the main topic).

<!-- more -->

## Ruby, gimme my `Month` please. Would you? Kindly?

Every time I implement any kind of reporting functionality for our clients I wonder why
is there no `Month` class. I mean, **there is such concept as month. Why not make it a
class?** I wondered how other languages deal with it and it turns out Java recently added
[`Month` class](http://docs.oracle.com/javase/8/docs/api/java/time/Month.html) to its API.
I looked at its implementation, its methods and no... That's not what I want.

To add more to the confusion I realized that there are two concepts here

* YearMonth - the concept of particular month in particular year like `January 2014`. That's the thing
that I need.
* Month - the general concept of Month. Like `January` in general. Every _January_. Not just a specific one. This
what you have in the Java API.

So to avoid confusion I decided to think about my little object that I have in mind (_January 2014_) as `YearMonth`. If
you **come up with a better name for it, leave me a comment**. I honestly couldn't come up with anything different and more
sophisticated. Maybe because _English as second language_... Anyway...

## `YearMonth` and what not...

I the domain of _Reporting_ we often think in terms of Time periods. Our customers often would like to have
**reporting per days, weeks, months, quarters etc.** When someone tells me to create a report from _January 2014_ to
_May 2014_ with the accuracy of month, well... I would like to say in my code
`YearMonth.new(2014, 1)..YearMonth.new(2014, 5)`. That's how my OOP part of the brain thinks about the problem.

What are the clues telling us that despite having the variety of classes for operating on time
(like `Date`, `DateTime`, `Time` and even `ActiveSupport::TimeWithZone`) we still need more classes? I don't know this
will convince you but here are my thoughts:

### YearMonth

```ruby
# Actual
Time.days_in_month(2014, 1)
Time.new(2014, 1).end_of_month
```

vs

```ruby
# Imaginary
january2014 = YearMonth.new(2014, 1)
january2014.number_of_days
january2014.end_of
```

### Year

Same goes for other:

```ruby
Date.new(2000).leap?
Date.new(2000).beginning_of_year
```

vs

```ruby
year2000 = Year.new(2000)
year.leap?
year.beginning_of
```

### Week

```ruby
Date.new(2001, 2, 3).cweek
Date.new(2001, 2, 3).cwyear
```

vs

```ruby
week = Week.from_date(2001, 2, 3)
week.year
week.number
```


### The pattern

Here is the pattern that I see. Whenever we want to do something related to a **period** of time such as
_Year_, _Quarter_, _Month_, _Week_ we create an instance of **moment** (`Time`, `Date`) in time that
happens to belong to this period (such as first day or first second of year). Then we use this object to query it
about the attributes of the time period it belongs with methods such as `#beginning_of_year`, `#beginning_of_quarter`,
`#beginning_of_month`, `#beginning_of_week`.

So I think we are **often missing the abstraction of time periods** that we think about and that we work with. I understand
that these methods are very useful when what we are doing depends on current time or current day or selected moment provided
by the user. However in my case, when the users gives me an integer representing Year (_2014_) I would really like to
create an instance of Year and operate on it. Operating on bunch of static methods or creating
a Date (_January 1st, 2014_) to deal with Years **does not taste me**.

### Even deeper digression

**What does my boss say? 😉**He says that knowing about things such as next and previous month is not the responsibility
of `YearMonth` class but rather something above (conceptually higher) like a `Calendar`. It's not that `May 2014` knows
that the next month in a year is `June 2014` but rather the calendar knows about it. I find it an interesting point
of view. What do you think? 

## `YearMonth`

Ok, enough with the digressions. The main topic was using custom class with `Range`. Let's have an exemplary class.

```ruby
class YearMonth < Struct.new(:year, :month)

  def initialize(year, month)
    raise ArgumentError unless Fixnum === year
    raise ArgumentError unless Fixnum === month
    raise ArgumentError unless year > 0
    raise ArgumentError unless month >= 1 && month <= 12

    super
  end

  def next
    if month == 12
      self.class.new(year+1, 1)
    else
      self.class.new(year, month+1)
    end
  end
  alias_method :succ, :next

  def beginning_of
    Time.new(year, month, 1)
  end

  def end_of
    beginning_of.end_of_month
  end

  private :year=, :month=
end
```

This was used as a **Value Object attribute** in my AR class:

```ruby
class ReportingConfiguration < ActiveRecord::Base
  composed_of :start,
    class_name: YearMonth.name, 
    mapping: [ %w(start_year year), %w(start_month month) ]
    
  composed_of :end,
    class_name: YearMonth.name, 
    mapping: [ %w(end_year year), %w(end_month month) ]

  def each_month
    (self.start..self.end)
  end
end
```

And it was all supposed to work but...

## ... bad value for range

```ruby
YearMonth.new(2014, 1)..YearMonth.new(2014, 2)
# => ArgumentError: bad value for range
```

That certainly wasn't something that I was expecting.

## What do we use `Range` for?

Let's think a moment about it. What do we actually use the `Range` class for? There are at least two usecases:

* **iterating over the collection** (without the need to create all its elements)
* checking whether another **object is part of the `Range`** (again, without the need to create all its elements)

For both of the usecases we need to add different methods to our custom (`YearMonth`) class for it to be
compatible with `Range`.

### Iterating

```ruby
range = YearMonth.new(2014, 1)..YearMonth.new(2014, 3)
# => #<struct YearMonth year=2014, month=1>..#<struct YearMonth year=2014, month=3>

range.each {|ym| puts ym.inspect }
# #<struct YearMonth year=2014, month=1>
# #<struct YearMonth year=2014, month=2>
# #<struct YearMonth year=2014, month=3>
```

**Iterating requires you to implement `#succ` method.**

```ruby
  def next
    if month == 12
      self.class.new(year+1, 1)
    else
      self.class.new(year, month+1)
    end
  end
  alias_method :succ, :next
```

That's how our Range knows how to yield next element from the range collection.

But how does it know when to stop yielding next elements? When it creates the instance of `YearMonth.new(2014, 3)`
as a third element that is yielded how does it know that it is the last one?

Well that's when the next usecase comes handy.

### Inclusion

**Checking the inclusion of values in Range require you to implement the `<=>` operator**. In other
words your class should be [`Comparable`](http://www.ruby-doc.org/core-2.1.2/Comparable.html). And that's the thing I forgot about. And it actually makes sense because how
else would the `Range` know when to stop without the ability to compare last generated element with the upper bound of
your Range?

```ruby
class YearMonth
  include Comparable

  def <=>(other)
    (year <=> other.year).nonzero? || month <=> other.month
  end
end
```

If you are not familiar with `<=>` operator here is a little reminder for you. It should return `-1`, `0` or `1`
depending on whether the compared objects is greater, equal to, or lower:

```ruby
YearMonth.new(2014, 1) <=> YearMonth.new(2014, 3)
# => -1

YearMonth.new(2014, 1) <=> YearMonth.new(2014, 1)
# => 0

YearMonth.new(2014, 3) <=> YearMonth.new(2014, 1)
# => 1
```

If you have `<=>` operator implemented and include `Comparable` module into your class you get the behavior
of classic operators `<`, `<=`, `==`, `>=` and `>` for free:

```ruby
YearMonth.new(2014, 3) > YearMonth.new(2014, 1)
# => true

YearMonth.new(2014, 1) >= YearMonth.new(2014, 1)
# => true

YearMonth.new(2015, 1) < YearMonth.new(2014, 3)
# => false
```

### Doc

The [`Range`](http://www.ruby-doc.org/core-2.1.2/Range.html) documentation explains it nicely:

_Ranges can be constructed using any objects that can be compared using the `<=>` operator. Methods that treat the
range as a sequence (`#each` and methods inherited from `Enumerable`) expect the begin object to implement a `succ` method
to return the next object in sequence. The `step` and `include?` methods require the begin object to implement
`succ` or to be numeric._

### My Lesson

Somehow I expected that is the `#succ` methods that is most important for the `Range` to exist and work correctly.
Probably because I was so focused on the fact that ranges can iterate over elements.

It is however that the `<=>` method in your own class is the most important factor. That's because **you can check whether
element is part of range without the ability to iterate over subsequent elements. But you can't generate subsequent
elements without knowing which one is the last one** (or whether you should start iterating at all).

All this can be summarized in a few examples:

```ruby
# Range needs to know that 2 <= 1 is false
# so it doesn't start iterating
(2..1).each{|i| puts i} # no output
```

```ruby
# Range needs to know that 1.succ gives 2
# 2.succ gives 3
# and 3 == 3 so we need to stop iterating
(1..3).each{|i| puts i}
```

```ruby

# You can't iterate over classes that don't have #succ method

(1.0..2.0).each{|i| puts i}
# => TypeError: can't iterate from Float

1.0.succ
# => NoMethodError: undefined method `succ' for 1.0:Float
```

```ruby
# But you can check for inclusion in Range
(1.0..2.0).include?(1.5)
 => true
```

So `Range` will give always you the ability to check if something is in the range, but it only **might** give you the
ability to iterate.

<%= show_product_inline(item[:newsletter_inside]) %>

## Resources

* [Range documentation](http://www.ruby-doc.org/core-2.1.2/Range.html)
* [`#nonzero?`](http://www.ruby-doc.org/core-2.1.2/Numeric.html#method-i-nonzero-3F)
* [Back to basics: the mess we've made of our fundamental data types](https://www.youtube.com/watch?v=l3nPJ-yK-LU) - not
Ruby related but FYI, dates are more complicated then what usually like to think about them.
* [Falsehoods programmers believe about time](http://infiniteundo.com/post/25326999628/falsehoods-programmers-believe-about-time)
* [More falsehoods programmers believe about time; “wisdom of the crowd” edition](http://infiniteundo.com/post/25509354022/more-falsehoods-programmers-believe-about-time-wisdom)
* [`Time.days_in_month`](https://github.com/rails/rails/blob/b775987e72260233c66080483b3c964f9549d094/activesupport/lib/active_support/core_ext/time/calculations.rb#L18)
* [`composed_of` removed from Rails 4](http://blog.plataformatec.com.br/2012/06/about-the-composed_of-removal/)
* [Value objects and Aggregates in Rails](http://pankowecki.pl/ddd/index.html#/)

## Simple `YearMonth` implementation

```ruby
class YearMonth < Struct.new(:year, :month)
  include Comparable

  def initialize(year, month)
    raise ArgumentError unless Fixnum === year
    raise ArgumentError unless Fixnum === month
    raise ArgumentError unless year > 0
    raise ArgumentError unless month >= 1 && month <= 12

    super
  end

  def next
    if month == 12
      self.class.new(year+1, 1)
    else
      self.class.new(year, month+1)
    end
  end
  alias_method :succ, :next

  def <=>(other)
    (year <=> other.year).nonzero? || month <=> other.month
  end

  def beginning_of
    Time.new(year, month, 1)
  end

  def end_of
    beginning_of.end_of_month
  end

  private :year=, :month=
end
```
