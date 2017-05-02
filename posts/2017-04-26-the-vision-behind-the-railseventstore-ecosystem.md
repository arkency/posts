---
title: "The vision behind the RailsEventStore ecosystem"
created_at: 2017-04-26 15:35:54 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

Arkency became known for our DDD efforts in the Rails community. DDD together with CQRS and Event Sourcing helped us dealing with large Rails apps. At some point we also started open-source tooling to support introducing DDD in Rails apps. This blogpost aims to highlight where we started, where we are and what is the vision for the future, for the RailsEventStore ecosystem.

<!-- more -->

# Where we started

The journey with DDD at Arkency started probably around ~6 years ago, when we started using technical patterns like service objects (in DDD we would call them application services), adapters and repositories. This phase resulted in writing the ["Fearless Refactoring: Rails Controllers"](http://rails-refactoring.com) ebook which is all about those patterns.

Those patterns helped, but didn't solve all of our problems. We could say, that service objects were like a gateway drug - they enabled us to isolate our logic from the Rails app. But still, how exactly to structure the logic?

If you want to watch more about this journey from service objects to DDD - watch our conversation with Robert, where we talked a lot about this evolution.

<div style="position:relative;height:0;padding-bottom:75.0%"><iframe src="https://www.youtube.com/embed/ynj_C-Abjgk?ecver=2" width="480" height="360" frameborder="0" style="position:absolute;width:100%;height:100%;left:0" allowfullscreen></iframe></div>

When I met Mirek and when Mirek has joined Arkency it was a fast progress with our understanding of DDD. You can read books, read blogposts, even try to write some simple prototypes, but having access to someone who already knows all of it is just priceless.  Our adoption of DDD, CQRS and Event Sourcing was at full speed.

In one of our biggest client projects, we have introduced the concept and the implementation of an Event Store. At the beginning it was just a simple table which stores events, wrapped with ActiveRecord. This enabled us to publish events and subscribe to them. Also this created the Event Log capabilities.

This was the time, when we thought we could help other people with existing Rails apps to introduce domain events, which we believed (and still believe) to be a great first step to better structure in Rails apps. We've started publishing more blogposts, but we also started 2 open-source projects:


- [HttpEventStore](https://github.com/arkency/http_event_store) (a Ruby binding/connector to the Greg's Event Store) - aka HES
- [RailsEventStore](https://github.com/arkency/rails_event_store) - aka RES


## HttpEventStore (aka HES)

With HttpEventStore our vision was to make it easy to use the so-called Greg's Event Store (or GetEventStore, or GES) from within a Ruby or Rails app.

We have released some code and it gained traction. Some people started using it in their production apps, which was great. We also got a lot of help/contributions from people like [Justin Litchfield](https://github.com/litch) or [Morgan Hallgren](https://github.com/hallgren) who became an active contributor.

## RailsEventStore (aka RES)

With RailsEventStore the main goal at the beginning was to be as Rails-friendly as possible. The goal was to let people plug RES in very quickly and start publishing events. This goal was achieved.
Another goal was to keep the API the same as with HttpEventStore, with the idea being that once people need a better solution than RES they can quickly switch to HES. This goal wasn't accomplished and at some point we decided not to keep the compatibility. The main reason was that while HES was mostly ready, the RES project became bigger and we didn't want it to slow us down. Which in the hindsight seems like a good decision.

# Where we are

Fast forward, where we are today. The ecosystem of tools grew to:

- [Rails Event Store](https://github.com/arkency/rails_event_store)
- [Ruby Event Store](https://github.com/arkency/ruby_event_store)
- [Rails Event Store ActiveRecord](https://github.com/arkency/rails_event_store_active_record)
- [Aggregate Root](https://github.com/arkency/aggregate_root)
- [Command Bus](https://github.com/arkency/command_bus)

RailsEventStore is the umbrella gem to group the other gems. The CommandBus is not yet put into RES, but it will probably happen.

We have also established development practices to follow in those projects with a strong focus on TDD and test coverage. We're using mutant to ensure all the code is covered with tests.  It's described here: [Why I want to introduce mutation testing to the rails\_event\_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/) and here: [Mutation testing and continuous integration](http://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/).

Education-wise we encourage people to use DDD/CQRS/ES in their Rails apps. **It's not our goal to lock-in people with our tooling**. On one hand, tooling is a detail here. On the other hand, an existing production-ready tooling makes it much easier for developers to try it and introduce it in their apps.

Arkency people delivered many talks at conferences and meetups, where we talk about the ups and downs of DDD with Rails.

We also offer a commercial (non-free) [Rails/DDD workshops](http://blog.arkency.com/ddd-training/). A 2-day format is a great way to teach all of this at one go.

The workshop comes with an example Rails/CQRS/DDD application which does show all the concepts. The application also contains a number of example "requirements" to add by using the DDD patterns.

Also, there's a video class which I recorded (about 3 hours) which is about using Rails, TDD and some DDD concepts together.

[Hands-on Ruby, TDD, DDD - a simulation of a real project](https://vimeo.com/ondemand/arkencyruby)

As for our client projects, we now use DDD probably in all of them. At the beginning we've only used DDD in legacy projects, but now we also introduce DDD/CQRS/ES in those projects which we start from scratch (rare cases in our company). In majority of those apps we went with RailsEventStore.

**CQRS or DDD are not about microservices**, but the concepts can help each other. In some of our projects, we have microservices which represent bounded contexts. This adds some infrastructure complexity but it also does bring some value in the physical separation and the ability to split the into smaller pieces.

