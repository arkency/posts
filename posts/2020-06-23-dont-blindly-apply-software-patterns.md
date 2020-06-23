---
title: "Don't blindly apply software patterns"
created_at: 2020-06-23 13:01:13 +0200
author: Mirosław Pragłowski
tags: ['ddd', 'saga', 'process manager']
publish: true
---

I went for a run today and I was catching up with some podcast episodes today
and I would like to share my comments to the great episode about sagas & process
managers published by [Mariusz Gil](https://twitter.com/mariuszgil) in the
[Better Software Design](https://bettersoftwaredesign.pl/episodes/5).

Mariusz has been talking with [Kuba Pilimon](https://twitter.com/jakubpilimon?lang=en).
This was the third episode when these devs have discussed how to design software using Domain Driven Design
techniques & design patterns. (The [podcast](https://bettersoftwaredesign.pl) is in Polish but some episodes - like the inverview with
[Alberto Brandolini](https://twitter.com/ziobrando) are recorded in English).

I've listened to this podcast and the overall discussion is very interesting but
I have some remarks:

<!-- more -->

## Patterns are not the silver bullet

Mariusz & Kuba have dicsussed the [saga pattern](https://dl.acm.org/doi/10.1145/38713.38742) based on the example of cinema seats reservations.
The model is simple - each `Seat` is an aggregate and to book 4 seats you need to have a saga
that will ensure that all 4 reservations are processed or all of them will be revoked by compensating actions.

The example was as follows (pardon the pseudocode):

```ruby
# ruby flavoured pseudocode here (time axis goes down)

    Process A             Process B
book_seat('A-1')      book_seat('A-3')
book_seat('A-2')      book_seat('A-4')
book_seat('A-3')      book_seat('A-5')
book_seat('A-4')
#... here  process A starts its compensating actions when booking of seat A-3
#    or A-4 has failed (booked already by process B)
```

This looks so simple - we have 2 processes (sagas). Each of them tries to book some
seats. The first wins. The other one runs its compensating action to release already
booked seats.

But the reality might not be that simple.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">There are only two hard problems in distributed systems: 2. Exactly-once delivery 1. Guaranteed order of messages 2. Exactly-once delivery</p>&mdash; Mathias Verraes (@mathiasverraes) <a href="https://twitter.com/mathiasverraes/status/632260618599403520?ref_src=twsrc%5Etfw">August 14, 2015</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Having that in mind we could imagine situation like this:

```ruby
# ruby flavoured pseudocode here (time axis goes down)

    Process A             Process B
book_seat('A-4')      book_seat('A-3')
book_seat('A-2')      book_seat('A-4')
book_seat('A-3')      book_seat('A-5')
book_seat('A-1')
```

What will be the result? `Process A` could not complete the saga - because seat `A-3` is already booked.
`Process B` could not complete its saga because seat `A-4` is already booked. Both are starting its
compensating actions and release all bookings. With some bad luck we could end up with seats that will
not be sold even when there was a huge demand - translating to business terms: diappointed customers
and lost revenue.

Another example I would like to comment is the most common example of saga pattern usage.
Booking a plane, a hotel and a car and releasing the bookings when one of these has failed.

## Don't blindly apply software patterns

Mariusz & Kuba have discussed several scenarios how this could be extended. But what I've missed here,
and what is always an issue for me when I read/hear this example is:

When you book plane, hotel & car and the car is not available what are your expectations?
I could be wrong - but I would expect that my plane & hotel is booked and then the system will
ask me what to do with missing car reservation. Definitelly I would not like the application
to cancel my plane & hotel bookings when the car is not available!

## What's the solution?

Just ask your business/domain expert. They probably handle this kind of situations
every day, business as usual. Don't blindly apply software design patterns. Talk to people.
Solve real world problems.
