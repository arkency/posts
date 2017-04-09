---
title: "Reliable notifications between two apps or microservices"
created_at: 2017-09-02 11:30:18 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'messaging' ]
newsletter: :arkency_form
img: reliable-messaging-notifications-between-two-apps-micoservices-api/queue.png
---

Let's say you have 2 systems or microservices (or processes). And one of them needs to be notified when something happened in another one. You might believe it is not so hard unless you start thinking about networking, reliability, and consistency.

I would like to briefly present some patterns for how it can be done and what do they usually bring to the table.

<!-- more -->

## Direct communication (v1)

1. System A does something in a SQL transaction, which is committed.
2. System A contacts system B directly via API after the transaction is committed.

It all works nicely until system B is down and non-responsive. In such case, it won't be notified about what happened in B so we have a discrepancy. Assuming we have some kind of error reporting (and it worked at that moment) a developer can be notified about the problem and try to fix it manually later.

This, however, could be easily fixed, couldn't it? Let's just contact system B inside the DB transaction, instead of outside.

## Direct communication (v2)

1. System A does something in a SQL transaction
2. System A contacts system B directly via API (still inside the DB transaction)
3. System A commits DB transaction.

Some developers believe this a perfect solution, but they forget about one corner case that can still occur. Imagine that system B received your message (HTTP request) but you didn't receive a response (because networking is not reliable).  In such case, there will be most likely an exception in system A. It will rollback a DB transaction and pretend that nothing happened. But system B assumes it did happen. So we have a discrepancy again.

Also, this situation might not happen just because the response did not get back. There are other cases where the final effect is the same. HTTP request was sent, but an application process was killed, or server turned off. Or there was a bug in a code (if there is such code) between sending the request and committing the DB transaction).

I believe however that all those situations combined are less likely than server B just being unavailable. So probably this is better than v1. But still not perfect.

## Using external queue

1. System A does something in a SQL transaction
2. System A saves info in an external queuing system
3. System A commits DB transaction.
4. a) System A takes jobs from queuing system and sends them to system B. Jobs can be retried in case of failure.
    
    or
    
    b) System B takes jobs from queuing system and processes them Jobs can be retried in case of failure.

In this situation, we introduced an external queuing system such as Kafka, RabbitMQ or redis. I called it external because the storage mechanism is using a different database then the application itself (which assume SQL DB).

Also depending on the situation, it might be your system (but another process, like a background workers solution) taking jobs from the queue and pushing them further. Or it might be that another micro-service (system B) takes the jobs and processes them.

Notice that by introducing a queueing system in the middle and retries we changed the semantics from at-most-once delivery to at-least-once delivery.

It's still not all roses, however. We don't contact a separate system directly now, but we contact a separate database. With exactly the same potential pitfalls. What if we rollback after pushing to the queue? What if we pushed to the queue, but we didn't receive a confirmation and rolled-back in SQL? All the same situations can happen. But because we assume those servers running queues are closer to us, we also assume the likelihood of such problems happening is much lower. But still not zero. In my system, it happened 10 times in one month.

Also, the assumption that both DBs are very close to each other is not always correct in modern world anymore. If you use hosted redis or hosted X there is a big chance they are going to be in the same region, but not necessarily the same availability zone.

To summarize. Thanks to retries we are safe from system B failures but we can still encounter problems on our side.

## Using internal queue

Ultimately the only safe solution is to use only one database only which would be the same SQL database.

1. System A does something in a SQL transaction
2. System A saves info in an internal queuing system running based on the same SQL DB
3. System A commits DB transaction.
4. a) System A (another thread or process) takes jobs from the internal queuing system and sends them to system B.
    
    or
    
    b) System A (another thread or process) takes jobs from the internal queuing system and moves them to the external queuing system, where system B takes them from.

In this case, we save jobs info about what we want to notify external system about in the same SQL DB we store application state in. We can safely commit or rollback both of them together.

Then we either have background workers pulling from the same DB (internal queue) and communicating with system B or pushing those jobs to the external queue such as Kafka or RabbitMQ (one reason for that is there might be more systems than just B interested in this data).

I am tempted to say that this gives you 100% reliability but probably that's not true and I am just missing a case where it can fail :)

Anyway, this is probably the safest solution. But it requires more monitoring. Not only you watch for system B, for the external queue, but now you also need to watch the thread or process moving data from the internal to the external queue.

## Summary

How do you solve those problems in your system? Which solution did you go with?

I think some apps just ignore them and handle such issues manually (or not at all), because they are not crucial. But many things that I work on, handle monetary transactions, so I am always cautious when thinking about such problems.

<%= img_fit("reliable-messaging-notifications-between-two-apps-micoservices-api/queue.png") %>

As you can see there are many ways system A can notify B about something (notice that we are talking about notifications, where A is not immediately interested in a response from B, just that it got the message and they are both in sync about the state of the world). You can do it directly, you can introduce external queues, you can have internal queues in the same DB or you can even go with both queues if you find it worthy of the cost of DevOps.

## More

Are you working on more advanced Rails Apps? Register [for our upcoming workshop in May, in Lviv](/ddd-training/) to learn and practice more techniques, beyond service objects, which will help you organize your code.

## Links

Examples of internal queues:

* https://github.com/collectiveidea/delayed_job

Examples of external queues:

* https://github.com/mperham/sidekiq
* https://kafka.apache.org/ + https://github.com/karafka/karafka
* https://www.rabbitmq.com/ + https://github.com/ruby-amqp/bunny

Other:

* [Patterns for dealing with uncertainty](/2016/12/techniques-for-dealing-with-uncertainity/)
* [You Cannot Have Exactly-Once Delivery](http://bravenewgeek.com/you-cannot-have-exactly-once-delivery/)
