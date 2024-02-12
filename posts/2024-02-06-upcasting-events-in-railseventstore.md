---
created_at: 2024-02-06 17:15:14 +0100
author: Łukasz Reszke
tags: [ 'rails', 'rails-event-store', 'event-sourcing', 'upcasting', 'ddd' ]
publish: false
---

# Upcasting events in RailsEventStore

Understanding the domain you are working with often leads to the need to redesign some of the models. Sometimes you'll
need to add or change a concept. Sometimes you'll need to remove a method or event produced by the aggregate. This was
the case for us.

Our goal was to remove an event from the system. To do this, we had to deal with the fact that this event was in the
aggregate stream.

It's interesting how we got there.

We started discussing how to implement a new business feature in the aforementioned model.
After tossing around a few ideas it felt like it didn't belong in the aggregate itself.
We realized that it belonged in the application layer, which is responsible for handling different business use cases.
It's often a dilemma that can arise. Where does this business logic go? The aggregate, the application layer that is
responsible for the use cases? Somewhere else?
From a code perspective, it's all about where to put this if statement.

Have you ever experienced a similar conundrum? :wink:

After some discussion, we decided to implement this feature in the application layer. But it felt hacky.
Writing a few test cases helped us realize that the aggregate class has two methods that basically do the same thing,
are presented the same way in the read model, but produce different events.

Long story short, it turned out that our aggregate was a little too feature-driven. It worked fine, all the business 
rules were respected. But it felt like it duplicated part of the business logic. 

Feature-driven design of an aggregate deserves its own blog post. It's not a bad place to start. Learning domain is a
process. With new insights, you may have to adjust the model.

Anyway. At the end, of this somewhat long introduction, we realized that we had two events representing the same concept.
And we decided to remove one of them.

Then the question remains. What to do with the events already in the stream?

[There are multiple ways to deal with that situation.](https://blog.arkency.com/4-strategies-when-you-need-to-change-a-published-event/)

We decided to upcast the event. Why? Events are immutable and shouldn't be removed. Having those in stream will make it
easier to access them and understand the full picture whenever needed. It's especially important when something goes
off.

## What is upcasting?

Upcasting is the process of converting an event to a newer version of the event. In our case, the event was
duplicated.
As I mentioned earlier, we discovered this while implementing a new business use case. It turned out that two of the
events
represent the same concept.

In our case, upcasting will convert the old event that was duplicated to the other one that was originally there.
and should be the only one that represents that business concept.

## How to upcast events in RailsEventStore?

There are probably several ways to implement the details. However, the general idea is to use a
transformation
to the pipeline. In the transformation, we setup the RailsEventStore to convert the old event to the new one. 

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

The pipeline mapper, referred to by the keyword `mapper`, is a place where you can add various transformations.

The `Upcast` transformation takes hash as an argument. The key is the name of the old event. The value is an lambda,
that takes the old event record and returns a new one. Or in our case, existing one that was duplicated.

There are transformations available in the RailsEventStore. You can take a look at them for reference. For example,
the [`SymbolizeMetadataKeys`](https://github.com/RailsEventStore/rails_event_store/blob/b8e4bbffabf43db98a154ebab694486229c3706c/ruby_event_store/lib/ruby_event_store/mappers/transformation/symbolize_metadata_keys.rb)
or [`WithIndifferentAccess`](https://github.com/RailsEventStore/rails_event_store/blob/b8e4bbffabf43db98a154ebab694486229c3706c/contrib/ruby_event_store-transformations/lib/ruby_event_store/transformations/with_indifferent_access.rb)
transformations.
It's also worth familiarizing yourself with
the [`JSONClient`](https://github.com/RailsEventStore/rails_event_store/blob/b8e4bbffabf43db98a154ebab694486229c3706c/rails_event_store/lib/rails_event_store/json_client.rb).

## When to use upcasting?

If you are using event sourcing, **it is not recommended that you delete events**.  Events are **immutable** and 
should be left as they were. This makes a lot of sense. It makes the application more reliable. It's good for auditing.

Alternatively, if you know the event shouldn't be in the stream, you could rewrite the stream and only include the
events that should be there. In this case, it felt unnecessary. The event was valid, it was just duplicated.

It's good to learn different strategies and know when to use them. In this case, upcasting seemed to be the best
solution.
