---
title: "The vision behind Rails, DDD and the RailsEventStore ecosystem"
created_at: 2017-05-07 15:35:54 +0200
publish: true
author: Andrzej Krzywda
tags: ['ddd']
---

Arkency became known for our DDD efforts in the Rails community. DDD together with CQRS and Event Sourcing helped us dealing with large Rails apps. At some point we also started open-source tooling to support introducing DDD in Rails apps. This blogpost aims to highlight where we started, where we are and what is the vision for the future, for the RailsEventStore ecosystem.

<!-- more -->

# Where we started

The journey with DDD at Arkency started probably around ~6 years ago, when we started using technical patterns like service objects (in DDD we would call them application services), adapters and repositories. This phase resulted in writing the ["Fearless Refactoring: Rails Controllers"](http://rails-refactoring.com) ebook which is all about those patterns.

Those patterns helped, but didn't solve all of our problems. We could say, that service objects were like a gateway drug - they enabled us to isolate our logic from the Rails app.

The patterns from the book are helping with one big mission - how to separate the Rails part from your actual application. Then we also help to structure your application with the app/infra layer and the domain layer. This is the real value of that phase. The next phase, the DDD phase is then more about how to structure the domain.

If you want to watch more about this journey from service objects to DDD - watch our conversation with Robert, where we talked a lot about this evolution.

<div style="position:relative;height:0;padding-bottom:75.0%"><iframe src="https://www.youtube.com/embed/ynj_C-Abjgk?ecver=2" width="480" height="360" frameborder="0" style="position:absolute;width:100%;height:100%;left:0" allowfullscreen></iframe></div>

When I met [Mirek](https://twitter.com/mpraglowski) and when Mirek has joined Arkency it was a fast progress with our understanding of DDD. You can read books, read blogposts, even try to write some simple prototypes, but having access to someone who already knows all of it is just priceless.  Our adoption of DDD, CQRS and Event Sourcing was at full speed.

In one of our biggest client projects, we have introduced the concept and the implementation of an Event Store. At the beginning it was just a simple table which stores events, wrapped with ActiveRecord. This enabled us to publish events and subscribe to them. Also this created the Event Log capabilities.

This was the time, when we thought we could help other people with existing Rails apps to introduce domain events, which we believed (and still believe) to be a great first step to better structure in Rails apps. We've started publishing more blogposts, but we also started 2 open-source projects:


- [HttpEventStore](https://github.com/arkency/http_event_store) (a Ruby binding/connector to the Greg's Event Store) - aka HES
- [RailsEventStore](https://github.com/RailsEventStore/rails_event_store) - aka RES


## HttpEventStore (aka HES)

With HttpEventStore our vision was to make it easy to use the so-called Greg's Event Store (or GetEventStore, or GES) from within a Ruby or Rails app.

We have released some code and it gained traction. Some people started using it in their production apps, which was great. We also got a lot of help/contributions from people like [Justin Litchfield](https://github.com/litch) or [Morgan Hallgren](https://github.com/hallgren) who became an active contributor.

## RailsEventStore (aka RES)

With RailsEventStore the main goal at the beginning was to be as Rails-friendly as possible. The goal was to let people plug RES in very quickly and start publishing events. This goal was achieved.
Another goal was to keep the API the same as with HttpEventStore, with the idea being that once people need a better solution than RES they can quickly switch to HES. This goal wasn't accomplished and at some point we decided not to keep the compatibility. The main reason was that while HES was mostly ready, the RES project became bigger and we didn't want it to slow us down. Which in the hindsight seems like a good decision.

# Where we are

Fast forward, where we are today. The ecosystem of tools grew to:

- [Rails Event Store](https://github.com/RailsEventStore/rails_event_store)
- [Ruby Event Store](https://github.com/RailsEventStore/rails_event_store/tree/master/ruby_event_store)
- [Rails Event Store ActiveRecord](https://github.com/RailsEventStore/rails_event_store/tree/master/rails_event_store_active_record)
- [Aggregate Root](https://github.com/RailsEventStore/rails_event_store/tree/master/aggregate_root)
- [Command Bus](https://github.com/arkency/command_bus)

RailsEventStore is the umbrella gem to group the other gems. The CommandBus is not yet put into RES, but it will probably happen.

We have also established development practices to follow in those projects with a strong focus on TDD and test coverage. We're using mutant to ensure all the code is covered with tests.  It's described here: [Why I want to introduce mutation testing to the rails\_event\_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/) and here: [Mutation testing and continuous integration](http://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/).

Education-wise we encourage people to use DDD/CQRS/ES in their Rails apps. **It's not our goal to lock-in people with our tooling**. On one hand, tooling is a detail here. On the other hand, an existing production-ready tooling makes it much easier for developers to try it and introduce it in their apps.

Arkency people delivered many talks at conferences and meetups, where we talk about the ups and downs of DDD with Rails.

We also offer a commercial (non-free) [Rails/DDD workshops](http://blog.arkency.com/ddd-training/). A 2-day format is a great way to teach all of this at one go. As an integral part of the workshop we have built [a non-trivial Rails DDD/CQRS/ES applications](http://blog.arkency.com/2017/05/whats-inside-the-rails-ddd-workshop-application/) which shows how to use DDD with Rails, but also with the RailsEventStore ecosystem.

The workshop comes with an example Rails/CQRS/DDD application which does show all the concepts. The application also contains a number of example "requirements" to add by using the DDD patterns.

Also, there's a video class which I recorded (about 3 hours) which is about using Rails, TDD and some DDD concepts together.

[Hands-on Ruby, TDD, DDD - a simulation of a real project](https://vimeo.com/ondemand/arkencyruby)

As for our client projects, we now use DDD probably in all of them. At the beginning we've only used DDD in legacy projects, but now we also introduce DDD/CQRS/ES in those projects which we start from scratch (rare cases in our company). In majority of those apps we went with RailsEventStore.

**CQRS or DDD are not about microservices**, but the concepts can help each other. In some of our projects, we have microservices which represent bounded contexts. This adds some infrastructure complexity but it also does bring some value in the physical separation and the ability to split the into smaller pieces.

To summarise where we are:

- we've created a tooling around the idea of introducing DDD into Rails apps. The tooling is now ready to use and a growing number of developers are using it
- we do a lot of education to inspire Rails developers to try out DDD

# Where we are going

Things are changing really fast so it's hard to predict anything precisely. However, all signs show that Arkency will keep doing DDD and Rails apps. This naturally means that we'll do even more **education** around DDD and about solving typical problems in Rails apps.

We'll also work on the **RailsEventStore ecosystem of tooling**. We want the tooling to stay stable and to be reliable.

I put education at the first place, as our offer it's not about "selling" you some tooling. We do have the free and open-source tools in our offer, but we care more about the real value of DDD - using the Domain language in the code, shape the code after discussions with Domain Experts. The tooling is irrelevant here. It helps only to provide you some basic structure but the real thing is your app. We want to focus on helping you split your application into bounded contexts. We want to help you understand how to map requirements into code. That's the big value here. If our tooling can help you, that's great.

We have already gathered a small but very passionate **community** around the DDD ideas. The important thing here - it's a community around DDD, not a community around RailsEventStore or any kind of specific tooling. We're learning together, we help each other. At the moment the community doesn't have a central place of communication, but we're thinking about improving this part.

**Even further in the future?**

One thing which I was sceptical in the past is **microservices**. Whenever we were suggesting any ideas how to improve Rails apps, microservices were rarely among the techniques. The thing is - microservices represent an infrastructural split, while what's more important is the conceptual split.

This has changed a little bit recently. I see the value in well-split microservices. After understanding the value of Bounded Contexts, aggregates, read models - I can now see much better that the the split is the same as with Bounded Contexts.

If you do more DDD, you'll notice how it emphasises good OOP - the one were attributes are not publicly exposed, where object tell, don't ask. Where messages are used to communicate. Where you can think about aggregates as objects or read models as objects. You will also notice how good OOP and good Functional Programming are close to each other and how DDD/CQRS/Event Sourcing exposes it.

**Aggregates** can be thought as functions. They are built from events and they "return" new events. A lot is being said about [functional aggregates](https://blog.scooletz.com/2017/01/05/event-sourcing-making-it-functional-1/).

**Read models** can be thought as functions - given some events, they return some state.

**Sagas** can be seen as functions, given some events, they return commands.

Rails + DDD + CQRS + ES +OOP + FP == that's a lot of buzzwords, isn't it? It's good to be able to name things to communicate between developers and understand the patterns by their name. But the buzzwords is not the point. Again, it's all about delivering business value in a consistent manner.

Let me throw another buzzword here - **serverless**. It's a confusing name for a concept that is relatively simple. It's about Functions as a Service, but also about a different way of billing for the hosting. How is that relevant to Rails and DDD? Well, if you work on a bigger Rails app, then hosting is a big part of your (or your client) budget. Whether you went with a dedicated machine or you went cloud with Heroku or Engine Yard or anything else, this all cost a lot of money, for bigger traffic and bigger data. Making your Rails app more functional by introducing Aggregates, Read models, sagas enables you to benefit from lower costs using the serverless infrastructure.

Splitting your app into smaller infrastructural pieces also enables you to experiment with other technologies which are trending in our community recently - **Elixir**, Clojure, Haskell, Go, Rust. Instead of having a big debate whether to start a new app in one of those languages (and probably risking a bit), you can now say - "let's build this read model in Elixir" - this is something much easier to accept by everyone involved!

This part a bit science-fiction so far, but as part of my preparation to the next edition of the [Rails/DDD workshops in Lviv](http://blog.arkency.com/ddd-training/), I started researching those topics more. At the workshop, we'll have a discussion about it.

I'm not sure about you, but I'm very excited about the state of the Rails and DDD ecosystem and I'm excited about the upcoming possibilities. I'm very happy to be part of the changes! Thanks for reading this blogpost and thanks for supporting us in our efforts!
