---
created_at: 2022-12-13 12:19:53 +0100
author: Piotr Jurewicz
tags: ['rails event store']
publish: false
---

# Speed up aggregate roots loading with snapshot events

[Rails Event Store](https://railseventstore.org/) 2.7 is coming with a new experimental feature: `SnapshotRepository`.

<!-- more -->

In event sourcing, each change to the state of an aggregate root is recorded as an event in the event store, linked to the specific stream.
This allows for a complete history of changes to be tracked, but can also lead to slow performance if there are a large number of events for a single aggregate root.

A general rule of thumb is to design short-lived streams in terms of the events count. However, you can find yourself in a situation where the streams rapidly grows too big and loading it becomes a performance bottleneck.
You need a quick solution to deal with this problem.

This is where Snapshotting comes in.

## RES implementation

There are several ways of snapshots implementation. 
...
<img src="<%= src_original("speed-up-aggregate-roots-loading-with-snapshot-events/snapshotting.png") %>" width="100%">




```ruby
Person.new.show_secret
# => 1234vW74X&
```
