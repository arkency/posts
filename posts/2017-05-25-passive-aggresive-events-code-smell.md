---
title: "Passive aggresive events - code smell"
created_at: 2017-05-25 13:49:31 +0300
kind: article
publish: true
author: Andrzej Krzywda
newsletter: skip
tags: ['domain event', 'ddd']
---

Today, while sitting on our [Rails/DDD workshops](http://blog.arkency.com/ddd-training/) led by Robert in Lviv, I was thinking/preparing a design of the new aggregates in my project. Robert was just explaining aggregates and how they can communicate (with events).

During the break, I asked Robert what he thinks about it and he mentioned a term, that I missed somehow. The term was coined by Martin Fowler in his [What do you mean by “Event-Driven”?](https://martinfowler.com/articles/201701-event-driven.html) article.

<!-- more -->

Here is the particular quote:

"A simple example of this trap is when an event is used as a passive-aggressive command. This happens when the source system expects the recipient to carry out an action, and ought to use a command message to show that intention, but styles the message as an event instead."

In my case, it was a situation, where I have a `Company` aggregate and when it receives an external request to "change\_some\_state" it has to delegate it to its "children" objects. Those objects are just value object in the aggregate, but they are also aggregates on their own (as separate classes). The design was split into smaller aggregates with hope of avoiding `Your Aggregate Is Too Big` problem.

I agree that with the approach I have planned my events are a little bit passive-aggresive and they sound more like commands. I will either live with that (but be aware of the trap) or I will consider using the Saga concept here (events as input, command as output).

BTW, the whole article by Martin Fowler is [worth a read](https://martinfowler.com/articles/201701-event-driven.html).

How do you deal with such problems in your DDD apps?
