---
created_at: 2022-11-18 15:06:19 +0100
author: Piotr Jurewicz
tags: ['architecture', 'turbo', 'rails']
publish: true
---

# Take advantage of Turbo Streams in event handlers
It's been a time since Rails 7 came with Turbo and its Turbo Streams.

At first, I was a bit skeptical because of the idea of broadcasting view updates as a sort of Active Record callbacks.
Sorry, I'm simply not buying the idea of mixing WebSockets calls into a data model.
However, rejecting the concept of `Turbo::Broadcastable` concern, I see Turbo Stream as a great tool and I'm sure there is a proper place for it in the Rails app architecture.

<!-- more -->

This is more or less what our typical architecture looks like.
    <img src="<%= src_original("take-advantage-of-turbo-streams-in-event-handlers/sync.png") %>" width="100%">
**Read models** are loaded and presented on the **UI**. A user issues a **command** which is passed to the domain layer. This usually culminates in one or more **domain events** being published.
These events are persisted and then handled synchronously or asynchronously by **event handlers** which update the **read models**. With the next page load, the user sees the updated **read models**. The circle is closed.

With Turbo Streams and just one more event handler, we can invoke asynchronous direct updates from the backend to the UI and significantly improve user experience.
<img src="<%= src_original("take-advantage-of-turbo-streams-in-event-handlers/async.png") %>" width="100%">

Let's see how we do it based on the [ecommerce](https://github.com/RailsEventStore/ecommerce/), our demo application.

```html+erb
<table>
  <thead>
    <tr>
      <td>Number</td>
      <td>Customer</td>
      <td>State</td>
    </tr>
  </thead>

  <tbody>
  <%% @orders.each do |order| %>
    <%%= turbo_stream_from "orders_order_#{order.uid}" %>
    <tr>
      <td><%%= order.number %></td>
      <td><%%= order.customer %></td>
      <td id="<%%= "orders_order_#{order.uid}_state" %>"><%%= order.state %></td>
    </tr>
  <%% end %>
  </tbody>
</table>
```

```ruby

class Configuration
  def call(event_store)
    @event_store = event_store

    # ... handlers building read models omitted

    subscribe(
      ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), 'Submitted') },
      [Ordering::OrderSubmitted]
    )
    subscribe(
      ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Paid") },
      [Ordering::OrderConfirmed]
    )
    subscribe(
      ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Cancelled") },
      [Ordering::OrderCancelled]
    )
  end
  
  private

  def subscribe(handler, events)
    @event_store.subscribe(handler, to: events)
  end

  def broadcast_order_state_change(order_id, new_state)
    Turbo::StreamsChannel.broadcast_update_later_to(
      "orders_order_#{order_id}",
      target: "orders_order_#{order_id}_state",
      html: new_state)
  end
end
```

Boom! Any time we catch an `OrderSubmitted`, `OrderConfirmed`, or `OrderCancelled` event, we invoke broadcasting an update. Every subscribed client receives a Turbo Streams message and updates the specific order state. Page reload is not required.