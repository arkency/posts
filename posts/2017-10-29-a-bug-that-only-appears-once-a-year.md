---
title: "A bug that only appears once a year"
created_at: 2017-10-28 22:03:26 +0200
kind: article
publish: true
author: Anton Paisov
tags: [ 'bugs', 'tests', 'testing' ]
newsletter: :skip
---

There are some bugs that only appear under certain circumstances. Today was the day I've got one of those (there is a hint in this sentence).

<!-- more -->

I pushed a small change and got a red build as a result. I already had the corresponding test fixed so red build was not something I was expecting.

An exception I've got was from a check in `TicketTransferPolicy` which had nothing at all to do with my changes. And so the investigation began.

```ruby
raise DeadlinePassed  if deadline_passed?(event)
```

```ruby
def deadline_passed?(event)
  if FT.on?(:extended_tickets_transfer_deadline, organizer_id: event.user_id)
    event.ends_at < Time.current
  else
    event.starts_at < Time.current.advance(days: 1)
  end
end
```

_Hint: failing test was not related to extended deadline._

I've looked into the failing test and here's the line that instantly got my attention:

```ruby
event = test_organizer.create_published_event(starts_at: 25.hours.from_now)
```

This was an instant 'aha' moment when I've realized, today's the day when we have 25 hours in the day.

In my opinion, the best solution here is to use `Time.current.advance(days: 1, hours: 1)` instead of `25.hours.from_now`, this approach is more consistent with the code we're testing.
Changing `25` to `26` would also work ;)

Thanks, [DST](https://www.timeanddate.com/time/dst/) :P