---
title: "Patterns for asynchronous read models in infrastructure without order guarantee"
created_at: 2019-02-14 13:57:44 +0100
kind: article
publish: true
author: Rafał Łasocha
tags: [ 'ddd', 'read models', 'background jobs' ]
newsletter: arkency_form
---

When we focus on the model in CQRS architecture, we put most effort into write model.
Not only this is the place where the business operations are implemented and breakthroughs in understanding domain are happening -- we also consider it the part of the implementation where we should put a lot of our technical attention to.

Different implementations of aggregates? Persistence in the model or not? Messaging? Different kinds of transaction boundaries and transaction guarantees between multiple databases?

All of these are exciting topic, but read model part, often considered as an easy job for "junior" developers also pose challenges in implemention.

<!-- more -->

In ideal scenario, read models are rebuilt from the [Domain Events](https://blog.arkency.com/2016/05/the-anatomy-of-domain-event/), in order of their publishing, and no errors are happening when processing them. But today, let's focus on a more legacy scenario. We do have some rails app and it became _de facto_ a standard to have some kind of backround jobs processing system, like Sidekiq, which give you [at-least-once guarantee](https://github.com/mperham/sidekiq/wiki/Reliability#using-super_fetch), but doesn't give you guarantees about the order of processing the messages. 

Not having an order guarantee can be a problem, if you're not paying attention to the implementation of the read model. For example, simple read model like this:

```ruby
class UserPersonalDetailsReadModel
  include Sidekiq::Worker

  class State < ActiveRecord::Base
  end

  def perform(domain_event)
    case domain_event
    ...
    when IdentityAndAccess::NameChanged
      user_read_model = State.find_by(domain_event.data[:user_id])
      user_read_model.update!(name: domain_event.data[:new_name])
    else raise
    end
  end
end
```

Would be usually unsatisfactory because if these events:

```ruby
IdentityAndAccess::NameChanged.new(1, data: { new_name: "John Doe" })
IdentityAndAccess::NameChanged.new(2, data: { new_name: "John S. Doe" })
```

were processed in different order, the outcome would be incorrect. That's why I'd like to describe a few techniques which can be useful when working with such legacy application.

## Setting some value only once

First case can be if you know that some value is `nil` initially, it will be set by some domain event, and it is a field which, when set, never changes.

Let's look at these events:

```ruby
Inventory::WarehouseCharacteristicsDecided.new(1, data: {
  location: nil,
  size: "120",
  ...
})
Inventory::WarehouseCharacteristicsDecided.new(2, data: {
  location: "Wrocław, Poland",
  ...
})
```

And following read model handler:

```ruby
def perform(domain_event)
  case domain_event
  ...
  when Inventory::WarehouseCharacteristicsDecided
    state = State.find_by(domain_event.data[:warehouse_id]).lock!
    state.location = [
      state.location,
      domain_event.data[:location]
    ].compact.first
    state.save!
  else raise
  end
end
```

Thanks to the `[state, domain_event.data[:warehouse_id]].compact.first`, even if the messages will arrive out of order and the event with `location: nil` will be processed as last one, the location will be remembered correctly as `"Wrocław, Poland"`.

## Remembering only a minimal/maximal value

Sometimes, we have a data type which forms a linear order and we only want to remember the biggest or the smallest value. In that case, let's look at the following example:

```ruby
# Events:
EventPublished.new(id: 1, data: { published_at: "2019-02-01", ... })
EventPublished.new(id: 2, data: { published_at: "2019-02-05", ... })

# Handler:
def perform(domain_event)
  case domain_event
  ...
  when EventPublished
    state = State.find_by(domain_event.data[:event_id]).lock!
    state.first_published_at = [
      state.first_published_at,
      domain_event.data[:published_at]
    ].compact.min
    # or max instead of min
    # or sort_by { ... }.first/last to use a nontrivial ordering
    state.save!
  else raise
  end
end
```

Remembering the biggest/smallest value is easy thing. We just need to always pick the smallest out of the previously stored, and the one from the event we are currently processing. It can be easily extended to have nth value in order (by remembering a list of values instead of only the smallest one).

## Remembering the newest value

A truly eventually consistent thing! We just want to remember current value, but we don't want to be fooled by messages arriving out of order. This is actually the problematic case from the example in the beginning of this post:

```ruby
# Events:
IdentityAndAccess::NameChanged.new(1, data: { new_name: "John Doe" })
IdentityAndAccess::NameChanged.new(2, data: { new_name: "John S. Doe" })

# Handler:
def perform(domain_event)
  case domain_event
  ...
  when IdentityAndAccess::NameChanged
    state = State.find_by(domain_event.data[:user_id]).lock!
    if state.name_changed_at < domain_event.timestamp
      state.name = domain_event.data[:new_name]
      state.name_changed_at = domain_event.timestamp
    end
    state.save!
  else raise
  end
end
```

In that case, we need to remember two fields, for each value. We can think of it of course as two columns in the database table, but it can also be some kind of compound value in blob storage.
First one remembers actual newest value. The second keeps track of the timestamp, for which that value was definitely true. Now, if we want to remember only the newest one, we just always have to check whether the domain event we are processing have really some newer data than we actually already have.


## Read model creation

All of the previous examples were based on updating the read model. What about creating the record for it? For example, what will happen if we will have some creation fact processed twice? It would be a shame to create two different records in that case, because further queries and updates will use one of the records, and we probably don't really know which one.

Again, solution is simple -- having unique index on a field generated before running a handler (like frontend generated UUID), will cause database to throw an error. Usually we want our handler to be idempotent in that case, and just ignore such error (but only this, very specific one).

Second problem is when the read model is particularly short lived, and we will process the events in following order:

```ruby
SomethingCreated.new(1, data: ...)
# Record for read model created in DB

SomethingDeleted.new(2, data: ...)
# Record for read model deleted from DB

SomethingCreated.new(1, data: ...)
# It is the same fact as in the first line! It was just processed again, because background system failed to ACK the completed job.
```

The bad thing is, that the second processing of the `SomethingCreated` fact, added the row for the second time. Logically, there should be none, because the read model was created and deleted afterwards. The solution is to use soft-deletes, meaning, instead of removing the record from the database, just anonymize them and set `deleted` boolean flag to true. That way, second processing of first fact will again raise error due to uniqueness violation and unwanted record won't be created.

These patterns were meant to be taken under consideration in a legacy system with at-least-once delivery, but without order guarantee. Not always there's a need for that. Sometimes we can get order guarantee by having [linearized writes](https://railseventstore.org/docs/repository/#using-pglinearizedeventrepository-for-linearized-writes) and remembering last processed position or having a queue infrastructure with only at most one consumer processing element from given queue at the time. This poses challenges on its own, but all I wanted to show is that read-models are not so trivial and in reality there are some nuances in their implementation.

Also, if all of this sounds interesting and you would like to know more about our approaches to legacy rails apps and architecture, consider joining our [Rails Architect MasterClass](https://arkency.com/masterclass/).
