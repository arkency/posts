---
title: Low-boilerplate process manager
created_at: 2021-01-07T11:01:14.852Z
author: Tomasz Wróbel
tags: []
publish: false
---

# A simple example to start with process managers

Process Manager — you can think of it as something that takes events on input and produces a command on output. You might have found yourself in situations, where you felt you should be implementing one.

A simple example that often happens: **you're familiar with event handlers**, but at some point it seems like you need **an event handler that would activate after two distinct events happen — not just one**. Often people are tempted to propagate attributes in events. It's rarely a good idea. It might be a good place to employ a process manager.

Typically, to implement it, you handle specific events and store process manager state in an plain ol' active record — but it's not the only way to do it. Since introduction of linking events in RES, another approach is viable: event sourced process managers. Their advantage is that you don't need to set up another db table. You might have already read about them in a [blogpost by Paweł](https://blog.arkency.com/process-managers-revisited/). 

What I'm giving you here is another implementation of it. A simple implementation that hopefully illustrates the essential parts. You can take it and tweak it. It utilizes linking to streams and RES projections:


```ruby
class OrderFulfillment
  def call(event)
    event_store.link(event.event_id, stream_name: stream_for(event))

    state = build_state(stream_for(event))

    execute(state) if state[:order_placed] && state[:payment_captured]
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def stream_for(event)
    "OrderFulfillment$#{event.data[:order_id]}"
  end

  def build_state(stream_name)
    RailsEventStore::Projection
      .from_stream(stream_name)
      .init(-> { {} })
      .when(OrderPlaced, -> (state, event) {
        state[:order_placed] = true
        state[:order_id] = event.data[:order_id]
      })
      .when(PaymentCaptured, -> (state, event) {
        state[:payment_captured] = true
      })
      .run(event_store)
  end

  def execute(state)
    FulfillOrder.new.call(state[:order_id])
  end
end
```

How it's wired up:

```ruby
event_store.subscribe(OrderFulfillment.new, to: [OrderPlaced, PaymentCaptured])
```

## What happens here

Exactly three things:

### 1. "Capture" the event that is needed to determine the process manager's state (put it into the process manager's stream):

```ruby
event_store.link(event.event_id, stream_name: stream_for(event))
```

### 2. Fetch all the events currently linked to the PM's stream and build the current state from them:

```ruby
state = build_state(stream_for(event))
```

### 3. If the conditions needed for the process to complete are met, execute the piece of code.

```ruby
execute(state) if state[:order_placed] && state[:payment_captured]
```

## What can be different

* This snippet is moderately primitive-obsessed. You can improve by implementing state as a class, and execute if `state.complete?`.
* Typically, a command is the thing that you execute upon completion of the process. It's nice to think of a process manager as something that takes events and produces a command. I spared it here because not everyone has a command bus in place.
* Does order of events and concurrency matter for your PM? RES provides [several options to control it](https://railseventstore.org/docs/v2/expected_version/).

## A typical situation when you might need it

If you started playing with events in your app, you may have already encountered situations where you'd like to do something in an event handler, but actually you need data from two distinct events for it to happen. Often that leads people to put more attributes to one of the events, but that's rarely a good idea. Consider a process manager in this case.

