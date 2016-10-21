---
title: "Testing an Event Sourced application"
created_at: 2015-07-07 13:32:09 +0200
kind: article
publish: true
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain', 'event', 'event sourcing', 'tests', 'TDD' ]
newsletter: :skip
newsletter_inside: :rails_event_store
img: "events/car-vehicle-motion-power.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("events/car-vehicle-motion-power.jpg") %>" width="100%">
  </figure>
</p>

Some time ago I’ve published a sample application showing how to build a simple event sourced application using Rails &amp; RES. But there was a big part missing there - the tests.

My sample uses CQRS approach to handle all operations.

<!-- more -->

That means the control flow is as follow:

* A command is created based on params from UI
* Command is handled by a command handler:
  * based on command’s aggregate id all events for an aggregate are loaded from RES and aggregate state is recreated
  * a domain object method is called that will produce new domain events
  * domain event are applied to the aggregate
  * domain events are stored in RES & published to event handlers

## AAA
This is a basic pattern how good test should be created. There are 3 parts: **Arrange** - when you setup initial state for a test, **Act** - where you perform actual operation you want to test and **Assert** - when you check results.

And the AAA pattern should be preserved for Event Sources application.

## Given a series of events
How to build an initial state when you don’t have a state?

This should be quite easy. Any state is a derivative of domain events. You could build any state by applying domain events.

To build a state you just need some events:

```
#!ruby
include CommandHandlers::TestCase

test 'order is created' do
  event_store = FakeEventStore.new
  aggregate_id = SecureRandom.uuid
  customer_id = 1
  order_number = "123/08/2015"
  arrange(event_store,
    [Events::ItemAddedToBasket.create(aggregate_id, customer_id)])
  # ...
end

# ./test/lib/command_handlers/test_case.rb
module CommandHandlers
  class FakeEventStore
    def initialize
      @events = []
      @published = []
    end

    attr_reader :events, :published

    def publish_event(event, aggregate_id)
      events << event
      published << event
    end

    def read_all_events(aggregate_id)
      events
    end
  end

  class FakeNumberGenerator
    def call
      "123/08/2015"
    end
  end

  module TestCase
    # ...
    def arrange(event_store, events)
      event_store.events.concat(events)
    end
    # ...
  end
end
```

Then we have our test state arranged. Notice that I've used fake event store & domain services to avoid dependencies and have really fast tests.

## When a command

In Event Sourced application act (operation we want to test) is usually handling of a command. To do it you just need a command, you need the command handler and then just dispatch the command to the command handler.

```
#!ruby
test 'order is created' do
  # ...
  act(event_store,
    Command::CreateOrder.new(order_id: aggregate_id, customer_id: customer_id))
  # ...
end

# ./test/lib/command_handlers/test_case.rb
module CommandHandlers
  # ...
  module TestCase
    include Command::Execute

    # ...
    def act(event_store, command)
      execute(command, **dependencies(event_store))
    end

    # ...
    private
    def dependencies(event_store)
      {
        repository:
          RailsEventStore::Repositories::AggregateRepository.new(event_store),
        number_generator:
          FakeNumberGenerator.new
      }
    end
  end
end
```

The same `Command::Execute` module is used in `ApplicationController` to dispatch real commands to the system.

## Expect a series or events

You should not assert on the current state, actually you should not rely on a state at all. All you need to verify is if the correct domain events have been produced.

```
#!ruby
test 'order is created' do
  # ...
  assert_changes(event_store,
    [Events::OrderCreated.create(aggregate_id, order_number, customer_id)])
end

# ./test/lib/command_handlers/test_case.rb
module CommandHandlers
  # ...
  module TestCase
    # ...

    def assert_changes(event_store, expected)
      actuals = event_store.published.map(&:data)
      expects = expected.map(&:data)
      assert_equal(actuals, expects)
    end

    def assert_no_changes(event_store)
      assert_empty(event_store.published)
    end
  end
end
```

And because all state is a result of events checking what have been produced has a nice side effect. You test if all expected domain events have been produced and if only the ones expected. In that case, you test if any unexpected change have not been introduced.

## or an exception

Remember that any command may end up with an error. There could be various reasons, technical ones (oh no! regression again?), or error could be just a result of some business rules validations.

Complete code sample for blog post could be found [here](https://github.com/mpraglowski/cqrs-es-sample-with-res).

<%= show_product_inline(item[:newsletter_inside]) %>
