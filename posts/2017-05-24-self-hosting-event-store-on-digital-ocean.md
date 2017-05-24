---
title: "Self-hosting Event Store on Digital Ocean"
created_at: 2017-05-24 11:46:11 +0300
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

Recently in one of our projects, we have decided that it would be a good idea to switch to [EventStore](https://geteventstore.com). Our current solution is based on [RailsEventStore](https://github.com/arkency/rails_event_store) (internal to each Bounded Context) and an external RabbitMQ to publish some event "globally". This approach works, but relying on EventStore sounds like a better approach. For a long time, we felt blocked, as EventStore doesn't offer a hosted solution and we were not sure if we want to self-host (in addition to the current heroku setup).

<!-- more -->

Luckily, one of the Arkency developers, Paweł, was following the discussion and quickly timeboxed a solution of self-hosting Event Store on Digital Ocean. It took him super quick to deliver a working node. This enables us to experiment with partial switching to EventStore.

I have asked Paweł to provide some instructions how he did it, as it seems to a very popular need among the DDD/CQRS developers.

Here are some of the notes. If it lacks any important information, feel free to ping us in the comments.

```
root@ges:~# history
    1  apt-get update
    2  curl -s https://packagecloud.io/install/repositories/EventStore/EventStore-OSS/script.deb.sh | sudo bash
    3  apt-get install eventstore-oss
    4  service eventstore start
    5  netstat -palnt
    6  service eventstore stop
    7  vim /etc/eventstore/eventstore.conf
    8  service eventstore start
```


```
root@ges:~# cat /etc/eventstore/eventstore.conf
---
RunProjections: None
ClusterSize: 1
ExtIp: XXX.XXX.XXX.NNN
```

```
root@ges:~# ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:36:88:bb:5d:6d
          inet addr:XXX.XXX.XXX.NNN  Bcast:XXX.XXX.XXX.255  Mask:255.255.255.0
          inet6 addr: fe80::36:88ff:febb:5d6d/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:323856446 errors:0 dropped:0 overruns:0 frame:0
          TX packets:450237174 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:53356158071 (53.3 GB)  TX bytes:40631577493 (40.6 GB)
```

Those are the instructions for the basic setup/installation.