---
title: "On microservices"
created_at: 2014-07-04 22:27:25 +0200
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
---

Microservices - everyone talks about them nowadays. Not everyone understands them however the same way. I've been researching this topic for a while, gathering and evaluating articles, presentations and conference videos. Today I'm presenting you this research with my comments. I've already distilled what characteristic does "ideal" microservice have. What does it have for you?

<!-- more -->

# Articles

* [http://martinfowler.com/articles/microservices.html]()

	Good broad introduction to the topic and further references, mentions *"you build it, you run it"* from Werner Vogels. Make sure to check related comments: [https://news.ycombinator.com/item?id=7382390
]()

* [http://yobriefca.se/blog/2013/04/28/micro-service-architecture/
]()
	
	Another broad description, how to go from legacy to microservices, also mentions importance of ops skills in this architecture.


* [http://abdullin.com/journal/2014/1/20/how-micro-services-approach-worked-out-in-production.html
]()
	
	Case study with some practical advice, mentions performance.

* [https://github.com/tobyclemson/testing-micro-service-architecture-presentation/raw/master/presentation/testing-strategies-in-a-micro-service-architecture.pdf
]()
	
	Shows anatomy of microservice, relation to DDD, various testing aproaches explained.

* [http://bovon.org/index.php/archives/350
]()

	> "Each business capability [microservice], should be no bigger than my head when you chunk up to this level. And these capabilities should be business-meaningful."

* [http://www.udidahan.com/2014/03/31/on-that-microservices-thing/
]()
	
	Remarks on microservices coupling on the example of product price.

* [http://arnon.me/2014/03/services-microservices-nanoservices/
]()

	Microservices is essentialy SOA without vendor bullshit.

* [http://service-architecture.blogspot.co.uk/2014/03/microservices-is-soa-for-those-who-know.html
]()
	
	Apparently microservices is just SOA described with langauge that can be understood by ordinary people. I've also learned that "microservice" is insulting for SOA service (too small).

* [http://blog.wordnik.com/with-software-small-is-the-new-big
]()

	The concept of microservice owner - more like product owner - that answers pager alarms, more less *You build it, you own it*.

* [http://www.paperplanes.de/2013/10/18/the-smallest-distributed-system.html
]()
	
	Not sure if microservices but still relevant on importance of monitoring in distributed system.

* [http://highscalability.com/blog/2014/4/8/microservices-not-a-free-lunch.html
]() and [http://contino.co.uk/blog/2013/03/31/microservices-no-free-lunch.html]()

	Good list of potential problems and fantastic response in comments:

	> Being one of the tech leads on transforming a monolithic Java application to a SOA implementation, I've come across everyone of the issues you raise but instead of seeing those as problems I see them as opportunities to build software better.

* [http://peopleandcode.blogspot.in/2014/03/microservices-and-agility.html
]()
	
	Mentions most common reasons to partition the system and organization, also confirms that bounded context makes great microservice.

* [http://davidmorgantini.blogspot.com/2013/08/micro-services-introduction.html](),
[http://davidmorgantini.blogspot.co.uk/2013/08/micro-services-what-are-micro-services.html](),
[http://davidmorgantini.blogspot.com/2013/08/micro-services-when-should-you-use.html](), 
[http://davidmorgantini.blogspot.com/2013/08/micro-services-why-shouldnt-you-use.html]() and 
[http://davidmorgantini.blogspot.com/2014/03/microservices-effective-testing.html]()

	Not bad but mostly obvious when you've read Fowler, more why than how.

* [http://klangism.tumblr.com/post/80087171446/microservices
]()

	Good definition and expectations for microservice.

* [http://dejanglozic.com/2014/04/07/micro-services-fad-fud-fo-fum/
]()

	Funny story comparing microservices to agile. TL;DR let's kill microservices movement hoping that it will continue to practised but it does not become enterprise agile after X years.

* [http://plainoldobjects.com/2014/03/25/thoughts-about-microservices-less-micro-more-service/
]()

	Services should be made as small as possible, but no smaller.

* [http://www.slideshare.net/jeppec/soa-and-event-driven-architecture-soa-20
]()

	Truly a masterpiece. A lot about copuling of SOA and what architectures failed in past. Events, asynchronicity, autonomy. Composite UI (also in form of public API).
	Related and recommended video [http://www.tigerteam.dk/talks/IDDD-What-SOA-do-you-have-talk/
]()

	Most importantly this presentation shows difference between layered architecture in SOA form and proper SOA (microservices).
	
	Also related:
	*  [http://www.tigerteam.dk/2014/micro-services-its-not-only-the-size-that-matters-its-also-how-you-use-them-part-1/]()
	* [http://www.tigerteam.dk/2014/micro-services-its-not-only-the-size-that-matters-its-also-how-you-use-them-part-2/]() 
 	
		Contains answer to important question *How do we split our data / services and identify them?*

   * [http://www.tigerteam.dk/2014/microservices-its-not-only-the-size-that-matters-its-also-how-you-use-them-part-3/]() 

		On services communication.

	* [http://www.tigerteam.dk/2014/microservices-its-not-only-the-size-that-matters-its-also-how-you-use-them-part-4/
]()

		Technique to decouple from monolith. Data duplication for events. Boundaries. Saga (workflow). Remarks on eventual consistency. Good exemplary system to be implemented using microservives.

	* [http://www.tigerteam.dk/2014/soa-synchronous-communication-data-ownership-and-coupling/]() 

		On SOA design principles, interesting.

* [http://gawainhammond.blogspot.co.uk/2014/03/microservices-and-soa.html
]()

	Microservices as a way to experiment and innovate, pre/lean-SOA,  guerrilla marketing tactic, micro meaning also micro effort to be up and running.

* [http://rrees.me/2014/03/24/the-state-of-microservices/
]()
	
	Mostly general opinions on microservices

* [http://byterot.blogspot.com/2014/04/reactive-cloud-actors-no-nonsense-microservice-beehive-restful-evolvable-web-events-orleans-framework.html
]()

	Focused on actors but not far away from microservices, remarks on reactive vs. imperative. Also on coupling and presents good example of it. Contains Reactive Cloud Actors proposal. I think it violates many microservices principles however presents good arguments on events (less coupling) and provides good code samples to reason about.

* [http://www.slideshare.net/michaelneale/microservices-and-functional-programming
]()

	If you remove FP nothing really about microservices left. So-so coupling definition (RMI).

* [http://qconlondon.com/dl/qcon-london-2014/slides/AdrianCockcroft_MigratingToMicroservices.pdf
]()

	Immutable code with instant rollback. De-normalized single function NoSQL data stores. Inverse Conway’s Law – teams own service groups. One “verb” per single function micro-service. Size doesn’t matter. One developer independently produces a micro-service. Each micro-service is it’s own build, avoids trunk conflicts. Stateless business logic, stateful cached data access layer. Reactive model RxJava using Observable to hide threading. Even if you start with a protocol, a client side driver is the end-state. Best strategy is to own your own client libraries from the start. Leave multiple old microservice versions running. Fast introduction vs. slow retirement asymmetry. Zookeeper or eureka for service discovery. RPC/Rest as API patterns. Microservice lifecycle - mature slow changing, new fast changing, number increase over time, services increase in size then split and
add a new microservice, no impact, route test traffic to it version aware routing, eventual retirement.

* [http://qconlondon.com/dl/qcon-london-2014/slides/BrianDegenhardt_RealTimeSystemsAtTwitter.pdf
]()

	Bashing on monorail, how they split it [no details on process]
details on tools used in twitter: twitter-server, finagle, zipkin.

* [http://www.slideshare.net/mobile/pcalcado/from-a-monolithic-ruby-on-rails-app-to-the-jvm]()

	Microservices as a way to reduce the risk of trying thins
choose jvm [jruby, scala, clojure]. Composite UI (api) and services with own storage. Apparently they have custom tool to bring services up/down.

* [http://blog.josephwilk.net/clojure/building-clojure-services-at-scale.html
]()

	They use netflix/twitter tools on jvm, also rxjava. Use circut breakers. Apparently REST/RPC. Very clojure and tools-used specific.

* [http://tx.pignata.com/2013/07/goruco-service-oriented-design.html
]()

	Briefly on events, Kafka. Prevent cascading failure with circuit breaker, plan for failure. Background worker is usually the most obvious service to extract.

* [http://pjagielski.pl/2014/02/24/microservices-jvm-clojure/
]()

	A bit of clojure, REST and misconceptions about must-haves.

* [http://nerds.airbnb.com/smartstack-service-discovery-cloud/
]()

	They wrote theit own service discovery and friends, again REST/RPC and autogenerating Haproxy configs to speak with other services.

* [http://techblog.netflix.com/2013/01/announcing-ribbon-tying-netflix-mid.html
]()

	Communication through REST, Eureka for service discovery. This is complicated.

* [http://monkey.org/~marius/funsrv.pdf
]()

	Futrues (for asynchronous operations). Services (boundaries). Filters (authentication, timeouts, retries).

* [http://wayfinder.co/pathways/53536427f7040a11002ae407
]()

	Just a link aggregator like this blog post, mostly duplicates but patient reader may find article not mentioned here.

* [http://literateprogrammer.blogspot.co.uk/2014/03/the-microservice-declaration-of.html
]()

	Trying to describe what SOA is and on this ambiguity, mostly missing the point.

* [http://redmonk.com/sogrady/2014/03/27/micro-services
]()

	Giveaway from Amazon's story:
	1. All teams will henceforth expose their data and functionality through service interfaces.
	2. Teams must communicate with each other through these interfaces.
	3. There will be no other form of interprocess communication allowed: no direct linking, no direct reads of another team’s data store, no shared-memory model, no back-doors whatsoever. The only communication allowed is via service interface calls over the network.
	4. It doesn’t matter what technology they use. HTTP, Corba, Pubsub, custom protocols — doesn’t matter. Bezos doesn’t care.
	5. All service interfaces, without exception, must be designed from the ground up to be externalizable. That is to say, the team must plan and design to be able to expose the interface to developers in the outside world. No exceptions.

* [http://www.slideshare.net/chris.e.richardson/microservices-decomposing-applications-for-deployability-and-scalability-jax
]()
	
	Wise words sad earlier in slightly more complicated language.

* [http://www.infoq.com/articles/russ-miles-antifragility-microservices
]()
	
	Didn't provide much value having consummed previous articles.

* [http://www.infoq.com/articles/microservices-intro]()

	Didn't provide much value having consummed previous articles.

* [http://www.infoq.com/news/2014/05/microservices
]()

	Didn't provide much value having consummed previous articles.

* [http://developers.soundcloud.com/blog/building-products-at-soundcloud-part-1-dealing-with-the-monolith
]()

	Bounded context as boundary. Wow microservices communicate with monolith [however they still ask monolith for data, which is strange]. 
Presumably Event Sourcing.

* [http://blog.carbonfive.com/2014/05/29/an-incremental-migration-from-rails-monolithic-to-microservices
]()

	API contracts, IDL, RPC. Not my microservices world. Interesting only if you're into RPC and contracts. 