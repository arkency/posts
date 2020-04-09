---
title: "Self-hosting Event Store on Digital Ocean"
created_at: 2017-05-24 11:46:11 +0300
kind: article
publish: true
tags: [ 'rails event store', 'ddd' ]
author: Andrzej Krzywda
newsletter: skip
---

Recently in one of our projects, we have decided that it would be a good idea to switch to [EventStore](https://geteventstore.com). Our current solution is based on [RailsEventStore](https://github.com/arkency/rails_event_store) (internal to each Bounded Context) and an external RabbitMQ to publish some event "globally". This approach works, but relying on EventStore sounds like a better approach. For a long time, we felt blocked, as EventStore doesn't offer a hosted solution and we were not sure if we want to self-host (in addition to the current heroku setup).

<!-- more -->

Luckily, one of the Arkency developers, Paweł, was following the discussion and quickly timeboxed a solution of self-hosting Event Store on Digital Ocean. It took him super quick to deliver a working node. This enables us to experiment with partial switching to EventStore.

I have asked Paweł to provide some instructions how he did it, as it seems to a very popular need among the DDD/CQRS developers.

Here are some of the notes. If it lacks any important information, feel free to ping us in the comments.

```
$  apt-get update
$  curl -s https://packagecloud.io/install/repositories/EventStore/EventStore-OSS/script.deb.sh | sudo bash
$  apt-get install eventstore-oss
```

```
$ ifconfig eth0 |grep addr:
          inet addr:XXX.XXX.XXX.NNN  Bcast:XXX.XXX.XXX.255  Mask:255.255.255.0
          inet6 addr: fe80::36:88ff:febb:5d6d/64 Scope:Link
```

```
$ echo "ExtIp: XXX.XXX.XXX.NNN" >> /etc/eventstore/eventstore.conf
$ cat /etc/eventstore/eventstore.conf
---
RunProjections: None
ClusterSize: 1
ExtIp: XXX.XXX.XXX.NNN
```

```
$ service eventstore start
```

Those are the instructions for the basic setup/installation. You can now start experimenting with EventStore. For production use though you'd need to invest in reliability (clustering, process supervision and monitoring) as well as in security.
