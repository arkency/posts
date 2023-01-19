---
created_at: 2023-01-19 16:30:49 +0100
author: Łukasz Reszke
tags: ['event sourcing', 'event store']
publish: false
---

# Replaying events in RailsEventStore

Event Sourcing comes with a very handy utility that lets you replay events that happened in the system. Imagine that you’re introducing a new report, or you fixed an existing event handler and you need to run some events against it to assemble a valuable outcome that your business friends expect.

<!-- more -->

_If you're not familiar with event sourcing, it's a way of storing the state of a system as a series of events, rather than just the current state. Check our [event sourcing tag](https://blog.arkency.com/tags/event-sourcing)._

## How to replay events using RailsEventStore?

It's simple!

Let's assume that we want to send a Xmas card to our customers that made at least 5 orders and haven't returned any of them during last 3 months. Luckily, in our system, we have events that will help us make decisions about which customers should receive the astonishing Xmas cards.

Those events are `OrderFulfilled` and `OrderReturned`. We also know exactly when they happened, right? We can easily find & replay events from the last 3 months and trigger the new functionality aka send Xmas cards. 

We'll need an instance of the `RailsEventStore` client. Then we need to specify which events you want to replay. The requirements are clear. We're interested in `OrderFulfilled` and `OrderReturned` events from the last 3 months. So let's prepare the list of events that will be replayed using the read API.

_Find all the events of type `OrderFulfilled` and `OrderReturned` that occurred in the last 3 months_

```ruby
events = client.read.of_type([OrderFulfilled, OrderReturned]).newer_than(3.months.ago).to_a
``` 

Events to be replayed are ready. `SendXmasCardToEligibleCustomer` is a class that determines whether the customer is eligible for a gift. If they're, it'll request sending the gift. Let's replay the events.

```ruby
events.each { |event| SendXmasCardToEligibleCustomer.new.call(event) }
```

And voila, we replayed the events for the needs SendXmasCardToEligibleCustomer class.

In this specific case we're instantiating the `SendXmasCardToEligibleCustomer` class and react to the event. However, there are other things that you could do. Given your handlers are idempotent, you could just publish those events once again.
