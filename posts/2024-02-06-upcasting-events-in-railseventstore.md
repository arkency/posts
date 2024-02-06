---
created_at: 2024-02-06 17:15:14 +0100
author: Łukasz Reszke
tags: [ 'rails', 'rails-event-store', 'event-sourcing', 'upcasting', 'ddd' ]
publish: false
---

# Upcasting events in RailsEventStore

We understood new domain concept and our model had to be adjusted to that latest understanding. The model is designed as
an event-sourced aggregate. As it's state is built from the events, we had to adjust them somehow, so the new model
would understand them.

In this post, I will show you how to upcast events in RailsEventStore.

<!-- more -->

In our case the new domain concept was actually removing part of the model. The reason behind is that the aggregate
itself,
when designed, was a little bit too much feature-driven. It works fine, the rules were still respected.
However when we were implementing new business concept it felt kind of... hacky.

After the discussion, we came to conclusion that we duplicated one of the business concepts.

Therefore, as mentioned already, we had to remove one of the method. This method produceed an event, which was used
to build the state.

[There are multiple ways to deal with that situation.](https://blog.arkency.com/4-strategies-when-you-need-to-change-a-published-event/)
We decided to upcast the event. We may forget that this situation existed, however events are immutable and won't be
removed.
Having those in stream will make them easier to access and understand the full picture. It's especially important when
something goes off.

## What is upcasting?

Upcasting is a process of converting an event to a newer version of the event. In our case, the event was kind of
duplicated.
As I mentioned, we discovered that during implementing new business use case. It turned out that two of the events
represent
the same concept. So in our case, upcasting will convert the old event, not used anymore, to the other one, that was
duplicated.

## How to upcast events in RailsEventStore?

There's probably multiple ways of how you can implement the details. However, the general idea is to add transformation,
that does the into the pipeline. In the transformation we tell the RailsEventStore what to do when it sees the old
event.

Take a look at the example below.

```ruby
RubyEventStore::Mappers::Pipeline.new(
  # ... other transformations
  RubyEventStore::Mappers::Transformation::Upcast.new(
    {
      "Module::RemovedEvent" => ->(record) do
        RubyEventStore::Record.new(
          event_id: record.event_id,
          metadata: record.metadata,
          timestamp: record.timestamp,
          valid_at: record.valid_at,
          event_type: "Module::TheOtherEvent",
          data: record.data
        )
      end
    }
  )
)
```

Pipeline mapper, referred to by the `mapper` keyword, is a place in which you can add different transformations. Often
what you'll see here is
the [`SymbolizeMetadataKeys`](https://github.com/RailsEventStore/rails_event_store/blob/b8e4bbffabf43db98a154ebab694486229c3706c/ruby_event_store/lib/ruby_event_store/mappers/transformation/symbolize_metadata_keys.rb)
or [`WithIndifferentAccess`](https://github.com/RailsEventStore/rails_event_store/blob/b8e4bbffabf43db98a154ebab694486229c3706c/contrib/ruby_event_store-transformations/lib/ruby_event_store/transformations/with_indifferent_access.rb)
transformations.
Or perhaps you won't, if you're using
the [`JSONClient`](https://github.com/RailsEventStore/rails_event_store/blob/b8e4bbffabf43db98a154ebab694486229c3706c/rails_event_store/lib/rails_event_store/json_client.rb).

The `Upcast` transformation takes hash as an argument. The key is the name of the old event. The value is an lambda,
that takes the old event record and returns a new one. Or in our case, existing one that was duplicated.

## When to use upcasting?

When you do event sourcing it is recommended not to delete events. They are immutable and should be kept.
It makes a lot of sense. It makes the application reliable.

I used to deal differently with "mistakes" in the aggregates stream. I did rewrite streams, applying only the events
that should be kept. However this strategy has few drawbacks. It is harder to see the full picture.
The events are not deleted, but they are not in the stream anymore. It makes it harder to see what happened in the past.

However, it's good learn multiple strategies and know when to use them. In this case, upcasting seemed like the best
solution.
