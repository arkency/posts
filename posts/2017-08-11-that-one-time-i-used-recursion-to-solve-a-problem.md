---
title: "That one time I used recursion to solve a problem"
created_at: 2017-08-11 13:17:27 +0200
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'recursion' ]
newsletter: arkency_form
img: "recursion-recursive-function-method-ruby-rails/recursion_ruby.png"
---

Some time ago I was working on a problem and I could not find a satisfactory solution. But it all turned out to be much simpler when I reminded myself about a tool that I rarely use: recursive function.

<!-- more -->

You see... The iterators from Ruby's Enumerable and queries from ActiveRecord are so nice that you barely need anything different than `each` to solve a problem. And here I was trying to use `each` in 5 different ways, in various different approaches failing again and again.

## The story

The story goes like this. Your platform sells a ticket to an event. It might be for example a race or a marathon or other something completely different. Some of those competitions are pro or semi-pro and they are announced and purchased even 2 years upfront.

The attendees (or should I rather say sportspeople) need to provide sometimes quite a lot of additional, mandatory data that the organizer asks for. It can be the name of your team, your age, your personal best record, etc. That kind of data. Which can also change over time...

Also for many other kinds of events, the platform offers additional services such as insurance (in case an accident prevents you from going to an event) or postal delivery (lol, yep). Some kinds of those services require plenty of additional data as well. We don't ask for them before purchase because that would lower the conversion. So we ask about them after a purchase, on the very first page after you pay. However, some customers (so happy that they bought a ticket) don't provide this data immediately.

This can have various consequences. It might mean their insurance is not valid yet, it might mean that the organizer does not have all the necessary information about them. Or it might mean we can't send them those tickets via postal like they wanted. But we don't want our customers to experience these problems. We want them to be happy and get what they paid for. So we have implemented reminders. From time to time they should receive an email to fill out missing data. But not too often (because that's annoying) and not rarely (because they might miss them).

Also... The reminders work best close to the purchase (just after it, when customers still remember what's all the fuss about) and close to the date of the actual event (you are more concerned about providing proper data 1 week before a match or a race than 1 year before yet). The reminders are obviously not sent anymore when you provide all the necessary data.

I wanted to implement an algorithm that would schedule reminders progressively less often going from the moment purchase towards the event date. And similarly in the other direction from the event date back to sales date. And they both should meet somewehre in the middle. On a timeline, it would look like this.

<%= img_fit("recursion-recursive-function-method-ruby-rails/reminders-calendar-over-time.png") %>

## The problem

At the beginning all of my approaches were similar. Almost identical. I split the timeline in half. I iterated from left to right, doubling the distance in time for every reminder (up to 1 month). Similarly, I iterated from right to left, doubling as well.

But there was a big problem with that solution. If often happened that two reminders in the middle were either:

* too far away
  * the less annoying and problematic case.
  * because there was no reminder in the middle
  * it could be that some reminders were 50 days from each other
  * even though we wanted 1 month to be max
* too close
  * the more annoying case
  * reminders could be 2 days from each other
  * even though previous and next reminders were 1 month from each other

<%= img_fit("recursion-recursive-function-method-ruby-rails/far_close.png") %>

I tried about 3 different approaches and all failed the same way.

## The solution

You see... The problem was that I tried to iterate from left to right, from right to the left and combine the solutions around the middle. What worked for me instead? Iterating from both sides at the same time.

```ruby
  class Calculator
    def initialize(current_time:, event_starts_time:)
      @current_time = current_time
      @event_starts_time = event_starts_time
      @eb = ExponentialBackoff.new(12.hours, 1.month)
    end

    def compute
      sub_compute(@current_time, @event_starts_time, 0).sort
    end

    private

    def sub_compute(left_boundary, right_boundary, current_level)
      duration = @eb.interval_at(current_level).seconds
      available_time = right_boundary - left_boundary
      if available_time >= 3*duration
        [
          new_left  = left_boundary  + duration,
          new_right = right_boundary - duration,
        ] + sub_compute(new_left, new_right, current_level+1)
      elsif available_time >= 2*duration
        [
          left_boundary + available_time/2,
        ]
      else
        []
      end
    end
  end
```

It works like this:

* We go in two directions at the same time. From the moment of sale (`current_time`, `left_boundary`) we go to the right, increasing the time. And from the moment the event starts (`event_starts_time`, `right_boundary`), we go to left, decreasing time.
* In every step we have certain amount of time that we move over
  * starting with 12 hours
* At every next step we double the amount of time
  * but maximally up to 1 month.
* In every step there are 3 possible situations:
  * The amount of time between two previous reminders is soo big (`3*duration`) that we can add at least two reminders (`1*duration` from each side). We add the reminders and recursively try to deal with what amount of time we have left inside.
  * The amount of time between two previous reminders is sufficient enough to add exactly 1 reminder in the middle of it. For example, we have 76 days between reminders and duration equals one month. That's not enough to add two reminders separated by 1-month period. Instead, we add 1 reminder exactly 38 days from the previous and from the next reminder. It's more than 1 month (which I wanted to be max) but that's ok. At least we don't have two reminders close to each other.
  * There is not enough time to add any reminder in between

The whole solution is around 12 logical lines of code in total :)

Because the time distances between the purchase and the event are no bigger than a few years, I was not worried about possible stack-overflow. In longer periods of time, we need about 6 method calls to compute reminders for a whole year.

## PS

This week we are releasing our newest book "Domain-Driven Rails".

<div style="margin:auto; width: 480px;">
  <a href="/domain-driven-rails/">
    <img src="//blog-arkency.imgix.net/domain-driven-rails-design/cover7-100.png?w=480&h=480&fit=max">
  </a>
</div>

It already has 140 pages and contains 10 building blocks you can use in your Rails app to achieve better architecture.

Subscribe to our [newsletter](http://arkency.com/newsletter) to always receive best discounts and free Ruby and Rails lessons every week.
