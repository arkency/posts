---
title: "Using streams to build read models"
created_at: 2019-04-11 16:23:35 +0200
publish: true
author: Rafał Łasocha
tags: [ 'ddd', 'read model', 'cqrs', 'rails_event_store' ]
newsletter: arkency_form
cover_image: using_streams_to_build_read_models/streams.jpg
---

Building read models sometimes pose a technical challenge, especially if given infrastructure doesn't provide order guarantee and the model has to be eventually consistent. Read models are considered the easy part, so we would like to be able to implement them quickly and move to the more interesting tasks. One of the simplest ways to ensure order is to use dedicated read model streams. Thanks to them, we will be able to spare ourselves a migration of data, so our implementation will be ready as soon as we will finish the code.

<!-- more -->

Let's assume that our read model is meant to keep track of some information about football match participants.
To build dedicated stream for a read model, we create a linker:

```ruby
module MatchParticipants
  class Linker
    include Handler.sync

    def call(event)
      case event
      when YearpassBought
        matches_in_nearest_year_query.call.each do |match|
          event_store.link(event.id, event_stream: "MatchParticipants$#{match.id}")
        end
      when TicketBought
        event_store.link(event.id, event_stream: "MatchParticipants$#{event.data.fetch(:match_id)}")
      # ...
      end
    rescue RubyEventStore::EventDuplicatedInStream
    end
  end
end
```

And we add that linker as a handler to all mentioned events. Note that thanks to `rescue RubyEventStore::EventDuplicatedInStream`, no errors will be raised in at-least-once strategy.

We want beforementioned order & consistency guarantees, so we want to make use of database locks to ensure that. For that reason, we could either use named locks, or just create separate structure for them:

```ruby
module MatchParticipants
  # Simple database structure, just to be able to set a lock.
  # It needs to at least have `stream_name` field.
  # It's so generic it could even be used for all read models implemented in similar fashion.
  class Status < ActiveRecord::Base
  end
end
```

Of course, we also need to have a unique index on `stream_name` attribute to prevent race-condition on creating.

Then, we need a builder and some data structure:

```ruby
module MatchParticipants
  class Model
    # ...
  end

  class Builder
    def call(match_id)
      status = Status.find_or_create_by!(stream_name: "MatchParticipants$#{match_id}")
      status.lock!
      stream_events = event_store.read.stream(status.stream_name).sort_by {|e| e.metadata.timestamp }

      stream_events.each_with_object(Model.new) do |event, model|
        model = handle(model, event)
      end

      status.save!
      return model
    end
  end
end
```

Depending on our preferences, we may consider a `Model` to be just a data structure which `Builder` knows how to build, or a `Model` may know how to build itself. On such granularity, it doesn't really matter.


## Simple caching

If we already have a status table for each model, we can easily add simple caching. Our cache would be invalidated by appending new event to the stream and it would be stored either as a "snapshot" (json, marshal) in `Status` ActiveRecord, or as a separate collection of tables. As always, the choice is up to you.

```ruby
class Builder
  def call(match_id)
    status = Status.find_or_create_by!(stream_name: "MatchParticipants$#{match_id}")
    status.lock!
    stream_events = event_store.read.stream(status.stream_name)
    return deserialize(status.snapshot) if status.processed_events_count == stream_events.count

    stream_events.inject(Model.new) do |model, event|
      handle(model, event)
    end

    status.processed_events_count = stream_events.count
    status.save!
    return model
  end
end
```

## Catching up

At that point, we got one really nice feature: we don't need to rebuild our read model -- it will be build on-demand. However, we still need to link all the events to the dedicated read model streams, which is as painful as having to build all the read models. Fortunately, we can solve this inconvenience by creating `Catchup` class, meant to be called always before `Builder` is called:

```ruby
class Catchup
  MATCH_STREAM_EVENTS = [
    TicketBought,
  ]
  YEARPASS_STREAM_EVENTS = [
    YearpassBought,
  ]

  def initialize(match_id)
    @match_id = match_id
    @linker = Linker.new
  end

  def call
    status = Status.find_or_create_by!(stream_name: "MatchParticipants$#{match_id}")
    status.with_lock do
      return if status.catchup_at.present?

      streams = []
      streams << ["Match$#{match_id}", MATCH_STREAM_EVENTS]
      YearpassesForMatchQuery.new.call(match_id).each do |yearpass|
        streams << ["Yearpass$#{yearpass.id}", YEARPASS_STREAM_EVENTS]
      end

      streams.each do |stream_name, stream_relevant_events|
        link_events(stream_name, stream_relevant_events)
      end

      status.last_processed_fact_id = nil
      status.catchup_at = Time.now
      status.save!
    end
  end

  def link_events(original_stream, event_types)
    event_store.read.stream(original_stream).each do |event|
      if event_types.include?(event.type)
        linker.handle(event)
      end
    end
  end
end
```

Thanks to it, before building given read model for the first time, all old domain events will be linked, so we are free from doing the data migration.

## Maintenance

Requirements obviously change, and from time to time we need to add some other domain event to be linked to all read model streams. The solution for that is simple and preserves all previous invariants -- use the linker:

```ruby
event_store.read.of_type([OurNewDomainEvent]).find_each do |event|
  linker.call(event)
end
```

## Caveats

As you saw, that approach has multiple of benefits, the biggest one being that we don't have to run any potentially long migrations. Of course, it comes at a price being a little bit time consuming at each retrieval (but we can solve that one with snapshots) and even more time consuming at the first retrieval. As they say, your mileage may vary, but for many of the use cases, this is more than enough. This pattern is especially well suited to read models which are "retrieved" in the background like reports being send over the e-mail or API.
