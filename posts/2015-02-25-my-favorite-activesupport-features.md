---
title: "My favorite ActiveSupport features"
created_at: 2015-02-25 11:36:56 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter_inside: react_books
tags: [ 'rails', 'active support' ]
img: "active-support/favorite-ruby-active-support.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("active-support/favorite-ruby-active-support.jpg") %>" width="100%">
  </figure>
</p>

This is short and not so comprehensie list of my favorite
ActiveSupport features.

<!-- more -->

## `Array#second`

```ruby
%i(a b).second
# => :b
```

Useful in ad-hoc scripts when you get primitive data from file or API. Together
with `map` they give you `some_array.map(&:second)` to get what you want.

## `Array#extract_options`

```ruby
def options(*args)
  args.extract_options!
end

options(1, 2)        # => {}
options(1, 2, a: :b) # => {:a=>:b}
```

But with [ruby 2.0 keyword arguments aka _kwargs_](https://gist.github.com/jacknagel/5027997) already present
and ruby [1.9.3 support ending in February 2015](https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/)
you should probably migrate to it:

```ruby
def options(*args, **kwargs)
  args
  kwargs
end

options(1, 2)        # => {}
options(1, 2, a: :b) # => {:a=>:b}
```

## `Array#in_groups_of` and `Array#in_groups`

```ruby
%w(1 2 3 4 5 6 7 8 9 10).in_groups(3) {|group| p group}
#   ["1", "2", "3", "4"]
#   ["5", "6", "7", nil]
#   ["8", "9", "10", nil]

%w(1 2 3 4 5 6 7 8 9 10).in_groups_of(3) {|group| p group}
  #   ["1", "2", "3"]
  #   ["4", "5", "6"]
  #   ["7", "8", "9"]
  #   ["10", nil, nil]
```

Remember that you can add `false` as a second argument to avoid `nil`s
in the arrays.

## `Array#wrap`

Wraps its argument in an array unless it is already an array.

```ruby
def method(one_or_many)
  Array.wrap(one_or_many).each(&:do_something)
end

method(1)
method([3,4,5])
```

Nicely explained in the documentation [why it is better then usual ruby idioms](https://github.com/rails/rails/blob/71fc7892399bcb3ca24eff0a8f528e3bc8d7d82d/activesupport/lib/active_support/core_ext/array/wrap.rb)

## `to_formatted_s` on many types

```ruby
BigDecimal.new("12.23").to_s
#=> "0.1223E2"

require 'active_support/all'

BigDecimal.new("12.23").to_s
#=> "12.23"
BigDecimal.new("12.23").to_formatted_s
#=> "12.23"

Time::DATE_FORMATS[:w3c] = "%Y-%m-%dT%H:%M:%S%:z"
Time.now.to_s(:w3c)
#=> "2015-02-25T17:51:53+00:00"
```

ActiveSupport overwrites `to_s` on my types to use
its `to_formatted_s` version instead (especially when
arguments provided)

## `#ago`, `#from_now`

```ruby

Time.now.ago(3.months)
# => 2014-11-25 17:55:53 +0000

3.months.ago
# => 2014-11-25 17:56:00 +0000

3.months.ago(Time.now)
#=> 2014-11-25 17:56:03 +0000
```

## `beginning_of_...` & `end_of_...`

```ruby
%i(
  beginning_of_minute
  beginning_of_hour
  beginning_of_day
  beginning_of_week
  beginning_of_quarter
  beginning_of_month
  beginning_of_year
  end_of_minute
  end_of_hour
  end_of_day
  end_of_week
  end_of_month
  end_of_quarter
  end_of_year
).each{|method| puts "#{method} - #{Time.now.public_send(method)}"}


# beginning_of_minute - 2015-02-25 18:03:00 +0000
# beginning_of_hour - 2015-02-25 18:00:00 +0000
# beginning_of_day - 2015-02-25 00:00:00 +0000
# beginning_of_week - 2015-02-23 00:00:00 +0000
# beginning_of_quarter - 2015-01-01 00:00:00 +0000
# beginning_of_month - 2015-02-01 00:00:00 +0000
# beginning_of_year - 2015-01-01 00:00:00 +0000
# end_of_minute - 2015-02-25 18:03:59 +0000
# end_of_hour - 2015-02-25 18:59:59 +0000
# end_of_day - 2015-02-25 23:59:59 +0000
# end_of_week - 2015-03-01 23:59:59 +0000
# end_of_month - 2015-02-28 23:59:59 +0000
# end_of_quarter - 2015-03-31 23:59:59 +0000
# end_of_year - 2015-12-31 23:59:59 +0000
```

## `ActiveSupport::Duration`

The class behind the little trick:

```ruby
3.seconds.class
# => ActiveSupport::Duration
```

## `ActiveSupport::TimeWithZone`

I hate time zones, but I love `ActiveSupport::TimeWithZone`. It is so easy to use.

```ruby
Time.use_zone("Europe/Moscow"){ Time.zone.now }
# => Wed, 25 Feb 2015 21:09:12 MSK +03:00

Time.find_zone!("America/New_York").parse("2015-03-03 12:00:11")
# => Tue, 03 Mar 2015 12:00:11 EST -05:00

Time.find_zone!("America/New_York").parse("2015-03-03 12:00:11").utc
# => 2015-03-03 17:00:11 UTC

Time.utc("2015-03-03 12:00:11").zone
# => "UTC"
```

And I love that it can properly compare times from different timezones
based on what moment of time they point to.

```ruby
moment = Time.utc("2015-03-03 12:00:11")
#=> 2015-01-01 00:00:00 UTC

moment.in_time_zone("Europe/Warsaw") == moment.in_time_zone("America/Chicago")
=> true
```

## `Hash#except`

Returns a hash that includes everything but the given keys.

```ruby
hash = { a: true, b: false, c: nil}
hash.except(:c)
# => { a: true, b: false}
```

Except that I always think that this method is called `#without`.

## `Hash#slice`


Slice a hash to include only the given keys.
 
```ruby

{ a: 1, b: 2, c: 3, d: 4 }.slice(:a, :b)
# => {:a=>1, :b=>2}
```

If only I could remember that this method is not named `#only` :)

## `Hash#reverse_merge`

```ruby
options.reverse_merge(size: 25, velocity: 10)
```

is equivalent to

```ruby
{ size: 25, velocity: 10 }.merge(options)
```

This is particularly useful for default values.

## `Module#delegate`

```ruby
class Foo < ActiveRecord::Base
  belongs_to :greeter
  delegate :hello, to: :greeter
end
```

Reading this is way easier for me, compared
to [`Forwardable#def_delegator`](http://ruby-doc.org//stdlib-2.0/libdoc/forwardable/rdoc/Forwardable.html).

With `prefix` and `allow_nil` options that you can use with it,
it probably solves 95% of my delegation cases.

## `Object#blank?` and `Object#present?` and `Object#presence`

```ruby

nil.blank?
# => true
"  ".blank?
#=> true
[].blank?
=> true

title = commment[:title].presence || "Missing title"
```

Never check for `nil` or empty string again.

## `Enumerable#sum`

```ruby
[2,3,5].sum
# => 10
```

## `ActiveSupport::Notifications`

Too long for our short blogpost but check out [instrumentation API](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html)

## `ActiveSupport::MessageVerifier`

You can use it to generate and verify signed messages

```ruby
@verifier = ActiveSupport::MessageVerifier.new('s3Krit', serializer: JSON)
@verifier.generate("private message")
#=> "InByaXZhdGUgbWVzc2FnZSI=--43fc83190b28daf8df04c0b86ff2976931a6dcd2"
@verifier.verify("InByaXZhdGUgbWVzc2FnZSI=--43fc83190b28daf8df04c0b86ff2976931a6dcd2")
#=> "private message"

@verifier.generate("a" => "private message")
#=> "eyJhIjoicHJpdmF0ZSBtZXNzYWdlIn0=--b253af3e77622f743cf6804c870f4a95cbbd6f00"
@verifier.verify("eyJhIjoicHJpdmF0ZSBtZXNzYWdlIn0=--b253af3e77622f743cf6804c870f4a95cbbd6f00")
=> {"a"=>"private message"}
```

## Summary

That's it. You can browse entire ActiveSupport codebase quickly and easily at [github](https://github.com/rails/rails/tree/master/activesupport/lib/active_support)

If you liked it, you may also enjoy [Hidden features of Ruby you may not know about](/2014/07/hidden-features-of-ruby-you-may-dont-know-about/)

<%= show_product_inline(item[:newsletter_inside]) %>
