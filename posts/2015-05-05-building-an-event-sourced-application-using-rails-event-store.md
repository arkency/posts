---
title: "Building an Event Sourced application using rails_event_store"
created_at: 2015-05-05 09:26:18 +0200
kind: article
publish: true
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain', 'event', 'event sourcing' ]
newsletter: skip
newsletter: arkency_form
img: "events/eventstore.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("events/eventstore.jpg") %>" width="100%">
  </figure>
</p>

Still not sure what is Event Sourcing and CQRS? Looking for a practical example? You've just read my previous post [Why use EventSourcing](http://blog.arkency.com/2015/03/why-use-event-sourcing/) and decided to give it a try? No matter why let's dive into building an Event Sourced application in Rails using Arkency's [Rails Event store](https://github.com/arkency/rails_event_store).

<!-- more -->

## CQRS
But first you need to learn what CQRS is.

CQRS stands for Command and Query Responsibility Segregation. It's a term coined by [Greg Young](http://twitter.com/gregyoung) and later polished in discussion with others (naming only a few [Udi Dahan](http://twitter.com/udidahan), [Martin Fowler](https://twitter.com/martinfowler)). It is based on CQS (Command Query Separation) devised by [Bertrand Meyer](https://twitter.com/Bertrand_Meyer):

> Every method should either be a command that performs an action, or a query that returns data to the caller, but not both. In other words, asking a question should not change the answer.
<p class="quote-by">Bertrand Meyer</p>

CQRS is a way of building your application. It is not a pattern, not an architecture, not a framework. The best description here will be _"architectural style"_.

It's just about separating reads and writes and building a separate stack (layers) for each of them:

* writes - it could be complex, could be modelled in separate layers like: application service, domain model (maybe using domain services also), with transactions required and complex stuff happening. We care here about consistency of our data more than about performance (usually we write data in a row of magnitude less often than we read them).
* reads - dead simple!, tailor made for your views, no abstraction over a data model - here is the part where Active Record shines - just define a model and use it - but read only!

You may say _"Ok, but I wanted to learn about Event Sourcing and you're writing here about some CQRS architecture style."_ There is a good reason for that:

> You can use CQRS without Event Sourcing, but with Event Sourcing you must use CQRS.
<p class="quote-by">Greg Young</p>

## Crunching your Domain

Let's start building our Event Sourced application with defining a domain model. When using Event Sourcing your domain model (your aggregates) are build based on domain events. Its underlying data model is not storing current state but series of domain events that have been applied to that aggregate since the beginning of its life. This allows you to build your aggregate that will not expose its state and will be able to protects its invariants.

Also an aggregate is a source of new domain events. Every call of a method for an aggregate might result in publishing new domain events. Every change in internal state of an aggregate must be done by publishing and applying a new domain event. No state change in other way! Only then we could ensure that our aggregate will be rebuild to the same state from events.

```ruby
module Events
  class OrderCreated < RailsEventStore::Event
    def order_number
      @data.fetch(:order_number)
    end

    #... some more stuff here

    def self.create(order_id, order_number, customer_id)
      new(data: {order_id: order_id, order_number: order_number, customer_id: customer_id})
    end
  end
end
```

I usually create a helper method to access event's attributes witch are stored the in `@data` hash attribute of `RailsEventStore::Event`. And I like also to add a class method `create` to build a new event with explicitly given parameters, but a RailsEventStore::Event is also a good way of creating a domain event.

Ok, now when we have domain events defined let's apply them to our domain object.

```ruby
module Domain
  class Order
    include AggregateRoot

    AlreadyCreated        = Class.new(StandardError)
    MissingCustomer       = Class.new(StandardError)

    def initialize(id = SecureRandom.uuid)
      @id = id
      @state = :draft
    end

    def create(order_number, customer_id)
      raise AlreadyCreated unless state == :draft
      raise MissingCustomer unless customer_id
      apply Events::OrderCreated.create(@id, order_number, customer_id)
    end

    #... some more stuff here

    def apply_order_created(event)
      @customer_id = event.customer_id
      @number = event.order_number
      @state = :created
    end

    private
    attr_accessor :id, :customer_id, :order_number, :state

    #... some more stuff here
  end
end
```

Let's see what is going on in our `Domain::Order` class.
First the `initialize` method. It builds the initial state of an aggregate, a state where all begins :)
Then we have the `create` method. It should be used by other objects to invoke aggregate features. Here we should protect our invariants, check business rules do validations etc. From CQRS we know it should not return a value - it should just execute or fail (by raising error). In the `create` method we never change the state of an aggregate. Instead we build and apply a new domain event. The `apply` method is defined in `AggregateRoot` module:

```ruby
module AggregateRoot
  def apply(event, new = true)
    send("apply_#{event.class.name.demodulize.tableize.singularize}", event)
    changes << event if new
  end

  def changes
    @changes ||= []
  end

  def rebuild(events)
    events.each { |event| apply(event, false) } if events
  end
end
```

By calling `apply Events::OrderCreated.create(@id, order_number, customer_id)` we are creating a new `OrderCreated` domain event, applying it to our aggregate - what results in a change of state, and storing it in the `changes` collection. It stores all domain events created by the aggregate during its method execution.

The last thing to take a look here is the `apply_order_created` method. This method updates the aggregate state based on domain event. It does not matter if the event was published by the aggregate itself or it was read from Event Store and applied when rebuilding the aggregate state. There must not be any business rules check or validations here. What has happened has happened. It is already done. We just reflect those changes in aggregate state.

And one more thing: notice that all state of an aggregate object is private. Not available outside aggregate itself - even for reads.

## Commands

A command is a simple object that encapsulates parameters for an action to be executed. Should be named in a business language (Ubiquitous Language) and express the user's intention. Before a command is executed it should be validated. Those validations should be simple, out of full context, just based on command data and read model data. Should not check business rules (that will be handled later by domain object).

```ruby
module Commands
  class CreateOrder < Command
    attr_accessor :order_id
    attr_accessor :customer_id

    validates :order_id, presence: true
    validates :customer_id, presence: true

    alias :aggregate_id :order_id
  end
end
```

They are also known as Form Object (in Ruby world).

Base class `Command` uses some ActiveModel features to allow simple validation and creation of command objects.

```ruby
class Command
  ValidationError = Class.new(StandardError)

  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Conversion

  def initialize(attributes={})
    super
  end

  def validate!
    raise ValidationError, errors unless valid?
  end

  def persisted?
    false
  end
end
```

## Handling a command

A command handler is a entry point to your domain. It should handle all "plumbing", orchestrate domain objects and domain services and execute domain object's methods with parameters given in a handled command. There could be several sources of commands send to our application: users, external systems or sagas (process managers).

Here is how I've defined "plumbing" for my sample Event Sourced application: [https://github.com/mpraglowski/cqrs-es-sample-with-res/blob/master/lib/command_handler.rb](https://github.com/mpraglowski/cqrs-es-sample-with-res/blob/master/lib/command_handler.rb)

This is the only module where I use core features of Rails Event Store. It loads events from RES in `load_events` using aggregate id as a stream name. It publishes events in the `publish` method. The publish in RES will store the published event in a given stream (again aggregate id) and then send it to all subscribers. This is an important assumption! **What is not stored is never published**.

So with the use of the `CommandHandler` module the `CreateOrder` command is handled by:

```ruby
module CommandHandlers
  class CreateOrder
    include Injectors::ServicesInjector
    include CommandHandler

    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order_number = number_generator.call
        order.create(order_number, command.customer_id)
      end
    end

    def aggregate_class
      Domain::Order
    end
  end
end
```

The `with_aggregate(command.aggregate_id)` method will return a `Domain::Order` object recreated from events read from RES. On an Order command handler executes a `create` method using parameters from given command.

The command is send from any controller using method from `ApplicationController` (notice it is validated before execution):

```ruby
def execute(command)
  command.validate!
  handler = "CommandHandlers::#{command.class.name.demodulize}"
  handler.constantize.new.call(command)
end
```

## Building a read model

Till now we have implemented:

* user sends command
* command is handled and domain logic is executed
* domain events are stored and published by RES

But when domain objects are not exposing their state we need another way to build the data for views - the read model. The model is a model as your application needs. It is denormalized - no costly joins, no lazy load, just select data and present them as is. It is tailor-made!
And one more thing: it could be anything - relational DB, NoSQL store, graph database (i.e. [RethinkDB](http://blog.arkency.com/2015/04/on-my-radar-rethinkdb-plus-react-dot-js-plus-rails/)).

Here we go with build in Rails Event Store pub/sub feature. If you took a look at source of `CommandHandler` module you might have noticed

```ruby
def event_store
  @event_store ||= RailsEventStore::Client.new.tap do |es|
    es.subscribe(Denormalizers::Router.new)
  end
end
```

The `es.subscribe(Denormalizers::Router.new)` will create a subscription for all events to event handler `Denormalizers::Router` where events will be routed to appropriate denormalisers that will create/update read model defined as a simple ActiveRecord classes.

Currently all this works synchronously - stay tuned for next post when some async features will be introduced.
