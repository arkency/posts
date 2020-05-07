---
title: Rails Event Store 1.0 — The Past, Present and Future
created_at: 2020-04-27T21:08:11.622Z
author: Mirosław Pragłowski
tags: ['rails event store']
publish: true
---


[Rails Event Store](https://railseventstore.org) is a Ruby library to persist, retrieve, publish and organize application architecture around domain events in an event-driven fashion. It's not a database itself — it is built on top of an existing (typically SQL) data store in the application. It makes a great foundation for CQRS, Event Sourcing and loosely coupled components in applications driven by domain events.

We've just reached [1.0 milestone](https://github.com/RailsEventStore/rails_event_store/releases/tag/v1.0.0)!


## How it all started

It all is a part of "My Ruby Story". I've joined Arkency in 2014 after a long time working as .NET developer.
It was a completely new environment for me. At that time I've not known Ruby. I've heard something about Ruby On Rails,
but I've never have any experience with dynamic languages.

You might ask how I was able to join experienced Ruby/Rails developers in Arkency?
It is the same way you could join us now. By bringing other valuable experiences,
or knowledge that will make our work more efficient.

My "assets" was a knowledge of Domain-Driven Design and experience in developing web applications.
I've attended a Ruby User Group meetup in Wrocław, when I've explained to Ruby devs the concepts
of DDD and in more details the Event Sourcing pattern. Two beers later I've become a Ruby developer ;)


The Rails Event Store prototype was "born" on one of our customer's project. It was a way to solve the
business problem. It was very "naive" implementation, with a lot of problems. But the job has been done.
It has been working in production for a long time, gradually replaced by various Rails Event Store components. Piece by piece, until finally it has been replaced by Rails Event Store as a whole completely. The learnings from that migration have been
described by Paweł in [a blogpost](https://blog.arkency.com/how-to-migrate-large-database-tables-without-a-headache/).


The first "prototype" version of our event store has been only 248 lines of code.
The current version of Rails Event Store is much bigger, it has more features, it supports different
use cases and, what is really important, it is much better tested.


The only thing that has not changed is the project philosophy. We build thing we need in our day to day work
on customer's projects. Arkency client projects are to Rails Event Store what Basecamp is to Rails.
We learn, sometimes the hard way, we define new needs, we implement them in Rails Event Store and
as always we share our experiences on [Arkency's blog](https://blog.arkency.com/tags/rails-event-store/).


## What is it means to be 1.0

It's just a milestone. In Rails Event Store we are using [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and
we follow the versioning guidelines defined by it. We have reached the point where the answer for question
["How do I know when to release 1.0.0"](https://semver.org/spec/v2.0.0.html#how-do-i-know-when-to-release-100)
was "oops, we should have done that some time ago". Rails Event Store is already used in production. Not only by us
— there is no trivial project in Arkency where Rails Event Store is not part of the solution. Also by other
companies and software houses in their ventures. The API is stable and with each release we worry not to
break other projects that use Rails Event Store as a dependency.

This does not mean we now stop introducing changes. We will implement new things, also the ones
that will change the public API. We will be following the SemVer versioning guidelines and preparing comprehensive changelogs — business as usual.


## The roadmap

The project philosophy does not change. Arkency is a consulting agency. We implement ourselves the features we need the most for successful client projects. And we're hesitant when adding the ones not widely used in production systems.

However Rails Event Store is bigger than us and is already [used by dozens of companies](https://railseventstore.org/). It is not uncommon to see other gems building on top of RES as well. We welcome any contribution that makes the project better for all and [encourage experimenting](https://github.com/RailsEventStore/rails_event_store/tree/master/contrib).

What we will focus on now? The key elements will be:

* improving [documentation](https://github.com/RailsEventStore/rails_event_store/issues?q=is%3Aissue+is%3Aopen+label%3Adocumentation), describing how RES works and fits in the architecture of an application
* support for quick prototyping of event-driven systems, to quickly garther and verify requirements
* debugging API - to make troubleshooting production issues easier when they emerge
* improved observability - logging, monitoring and metrics
* better support for ongoing refactoring and refining with growing understanding of the system — domain events versioning
* making it even easier to start with Event Sourcing using RES in new projects

