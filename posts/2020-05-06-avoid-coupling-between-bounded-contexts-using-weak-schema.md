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
showing how to use CQRS and Event Sourcing to implement a sample business process.

The idea of bounded context is to have separate modules, with its own
ubiquitous language and with its concepts (you know, a `Customer` in
ordering context could be a `DeliveryAddress` in the shipping context, and a `Customer`
in invoicing context may be a different concept than the one on ordering context).

But we still need to communicate the business events between contexts. Because no
context is an information silo. We build systems. We build things that cooperate.
That system cooperation is what makes the difference. This is where business
processes are defined. Probably a lot of companies have similar ordering, invoicing
& shipping contexts build in their system. Also, most of them are quite similar.
At least the non-core ones. Is there any e-commerce company that builds its
invoicing system? Yeah, I know Amazon might have one, but do you think it is
a reasonable thing to invest in building custom invoicing system by small e-commerce
shop? Or it is better to buy access to an existing solution and invest in integrating it
into your business process?

## Coupling here

And that's the place where the coupling is introduced. At least in our simple
(sometimes too simple) sample application. So where the coupling is?

Event sourced aggregates defined in modules (bounded contexts) are using
module defined domain events for both - storing state changes (event sourcing) and
for communicating business events between system components (via Rails Event Store pub/sub).
The default configuration of `RailsEventStore::Client` uses a mapper with `YAML`
serializer. Also the `RailsEventStore::Event` uses class name as event type.
And here is the problem.

## Why?

Why there is a problem?

This is coupling we have on several levels:

* coupling of domain events persistence with publishing them to other components, especially to other bounded contexts,
* coupling of event type to event's implementation (by using a class name),
* coupling between bounded contexts as with this implementation all of them must "know" the same class (i.e. shipping BC needs to be able to use ordering domain events).

This is not an optimal solution, but we have deliberately made those
choices because of several reasons. The main of them was:

* for the sake of simplicity when you start with Rails Event Store,
* backward compatibility... because some use that setup in your production projects,

## How to decouple

### 1st: decouple persistence from communicating business events.

You must not store as an internal state change of aggregate and publish outside of
the bounded context the same message (event). You could use the mailbox pattern,
known from [Actor Model](https://en.wikipedia.org/wiki/Actor_model) to handle
incoming messages and a [outbox pattern](https://microservices.io/patterns/data/transactional-outbox.html)
to communicate important business facts that have happened in the bounded context (module).
The events used to store aggregate state changes are now only internal
implementation of this module and must not be exposed outside of it.
Keep them private in the scope of the module. This also means you could no longer use
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

But the domain event is not just a name (event type). Event if we decouple from event class
we still might have coupling on the event's schema level.

```ruby
module Ordering
  class OrderCancelled < Event
    event_type 'cancelled'

    attribute  :order_no, Types::Strict::Integer
    attribute  :reason, Types::Strict::String.optional
  end
end

module Shipping
  class DeliveryRevoked < Event
    event_type 'cancelled'

    attribute  :order_no, Types::Coercible::String
  end
end
```

Here we have 2 events. In the beginning, they look different.
They have different class names, different schema - however they
share some attributes. As defined before these events share event
type. As a base class, I use here my implementation of base
event class, compatible with `RailsEventStore::Event` but
allowing to define attributes using `dry-schema` and `dry-types` gems.
You could see the implementation of this base class
[here](https://github.com/RailsEventStore/rails_event_store/blob/master/contrib/scripts/dry-event.rb).
These events have a different schema. But the way they are defined allows
usage of the Weak Schema technique.

However to be albe to use the weak schema we need to change the serialization
format in Rails Event Store. `YAML` has been a really bad idea ;)
Fortunatelly for us it is very simple with `Default` mapper:

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

BTW do you know that it is just a wrapper for a `PipelineMapper`
and you could build your  mapper by composing any transformations you need?
But this is a story for a different post.


There are some rules that you need to be aware of to use the weak schema.
The rules for mapping are simple. When reading the event from the event store,
you look at the serialized JSON and the event instance.
And then the rules apply:

* Exists on JSON and instance -> value from JSON
* Exists on JSON but not on the instance -> NOP
* Exists on the instance but not in JSON -> default value

You could read more about Weak Schema in [Event Versioning book](https://leanpub.com/esversioning/read_full)
by [Greg Young](https://twitter.com/gregyoung) (available for free to read on LeanPub).

With the use of `dry-types` attributes, we could also define coercion rules
(i.e. replacing integers with strings) and define default values.

### 3rd: decouple persistence & pub/sub

The last coupling to avoid is the persistence & publishing of the domain events.
I've already mentioned the solution here.
You just don't publish outside of your bounded context (module)
the internal events you use to persist state changes
of the aggregates. This technique has several advantages:

* you define "the contract" between your BCs - read more about Open Host Service & Published Language context relationships
* changes of the contract could be versioned - i.e. you could publish 2 versions of the same public event until all downstream contexts (clients) will catch up and will be able to handle the latest version
* the changes in internal domain events schema do not have an impact on published public events
* you could enrich published events with additional data and publish the result of several internal events as an [summary event](https://verraes.net/2019/05/patterns-for-decoupling-distsys-summary-event/)
* use event class remapping as a simple form of bounded context [anti-corruption layer](https://docs.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer)

The separation could be done via physical separation of data in different data stores.
In this solution, each BC should have its private data store and specific
Rails Event Store configuration, and an additional Rails Event Store (or any other
pub/sub implementation that will support Weak Schema) as a communication interface
between different bounded contexts.

In a modular-monolith application, we could simplify this by using only a single instance
of Rails Event Store and separate domain events on streams level. This will require
more reliance on conventions and discipline of the development team as there is no
such restriction implemented in Rails Event Store.

The mixed model is also possible. Separate instances of Rails Event Store with a wrapper
for `EventRepository` to force the convention by adding module prefix to stream names.
This way we still have single data store but each context (module) could only write
to its streams and "public" streams via the RES instance which is used to
communicate between bounded contexts.