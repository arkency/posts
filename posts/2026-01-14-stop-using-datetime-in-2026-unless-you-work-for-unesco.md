---
created_at: 2026-01-14 15:08:58 +0100
author: Szymon Fiedler
tags: [ruby, rails, time, datetime, legacy]
publish: true
---

# Stop using DateTime in 2026 (unless you work for UNESCO)

`DateTime` has been considered deprecated in Ruby since 3.0. It's 2026. Why are people still using it?

<!-- more -->

During a recent code review, we found this:

```ruby
whatever.starts_at = DateTime.now
```

When asked why `DateTime` instead of `Time`, the response was: "`DateTime` handles a wider range of dates."

That was partially true. In 2008. On 32-bit systems.

## DateTime's range advantage died in Ruby 1.9.2

Before Ruby 1.9.2 (released in 2010), Time was limited by the system's `time_t` type — typically 32-bit signed integer covering 1901-2038. `DateTime` had a much wider range.

[Ruby 1.9.2 changed this](https://ruby-doc.org/core-2.1.9/Time.html). Time started using a signed 63-bit integer representing nanoseconds since epoch, giving it a range of 1823-2116. For dates outside this range, `Time` uses `Bignum` or `Rational` — slower, but it works.

The practical range advantage is gone.

## Remember Rails 4.2?

[_Pepperidge Farm Remembers_](https://knowyourmeme.com/memes/pepperidge-farm-remembers). 
Some time ago when upgrading Rails app from 4.2 to 5.0, the test suite fortunately failed. The culprit was surprising: `DateTime#utc` changed its return type.

[Rails 4.2](https://api.rubyonrails.org/v4.2/classes/DateTime.html#method-i-utc):

```ruby
DateTime.now.utc.class
# => DateTime
```

[Rails 5.0](https://api.rubyonrails.org/v5.0/classes/DateTime.html#method-i-utc):

```ruby
DateTime.now.utc.class # => Time
```

This broke several `Dry::Struct` objects with strict type definitions expecting `DateTime`. But instead of "fixing" the types, we asked a better question: *why were we using `DateTime` at all?*

Rails 5's breaking change to `DateTime#utc` wasn't a bug — it was a nudge. It was telling you: stop using this class.

[Struggling with upgrades? We have a solution for you](https://arkency.com/ruby-on-rails-upgrades/).

## The UNESCO problem

There's actually **one** legitimate use case for `DateTime`: historical calendar reforms.

From [Ruby's own documentation](https://ruby-doc.org/stdlib-2.4.1/libdoc/date/rdoc/DateTime.html):

> It's a common misconception that William Shakespeare and Miguel de Cervantes died on the same day in history - so much so that UNESCO named April 23 as World Book Day because of this fact. However, because England hadn't yet adopted the Gregorian Calendar Reform (and wouldn't until 1752) their deaths are actually 10 days apart.

Ruby's `Time` uses a proleptic Gregorian calendar — it projects the Gregorian calendar backwards, ignoring historical reality. October 10, 1582 doesn't exist in Italy (Pope Gregory XIII removed 10 days that October), but Ruby happily creates that timestamp.

`DateTime` can handle different calendar reform dates:

```ruby
shakespeare = DateTime.iso8601('1616-04-23', Date::ENGLAND)
cervantes = DateTime.iso8601('1616-04-23', Date::ITALY)

(shakespeare - cervantes).to_i # => 10 days apart
```

For cataloging historical artifacts or dealing with pre-1752 dates across different countries, `DateTime` is your tool.

For literally everything else — which is 99.99% of applications — it's the wrong choice.

Norbert Wójtowicz gave an excellent [talk about calendars at wroclove.rb](https://www.youtube.com/watch?v=YiLlnsq2fJ4) covering exactly these issues.

## `DateTime`’s actual problems

**No timezone support**. DateTime doesn't handle timezones.

```ruby
DateTime.now
# => #<DateTime: 2026-01-14T13:00:00+00:00>
# Why +00:00 when my system is CET (+01:00)?
```

**Incompatible with Rails**. `ActiveSupport` extends `Time` with timezone support. `DateTime`? Barely.

```ruby
Time.current   # ✅ Respects Rails.application.config.time_zone
DateTime.now   # ❌ Uses system timezone, ignores Rails config
```

**Confusing arithmetic**:

```ruby
Time.now + 1      # => 1 second later
DateTime.now + 1  # => 1 day later
```

This has caused bugs. Many bugs.

**Ignores DST**. `DateTime` doesn't track daylight saving time. If you use `DateTime` for anything involving timezones, you will have bugs.

**Performance**. `Time` is faster. Noticeably.

## Why people still use it

**"We've always used it"**

The code was written in 2009. It's 2026. Update it.

**"I need to store dates without time"**

Use `Date`. That's what it's for.

```ruby
Date.current  # ✅ Rails.application.config.time_zone aware
```

**"The library I'm using returns DateTime"**

Convert immediately:

```ruby
legacy_gem.fetch_date.to_time.in_time_zone
```

## What to use instead

For timestamps: `Time.current` or `Time.zone.now`

For dates: `Date.current`

For parsing: `Time.zone.parse('2026-01-14 13:00:00')`

## The only exception

If you're cataloging historical documents, artifacts, or working with dates before calendar reforms in different countries, `DateTime` is your tool. You need to track which calendar reform date applies.

For everything else — modern applications, APIs, databases — use `Time`.

`DateTime` is deprecated for a reason.

## References

- [Ruby Time documentation - Ruby 1.9.2 changes](https://ruby-doc.org/core-2.1.9/Time.html)
- [Ruby DateTime documentation - UNESCO calendar problem](https://ruby-doc.org/stdlib-2.4.1/libdoc/date/rdoc/DateTime.html)
- [Norbert Wójtowicz - It's About Time (wroclove.rb)](https://www.youtube.com/watch?v=YiLlnsq2fJ4)
- [Ruby Style Guide: No DateTime](https://rubystyle.guide/#no-datetime)
