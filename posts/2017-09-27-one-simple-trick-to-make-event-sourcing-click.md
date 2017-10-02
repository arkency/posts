---
title: "One simple trick to make Event Sourcing click"
created_at: 2017-10-02 09:34:57 +0200
kind: article
publish: true
author: Paweł Pacana
tags: [ 'ddd', 'eventsourcing', 'aggregate' ]
newsletter: :arkency_form
---

Event Sourcing is like having two methods when previously there was one. There — I've said it.
 
<!-- more -->

But it isn't my idea at all.

It was Greg that used it first, in a bit different context. When [explaining CQRS](http://codebetter.com/gregyoung/2010/02/16/cqrs-task-based-uis-event-sourcing-agh/) he used this exact words:

> Starting with CQRS, CQRS is simply the **creation of two objects where there was previously only one**. The separation occurs based upon whether the methods are a command or a query (the same definition that is used by Meyer in Command and Query Separation, a command is any method that mutates state and a query is any method that returns a value).

You can have quite a similar statement on event-sourced aggregate root. The separation occurs based upon whether the method:

* corresponds to an **action** we want to take on an aggregate — protects **business rules** and tells what domain event happened if those were met
* maps **consequences of the domain event** that happened to internal state representation (against which business rules are executed)

Not convinced yet? Let the examples speak.

## Stereotypical aggregate without Event Sourcing

Below is a typical aggregate root. In the scope of the example there are only two actions you can take — via public **register** and **supply** methods.

```ruby
class Product
  CannotSupply = Class.new(StandardError)
  AlreadyRegistered = Class.new(StandardError)
    
  def initialize(store_id: nil, sku: nil, quantity_available: 0)
    @store_id = store_id
    @sku = sku
    @quantity_available = quantity_available
  end
  
  def register(store_id:, sku:, event_store:)
    raise AlreadyRegistered if @store_id
    @store_id = store_id
    @sku = sku
    
    event_store.publish_event(ProductRegistered.new(data: {
      store_id: @store_id,
      sku: @sku, 
    }))
  end
  
  def supply(quantity, event_store:)
    raise CannotSupply unless @store_id && @sku
    
    @quantity_available += quantity
  
    event_store.publish_event(ProductSupplied.new(data: {
      store_id: @store_id,
      sku: @sku,
      quantity: quantity,
    }))
  end
end
```

## Aggregate with Event Sourcing 

In event sourcing it is the domain events that are our source of truth. They state what happened. What we need to do is to make them a bit more useful and convenient for decision making. This is the **sourcing** part.

```ruby
class Product
  CannotSupply = Class.new(StandardError)
  AlreadyRegistered = Class.new(StandardError)
    
  def initialize(store_id: nil, sku: nil, quantity_available: 0)
    @store_id = store_id
    @sku = sku
    @quantity_available = quantity_available
  end
  
  def register(store_id:, sku:, event_store:)
    raise AlreadyRegistered if @store_id

    event = ProductRegistered.new(data: {
      store_id: store_id,
      sku: sku, 
    })
    
    event_store.publish_event(event)
    registered(event)
  end
  
  def supply(quantity, event_store:)
    raise CannotSupply unless @store_id && @sku
    
    event = ProductSupplied.new(data: {
      store_id: @store_id,
      sku: @sku,
      quantity: quantity,
    })
    
    event_store.publish_event(event)
    supplied(event)
  end
  
  private
  
  def supplied(event)
    @quantity_available += event.data.fetch(:quantity)
  end
  
  def registered(event)
    @sku = event.data.fetch(:sku)
    @store_id = event.data.fetch(:store_id)
  end
end
```

In this step we've drawn the line between making a statement that something happened (being possible to happen first) and what side effects does it have. Notice private **registered** and **supplied** methods.

Why make such effort and introduce indirection? The reason is simple — if the events are source of truth, we could not only shape internal state for current actions we take but also for the ones that happened in the past.

Instead of loading current state stored in a database, we can take collection of events that happened in scope of this aggregate — in its stream.

```ruby
class Product
  CannotSupply = Class.new(StandardError)
  AlreadyRegistered = Class.new(StandardError)
    
  def initialize(store_id: nil, sku: nil, event_store:)
    stream_name = "Product$#{store_id}-#{sku}"
    events = event_store.read_all_events_forward(stream_name)
    events.each do |event|
      case event
      when ProductRegistered then registered(event)
      when ProductSupplied then supplied(event)
      end
    end
  end
  
  def register(store_id:, sku:, event_store:)
    raise AlreadyRegistered if @store_id

    event = ProductRegistered.new(data: {
      store_id: store_id,
      sku: sku, 
    })
    
    event_store.publish_event(event)
    registered(event)
  end
  
  def supply(quantity, event_store:)
    raise CannotSupply unless @store_id && @sku
    
    event = ProductSupplied.new(data: {
      store_id: @store_id,
      sku: @sku,
      quantity: quantity,
    })
    
    event_store.publish_event(event)
    supplied(event)
  end
  
  private
  
  def supplied(event)
    @quantity_available += event.data.fetch(:quantity)
  end
  
  def registered(event)
    @sku = event.data.fetch(:sku)
    @store_id = event.data.fetch(:store_id)
  end
end
```

At this point you may have figured out that `event_store` dependency that we constantly pass as an argument belongs more to the infrastructure layer than to a domain and business.

What if something above passed a list of events first so we could rebuild the state? After an aggregate action happened we could provide a list of domain events to be published (`unpublished_events`):

```ruby
class Product
  CannotSupply = Class.new(StandardError)
  AlreadyRegistered = Class.new(StandardError)
  
  attr_reader :unpublished_events  
    
  def initialize(events)
    @unpublished_events = []
    events.each { |event| dispatch(event) }
  end
  
  def register(store_id:, sku:)
    raise AlreadyRegistered if @store_id

    apply(ProductRegistered.new(data: {
      store_id: store_id,
      sku: sku, 
    }))
  end
  
  def supply(quantity)
    raise CannotSupply unless @store_id && @sku
    
    apply(ProductSupplied.new(data: {
      store_id: @store_id,
      sku: @sku,
      quantity: quantity,
    }))
  end
  
  private
  
  def apply(event)
    dispatch(event)
    @unpublished_events << event
  end
  
  def dispatch(event)
    case event
    when ProductRegistered then registered(event)
    when ProductSupplied then supplied(event)
    end
  end
  
  def supplied(event)
    @quantity_available += event.data.fetch(:quantity)
  end
  
  def registered(event)
    @sku = event.data.fetch(:sku)
    @store_id = event.data.fetch(:store_id)
  end
end
```

More or less this reminds the [aggregate_root](https://github.com/RailsEventStore/rails_event_store/tree/master/aggregate_root) gem that is aimed to assist you with event sourced aggregates.

The rule of **having two methods when there was previously one** however still holds.

* **The public method** (such as `supply`) corresponds to an **action** we want to take on an aggregate — protects **business rules** and tells what domain event happened if those rules were met.
* **The private method** (such as `supplied`) maps **consequences of the domain event** that happened to the internal state representation.

There are more code samples and _The Why_ of Event Sourcing in [Rails Meets DDD](https://blog.arkency.com/domain-driven-rails/) which I fully recommend.

Have a great day!