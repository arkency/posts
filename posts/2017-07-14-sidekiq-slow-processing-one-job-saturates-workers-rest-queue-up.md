---
title: "Handle sidekiq processing when one job saturates your workers and the rest queue up"
created_at: 2017-07-14 18:25:06 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'sidekiq' ]
newsletter: :arkency_form
---

I saw a great question on reddit which I am gonna quote and try to provide a few possible answers.


> Ran in to a scenario for a second or 3rd time today and I'm stumped as how to handle it.
> We run a ton of stuff as background workers, pretty standard stuff, broken up in to a few priority queues.
> Every now and then one of our jobs fails and starts running for a long time - usually for reasons outside of our control - our connection to S3 drops or as it happened today - our API connection to our mail system was timing out.
> So jobs that normally run in a second or two are now taking 60 seconds and holding a worker for that time. Enough of those jobs quickly saturate our available workers and no other work gets done. The 60 second timeout hits for those in-process jobs, they get shuffled to the retry queue, a few smaller jobs process through the available workers until the queued jobs pull in enough of the failing jobs to again saturate the available workers.
> I'd think this would be a pattern that other systems would have and there would be a semi-obvious solution for it - I've come up empty handed. My thought was to separate the workers by queue and balance those on different worker jobs but then that still runs the risk of saturating a specific queue's workers.

<!-- more -->

* Lower your timeouts

* Pause a queue.

    Keep the troublesome job on a separate queue. Use Sidekiq Pro. When lots of jobs are failing or taking too long, just [pause the queue](https://github.com/mperham/sidekiq/wiki/Pro-API#pausing-queues). Great feature. Saved our ass a few times.

* Partition your queues into many machines or processes.

    Have machine one work on queues A,B,C,D and machine two work on queues E,F,G,H

* Keep your queues in two reverse orders

    I am not sure if that's possible with sidekiq but it was possible with resque. Most of our machines were processing jobs in normal priority: A,B,C,D,E,F,G. But there was one machine configured to process them in reverse: G,F,E,D,C,B,A.