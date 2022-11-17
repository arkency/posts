---
created_at: 2022-11-17 15:06:19 +0100
author: Piotr Jurewicz
tags: ['turbo', 'rails']
publish: false
---

# Turbo event handlers
It's been a time since Rails 7 came with Turbo and it's Turbo Streams. 
bla bla bla

This is more less how our typical architecture looks like.

<img src="<%= src_original("turbo-event-handlers/sync.png") %>" width="100%">

bla bla bla

<img src="<%= src_original("turbo-event-handlers/async.png") %>" width="100%">

bla bla bla

Let's see how we do it based on the [ecommerce](https://github.com/RailsEventStore/ecommerce/), our demo application.

```ruby

class Configuration
  def call(event_store)
    @event_store = event_store

    # ...

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

```html
<table>
  <thead>
    <tr>
      <td>Number</td>
      <td>Customer</td>
      <td>State</td>
    </tr>
  </thead>

  <tbody>
  <% @orders.each do |order| %>
    <%= turbo_stream_from "orders_order_#{order.uid}" %>
    <tr>
      <td><%= order.number %></td>
      <td><%= order.customer %></td>
      <td id="<%= "orders_order_#{order.uid}_state" %>"><%= order.state %></td>
    </tr>
  <% end %>
  </tbody>
</table>
```
