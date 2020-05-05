---
title: Rails Event Store 1.0 — The Past, Present and Future
created_at: 2020-04-27T21:08:11.622Z
author: Mirosław Pragłowski
tags: ['rails event store']
publish: false
---

## How it all started

It all is a part of "My Ruby Story". I've joined Arkency in 2014 after a long time working as .NET developer.
It was a complete new environment for me. At that time I've not known Ruby, I've heard something about Ruby On Rails,
but I've never have any experience with dynamic languages.

You migth ask how I was able to join experienced Ruby/Rails developers in Arkency?
It is the same way you could join us now. By bringing other valuable experiences,
or knowledge that will make our work more efficient.

My "assets" was a knowledge of Domain-Driven Design and experience in developing web applications.
I've attended a Ruby User Group meetup in Wrocław, when I've explained to Ruby devs the concepts
of DDD and in more details the Event Sourcing pattern. Two beers later I've become a Ruby developer ;)


The Rails Event Store prototype was "born" on one of our customer's project. It was a way to solve the
business problem. It was very "naive" implementation, with a lot of problems. But the job has been done.
It has been working in production for a long time, gradually replaced by Rails Event Store components until,
finally, it has been replaced by Rails Event Store some time ago. The learnings from that migration have been
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
[How do I know when to release 1.0.0?](https://semver.org/spec/v2.0.0.html#how-do-i-know-when-to-release-100)
was "ups, we should have done that some time ago". Rails Event Store is already used in production, not only by us
(there is no simple project in Arkency where Rails Event Store is not part of the solution) but also for other
companies & software houses working on theirs projects. The API is stable and with each release we worry not to
break other projects that use Rails Event Store as a dependency.


This does not mean we will stop making changes. We will implemnent new things, also the ones
that will change the public API. We will follow the SemVer versioning guidelines and we will
describe the changes in the release notes (as it is done for a long time already).


## The roadmap

The project philosophy will not change. We work on client's projects. We will implement features we need.
We will avoid to have features that are not widely used in production systems.

But this is not only for our projects now. Rails Event Store is [used by dozens of companies](https://railseventstore.org/),
working on theirs internal projects or theirs customer's projects. Any contribution is welcomed.


What we will focus now? The key elements will be:

* adding support for quick prototyping of event-driven systems, to quickly garther & verify requirements
* Debugging API - to make troubleshooting production issues easier
* improved observability - logging / monitoring / metrics API
* better support for domain events versioning
* make it easier to start with Event Sourcing using RES in new projects
