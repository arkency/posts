---
title: 4 strategies when you need to change a published event
created_at: 2021-01-11T13:31:08.554Z
author: Tomasz Wróbel
tags: ["event store", "event sourcing", "ddd", 'rails event store']
publish: true
---

# 4 strategies when you need to change a published event

Event versioning — you'll need it one day anyway. You publish an event. You handle it in some consumers, perhaps aggregates or process managers. Soon you realize you need to change something in the event's schema... Like adding an attribute, filling up a missing value, flattening the attribute structure. What do you in such a situation?

## 0. Mutate past events 😧

Meaning you just loop over the past events that need to change and mutate their payload in the database. You might be tempted to do it using RES internals:

```ruby
RailsEventStoreActiveRecord::Event.where(event_type: "SomethingHappened").find_each do |record|
  record.data[:new_attribute] = "new_value"
  record.save!
end
```

But please do not. There's an api exactly for this purpose described [in the RES docs](https://railseventstore.org/docs/v1/migrating_messages/):

```ruby
event_store.read.each_batch do |events|
  events.each do |event|
    event.data[:new_attribute] = "new_value"
  end
  event_store.overwrite(events)
end
```

This way or another, mutating past events is what most people intuitively do if they weren't previously exposed to the topic of event versioning. But, I believe in most cases you should not go for this strategy. It seems like it's just fine, but:

* Do you control all the consumers?
* An event is a fact — should you be changing the history?
* An event is conventionally assumed to be immutable. What if some other piece of code (rightfully) depends on this assumption?
* Do you go for this strategy only to avoid dealing with the other ones? What if you become used to it and one day employ it in a situation where the consequences will show up?

This strategy can be still fine in situations like: the event was only published on a staging environment so far. Or when you control the consumers and the change is trivial — where triviality can mean anything depending on your team. A lot of people are fine with it for e.g. event name change, some other people will say changing a key/value in the payload is trivial too (like `user_id: 12345` -> `approved_by: "someone@example.com"`).

<!-- If you still need to do it on occassion and you feel anxious about not screwing something up, it may be useful to dump the previous payload to the event metadata or to another technical event. -->

## 1. Weaken the event schema and make consumer code more defensive 😕

I.e. you just let your event be this or that. Newer events will have the new attribute, older events simply won't. It's not easily seen if you don't have schema validation set up. But if you do, you typically need to explicitly weaken the schema. If you happen to use `dry-struct`, that can mean using `attribute?` to let older events stay without the new attribute without causing validation errors when loading events.

```ruby
class SomethingHappened < Dry::Struct
  attribute  :id,            Types::String
  attribute? :new_attribute, Types::String
end
```

In any case, this pushes the complexity of handling different event shapes to consumers and results in a lot of defensive code. Also, with schema validation set up, it weakens the writes — which is completely unnecessary (unless you choose to validate only on write, which has its own pros and cons).

The downsides of weak schema are clear. It still sometimes makes sense — for example as a hotfix to gain time for a cold fix.

## 2. Upcasting the event on-the-fly 🛩

I.e. whenever an old event is read, you transform it on-the-fly. You can do it by defining a mapper in RES. Now, whenever an old event is read from the event store, it's transformed and the consumer receives it in the new shape, so it doesn't need to handle both of them.

```ruby
Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      mapper: MyCustomMapperWithUpcastingCapabilities.new
    )
  end
end
```

* Before RES 2.1.0 you need to configure a custom mapper. More on this: [RES docs on configuring mappers](https://railseventstore.org/docs/v1/mapping_serialization/#custom-mapper).
* Since RES 2.1.0 you can use a `Transformation::Upcast` mapper, [see an example here](https://github.com/RailsEventStore/rails_event_store/pull/836).

Upcasting is often a good default strategy when events are already in production. But, what if the necessary transformation is not practical to achieve on the fly?

## 3. Stream rewriting a.k.a copy-and-replace 💾

I.e. publish/append new events into a new stream, leave the old stream untouched, switch to the new stream. Like permanent upcasting with the price of new event records. Arguably most expensive operationally, but it can handle complicated scenarios and doesn't wipe out the history. It may be helpful to compare this strategy to `git rebase`.

## Where can I learn more?

This is far from what can be said on the topic. If you want to know more, make sure to check [Versioning in an Event Sourced System](https://leanpub.com/esversioning/read) by Greg Young.

Got comments/questions? Ping or DM [me on twitter](https://twitter.com/tomasz_wro) or [reply under this tweet](https://twitter.com/tomasz_wro/status/1348629438121078784).

Special thanks for [Paweł](https://twitter.com/pawelpacana/) for crunching the topic together.
