---
title: "Why use Event Sourcing"
created_at: 2015-03-10 21:35:01 +0100
kind: article
publish: true
author: Mirosław Pragłowski
tags: [ 'domain event', 'event sourcing' ]
newsletter: arkency_form
img: "events/eventsourcing.jpg"
meta_title: "→ Event Sourcing - The Reasons Why To Use It"
description: "Event Sourcing - We Explain The Biggest Advantage of Using It. Visit Our Blog and READ MORE !!!"
---

<p>
  <figure>
    <img src="<%= src_fit("events/eventsourcing.jpg") %>" width="100%">
  </figure>
</p>

Event Sourcing relies on not storing current state. All of application state is first level derivative out of facts. That opens completely new ways of architecting our applications.

## But why?

There is a lot of reasons to use Event Sourcing. When you browse through Greg Young’s and other articles & talks you will find most of them. Usually they mention:

* It is not a new concept, a lot of domains in real world works like that. Check out your bank statement. It’s not the current state - it is log of domain events. Or if you are not still convinced talk to your accountant ;)
* By replaying an event we could get a state of an object (or let’s use correct term here: aggregate) for any moment in time. That could greatly help us to understand our domain, why things changed and debug really nasty errors.
* There is no coupling between the representation of current state in the domain and in storage.
* Append-only model storing events is a far easier model to scale. And by having a read model we could have best of both worlds. Read side optimised for fast queries and write side highly optimised for writes (and since there is no delete here, it could really be fast writes).
* Beside the “hard” data we also store user’s intentions. The order of events stored could be used to analyse what user was really doing.
* We are avoiding impedance mismatch between object oriented and relational world.
* Audit log for free. And this time the audit log really has all the changes (remember there is no change of state if there is an event for that).

<!-- more -->

> Every database on a planet sucks. And they all suck it their own unique original ways.

<p class="quote-by">Greg Young, Polyglot Data talk</p>

For me the biggest advantage is that I could have different data models generated based on domain events stored in Event Store. Having an event log allows us to define new models, appropriate for the new business requirements. That could be not only tables in relational database. That could be anything. That could be a graph data model to store relations between contractors in your system with easy way to find how the are connected to each other. That could be a document database. That could
be a static HTML page if you are building newest and fastest (or of course most popular) blogging platform :)

> As the events represent every action the system has undertaken any possible model describing the system can be built from the events.

<p class="quote-by">
  <a href="http://docs.geteventstore.com/introduction/event-sourcing-basics">Event Sourcing Basics</a> at Event Store documentation
</p>

You might not know future requirements for your application but having an event log you could build a new model that hopefully will satisfy emerging business requirements. And one more thing… that won’t be that hard, no long migrations, no trying to guess when something has changed. Just replay all your events and build new model based on the data stored in them.


If you are interested in pros and cons of Event Sourcing and another point of view on why to use it read Greg’s post from 2010 (I’ve said Event Sourcing is not a new thing): http://codebetter.com/gregyoung/2010/02/20/why-use-event-sourcing/
