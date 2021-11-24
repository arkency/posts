---
title: Difference between Cache and Read Model, an example
created_at: 2021-11-24T11:29:35.457Z
author: Tomasz Wróbel
tags: [ 'ddd', 'read model', 'cqrs', 'rails_event_store' ]
publish: true
---

Let's say you have a fairly complicated view: a calendar-like table with apartments to rent as rows and availability dates as columns.

<%= img_fit("cache-vs-read-model/cache-vs-read-model.png", title: "Courtesy of getlavanda.com") %>

Of course you want to be able to:

* filter by availability, by location
* sort
* paginate the list of properties
* paginate the dates (look at a different date range)

The server gives you a JSON which is then consumed by a client like a SPA frontend.

You need to join data from a couple different tables:

* `apartments`
* `addresses`
* `bookings`
* a sequence of dates

What happens next:

* At the beginning you just query your tables, do some joins.
* Later you optimize the queries and perhaps write some of them by hand.
* Developers keep extending this view over the years by adding more and more data.
* Clients grow their datasets and soon they start complaing about the page being too slow.
* You start to think about a solution to make it fast enough. Perhaps caching?

## Caching

In this case you want to cache the JSON responses.

* You need to cache a response for every combination of filters/pages/sorting
* You will probably cache on first request, so some of the requests can still be slow, no predictable performance 
* Warming up a cache can be cumbersome and feels dirty
* Now comes the second hardest problem of computer science: _cache expiration_ (the first one being _naming things_)

Is a cache the only option?

Let's look at...

## Read models

In this solution you'd do something different.

* Build a new DB table which is totally optimized for the queries that the client wants to do.
* Let's have a single table (as opposed to multiple cached variants per page/sorting/filters). This table should contain all the data for further pagination/sorting/filtering. (Generally, a read model does not have to be a single table. It doesn't have to be an SQL table at all. It can be anything from an in memory object to a file on the disc).
* Have all the fields as client-ready as possible. If you need to show the address alongside the apartment, instead of joining with `addresses` table, put this data into the read model table, so that now the row is as ready as possible. DB denormalization and data redundancy are allowed and very welcome. 
* If you need to have a complicated filter or sort expression, precalculate it and put it in a field to make querying as easy as possible

But how do we keep the read model up to date with the write model?

## How to keep the read model up to date — the _vanilla_ way

The "vanilla" way is pretty straightforward: 

```ruby
ApplicationRecord.transaction do
  booking = Booking.create!(params)
  CalendarReadModel.handle_booking_created(booking)
end  
```

You can move all these read-related methods from the original model to the read model. Feels good.

You need to update the read model everytime you change anything related to the read model (here: not only when creating a booking but also when adding another appartment, changing an addres, changing the price). Feels like a lot of work? Probably. But it might still be justifiable.

But it's not the only way to update the read model.

## How to keep the read model up to date — the _event-driven_ way

Here's the other approach. When you book an apartment, publish an event alongside it:

```ruby
ApplicationRecord.transaction do
  booking = Booking.create!(params)
  event_store.publish(BookingCreated.new(data: { booking_id: booking.id })
end
```

And subscribe the event to a handler that will update the read model:

```ruby
event_store.subscribe(
  -> event { CalendarReadModel.handle_booking_created(event) },
  to: [BookingCreated]
)
```

It's way more decoupled this way. It doesn't decrease the effort — you still need to react to changes in all the relevant models — but the implementation is arguably cleaner and simpler and there's so much more you can now do with the event that you publish.

It's worth noting, that the handler is synchronous so it will execute in the same transaction, just as in the "vanilla" example. You can make the handler asynchronous, but then you need to account for _eventual consistency_, meaning that there might be a little lag between what the read model shows and what the write model allows. It's a justifiable drawback in many situations.
