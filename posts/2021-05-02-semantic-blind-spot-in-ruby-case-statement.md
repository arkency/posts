---
created_at: 2021-05-02 19:16:20 +0200
author: Paweł Pacana
tags: ['mutant', 'ruby']
publish: false
---

# Semantic blind spot in Ruby case statement

Some time ago I've stumbled upon an [article](https://twitter.com/RubyInside/status/1387015675567353860) on case statements in Ruby. The author presents there an example of case statement with [ranges](https://ruby-doc.org/core-3.0.1/Range.html):

```ruby
case number
when (0..3)
	'low value'
when (4..7)
	'medium value'
when (8..10)
	'high value'
else
	'invalid value'
end
```

The ranges actually read well. I'd even write similar case statement myself. And yet... an avid [mutant](https://github.com/mbj/mutant) user may tell you there's a "flaw" hidden there. Can you spot it?

Let's pick one branch of that conditional for a closer look. Be it this one:

```ruby
when (8..10) then 'high value'
```

Assume we also have 100% line coverage, reported by [simplecov](https://github.com/simplecov-ruby/simplecov) for that example. That's rather easy to achieve:

```ruby
def test_high
  case_when = lambda do |number|
    case number
    when (0..3)
      'low value'
    when (4..7)
      'medium value'
    when (8..10)
	    'high value'
    else
	    'invalid value'
    end
	end

  assert_equal 'high value', case_when.call(8)
  assert_equal 'high value', case_when.call(9)
  assert_equal 'high value', case_when.call(10)
end
```

What would mutant report here, given that 100% line coverage?

```
Coverage:        88.00%
```

That drop of the coverage (as mutant sees it) can be attributed to conditions being shadowed by earlier branches. It doesn't really matter if the lower-bound of the range in condition is a bit off. The test still pass.

```diff
   case number
   when (0..3)
     "low value"
   when (4..7)
     "medium value"
-  when (8..10)
+  when (1..10)
     "high value"
   else
     "invalid value"
   end
```

The [mutant](https://github.com/mbj/mutant) gem is a way to automatically detect such semantic gaps:

> An automated code review tool, with a side effect of producing semantic code coverage metrics.
>
> Think of mutant as an expert developer that simplifies your code while making sure that all tests pass.

Yet you can perform such code mutations in small scale, manually. It's a matter of changing the lower-bound in range condition and re-rerunning the tests.

```ruby
def test_high
  case_when = lambda do |number|
    case number
    when (0..3)
      'low value'
    when (0..7)
      'medium value'
    when (0..10)
	    'high value'
    else
	    'invalid value'
    end
	end

  assert_equal 'high value', case_when.call(8)
  assert_equal 'high value', case_when.call(9)
  assert_equal 'high value', case_when.call(10)
end
```

So what's the semantically reduced case statement, that passes under mutant's scrutiny?

It appears to be this one:

```ruby
case
when number < 0
  'invalid value'
when number <= 3
  'low value'
when number <= 7
  'medium value'
when number <= 10
  'high value'
else
  'invalid value'
end
```

Would you call it a good middle ground? Is the case statement still useful in this form?

You can find the code used in this post on my [github](https://github.com/pawelpacana/case-mutant).

Happy mutation testing!
