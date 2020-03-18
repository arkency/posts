---
title: "Interview with Sergii Makagon about hanami-events, domain-driven design, remote work, blogging and more"
created_at: 2017-08-29 17:42:44 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'sergii', 'makagon', 'hanami', 'ddd', 'interview' ]
newsletter: arkency_form
---

You might not have heard about Sergii but he got my attention some time ago. Because, you see... In one year Sergii wrote about 40 articles on http://rubyblog.pro/ and I started to see them mentioned in various places.

Then I saw he started doing some open source work on `Hanami::Events` and that tipped the balance. For a long time I wanted to interview some Ruby developers and I decided to start with him as I met him personally before :)

Meet Sergii Makagon :)

<%= img_thumbnail("sergii-makagon-ruby-hanami-events-domain-driven-interview/sergii-look-into-you.jpg") %>

<!-- more -->

### Can you tell us what motivated you to start working on hanami-events and what is its long-term goal?

I was interested in Hanami because they follow Clean Architecture principles. That's exactly how I structured my current Rails project.
I've started my pet-project with Hanami and I like it! I decided to look for opportunities to contribute.
Luca Guidi (founder of Hanami), [suggested](https://discourse.hanamirb.org/t/hanami-2-0-ideas/306/9) that for Hanami 2.0 it would be good to have Pub/Sub functionality implemented with Wisper gem.

I like event-driven systems, and I've been using Wisper for a while, so I created an example of possible implementation. Luca suggested some improvements, but in general, he liked it. After some iterations and discussions, he created a repository and [Anton Davydov](https://twitter.com/anton_davydov) (core dev of Hanami) and I started to work on a gem called `Hanami::Events`. I enjoy working with Anton, it's a good way to learn something new.

I think the long term goal for this gem is to be included into Hanami framework and provide flexible a solution for event-driven systems. We tried to keep our focus on flexibility. For example, developers can extend the gem by any custom adapter, or use existing ones. For now, we have MemorySync, MemoryAsync and Redis adapters included into the gem. We have ideas to implement DB adapters and Anton wants to add Kafka adapter as well.
This gem is still in an early stage but I think we have created a good foundation for future features.

### What was your most challenging or frustrating moment when working on hanami-events?

> There are only two hard things in Computer Science: cache invalidation and naming things.
> _-- Phil Karlton_

I feel like we've been struggling with the second one. Naming things is hard. Especially considering the fact that we have ["Many Meanings of Event-Driven Architecture"](https://www.youtube.com/watch?v=STKCRSUsyP0). I like that talk by Martin Fowler. If somebody says "we have an event-driven system", usually we need to ask more questions to clearly understand the role of events in the system and how they're being used.

We had to refactor code couple times just to change naming conventions. Also, Anton suggested creating a definition for each keyword. It was a really good idea.


### Where do you look for inspiration on how to design a good API for a high-level library with many adapters?

We had a lot of good gems to get inspiration from (wisper, rails\_event\_store).
Speaking about API for libraries, I prefer to start with something really simple, like MVP in a startup world.
My idea was to solve one specific problem and make sure it works perfectly. When I have a simple well-tested solution I can add more features.

In case of `Hanami::Events` it was as simple as: `broadcast` (or `publish`? :) and `subscribe` methods. You can not go wrong with those two.
Then we started to add more features: more adapters, allowed to inject custom logger, etc.
In the early stage, Anton did all hard work and set that foundation for us.

By the way, it's a good idea to start using own gem when it’s on early stage. Anton tried to create Hanami app with `Hanami::Events` and found couple bugs which we already fixed.

### Do you work with hanami in your everyday job?

I use Rails in my everyday project. With proper architecture - a framework is not a vital part of a project. We could switch to Hanami if we needed to.
I want to try Hanami in a couple more pet projects to see pros and cons of it and then I will consider using it in production.
From what I've seen so far it looks like a promising production-ready framework.

### How would you describe the biggest difference between Hanami and Rails? Is there such thing as Hanami-way of writing apps?

Hanami feels really similar to Rails, especially if you use it with a basic MVC approach (I know that some Ruby devs will not agree with this statement, but I describe my own experience here :). I think it makes developers feel more confident and comfortable with a framework.

I should mention that some ideas looked unusual at the beginning, but when I became more familiar with it, I noticed a lot of benefits.
For example, in Hanami, controllers are Ruby modules that group actions. Actions are objects that respond to the `#call` method.
The View layer is split into two pieces: template and view. Where a view is a testable object that's responsible for rendering a template.
Hanami has nice documentation that should help dive into all the details.

Speaking about Hanami-way of writing apps, I think it’s defined in description of the framework and [Architecture Overview](http://hanamirb.org/guides/1.0/architecture/overview/):

> Hanami prioritizes the use of plain objects over magical, over-complicated classes with too much responsibility

> Hanami is based on two principles: Clean Architecture and Monolith First.

Clean Architecture is a hot topic. Robert C. Martin (Uncle Bob) is publishing his book "Clean Architecture" in October. I've pre-ordered one and really looking for it. I've been using this approach for a while I want to learn more from Uncle Bob.

When they say “Monolith First”, they refer to Martin Fowler's article which suggests to start with Monolith and split it to microservices only if there's a need for that. Usually, that happens when developers understand domain and complexity behind it so they can split it properly.


### Do you use some DDD techniques in your applications? If so, which ones do you find most useful and beneficial for your projects?

Sure. I read all 3 books on DDD and [visited](https://www.youtube.com/watch?v=ed7qhvR7oAE) [your workshop](http://blog.arkency.com/ddd-training/) where I learned how to actually use DDD in Rails projects. It totally changed my way of thinking about designing applications. Your last book [Domain-Driven Rails](http://blog.arkency.com/domain-driven-rails/) is a really good one too. I like the practical aspect of it.

DDD brings a lot of benefits. First, most important and underestimated is ubiquitous language. I've seen many times where developers and project managers have misunderstandings because of different vocabulary for the same object. Also, I've seen developers use different names for the same things in code, which is even worse.

I use the idea of Entities, Value objects and Repositories. Having those little PORO’s in your core domain is really beneficial.
The idea of layered architecture works out pretty well too. It allows to decouple elements of a system. Also, I like to use events as a way to communicate between some parts of the application.

I must admit that I don't use everything that DDD offers, I try to pick just what I need.
I have an architecture which is more similar to Clean Architecture, but as I dive into different architectures, I see more similarities.

In apps that I create these days I usually have three layers:

* core domain with: entities, value objects, and repositories.
* application level: with use cases (somehow similar to services in DDD) and data sources
* infrastructure level: where frameworks, databases, and anything low-level lives.

As you mentioned in your book, it's just layers of the same cake :)
But then we should keep in mind that layered cake should be sliced to pieces as well. That's where bounded contexts come into play. I try not to overcomplicate apps from the beginning, that split should happen naturally. The most important thing is not to miss that moment.

### “Not to miss that moment” - I like it. And how do you not miss it exactly? What heuristics do you use to decide that a certain part of an application should be extracted into a separate bounded context? What are the clues that we as developers should not miss?

I can not miss opportunity to answer with “It depends” :)
But it really does. Sometimes, if I know upfront that it’s going to be just a small app: portfolio website, “Proof of concept” project, etc, I follow _YAGNI_ principle and try not to over engineer things.
But if it’s an app that supposed to grow to something bigger - it’s a good idea to invest time into flexible architecture.

Usually, I keep an eye on 2 sources of complexity that can lead to changes: business requirements and existing codebase.

Business requirements:

When I start working in a new domain - things might look simple in the beginning.
For example, one of my previous projects was related to child day care. Sounds easy, right? Just create a simple web app for day care centers.

But as we started to dig into that domain, we figured out that it's huge. Schedules and notifications for parents. Payment collection and benefits calculation. Absence calculation, etc, etc.

Every time we received a request from the business, we revisited our existing implementation, how it fits to new requirements? Which words did they use to describe new business processes? It brings us back to the ubiquitous language. It's just great how much we can learn from domain experts. Usually, after a discussion with them, I feel like I'm super overwhelmed, but new knowledge allows developers to architect solution properly. If you see that new words and definitions appear in requirements, make sure you understand the meaning behind it. Is that a separate entity, or just an existing one but used in different context?
Long story short: I try to keep an eye on complexity and new knowledge. Listen to domain experts. Revisit what I have. Constantly.

Codebase:

Sometimes we make decisions that are not exactly accurate because of many reasons: lack of domain knowledge, lack of programming skills, lack of time, etc.
That's why I try to revise existing solutions from time to time.

We can have a relatively simple domain, but business rules can be implemented in a way that it makes it hard to follow. In that case, we want to refactor it to the smaller pieces. Knowledge of object-oriented design should help here. I found that [Sandi Metz rules](https://robots.thoughtbot.com/sandi-metz-rules-for-developers) help a lot. It sounds too simple to be true, right? But it helps. The benefit I see is that it shows areas where you probably have an opportunity to refactor code and extract nice little classes with single responsibility out of one huge God object.
Writing clean code helps to prevent future messes. It's much easier to add `if..else` statement to a method with 50+ lines of code than add it to a method with 5 lines of code. It will be too obvious that you're just trying to hotfix something, instead of providing a solid solution.

### Do you work remotely? If so, was it hard to start? What are the potential traps for remote workers or remote companies and how can they avoid them?

I like to work remotely. I worked remotely as a freelancer for different companies around 4 years. At my previous company, I worked in the office. At my current one, I work from home 2-3 days a week.

Speaking about traps. I think remote work is not for everyone.
I know that there are people who like small-talks and communication in general. It's going to be hard for them to just stay at home and talk only through the internet when needed.

From what I've seen, many developers are introverts, so remote work looks good to them because all communication is happening online. But at the same time, they're losing their soft skills. In general, soft skills are really important in any field, not just in development.

Also, sometimes working remotely I felt like I was disconnected from all exciting things that were happening in the company, community, etc. Basically, it was my responsibility to set new challenges and goals for myself, but it creates sort of comfort zone which is hard to break. In this case, it's a really good idea to find meetups, go to conferences, try new technologies, find a new source of inspiration. It applies not just to remote developers, but when I worked remotely I felt that more often.

To work from home efficiently, a developer should be self-disciplined and should be able to stay focused. At home, we usually have a lot of distractions that might pull us from code to something else. Without self-discipline, it can be a problem.
I like to use Pomodoro technique with 50 minutes of work without any distractions and 10 minutes of break. 4-5 sessions a day allow to accomplishing A LOT, often much more than 8-9 hours in the office with distractions.
Proper sleep and physical activities are important too.

I found for myself that I like to be in office 1-2 days a week. It allows me to stay connected to the team and have enough communication.


### I’ve been impressed recently by how regularly you publish on http://rubyblog.pro/ ? What motivates you to keep sharing your knowledge and how do you find time to write?

Thanks! In software development, we have to learn constantly. Because everything's changing: languages, frameworks, tools. I like to learn and I like to share what I learned, that’s my motivation. I’m happy to see that people find my blog useful. They leave really nice comments and provide awesome feedback too. I learned a lot from discussions around those blog posts.

Since I started my blog I used it many times to explain something to other developers or to refresh my knowledge of the topic. I'm a Ruby developer, but I try to cover topics that are not framework-related or tool-related.

I switched my focus more to the approach and techniques that I can use in any object-oriented language. For example, Object-Oriented Design, Domain-Driven Design, Clean Architecture - those do not require us to use Ruby. It's more about the structure, domain, an approach in general. I like it because those things are not 'new hotness' (that will fade out next week) in the world of frameworks and languages. It's more about tackling complexity. We're dealing with complexity in any project and it's our responsibility to know how to do that properly.

Speaking about time, I prefer to write on Sundays. It's good to have it scheduled so it becomes like a good routine. I enjoy having that time. Sunday works because during a week I can come up with the idea for the future post and gather all information. The more I write, the less time it takes.

### What do you think is the best way to teach junior Ruby developers? Which strategies or approaches work in your opinion and which not?

I like the practical approach. It's great to start with a simple pet-project and add more and more advanced features. It will walk developer from planning phase and development to deployment stage. Pet-project should be in a domain that is interesting to a developer. It will help to keep him engaged to the project.

Junior developers are usually focused on tools. Let's say they want to know Rails, React, because that will give them a job, that will help them to get something done. It makes sense to teach them that tool. It helps developers to feel more comfortable and safe in terms of the job.

Once they have a good understanding of a framework it's good to dig into language and get a better understanding that a framework is just a tool. Of course, we have different tools for different tasks, so it's good to know pros and cons of those tools. That will allow them to pick proper tool for a task. Usually, at that moment "Junior Rails developer" become a Ruby developer :)

Very often junior developers need guidance with soft skills as well. It's good to be able to communicate with team mates on a good level, not to have a problem with stand-ups and other meetings, to be able to show own strengths during an interview, etc.

When a developer knows framework and language, it's good to help him to write not just code that works, but code that can be considered as clean code. At that moment I would show the ideas of Object-Oriented Design, Patterns and some general ideas of possible architectural decisions. It will help a developer to pass code review stage with fewer iterations. At that moment developer can be considered as a middle-level developer, I think. But all companies are different so it's a good idea to have something like this: https://github.com/basecamp/handbook/blob/master/titles-for-programmers.md

### What do you think about Ukrainian Ruby community? I’ve been a guest at Pivorak meetup in Lviv and for me, that was a splendid experience. Top-notch organization and plenty of friendly attendees to discuss with. I am not sure about other cities though. Can you shed some light?

Yes, [Pivorak](https://www.facebook.com/pivorak/) is amazing. They created the unique environment for developers. It motivates, it makes you feel like you're part of something big. They bring amazing speakers.
I met Piotr Solnica, creator of dry-rb there. Nick Sutterer (creator of Trailblazer) did a workshop on Trailblazer for us. I met Michal Papis - core developer of rvm. I learned a lot from my Ukrainian colleagues as well. It's definitely worth visiting.

There is also RubyC conference - it's a big annual Ruby-conference in Ukraine. It's a really good one too. A lot of new ideas and interesting speakers there.

I know that in Kyiv there is a Ruby Meditation meetup which is quite popular too. I haven’t had a chance to visit it yet, but I would love to.

I feel like we have a strong Ruby community in Ukraine. I will be happy if more local meetups like Pivorak appear in Ukrainian cities in the nearest future.

### What’s your strategy for releasing new features? For example, do you often use feature toggles? Do you monitor some key metric changes after a deploy?

I prefer to release fewer features but more often. Of course "more often" depends on the structure of a company and the process of software delivery it has.
In general, I try to rely on tests and additional checks, for example, linters and code quality tools. If everything's green I can pass it to QA for regression and manual testing.

I like the idea of feature toggle but it should be used really carefully. It looks good on paper, but when you have a complex system and too many toggles, the code can be really messy and contain a lot of duplication. It makes much harder to debug issues and follow the flow of the application. It's a powerful tool that should be used wisely and only if it's needed.

The last part of the question regarding monitoring is really broad and interesting. On previous projects, I had experience of using tools like NewRelic and Nagios and it was good. Sometimes even simple Heroku dashboard was enough to get an understanding that everything's fine. Depending on the project, the key metric can be different. Size of the project is an important factor as well.

We have a lot of things to monitor and measure these days. It's good to have systems that provide visibility and help to understand what's going on in our system.
