---
title: "Interview with Scott Bellware (Eventide co-creator) about micro-services in Ruby, event sourcing, autonomous services, SOA, dumb pipes, EventStore and mis-representation of terms in IT"
created_at: 2017-11-15 17:20:56 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'SOA', 'microservices', 'ruby', 'eventide', 'scott', 'bellware', 'interview' ]
newsletter: :arkency_form
img: soa-microservices-ruby-eventide/scott-bellware-interview-ruby.png
---

Are you confused about micro-services? Don't worry, you are not the only one. In this interview with Scott Bellware (the co-creator of Eventide), I am trying to shed some light on this complex topic.

<!-- more -->

### Can you tell our readers in a few sentences what is Eventide and what good use-cases do you imagine for it?

Eventide is a toolkit for building microservices. Specifically, it’s a toolkit for building pub-sub services and event sourcing.

### What was your primary motivation for writing Eventide?

I had some background in SOA and had been working in Ruby for a number of years. I wanted to continue working with Ruby, but I wanted to remove the limitations on design that the predominant Ruby web development frameworks imposed. I would say that I had “Rails Fatigue”. I was tired of the framework getting in the way of letting me respect some of the most basic and fundamental design principles.

### There is a ton of advice on the Internet around micro-services? Many times it’s conflicting: Use message bus, don’t use message bus, use stream processing etc, no just use HTTP. What’s your advice?

“Microservices” as an architectural style came into existence because of how misinterpreted, misrepresented, and mistakenly-applied “Service-Oriented Architecture” had become. Now it’s the knowledge of microservices that has been muddied and rendered unusable.

The two defining qualities of Microservices are “autonomy”, and “dumb pipes”.

The implications of autonomy are that a service cannot be queried. A service that has a “get” API isn’t autonomous. Arguably, it’s not a service at all because it’s not autonomous.

If services have autonomy, then any one of them can become unavailable and no other services become unavailable as a result, like when doing a deployment, or during some other kind of outage. This is impossible when service query each other’s data via “get” APIs. If a service that is queried is unavailable, then the services that are doing the queries will experience errors and also become unavailable.

It means that every service in the architecture is a single point of failure that can create cascades of failures through the entire architecture. That’s the “Distributed Monolith”. It’s not worth spending time, money, and attention on. You likely already have a monolith. Adding distributed systems failure modes to it makes it worse, not better.

The implication of “dumb pipes” means that microservices are of an era when we’ve moved beyond brokers and have accepted the realities of distributed systems, and the physical impossibility of a messaging technology to guarantee “exactly-once delivery”.

In the microservices world, the job of ensuring that a message is not “processed” more than once is the job of application logic. Trying to achieve this with delivery guarantees of transports is a dead end.

It’s the developer’s responsibility to understand the laws of distributed systems - especially the fallacies of distributed systems - and make allowances for them in the service code.

The failure to come to these understandings has led to a profusion of bad advice that amounts to little more than beginner service developers talking only to each other rather than digging into the readily available body of knowledge and experience surrounding service development. When the inexperienced lead the uninformed into service architecture, the result is usually predictably undesirable.

### How do you think Service-Oriented Architecture and Microservices has been mis-represented and muddied?

Just as was done to SOA, Microservices has been egregiously misrepresented by everyone who wants to be identified with Microservices - often without doing any learning, practice, or research.

The “why” is geek vanity. The “how” is simply perpetuating and reinforcing the idea that Microservices is whatever your particular schtick is.

It’s the way that geeks always destroy knowledge before it has a chance to be grasped by the larger community: Lower the bar so that you can claim that you’ve already achieved it.

It’s about what you’ve staked your relevance on. For example, DevOps people had staked their relevance on Docker and containers. Microservices comes along and threatened to draw attention away from containers, so the DevOps geeks entangled “Microservices” with containers.

The truth of the matter is that Microservices have nothing to do with Docker. They also have nothing to do with RabbitMQ and brokers. They also have nothing to do with HTTP or REST. And they have nothing to do with getting your company to allow you to do your first experiments with Go at their expense.

Like SOA, Microservices risked distracting from the things that geeks wanted to gain popularity from - whether at home in their teams and companies, or in the wild in the community at large.

SOA and Microservices became misrepresented and muddied because of rampant professional and personal immaturity, which remains one of the defining characteristics of geek culture and one it its most harmful and limiting influences.

Like SOA, Microservices became largely meaningless as a term in the community at large because geeks wanted to be given credit for already doing it without actually doing the work that would legitimately allow for that credit to be given. Since it became associated with everything that geeks were already doing, it became indicative of nothing in particular.

The outcome is that many teams have failed and lost the trust of their organizations for having accidentally created distributed monoliths which are worse than the monolith they had previously created.

SOA and Microservices became misrepresented and muddied because geeks chose to misrepresent and muddy them. Because they thought it would be a harmless shortcut that would let them advance the perception of their relevancy in their organizations and their community.

Microservices was an attempt to reclaim the core meaning of SOA, and to formalize the progress beyond brokers and other smart pipe technology that reflects where we are in 2015 rather than where we were in 2005. But it was subjected to the same corrosive insecurity impulses of tech community that made SOA largely irrelevant.

The good news is the that “good parts” of SOA remains well-defined, and the “good parts” of Microservices build upon the SOA foundation. And if you can set aside the geek impulse to lower the bar rather than raise yourself up, SOA and Microservices can still be learned, understood, and practiced. And they can still be used effectively to achieve the qualities and characteristics of software systems and software development that SOA and Microservices promise.

The promise of SOA and Microservices is still available - as long as the impulse to take shortcuts to perceived glory is eradicated. And this is one of the reasons why Microservices is not for everyone and every team, and can be as harmful in the wrong hands as it can be productive in the right hands.

### What do you think should be a primary concern when evaluating an architecture for micro-services?

If you’re not careful, you will go through the whole cycle of breaking up a monolithic app into what you believe are services, and simply end up with a Distributed Monolith.

The primary concern for a service architecture is both autonomy and understanding for any service whether its messages must arrive at their destinations, or if losing messages is acceptable.

If you don’t have a background in distributed systems, then the first thing you need to do is learn how easy it is to get tricked into believing that a broker, rather than applicative code, can guarantee anything about message delivery. As tempting as that belief is, it’s the most dangerous indulgence that a developer or architect can make. It’s the thing that will lead to malfunctions like putting more money into a customer’s account than they’ve deposited, or taking away more money than they’ve withdrawn, or not processing any operations at all.

Microservices is a style that’s predicated on the recognition that message transports - no matter how elaborate - cannot guarantee anything but the fundamental physics of messaging: 1) Messages will be delivered more than once, and 2) Messages will not be delivered at all. And in many cases, that messages will not arrive in the order that you expected them to be in.

The only things that really need to be considered when evaluating an architecture are the foundational principles. If you don’t know what they are, then getting familiar with them and comfortable with them is the first step. And unfortunately, because there is so much more misinformation available on the web now, it’s a much more difficult proposition.

The architecture is a result of considering and employing the principles. If those principles and their application is unknown, then developers and architects are largely guessing at what a service architecture might be. It can be a better use of time to clean up the monolith and introduce the separation, and partitioning that should have been in the monolith from the start.

Service architecture is not an answer to a monolith that was left to run wild with shortcuts and undisciplined hacking. If you can’t build a monolith that you don’t end up wanting to replace, you should be very concerned about pursuing a service architecture.

So, I feel that your question might have been, “What steps were taken to misrepresent and muddy SOA and Microservices”. If it was, I obviously chose to answer another question. But I would do so with good reason: The particular steps aren’t as important to avoiding these kinds of pathological transgressions as exploring the predispositions and root causes that keep this kind of knowledge degradation firmly-rooted in geek culture.

It’s not just Microservices and SOA that got treated to this kind of toxic degradation, but almost every facet of the software world has been sacrificed to it. Even Waterfall is reviled for reasons that are largely synthetic straw men, and even the Agile that developers regularly credit themselves with is a degraded misrepresentation. The same can be said for TDD, ORM, MVC, OO, FP, and a host of incredibly-important technologies that we credit ourselves with expertise for but don’t really have a grasp of much more than the misrepresentations.

### _"understanding for any service whether its messages must arrive at their destinations, or if losing messages is acceptable"_ - so in other words deciding between _at least once delivery_ and _at most once delivery_. I personally never see much value from _at most once_. Maybe that's because my apps constantly deal with big amounts of money. What's your experience? Do you often have use-cases where messages can be lost?

It’s important to take a pause here and note that there has never be a messaging technology that has been proven to be capable of either at-least-one delivery or at-most-once delivery. These are largely misconceptions in and of themselves.

There’s a whole new wave of people new to messaging who missed out on being present when this was the principal topic of discussion in the distributed systems and messaging world, and therefore have a mistaken grasp of what those terms mean.

You can’t guarantee delivery no matter what you do. There are always conditions and cases that ensure that you’ll always have to do extra work to ensure delivery guarantees, whether at-least-once or at-most-once.

It’s not really about “delivery”. It’s about “processing”. Those terms are understood to mean “at-least-once processing” and “at-most-once processing”.

With so many people recently moving to messaging during the Microservices hype wave, that understanding is not evenly-distributed throughout the developer population.

As for use cases for messages that don’t need to arrive, I don’t have those use cases, but like you, it’s because of the domains I work in.

However, if I were working in a domain like systems monitoring, for example, I might be tolerant of an infrastructure telemetry signal never arriving - especially if the missing signal is only one of many that establish a trend.

If 100 health check messages are processed but one goes missing, the application of those remaining messages to the question “Is the system’s health trend generally positive over some window of time?” may be completely unaffected by a missing message.

However, if an electronic funds transfer message simply disappeared after it left the sender’s account and before it got to my account, that would be a different story.

If the “Abort the surgical laser” message got lost, the consequences could be deadly. If the “Close the flood gates” message got lost, the consequences could be disastrous.

But it’s important to note that that the assurances that brokers make about guaranteed delivery aren’t really guarantees. Combinations of network conditions and timing can still result in messages being duplicated, coming out of order, or not arriving at all.

In mission-critical distributed systems, message delivery guarantees are largely the responsibility of the application developer, not the messaging technology and tooling. If a message absolutely, positively has to get there, then there’s no out-of-the-box messaging tech that can deliver on that requirement.

And this quality is probably the most significant and defining characteristic of the difference between how things were done in the SOA era and how things are done in the Microservices era.

### Eventide can be used with 2 underlying databases for storing events: Postgresql or EventStore. Which one would you recommend in which situation?

EventStore is a quorum cluster database, like Cassandra.

If you need the kinds of things that a quorum cluster provides, then you’ll already be well aware of that fact. If you are already getting by on something like Postgres or MySQL, and are not looking at something like Cassandra, then there’s a good chance that you can continue satisfying your needs with Postgres.

EventStore has some really amazing features - especially around querying and data analysis. But that comes with some real tradeoffs. A quorum cluster has higher demands on operations staff and operations activities. It is a distributed system in and of itself. If you’re not already facing problems that are best solved by a distributed database, then there’s a good chance it’s not a solution for a problem that you have.

That said, a tremendous amount of learning can be had by building something on EventStore that you don’t need to put into production. We would not have had the perspective we needed for building the Eventide Postgres implementation without having spent a couple of years exclusively with EventStore.

If you’re just getting started, and if a database like Postgres is already sufficient for your needs, then you might as well continue with Postgres.

But it’s important to recognize that an event store is a different beast than the kind of entity storage that we typically do with ORM and relational databases. The event storage table will likely have orders of magnitude more records in it that the typical entity storage table. So, there can be new operations concerns related to capacity planning. But these are things that database operators are very well attuned and accustomed to already. Postgres is a known-known for most operators.

### _"a tremendous amount of learning can be had by building something on EventStore that you don’t need to put into production"_ - I agree. Just playing with projections can really open your mind, don't you think?

Yes, absolutely. The projections feature that the EventStore team has been working to bring to fruition has a lot of promise for the kind of analytics that is typically done today with more elaborate tooling. That said, it’s still a relatively young feature that has had a bumpy road to delivery.

### You said that _"EventStore is a quorum cluster database, like Cassandra"_. Would it make sense to use EventStore with one instance and no cluster? Or, in such case it's easier to just go with Postgres?

I would say that operating EventStore with a single instance would only be a good option in cases where you wouldn’t mind writing your data to `/dev/null`.

To wit, EventStore is big iron, like Cassandra. You wouldn’t just choose to use it if you didn’t have workloads and operational constraints that exceed what you can do with Postgres, or something similar.

It’s impossible to assert for all cases that it would be easier to run Postgres rather than EventStore. For a case where Postgres is already sufficient, then it stands to reason that Postgres is sufficient for message storage and as an event store.

### How do you make micro-services as autonomous as possible?

Enforce service encapsulation and autonomy by disallowing services to respond to queries, or to even have “get” interfaces. And use pub-sub of events to account for the “no queries” design constraint.

Service implementations go bad within the first few minutes of a service project. Most Web developers leap to the unconscious conclusion that services will be organized around the “models” that they already have in their web apps.

Services are not organized around data, the way that ORM-based apps are. Services are organized around behavior and processes. If the design implications of this are not understood, even the enforcement of the “no queries” constraint won’t keep the project from undesirable outcomes.

You can end up with a distributed monolith, and you’ll end up using pub-sub to affect CRUD operations rather than business process operations. And that is simply the same kind of tight coupling that made your monolith unsurvivable to begin with. Except now you’ll also have all the complications of distributed systems to deal with.

To make services as autonomous as possible, you have to ween yourself off of the fixation on data and “models” that dominate your attention when doing ORM+MVC, and train yourself to focus on business processes and behavior.

ORM is about tacking on some behavior to data objects. Services are about supporting behavior with its necessary data, moving that data to the vicinity of the behavior that is authoritative over it, and ensuring that only one service is authoritative over any piece of data. A service is “authoritative” over data when it’s the only thing that can change or create that data.

### _"and the physical impossibility of a messaging technology to guarantee “exactly-once delivery”. In the microservices world, the job of ensuring that a message is not delivered more than once is the job of application logic."_ - I couldn't agree more with this. I had to co-operate with a number of APIs (which I considered another service that my app interacts with) and almost none of the had the guarantees that I expected. I asked the developers i.e. about idempotency and they didn't even know what that means. Do you have similar experiences? There are so many APIs for developers out there now, but it's damn hard to use them in a safe way.

APIs are not services. They’re just interfaces. If what is behind the interface is built by good-intentioned developers whose experience is limited to monolithic web apps (which is true for the vast majority of implementations in the wild), then idempotence won’t be a consideration of the design, implementation, or testing.

Web app development rarely imbues developers with even an awareness of idempotence issues, let alone the countermeasures and the design and implementation approaches that deal effectively with it.

Ironically, web developers are dealing with it all the time. The result is often that there are intermittent problems whose source is not understood, resulting in ad-hoc data repair jobs.

We can see naive approaches to idempotence all over the web. They take the form of modal dialogs that seek to constrain the user from clicking the “submit” button more than once. Or worse, some warning text near the submit button that says something like, “Don’t click this button twice or you will be charged twice,” or “Don’t press the browser’s back button after clicking submit.”

In the end, it doesn’t matter if the HTTP interface communicates via HTML with users or via JSON with user agents. If it’s not implemented in such a way that duplicate submissions can be rejected, it’s going to invite ambiguities that are going to invite mistakes, either by an interactive user or a programmatic user agent.

### Do you think that Event Sourcing is a mandatory part of autonomous services or just a technique which makes the goal much easier to achieve?

If you have pub-sub of events, then you have events. If you’re doing Microservices, then you’ve moved on from brokers.

If you follow this to its logical conclusion, then you’ll arrive at event sourcing. You don’t need to be retrieving, modifying, and re-saving database rows based on the handling of events.

That whole aspect of developing, operating, and maintaining the transactional side of systems is simply eliminated. That’s a tremendous simplification of the part of the system that makes decisions and does things.

But that simplification comes with some tradeoffs. Simplicity is harder to accomplish than complexity. You know this because of how complexity can be achieved entirely by accident.

There are requirements for building read-only data views that are used for displaying data when you’re doing event sourcing. And that can seem daunting at the outset. But once you learn it, it’s no longer as intimidating as something that is utterly unfamiliar.

### _"building read-only data views that are used for displaying data when you’re doing event sourcing"_ - Where would you implement building those read-only data? And how would you expose it to the end user? Would that be a separate service (or many of them, one per data-view) which could have those "get" APIs?

I wouldn’t call those things that return data “services”. We already have a name for them. They’re called “databases”. Putting an HTTP interface in front of a database doesn’t make it a service, it just makes it a database with an HTTP interface in front of it.

In fact, enterprisey databases like SQLServer and Oracle have HTTP interfaces built-in. And popular open source databases have extensions that can add HTTP interfaces.

So, it’s largely an uninteresting topic. You put your data where you put your data. It can’t be answered in a generalized way. There are too many specifics. But those specifics are already the specifics you’re already dealing with today by running a database.

As long as you call a database a “database” and not a “service” this is already an easy question to answer.

Services process commands. When they need to make decisions based on data, that data is retrieved as events. I can tell you that your bank account does not have sufficient funds for a $20 check if there has only have been two previous deposit transactions for $1 each.

So, event data is used when processing commands (eg: Cash a check for $20 for account #123). The reason we like this is that event data provides certain guarantees about the consistency of the data that are harder to achieve with things like ORM. And if you’re comfortable with the paradigm, developing systems like this can be a good deal easier than doing it with ORM.

But if you want to display data to a UI, then use a database, like you already do.

Because those two $1 deposit events have been created at some point in the past, a handler can be written and deployed that “sees” those events and updates the account details for that account, allowing an account statement to be printed to the screen (or PDF, or paper, or whatever).

That handler is part of the architecture often referred to as “data aggregation”. In an event-sourced world, it means that pre-computed “materialized views” of data used for display is kept up-to-date based on the events that are flowing through the system.

So, you have one process for processing the commands, and another process for keeping read only views data up-to-date based on the events that are the result of processing the commands.

The data used to decide whether to process a command and the data used for display are kept separate.

You can separate the process used to keep the view data up-to-date from the command-processing processes, or you can host them together. The factors that influence which option you chose are concerns more of server operations (load, latency, throughput, etc) than they are of application architecture.

These data aggregators aren’t “services” themselves, but they can be built with the exact same tooling that’s used to build services.

A service processes commands and uses previous event data to calculate the current state needed to make a decision as to how to process a command. A database serves the read only view data. A data aggregator takes the results of the services and updates the read-only data. A client application gets its display data from the database. It sends commands to services to do whatever the user is trying to do (eg: Cash this $20 check for account #123).
