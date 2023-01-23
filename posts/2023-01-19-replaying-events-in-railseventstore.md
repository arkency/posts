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

Let's assume that we want to send a Xmas card to our customers that made at least 5 orders and haven't returned any of them during last 3 months. Luckily, in our system, we have events that will help us make decisions about which customers should receive the astonishing Xmas cards.

Those events are `OrderFulfilled` and `OrderReturned`. We also know exactly when they happened, right? We can easily find & replay events from the last 3 months and trigger the new functionality aka send Xmas cards. 

We'll need an instance of the `RailsEventStore` client. Then we need to specify which events you want to replay. The requirements are clear. We're interested in `OrderFulfilled` and `OrderReturned` events from the last 3 months. So let's prepare the list of events that will be replayed using [the read API](https://railseventstore.org/docs/v2/read/).

_For detailed information on setting up the RailsEventStore client, see the [doc](https://railseventstore.org/docs/v2/install/#instantiate-a-client)._

Find all events of type `OrderFulfilled` and `OrderReturned` that have occurred in the last 3 months.

```ruby
events = client.read.of_type([OrderFulfilled, OrderReturned]).newer_than(3.months.ago)
``` 

The events to do the replay are ready. `SendXmasCardToEligibleCustomer` is a class that will determine if the customer is eligible to receive a gift. If they are, there will be a request for the gift to be sent. Lets do a replay of our events.
```ruby
events.each { |event| SendXmasCardToEligibleCustomer.new.call(event) }
```

And voila, we have replayed the events for the needs of the `SendXmasCardToEligibleCustomer` class.

In this particular case we're instantiating the `SendXmasCardToEligibleCustomer` class and executing its logic based on the event passed to the call method. However, there are other things that you could do. Given your handlers are idempotent, you could simply re-publish those events once again.

## One way to implement such example

Lets take a look at a possible implementation of `SendXmasCardToEligibleCustomer`.

```ruby
class SendXmasCardToEligibleCustomer
  NUMBER_OF_DAYS_TO_RETURN_ORDER = 14.days.freeze

  class State
    def initialize
      @fulfilled_orders = []
      @has_no_returned_orders = true
      @completed = false
      @version = -1
      @event_ids_to_link = []
    end

    def mark_as_completed
      @completed = true
    end

    def apply_order_fulfilled(order_id, fulfillment_date)
      @fulfilled_orders << { order_id: order_id, fulfillment_date: fulfillment_date }
    end

    def apply_order_returned
      @has_no_returned_orders = false
    end

    def complete?
      @fulfilled_orders.size >= 5 &&
        @has_no_returned_orders &&
        last_fulfilled_order_return_date_passed?
    end

    def last_fulfilled_order_return_date_passed?
      @fulfilled_orders
        .map { |order| order.fetch(:fulfillment_date) }
        .all? { |date| date + NUMBER_OF_DAYS_TO_RETURN_ORDER < Time.now }
    end

    def apply(*events)
      events.each do |event|
        case event
        when OrderFulfilled
          apply_order_fulfilled(
            event.data.fetch(:order_id),
            event.data.fetch(:fulfilled_at)
          )
        when OrderReturned
          apply_order_returned
        end
        @event_ids_to_link << event.id
      end
    end

    def load(stream_name, event_store:)
      events = event_store.read.forward(stream_name)
      events.each { |event| apply(event) }
      @version = events.size - 1
      @event_ids_to_link = []
      self
    end

    def store(stream_name, event_store:)
      event_store.link(@event_ids_to_link, stream_name: stream_name, expected_version: @version)
      @version += @event_ids_to_link.size
      @event_ids_to_link = []
    end
  end
  private_constant :State

  def call(event)
    customer_id = event.data(:customer_id)
    stream_name = "SendXmasCardToEligibleCustomer$#{customer_id}_#{Time.current.year}"

    state = State.new
    state.load(stream_name, event_store: event_store)

    return if state.completed? # The gift has to be sent once only.

    state.apply(event)
    state.store(stream_name, event_store: event_store)

    if state.complete?
      command_bus.(ScheduleXmasCardShipment.new(data: { customer_id: customer_id }))
      state.mark_as_completed # Mark process as finished
    end
  end
end
```

Since it responds to two events and needs to calculate the occurrence, it seems like it could be a [process manager](https://blog.arkency.com/tags/process-manager/) instead of a simple event handler.

SendXmasCard has to make a decision about sending the gift. To do this, it needs to keep track of fulfilled orders and returned orders for customers. Additionally, it needs to check if the time to return fulfilled orders has passed. Also, the card should be sent only once a year. Therefore, once it is sent, the state is marked as completed.

