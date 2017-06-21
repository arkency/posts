---
title: "Dogfooding Process Manager"
created_at: 2017-06-21 23:09:00 +0200
kind: article
publish: false
author: Pawel Pacana
tags: [ 'ddd', 'saga', 'process_manager', 'event_store', 'projection' ]
newsletter: :arkency_form
---

<%= img_fit("dogfooding-process-manager/dogfooding.jpg") %>


Process managers (sometimes called Sagas) help us with modeling long running processes which happen in our domains. Think of such process as a series of domain events. When enough of them took place (and the particular ones we're interested in) then we execute a command. The thing is that the events we're waiting for might take a longer time to arrive, during which our process manager has to keep track of what has been already processed. And that's where it gets interesting.

<!-- more -->

## The Domain

Consider following example taken from catering domain. You're an  operations manager. Your task is to suggest your customer a menu they'd like to order and at the same time you have to confirm that caterer can deliver this particular menu (for given catering conditions). In short you wait for `CustomerConfirmedMenu` and `CatererConfirmedMenu`. Only after both happened you can proceed further.
You'll likely offer several menus to the customer and each of them will need a confirmation from corresponding caterers.

If there's a match of `CustomerConfirmedMenu` and `CatererConfirmedMenu` for the same `order_id` you cheer and trigger `ConfirmOrder` command to push things forward. By the way there's a chance you may as well never hear from the caterer or they may decline, so process may as well never complete ;)

## Classical example

Given the tools from `RailsEventStore` ecosystem I use on a daily basis, the implementation might look more or less like this:

```
#!ruby
class CateringMatch
  class State < ActiveRecord::Base
    self.table = :catering_match_state
    # order_id
    # caterer_confirmed
    # customer_confirmed

    def complete?
      caterer_confirmed? && customer_confirmed?
    end
  end
  private_constant :State

  def initialize(command_bus:)
    @command_bus = command_bus
  end

  def call(event)
    order_id = event.data(:order_id)
    state = State.find_or_create_by(order_id: order_id)

    case event
    when CustomerConfirmedMenu
      state.update_column(:customer_confirmed, true)
    when CatererConfirmedMenu
      state.update_column(:caterer_confirmed, true)
    end

    command_bus.(ConfirmOrder.new(data: {
     order_id: order_id
    })) if state.complete?
  end
end
```

This process manager is then enabled by following `RailsEventStore` instance configuration:

```
#!ruby
RailsEventStore::Client.new.tap do |client|
  client.subscribe(ProcessManager.new(command_bus: command_bus),
    [CustomerConfirmedMenu, CatererConfirmedMenu])
end
```

Whenever one of the aforementioned domain events is published by the event store, our process manager will be called with that event as an argument.

Implementation above uses ActiveRecord (with dedicated table) to persist internal process state between those executions. In addition you'd have to run database migration and create this table. I was just about to code it but then suddenly one of those aha moments came.

We already know how to persist events - that's what we use `RailsEventStore` for. We also know how to recreate state from events — with event sourcing. Last but not least the input for process manager are events. Wouldn't it be simpler for process managers to eat it's own dog food?

## Let's do this!

My first take on event sourced process manager looked something like this:

```
#!ruby
require 'aggregate_root'

module EventSourcing
  def apply(event)
    apply_strategy.(self, event)
    unpublished_events << event
  end

  def load(stream_name, event_store:)
    events = event_store.read_stream_events_forward(stream_name)
    events.each do |event|
      apply(event)
    end
    @unpublished_events = nil
  end

  def store(stream_name, event_store:)
    unpublished_events.each do |event|
      event_store.append_to_stream(event, stream_name: stream_name)
    end
    @unpublished_events = nil
  end

  private		
  def unpublished_events
    @unpublished_events ||= []
  end

  def apply_strategy
    ::AggregateRoot::DefaultApplyStrategy.new
  end
end

class CateringMatch
  class State
    include EventSourcing

    def initialize
      @caterer_confirmed  = false
      @customer_confirmed = false
    end

    def apply_caterer_confirmed_menu(_)
      @caterer_confirmed = true
    end

    def apply_customer_confirmed_menu(_)
      @customer_confirmed = true
    end

    def complete?
      caterer_confirmed? && customer_confirmed?
    end
  end
  private_constant :State

  def initialize(command_bus:, event_store:)
    @command_bus = command_bus
    @event_store = event_store
  end

  def call(event)
    order_id = event.data(:order_id)
    stream_name = "CateringMatch$#{order_id}"

    state = State.new
    state.load(stream_name, event_store: @event_store)
    state.apply(event)
    state.store(stream_name, event_store: @event_store)

    command_bus.(ConfirmOrder.new(data: {
      order_id: order_id
    })) if state.complete?
  end
end
```

When process manager is executed, we load already processed events from stream (partitioned by `order_id`). Next we apply the event that just came in, in the end appending it to stream to persist. The trigger with condition stays unchanged since it is only the `State` implementation that we made different.

In theory that could work, I could already feel that dopamine kick after job well done. In practice, the reality brought me this:

```
#!sql
Failure/Error: event_store.append_to_stream(event, stream_name: stream_name)

ActiveRecord::RecordNotUnique:
  PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_event_store_events_on_event_id"
  DETAIL:  Key (event_id)=(bddeffe8-7188-4004-918b-2ef77d94fa65) already exists.
  : INSERT INTO "event_store_events" ("event_id", "stream", "event_type", "metadata", "data", "created_at") VALUES ($1, $2, $3, $4, $5, $6) RETURNING "id"
```

Doh!

I forgot about this limitation of `RailsEventStore`. You can't yet have the same event in multiple streams. By contrast in `GetEventStore` streams are cheap and that's one of the common use cases.

## Take 2

Given the `RailsEventStore` limitation I had to figure out something else. The idea was just too good to give it up that soon. And that's when second aha moment arrived!

There's this `RailsEventStore::Projection` mechanism, which let's you traverse multiple streams in search for particular events. When one is found, given lambda is called. Sounds familiar? Let's see it in full shape:

```
#!ruby
class CateringMatch
  class State
    def initialize(event_store:, stream_name:)
      @event_store = event_store
      @stream_name = stream_name
    end

    def complete?
      initial =
        { caterer_confirmed: false,
          customer_confirmed: false,
        }
      state =
        RailsEventStore::Projection
          .from_stream(@stream_name)
          .init(->{ initial })
          .when(CustomerConfirmedMenu, ->(state, event) {
              state[:customer_confirmed] = true
            })
          .when(CatererConfirmedMenu, ->(state, event) {
              state[:caterer_confirmed] = true
            })
          .run(@event_store)
      state[:customer_confirmed] && state[:caterer_confirmed]
    end
  end
  private_constant :State

  def initialize(command_bus:, event_store:)
    @command_bus = command_bus
    @event_store = event_store
  end

  def call(event)
    order_id = event.data(:order_id)			
    state    = State.new(event_store: @event_store, stream_name: "Order$#{order_id}")

    command_bus.(ConfirmOrder.new(data: {
     order_id: order_id
    })) if state.complete?
  end
end
```

Implementation is noticeably shorter (thanks to hidden parts of `RailsEventStore::Projection`. It also works, especially in practice. And this is the one I chose to stick with for my process manager.

I cannot however say I fully like it. The smell for me is that we peek into the stream that does not exclusively belong to the process manager (it does belong to aggregate into whose stream `CustomerConfirmedMenu` and `CatererConfirmedMenu` were published).
Another culprit comes when testing. Projection can only work with events persisted in streams, so it is not sufficient to only pass an event as an input to process manager. You have to additionally persist it.

```
#!ruby
RSpec.describe CateringMatch do
  facts = [
    CustomerConfirmedMenu.new(data: { order_id: '42' }),
    CatererConfirmedMenu.new(data: { order_id: '42' })
  ]
  facts.permutation.each do |fact1, fact2|
    specify do
      command_bus = spy(:command_bus)
      event_store = RailsEventStore::Client.new

      CateringMatch.new(event_store: event_store, command_bus: command_bus).tap do |process_manager|
        event_store.append_to_stream(fact1, stream_name: "Order$#{fact1.data[:order_id]}")
        process_manager.(fact1)

        event_store.append_to_stream(fact2, stream_name: "Order$#{fact2.data[:order_id]}")
        process_manager.(fact2)
      end

      expect(command_bus).to have_received(:call)
    end
  end
end
```

Would you choose event backed state for process manager as well? Let me know in comments!
