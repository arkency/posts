---
title: "Avoid coupling between Bounded Contexts using Weak Schema"
created_at: 2020-05-06 11:13:13 +0200
author: Mirosław Pragłowski
tags: ['ddd', 'rails event store', 'domain events']
publish: false
---

The [Rails Event Store](https://railseventstore.org) comes with
a [bounded_context](https://www.rubydoc.info/gems/bounded_context/) gem
(and a generator) that simplifies making your application modular.
Using the command:

```bash
rails generate bounded_context:bounded_context YOUR-BOUNDED-CONTEXT-NAME
```

you can quickly generate folder structure, add load path and start working
on implementing your business logic without friction.

<!-- more -->

You could see how we've used this gem in our
[sample application](https://github.com/RailsEventStore/cqrs-es-sample-with-res)
showing how to use CQRS and Event Sourcing to implement sample business proces.

The idea of bounded context is to have separate modules, with it's own
ubiquitious language and with it's own concepts (you know, a `Customer` in
ordering context could be a `DeliveryAddress` in shipping context, and a `Customer`
in invoicing context may be a different concept that the one on ordering context).

But we still need to communicate the business events between contexts. Because no
context is an information silos. We build systems. We build things that cooperate.
That system cooperation is what makes the difference. This is where the business
processes are defined. Probably a lot of companies have similar ordering, invoicing
& shipping contexts build in theirs system. Also most of them are quite similar.
At least the non-core ones. Is there any e-commerce company which builds it's own
invocing system? Yeah, I know Amazon might have one, but do you think it is
a reasonable thing to invest in building custom invocing system by small e-commerce
shop? Or it is better to buy access to existing solution and invest in integating it
into your business process?

## Coupling here

And that's the place where coupling is introduced. At least in our simple
(sometimes too simple) sample application. So where the coupling is?

Event sourced aggregates defined in modules (bounded contexts) are using
module defined domain events for both - storing state changes (event sourcing) and
for communicating business events between system components (via Rails Event Store pub/sub). The default configuration of `RailsEventStore::Client` uses a mapper with `YAML`
serializer. Also the `RailsEventStore::Event` uses class name as event type. And here is the problem.

## Why?

Why there is a problem?

This is coupling we have on several levels:

* coupling of domain events persistence with publishing them to other components, especially to anouther bounded contexts,
* coupling of event type to event's implementation (by using a class name),
* coupling between bounded contexts as with this implementation all of them must "know" the same class (i.e. shipping BC need to be able to use ordering domain events).

This is not an optimal solution.

Why we have that?

* for historical reasons... or just blame me for my lack of Ruby knowledge when I've started this project,
* for backward compatibility... because some of you use that setup in your production projects,
* for the sake of simplicity of the sample application ;)

## How to decouple

### 1st: decouple persistence from communicating business events.

You must not store as internal state change of aggregate and publish outside of the bounded context the same message (event). You could use the [mailbox pattern](link here), known from [Actor Model](link here) to handle incomming messages and a [outbox pattern](link here) to communicate important business facts that have happened in the bounded context (module). The events used to store aggregate state changes are now
only internal implementation of this module and must not be exposed outside of it.
Keep them private in scope of the module. This also means you could no longer use
a class name as an event type.

This sample code is a definition of "business" events in separate modules:

```ruby
module Ordering
  class OrderCompleted < RailsEventStore::Event
    def event_type
      'ordered'
    end
  end
end

module Shipping
  class DeliveryScheduled < RailsEventStore::Event
    def event_type
      'ordered'
    end
  end
end
```

Overriding the `event_type` method will allow to identify the event and match
it to different event's classes in both modules. To do it you need to define
event class remapping in each module's Rails Event Store configuration:

```ruby
module Ordering
  def event_store
    mapper = RubyEventStore::Mappers::Default.new(
      events_class_remapping: {
        'ordered' => 'Ordering::OrderCompleted',
      }
    )
    RailsEventStore::Client.new(mapper: mapper)
  end
end

module Shipping
  def event_store
    mapper = RubyEventStore::Mappers::Default.new(
      events_class_remapping: {
        'ordered' => 'Shipping::DeliveryScheduled',
      }
    )
    RailsEventStore::Client.new(mapper: mapper)
  end
end
```


### 2nd: decouple domain events schema

But the domain event is not just a name (event type). Event if we decouple from event class we still might have coupling on
event's schema level.

```ruby
module Ordering
  class OrderCancelled < Event
    attribute  :order_no, Types::Strict::Integer
    attribute  :reason, Types::Strict::String.optional

    def event_type
      'cancelled'
    end
  end
end

module Shipping
  class DeliveryRevoked < Event
    attribute  :order_no, Types::Coercible::String

    def event_type
      'cancelled'
    end
  end
end
```

Here we have 2 events. At the begginging they look different.
They have different class names, different schema - however they
share some attribute. As defined before these events share event
type. As a base class I use here my own implementation of base
event class, compatible with `RailsEventStore::Event` but
allowing to define attributes using `dry-schema` and `dry-types` gems.
You could see the implementation of this base class [here](link here).
This events have different schema. But the way they are defined allows
usage of the Weak Schema technique.

However to be albe to use the weak schema we need to change the serialization
format in Rails Event Store. `YAML` has been a really bad idea ;)
Fortunatelly for us it is very simple with `DefaultMapper`

```ruby
module Ordering
  def event_store
    mapper = RubyEventStore::Mappers::Default.new(
      serializer: JSON,
      events_class_remapping: {
        'ordered' => 'Ordering::OrderCompleted',
      }
    )
    RailsEventStore::Client.new(mapper: mapper)
  end
end

module Shipping
  def event_store
    mapper = RubyEventStore::Mappers::Default.new(
      serializer: JSON,
      events_class_remapping: {
        'ordered' => 'Shipping::DeliveryScheduled',
      }
    )
    RailsEventStore::Client.new(mapper: mapper)
  end
end
```

BTW do you know that it is just a wrapper for a `PipelineMapper` and you could build your own mapper by
composing any transformations you need? But this is a story for a different post.

TODO: more about weak schema rules

### 3rd: decouple persistence & pub/sub
