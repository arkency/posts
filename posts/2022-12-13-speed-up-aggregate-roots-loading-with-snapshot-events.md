---
created_at: 2022-12-13 12:19:53 +0100
author: Piotr Jurewicz
tags: ['rails event store']
publish: false
---

# Speed up aggregate roots loading with snapshot events

[Rails Event Store](https://railseventstore.org/) 2.7 is coming with a new experimental feature: `SnapshotRepository`.

<!-- more -->

<img src="<%= src_original("speed-up-aggregate-roots-loading-with-snapshot-events/ snapshotting.png") %>" width="100%">

```ruby
Person.new.show_secret
# => 1234vW74X&
```
