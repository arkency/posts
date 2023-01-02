---
created_at: 2023-01-02 16:53:30 +0100
author: Łukasz Reszke
tags: ['event store', 'event sourcing', 'rails event store']
publish: false
---

# Effortless debugging with those 4 linking classes from RailsEventStore

Some time ago I wrote a [short article](https://blog.arkency.com/simplify-your-system-debugging-by-introducing-event-store-linking/) about simplifying your system debugging by using the linking feature of RailsEventStore. The post is describing custom built linking class.

However, I forgot to mention that RailsEventStore provides a few linking classes out of the box!

Currently, there are [4 linking classes](https://railseventstore.org/docs/v2/link/#available-linking-classes):

<!-- more -->

- `RailsEventStore::LinkByMetadata` - links events to stream built on specified metadata key and value,
- `RailsEventStore::LinkByCorrelationId` - links events to stream by event's correlation id,
- `RailsEventStore::LinkByCausationId` - links events to stream by event's causation id,
- `RailsEventStore::LinkByEventType` - links events to stream by event's type
It's easy to use. All you have to do is to add the following line to your subscriptions:

```ruby
event_store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
event_store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
event_store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
```
And from now on, you can go to RailsEventStore Browser and browse your events by an event type, causation, and correlation ids.

You can read more about linking in the [docs](https://railseventstore.org/docs/v2/link/).
