---
title: "You get feature toggle for free in event-driven systems"
created_at: 2015-03-06 15:01:01 +0100
kind: article
publish: true
author: Jakub Rozmiarek
newsletter: :arkency_form
tags: [ 'events', 'eventstore', 'event-driven' ]
---
Event-driven programming has many advantages. One of my favourite ones is a fact that by design it provides feature toggle functionality.
In one of projects we've been working on we introduced an event store. This allows us to publish and handle domain events.

<!-- more -->

Below you can see an example of `OrderEvents::OrderCompleted` event that is published after an order has been completed:

```
#!ruby
class Orders::CompleteOrder
  def initialize(event_store)
    self.event_store = event_store
  end

  def call(order)
    # Do something

    event_store.publish(OrderEvents::OrderCompleted.new({
      event_id:        order.event_id,
      organization_id: order.organization_id,
      buyer_id:        order.user_id,
      order_id:        order.id,
      locale:          order.locale,
    }))
  end

  private

  attr_accessor :event_store
end
```

After this fact take place, we want to deliver an email to the customer. We utilize an event handler to do it. To make the handler work we need to subscribe it to the event. We subscribe handlers to events in a config file like this:

```
#!yaml
OrderEvents::OrderCompleted:
  stream: "Order$%{order_id}"
  handlers:
    - Order::DeliverEmail
```

When the event is published it is stored in a stream and for each of subscribed handlers "perform" class method is called with the event passed as an argument:

```
#!ruby
class Order::DeliverEmail
  def self.perform(event)
    new.call(event)
  end

  def call(event)
    data              = event.data.with_indifferent_access
    order_id          = data.fetch(:order_id)
    locale            = data.fetch(:locale)
    delivery_attempts = data.fetch(:delivery_attempts, 0)
    enqueue_delivery(order_id, locale, delivery_attempts)
  end
end
```

Happy customer has just received a confirmation email about their order.

Now if we want to turn email delivery off for some reason, we can do it easily by unsubscring the handler - in this case by removal of the handler line from the config file. 
As you can see it doesn't require any additional work to implement feature toggle - it's available out of the box when using event store. It can be very handy, for example when business requirements change or when we develop a new feature - we can safely push the code and don't worry if it isn't fully functional yet. As long as the handler is not subscribed to the event it won't be fired.
