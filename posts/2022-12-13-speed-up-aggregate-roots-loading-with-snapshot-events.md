---
created_at: 2022-12-13 12:19:53 +0100
author: Piotr Jurewicz
tags: ['rails event store']
publish: false
---

# Speed up aggregate roots loading with snapshot events

[Rails Event Store](https://railseventstore.org/) 2.7 is coming with a new experimental feature: `AggregateRoot::SnapshotRepository`.

<!-- more -->

In event sourcing, each change to the state of an aggregate root is recorded as an event in the event store, linked to the specific stream.
This allows for a complete history of changes to be tracked, but can also lead to slow performance if there are a large number of events for a single aggregate root.

A general rule of thumb is to design short-lived streams in terms of the events count. However, you can find yourself in a situation where the streams rapidly grows too big and loading it becomes a performance bottleneck.
You need a quick solution to deal with this problem.

This is where Snapshotting comes in.

## Many possible implementations

There are several ways of snapshots implementation. 

They can be treated as a kind of technical events, or they can be stored elsewhere.
If you goes with the first approach, you can either use aggregate root's stream or a separate one.
It is not so obvious how to actually dump the state of the aggregate for a persistence.
We can also debate if Aggregate root should know about being snapshotted or not.

So many things to consider made us blocked to provide a ready-to-use solution for some time.
During our last RES camp in Poznań, we decided to break the deadlock and provide a simple solution to check if it is a good fit for the community.

## RES implementation

For a initial implementation, we decided to go with an alternative aggregate root repository storing snapshots in a separate stream for a given interval of events.

```ruby
# save aggregate snapshot on each 50 events
repository = AggregateRoot::SnapshotRepository.new(event_store, 50)
# or stick to the default interval of 100 events
repository = AggregateRoot::SnapshotRepository.new(event_store)
```

<img src="<%= src_original("speed-up-aggregate-roots-loading-with-snapshot-events/snapshotting-transparent.png") %>" width="100%">

In the above example, using snapshots every 100 events, with aggregate root `Order` having 202 events, we would have only 2 events to read from the event store to load the aggregate root.
* At first, we check for the latest snapshot event in the `Ordering::Order$bb7c6c8b..._snapshots` stream. If it exists, we load the aggregate root state from the event data.
* Then, we read the remaining domain events from the `Ordering::Order$bb7c6c8b...` stream and apply them to the aggregate root one by one.

A standard implemantion would go through all the 202 domain events to achieve the same result. STONKS!




Under the hood, we use Ruby's `Marshal` library to dump the aggregate root state into a byte stream, allowing them to be stored in the event data.
Marshal format has its limitations. Dumping an aggregate root will not work if its instance variables are bindings, procedure or method objects, instances of class IO, or singleton objects. 
