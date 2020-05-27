---
title: "Event-sourcing whole app — opinions"
created_at: 2017-10-10 17:12:35 +0200
publish: true
author: Paweł Pacana
tags: [ 'ddd', 'event sourcing' ]
newsletter: arkency_form
---

You might have heard the _"Event-sourcing your whole app in an anti-pattern"_ meme. It's not uncommon to get exposed to it once you find yourself speaking with another practitioner of this technique.

I had — just recently, on a [Rails DDD training](https://blog.arkency.com/ddd-training/) that we've organized. To be honest I've heard about it before. This time however it provoked me to dig deeper. To find the reasons which led to formulate it. To understand the context in which it makes most sense.

<!-- more -->

## The opinions

No surprise that the original quote comes from the godfather of CQRS, **Greg Young**:

> The single biggest bad thing that Young has seen during the last ten years is the common anti-pattern of building a whole system based on Event sourcing. That is a really big failure, effectively creating an event sourced monolith. CQRS and Event sourcing are not top-level architectures and normally they should be applied selectively just in few places.

The above [except](https://www.infoq.com/news/2016/04/event-sourcing-anti-pattern) is extracted specifically from [A Decade of DDD, CQRS, Event Sourcing](https://www.youtube.com/watch?v=LDW0QWie21s) that Greg gave at DDD Europe 2016.

Main takeaways:

- you have to think about corrections in event sourced system (i.e. fixing typo in the data) — not that straightforward with immutable events as it was with CRUD
- it's a different style of problem analysis and it can be more expensive
- there are times it actually becomes easier to event-source but as rule you really don’t want to event-source everything
- it should not be your top-level architecture (it should be some kind of event-driven though)

After learning from Greg, let's examine what **Udi Dahan** says on [similar topic](http://udidahan.com/2011/04/22/when-to-avoid-cqrs/):

> Most people using CQRS (and Event Sourcing too) shouldn’t have done so.

On the audit logs, that come for free, as a side-effect, with Event Sourcing:

> Who put you in a position to decide that development time and resources should be diverted from short-term business-value-adding features to support a non-functional requirement that the business didn’t ask for?

> (…) you can usually implement this specific requirement with some simple interception and logging.

About the “proof of correctness” in Event Sourcing:

> While having a full archive of all events can allow us to roll the system back to some state, fix a bug, and roll forwards, that assumes that we’re in a closed system. We have users which are outside the system. If a user made a decision based on data influenced by the bug, there’s no automated way for us to know that, or correct for it as we roll forwards.

## When to use Event Sourcing

Not only me — also [Andrzej](https://www.youtube.com/channel/UCmrGGj6Y_XQuockwwI3yemA) decided to research some pros and cons:

<iframe width="560" height="315" src="https://www.youtube.com/embed/yHtw5C7mouE?rel=0" frameborder="0" allowfullscreen></iframe>

## Recap

Being honest about a technology or a technique is not only knowing _"the good parts"_ but also what pitfalls to be aware of.

There is [No Silver Bullet](https://en.wikipedia.org/wiki/No_Silver_Bullet). In the end you'll have to make a judgement — in the context of your application and the business domain it supports.

It is however good to **know your options first** and **what price tag** does each of them comes with.
