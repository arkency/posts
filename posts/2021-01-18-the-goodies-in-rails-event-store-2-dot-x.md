---
title: The Goodies in Rails Event Store 2.x
created_at: 2021-01-18T11:45:37.311Z
author: Tomasz Wróbel
tags: ['rails event store']
publish: true
---

# The Goodies in Rails Event Store 2.x

**But... what is Rails Event Store and why would I use it?** It's a Ruby library to publish, consume and *store* events in your Rails application. [Events](https://blog.arkency.com/tags/domain-event/) are an architectural pattern that helps you decouple your code, records what's happening inside your app, avoid callback hell and many other kinds of hells. Once you try this pattern, there's no going back.

We've released 2.0.0, 2.0.1, 2.1.0. High fives for [Paweł](https://twitter.com/pawelpacana), [Mirek](https://twitter.com/mpraglowski) and [Rafał](https://twitter.com/swistak35) for all the hard work. Some of the goodies inside:

* Significantly reduced storage (no explicit "all" stream)
* Filtering events by timestamp
* Bi-temporal event sourcing support
* Multiple database support
* Listing event subscribers
* Ruby 3.0 support (2.0.1 and 1.3.1)
* Built-in event upcasting (2.1.0)
* Ability to explicitly configure event type resolver (2.1.0)

Read on for details. Read [the release notes](https://github.com/RailsEventStore/rails_event_store/releases/) for even more details, specifically for migration guide (2.0 requires DB migrations).

## Significant storage performance improvement

No more explicit db record to indicate that the event belongs to the default stream `all`.

Before: every time you published an event, at least two db records were created:

* one in `event_store_events`
* one in `event_store_events_in_streams` – plus another one for every stream you append your event to.

After: unless you add your event to a specific stream, no record is added to `event_store_events_in_streams`.

(keep in mind that you still probably link all events to type and correlation streams)

## Filtering by timestamp 

A lot of users have asked for this. Let the code speak for itself:

```ruby
event_store.read.older_than(7.days.ago).to_a
event_store.read.newer_than_or_equal(Time.utc(2020, 1, 1)).to_a
event_store.read.newer_than(14.days.ago).older_than(7.days.ago).to_a
event_store.read.between(14.days.ago...7.days.ago).to_a
```

## Support for Bi-Temporal event-sourcing

Now, your event can have two timestamps: regular `timestamp` and `valid_at`.

**But why**? Keyword: [Bi-Temporal event sourcing](https://www.youtube.com/watch?v=xzekp1RuZbM). You can have one timestamp denote when the event was appended to the store, and the other when it should count as in-effect. Example: you have some kind of policy that is created at one day, but should only be valid at some point in the future.

You can query by either of the timestamps:

```ruby
event_store.read.stream("my-stream").as_at.to_a # ordered by time of appending (timestamp)
event_store.read.stream("my-stream").as_of.to_a # ordered by validity time (valid_at)
```

## Multiple databases support

Read more: https://blog.arkency.com/rails-multiple-databases-support-in-rails-event-store/

As a side-effect you can now pass AR model classes to be used by repository. Useful for example when for any reason you had to change default table names:

```ruby
class MyEvent < ActiveRecord::Base
  self.table_name = 'event_store_events_res'
end

class MyEventInStream < ::ActiveRecord::Base
  self.primary_key = :id
  self.table_name = 'event_store_events_in_streams'
  belongs_to :event, primary_key: :event_id, class: MyEvent
end

repository = EventRepository.new(model_factory: ->{ [MyEvent, MyEventInStream] }, serializer: YAML)
```

## List all subscribers of an event

`Client#subscribers_for(event_type)` returns list of handlers subscribing for given event type. Useful in specs and diagnostics.

## Ruby 3.0 support (2.0.1)

Speaks for itself. Also introduced in 1.3.1.

## Built-in event upcasting support  (2.1.0)

Upcasting is a technique you can use when you need to change an already published event. [Read more here](https://blog.arkency.com/4-strategies-when-you-need-to-change-a-published-event/). Now RES helps you with that:

```ruby
class Mapper < PipelineMapper
  def initialize(upcast_map: {})
    super(Pipeline.new(
      Transformation::Upcast.new(upcast_map),
    ))
  end
end

RubyEventStore::Client.new(
  mapper: Mapper.new(upcast_map: {
    'OldEventType' => lambda { |record|
      Record.new(
        event_type: 'NewEventType',
        data:        ...,
        metadata:    record.metadata,
        timestamp:   record.timestamp,
        valid_at:    record.valid_at,
        event_id:    record.event_id
      )
    }
  }),
  repository: ...
) 
```

## Explicit event type resolver (2.1.0)

Some people prefer to explicilty define event type, to avoid having event type depend on class names, which may cause bugs on class name changes. This was already possible with: 

```ruby
class SomeEvent < MyEvent
  self.event_type = "some.event"
end
```

But the drawback was that you then needed to use `SomeEvent.event_type` wherever you'd normally use `SomeEvent`:

```ruby
client.subscribe(lambda { |event| ... }, to: [SomeEvent.event_type])
```

Now, with this change you can avoid that. Configure the event type resolver:

```ruby
client = RubyEventStore::Client.new(
  repository: InMemoryRepository.new,
  subscriptions: Subscriptions.new(event_type_resolver: ->(klass) { klass.event_type })
)
```

And now you can stick to the plain way:

```ruby
client.subscribe(lambda { |event| ... }, to: [SomeEvent]) 
```


<!-- Migrations -->
