---
created_at: 2018-10-08 12:14:17 +0200
publish: true
author: Paweł Pacana
tags: [ 'rails_event_store', 'rescon' ]
newsletter: arkency_form
img: rescon_andrzej_thinking.jpg
---

# What I've learnt at RESCON

<%= img_fit("rescon_andrzej_thinking.jpg") %>

During 4–6 October 2018 I had a pleasure to organize and participate in [RESCON](https://rescon.arkency.com). It was an opportunity to show and share what I've learned over the years. I've met new people that are into this topics and that gave me new perspective on things I work on. Without further ado, below are things I’ve learnt on first ever RailsEventStore conference.

<!-- more -->

## People love event schemas

There is a certain appeal in knowing the current shape of a domain event. It helps from a documentation point of view, it could drive better tooling as well.
Without schemas you rely on thorough test coverage.

On hackathon I've seen a tool to show focused diff of schema changes over time. High five to Ania and Mariusz!

The topics that circulated were how to handle event versioning, the promise of upcasting in future RES versions and how to make JSON a default serializer (with a little help of schemas).

## NServiceBus has a decent UI to debug message flows

One of our guests was [Szymon Pobiega](https://twitter.com/SzymonPobiega) who works daily on NServiceBus. He was kind enough to run a quick demo of it's dashboard. In the app you could drill down what messages were recorded in a system, how they connect together and visualize the whole business processes. That gave me much inspiration what could land in [Browser](https://railseventstore.org/docs/browser/) some day.

## The concept of a stream is not that familiar

A stream is a simple grouping of events under one name. Simple yet powerful as it allows [partitioning for a particular reader](https://eventstore.org/blog/20130210/the-cost-of-creating-a-stream/index.html). And organizing events into streams in RES is quite cheap now with link operation.

You will primarily use a stream per aggregate but you're not limited to. We use streams to manage process manager state — by linking the events process is reacting to into it's stream. We also started using it for different projections — grouping events by correlation id or collecting events to be processed for particular read model, that is a report.

## Sending messages into the future is tricky

This technique can be used to decouple infrastructure from a domain code. Instead of relying on a clock and modifying it, you send an event describing what time-related just happened in your domain — `MonthClosed`, `TwoWeeksBeforeEditionReached`, etc. The infrastructure to deliver it when it needs to be done stays on infrastructure layer. We've seen it first in workshop app. Then Szymon took us on a journey through several possible applications and how they've done the infrastructure part on RabbitMQ. Lastly, on hackathon, David showed us the Metronome to tick with time-related events relevant for a app he works on.

There are philosophical difficulties when considering sending past message to your future self. What kind of message it is? Can you reject it? I've definitely have a food for thought and that is on our RES roadmap.

## Metronome is a really cool name for time-related events module

[David](https://twitter.com/davidsaitta) shared a joy for finding a good name and I would totally use that one as well.

## There are many RES versions in the wild and not necessarily the newest

I've learned about deployments of different RES versions and the struggles to keep it up-to-date. It is especially tricky if you implement a lot of custom extensions on top of such moving target.

That's the downside of current [before-1.0-release](https://github.com/RailsEventStore/rails_event_store/milestone/3) situation and we're aligned to make it better soon.

## There are many extensions on top of RES

It was [not the first time](https://www.youtube.com/watch?v=cdwX1ZU623E) I've seen such extensions. That keeps me convinced RES is a great base to extend (when stable), yet we might miss some conventions to keep you more productive from day one like Rails does.

It seems the choice nowadays is to lean on dry-rb ecosystem. That usually comes with a sentiment that Virtus was much more pleasant to work with.

Some of the extensions fill the void of RES not having first-class command support — it really seems to be the missing part.

Btw. if you wish to get featured on [Community](https://railseventstore.org/community/) send me a link to your article or code and I'll make sure it gets there!

## The promise

If you haven't seen it live already, I'd recommend watching Andrzej's keynote on The Vision of Rails Event Store!

<iframe src="https://www.facebook.com/plugins/video.php?href=https%3A%2F%2Fwww.facebook.com%2FArkencyCom%2Fvideos%2F2187126198226563%2F&show_text=0&width=560" width="560" height="315" style="border:none;overflow:hidden" scrolling="no" frameborder="0" allowTransparency="true" allowFullScreen="true"></iframe>

This also makes a good moment to announce next year's edition — there will definitely be one. Can you imagine where RES will be `12.months.from_now`?. If you want to make sure you don't miss it, [subscribe here](http://eepurl.com/doIcqP).
