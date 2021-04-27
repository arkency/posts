---
created_at: 2021-04-27 18:20:23 +0200
author: Paweł Pacana
tags: ['rails_event_store']
publish: false
---

# How to balance the public APIs of open-source library — practical examples from RailsEventStore

On twitter, Krzysztof asked an interesting question: what are our thoughts on carving a well-balanced API for an open-source library that [RailsEventStore](https://railseventstore.org) is: 

<blockquote class="twitter-tweet" data-conversation="none" data-dnt="true"><p lang="en" dir="ltr"><a href="https://twitter.com/arkency?ref_src=twsrc%5Etfw">@arkency</a> what are your thoughts on carving a well balanced API the an <a href="https://twitter.com/hashtag/opensource?src=hash&amp;ref_src=twsrc%5Etfw">#opensource</a> library <a href="https://twitter.com/hashtag/railseventstore?src=hash&amp;ref_src=twsrc%5Etfw">#railseventstore</a>?</p>&mdash; Krzysztof Platis (@KrisPlatis) <a href="https://twitter.com/KrisPlatis/status/1385303686948212737?ref_src=twsrc%5Etfw">April 22, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

This post is a whirlwind tour on RailsEventStore interfaces, components and decisions behind them.

In case you're still wondering:

> Rails Event Store is a library for publishing, consuming, storing and retrieving events. It's your best companion for going with an Event-Driven Architecture for your Rails application.

In other words — it is a storage for events. And a reader of events. On top of relational database. And a pub-sub mechanism. And a few more bits you could implement by your own, like you would implement a web framework. But nobody implements web frameworks on a daily basis, right?


# Client facade

The most straightforward way to **start** using RES is to instantiate the client:

```ruby 
event_store = RailsEventStore::Client.new
```

That requires **no additional configuration** or upfront decisions. Perhaps it's your first time with this library. You're evaluating it and exploring its usefulness in context of the project you're working on. At this point any obstacle from getting to the core functionality is a friction to eliminate. We provide sensible **defaults** to lean on.

This facade channels most library interactions. It is the entry point. Quite **liberal on the inputs** in some ways, like accepting both event or collection of events:

```ruby

# Persists events and notifies subscribed handlers about them
#
# @param events [Array<Event>, Event] event(s)
# @param stream_name [String] name of the stream for persisting events.
# @param expected_version [:any, :auto, :none, Integer] controls optimistic locking strategy. {http://railseventstore.org/docs/expected_version/ Read more}
# @return [self]
def publish(events, stream_name: GLOBAL_STREAM, expected_version: :any)
  enriched_events = enrich_events_metadata(events)
  records         = transform(enriched_events)
  repository.append_to_stream(records, Stream.new(stream_name), ExpectedVersion.new(expected_version))
  enriched_events.zip(records) do |event, record|
    with_metadata(
      correlation_id: event.metadata.fetch(:correlation_id),
      causation_id:   event.event_id,
    ) do
      broker.(event, record)
    end
  end
  self
end
```

On the other hand, an entry point is the best place to **validate the input** and **catch mistakes** early on:

```ruby
# Subscribes a handler (subscriber) that will be invoked for published events of provided type.
#
# @overload subscribe(subscriber, to:)
#   @param to [Array<Class>] types of events to subscribe
#   @param subscriber [Object, Class] handler
#   @return [Proc] - unsubscribe proc. Call to unsubscribe.
#   @raise [ArgumentError, SubscriberNotExist]
# @overload subscribe(to:, &subscriber)
#   @param to [Array<Class>] types of events to subscribe
#   @param subscriber [Proc] handler
#   @return [Proc] - unsubscribe proc. Call to unsubscribe.
#   @raise [ArgumentError, SubscriberNotExist]
def subscribe(subscriber = nil, to:, &proc)
  raise ArgumentError, "subscriber must be first argument or block, cannot be both" if subscriber && proc
  subscriber ||= proc
  broker.add_subscription(subscriber, to)
end
```

This further allows collaborators (i.e. broker or repository) to expect and act on a valid input. Also to have much **stricter APIs down the stack**. Like no longer accepting item-or-array-of-items or string-or-symbol primitives in this [RBS](https://github.com/ruby/rbs) description:

```ruby
module RailsEventStoreActiveRecord
  class EventRepository
    def append_to_stream: (Array[RubyEventStore::Record] records, RubyEventStore::Stream stream, RubyEventStore::ExpectedVersion expected_version) -> untyped
  end
end
```

Since facade is the thing a developer would interact with the most, its worth **taking care of ergonomics**. For example, a fluent interface on the [reader](https://railseventstore.org/docs/v2/read/):

```ruby
scope = client.read
  .stream('GoldCustomers')
  .backward
  .limit(10)
  .of_type(Customer::GoldStatusGranted)
scope.to_a
```

# Swappable components

Starting with batteries included is great. Over time your project will likely diverge from the defaults "for everyone". At this point it would be better if the library allowed some room for that. 

If `RailsEventStore::Client.new` was the frontend, here's the backend view. All of the assumptions, defined as default arguments:

```ruby
module RailsEventStore
  class Client < RubyEventStore::Client
    attr_reader :request_metadata

    def initialize(mapper: RubyEventStore::Mappers::Default.new,
                   repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: YAML),
                   subscriptions: RubyEventStore::Subscriptions.new,
                   dispatcher: RubyEventStore::ComposedDispatcher.new(
                     RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: YAML)),
                     RubyEventStore::Dispatcher.new),
                   clock: default_clock,
                   correlation_id_generator: default_correlation_id_generator,
                   request_metadata: default_request_metadata)
      super(repository: RubyEventStore::InstrumentedRepository.new(repository, ActiveSupport::Notifications),
            mapper: RubyEventStore::Mappers::InstrumentedMapper.new(mapper, ActiveSupport::Notifications),
            subscriptions: subscriptions,
            clock: clock,
            correlation_id_generator: correlation_id_generator,
            dispatcher: RubyEventStore::InstrumentedDispatcher.new(dispatcher, ActiveSupport::Notifications)
            )
      @request_metadata = request_metadata
    end

    def with_request_metadata(env, &block)
      with_metadata(request_metadata.call(env)) do
        block.call
      end
    end

    private
    def default_request_metadata
      ->(env) do
        request = ActionDispatch::Request.new(env)
        {
          remote_ip:  request.remote_ip,
          request_id: request.uuid
        }
      end
    end
  end
end
```

You can change any of these components. They're dependencies. Passed via initializer, not hardcoded. 

In need for [in-memory event repository](https://railseventstore.org/docs/v2/repository/#using-rubyeventstore-inmemoryrepository-for-faster-tests) for faster tests? Check.

Working on a DynamoDB [storage backend](https://github.com/carsdb/rails_event_store_dynamoid)? Check.

Not an ActiveRecord fan or [integrating with ROM](https://github.com/RailsEventStore/rails_event_store/tree/master/contrib/ruby_event_store-rom) and Hanami? Check.

Same could go for subscriptions — i.e. persistent storage over in-memory from evaluating configuration file. Or to replace a broker (the in-process pub-sub bus). 

Perhaps you just need the [mapper to encrypt](https://railseventstore.org/docs/v2/gdpr/#encryptionmapper) the payload, before it is persisted and announced on the message bus. 

It is **hard to please everyone with a single choice** of configuration. But it seems **easy to leave some room to diverge**. After all each component can have its [set of linters](https://www.toptal.com/ruby/ruby-lint-libraries#railseventstore---repository-lint), a [shared test suite](https://github.com/RailsEventStore/rails_event_store/blob/master/ruby_event_store/lib/ruby_event_store/spec/event_repository_lint.rb) to ensure its playing well with others.


# Framework integrations

Little known fact is that RailsEventStore is a tiny wrapper on RubyEventStore. It is more of a configuration preset for RubyEventStore. An umbrella for bringing several gem dependencies together.

But it also comes with several component implementations that are enabled by the presence Rails framework:
* [instrumentation](https://railseventstore.org/docs/v2/instrumentation/) based on `ActiveSupport::Notifications`
* event repository and [after-commit event dispatcher](https://github.com/RailsEventStore/rails_event_store/blob/0c0e0d35fe5925c587b92c10e3707c9719fae61c/rails_event_store/lib/rails_event_store/after_commit_async_dispatcher.rb) based on `ActiveRecord` 
* [asynchronous event handlers](https://railseventstore.org/docs/v2/subscribe/#async-handlers) on top of `ActiveJob`
* `Rack` [middleware to correlate event metadata](https://github.com/RailsEventStore/rails_event_store/blob/master/rails_event_store/lib/rails_event_store/middleware.rb) with Rails requests

You can **opt-out from these framework integrations**. Chances are you won't — you've chosen Rails for a reason. 
But in case you need it, compose your own event store from the ground up with [RubyEventStore](https://railseventstore.org/docs/v2/without_rails/). 

Think of it this way: RailsEventStore is a specialization of RubyEventStore. Can there be HanamiEventStore, on top RubyEventStore? Sure!

Catch me up on [twitter](https://twitter.com/pawelpacana) to discuss more — my DMs are open.

