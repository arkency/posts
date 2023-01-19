---
created_at: 2023-01-19 16:30:49 +0100
author: Łukasz Reszke
tags: ['event sourcing', 'event store']
publish: false
---

# Replaying events in RailsEventStore

Event Sourcing comes with a very handy utility that lets you replay events that happened in the system. Imagine that you’re introducing a new report, or you fixed an existing event handler and you need to run some events against it to produce a valuable outcome that your business friends expect.

<!-- more -->

_If you are not familiar with event-sourcing, it's a way to store the state of a system as a series of events, not just the current state. Check out our [event sourcing tag](https://blog.arkency.com/tags/event-sourcing)._

## How do I replay events with RailsEventStore?

It's easy 

Let's assume that we want to send a Xmas card to our customers that made at least 5 orders and haven't returned any of them during last 3 months. Luckily, in our system, we have events that will help us make decisions about which customers should receive the astonishing Xmas cards.

Those events are `OrderFulfilled` and `OrderReturned`. We also know exactly when they happened, right? We can easily find & replay events from the last 3 months and trigger the new functionality aka send Xmas cards. 

We'll need an instance of the `RailsEventStore` client. Then we need to specify which events you want to replay. The requirements are clear. We're interested in `OrderFulfilled` and `OrderReturned` events from the last 3 months. So let's prepare the list of events that will be replayed using [the read API](https://railseventstore.org/docs/v2/read/).

_For detailed information on setting up the RailsEventStore client, see the [doc](https://railseventstore.org/docs/v2/install/#instantiate-a-client)._

Find all events of type `OrderFulfilled` and `OrderReturned` that have occurred in the last 3 months.

```ruby
events = client.read.of_type([OrderFulfilled, OrderReturned]).newer_than(3.months.ago).to_a
``` 

The events to do the replay are ready. `SendXmasCardToEligibleCustomer` is a class that will determine if the customer is eligible to receive a gift. If they are, there will be a request for the gift to be sent. Lets do a replay of our events.
```ruby
events.each { |event| SendXmasCardToEligibleCustomer.new.call(event) }
```

And voila, we have replayed the events for the needs of ``SendXmasCardToEligibleCustomer` class.

In this particular case we're instantiating the `SendXmasCardToEligibleCustomer` class and executing its logic based on the event passed to the call method. However, there are other things that you could do. Given your handlers are idempotent, you could simply re-publish those events once again.
