---
title: "Fast introduction to Event Sourcing for Ruby programmers"
created_at: 2015-03-09 23:41:01 +0100
kind: article
publish: true
author: Tomasz Rybczyński
newsletter: :arkency_form
tags: [ 'domain', 'event' ]
img: "events/events.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("events/events.jpg") %>" width="100%">
  </figure>
</p>

Many applications store a current state in these days. Although there are situations where we want to see something more than a current information about our domain model. 
If you feel that need Event Sourcing will help you here.

The Event Sourcing is an architectural pattern which allows us to keep information about object’s state as a collection of events. 
These events represent modifications of our model. If we want to recreate current state we have to apply events on our „clean” object.

<!-- more -->

## Domain Events

Domain Events are the essence of whole ES concept. We use them to capture changes on model’s state. Events are something that has had already happened. Each event represent one step of our model’s life. 
The most important feature is that every Domain Event is immutable. This is because they represent domain actions that took place in the past. We should not modify persisted event.
Every change has to be reflected in model's state.

Events should be named as verb in past tense. The name should represent `Ubiquitous Language` used in project. For example `CustomerCreated`, `OrderAccepted` and so on. 
Implementation of event it is very simple. Here I have an example created by one of my team-mates in Ruby:

```ruby
module Domain
  module Events
    class OrderCreated
      include Virtus.model

      attribute :order_id, String
      attribute :order_number, String
      attribute :customer_id, Integer

      def self.create(order_id, order_number, customer_id)
        new({order_id: order_id, order_number: order_number, customer_id: customer_id})
      end
    end
  end
end
```

As we can see It is only a data structure with all needed attributes. (Example solution has been taken from [here](https://github.com/mpraglowski/cqrses-sample))

## Event Store

Event Sourcing approach events are our storage mechanism. The place where we keep events is called Event Store. 
It can be everything like a relational DB or NoSQL. We save events as streams. Each stream describe state of one model (Aggregate). 
Typically, event store is capable of storing events from multiple types of aggregates. We save events as they happened in time. This way we have complete a log of every state change ever. 
After all we can simply load all of the events for an Aggregate and replay them on new object instance. This is it.

## Base of knowledge:

- http://martinfowler.com/eaaDev/EventSourcing.html
- http://ookami86.github.io/event-sourcing-in-practice/#considering-event-sourcing/01-pros-and-cons-of-event-sourcing.md
- http://martinfowler.com/eaaDev/DomainEvent.html
- https://geteventstore.com/
- http://www.udidahan.com/
- https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf
- https://github.com/mpraglowski/cqrses-sample

