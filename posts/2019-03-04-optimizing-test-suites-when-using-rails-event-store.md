---
title: "Optimizing test suites when using Rails Event Store"
created_at: 2019-03-04 17:24:55 +0100
publish: true
author: Rafał Łasocha
tags: [ 'ddd', 'testing', 'rspec' ]
newsletter: arkency_form
---

Using domain events in DDD make it easier to tackle complex workflows. If we are working in a monolith infrastructure, it may cause our event store to have thousands handlers and running all of them in test environment is short way for long test suites. However, there's a trick which may allow you to increase the speed of your test suite by disabling unnecessary handlers.

<!-- more -->

The idea is to reinstantiate an event store configuration before each test. Developer will have the control over what will and what will not be run from the test file, by using [rspec test metadata](https://relishapp.com/rspec/rspec-core/v/3-8/docs/metadata/user-defined-metadata) feature. You can probably find respective features in other testing frameworks as well.

But let's start with the basics. If you are having only one instance of event store, there's a chance that you have global configuration file. In one of our projects, it looks like this:

```ruby
class Subscriptions
  def setup
    {
      Ordering::OrderCompleted => [
        SomeHandler,
        OtherHandler,
        GenerateOrderReceiptPdf,
      ],
      # ...
    }
  end

  # Switch from hash (event => [handlers]) to (handler => [events])
  def handlers
    setup.reduce({}) do |memo, (event, handlers)|
      handlers.each do |handler|
        memo[handler] ||= []
        memo[handler] << event
      end
      memo
    end
  end
end
```

There is a map, from each event to list of handlers it should trigger, and the method `handlers`, which converts to the opposite mapping -- from each handler, to list of events on which it should react.

The first optimization may be, that we want to disable some handler, which is computing very long -- for example, PDF generation.

```ruby
RSpec.configure do |config|
  config.before(:each) do |_example|
    event_store = RailsEventStore::Client.new

    disabled_handlers = [
      GenerateOrderReceiptPdf,
    ]

    Subscriptions.new.handlers.except(*disabled_handlers).each do |handler, events|
      event_store.subscribe(handler, to: events)
    end

    Rails.configuration.event_store = event_store
  end
end
```

That should give a major speed up, but because handler for generating order receipt pdf is not running at all, some tests will probably fail. That's why we want to tag the specific tests in which we are interested in that handler.

```ruby
RSpec.configure do |config|
  config.before(:each) do |_example|
    event_store = RailsEventStore::Client.new

    disabled_handlers = [
      GenerateOrderReceiptPdf,
    ]
    if example.metadata[:enable_handlers]
      disabled_handlers -= Array(example.metadata[:enable_handlers])
    end

    Subscriptions.new.handlers.except(*disabled_handlers).each do |handler, events|
      event_store.subscribe(handler, to: events)
    end

    Rails.configuration.event_store = event_store
  end
end

# In tests:
describe "some pdf spec", enable_handlers: [GenerateOrderReceiptPdf] do
  # ...
end
```

There may also be situations, where you want to disable some handlers, but only in specific tests:

```ruby
# ...
if example.metadata[:disable_handlers]
  disabled_handlers -= Array(example.metadata[:disable_handlers]) 
end
# ...
```

Last but not least, if you are working on fresh bounded context, in which you don't have your usual legaccy baggage, you may want to disable whole default handlers configuration and enable the handlers selectively. The final code:

```ruby
RSpec.configure do |config|
  config.before(:each) do |_example|
    event_store = RailsEventStore::Client.new

    if example.metadata[:only_handlers]
      only_handlers = example.metadata[:only_handlers]

      Subscriptions.new.handlers.slice(*only_handlers).each do |handler, events|
        event_store.subscribe(handler, to: events)
      end
    else
      disabled_handlers = [
        GenerateOrderReceiptPdf,
      ]
      if example.metadata[:enable_handlers]
        disabled_handlers -= Array(example.metadata[:enable_handlers])
      end
      if example.metadata[:disable_handlers]
        disabled_handlers -= Array(example.metadata[:disable_handlers]) 
      end

      Subscriptions.new.handlers.except(*disabled_handlers).each do |handler, events|
        event_store.subscribe(handler, to: events)
      end
    end

    Rails.configuration.event_store = event_store
  end
end
```

I hope that those of you who work with bigger applications and Rails Event Store, will find that snippet useful. If you would like to become better in working with complex rails applications and have more holistic knowledge about software architecture, consider joining our [Rails Architect MasterClass](https://arkency.com/masterclass/).
