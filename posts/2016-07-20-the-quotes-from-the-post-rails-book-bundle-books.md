---
created_at: 2016-07-20 14:36:28 +0200
publish: true
tags: [ 'rails', 'book' ]
author: Andrzej Krzywda
---

# The quotes from the Post Rails Book Bundle books

Given that I now looked at all the [Post Rails Book Bundle](http://www.railsbookbundle.com) (Psst, the offer ends on Friday!) books, I've decided to pick some quotes which may shed more light into the whole message. This may help you understand the different points of views reflected by each author. 
Some of the authors are very opinionated and use a strong language, whiles others seem to quite positive towards Rails, but show their ways of extending The Rails Way.

What the books share is the view that The Rails Way may not be enough. They also share the constructive approach - they all present some alternatives.
However, the books differ in "what's next". Thanks to the bundle you can have a wide perspective on the possible alternatives.

<!-- more -->



Unfuck A Monorail For Great Justice
================

Rails apps are not supposed to be monolithic. If your Rails app is monolithic, it is fucked.



Trailblazer
=========

Explaining why a conventional Rails architecture fails is simple: There is no architecture.
The fatal delusion that three abstraction layers, called “MVC”, are sufficient for implementing complex applications is failure by design.

On an architectural level, everything in Rails is crying for separation and encapsulation. But those cries go unheard, mostly.

I believe the puristic Rails Way isn’t appropriate for projects with a complexity greater than a 5-minute blog. Full stop. I also believe that writing an application with J2E specifications sucks. I don’t want to be constantly thinking about types and interfaces and builders and how to wire them together.

The monolithic design of Rails basically led every application I’ve worked on into a cryptic code hell. Massive models, controllers with 7 levels of indentation for conditionals. Callbacks, observers and filters getting randomly triggered and changing application state where you don’t want it.


Rails as She is Spoke
=========

You have to go into what's fucked up with Rails in order to figure out the difference between where Rails cheats on OOP, but shouldn't, and where Rails cheats on OOP, but totally gets away with it. Identifying those differences are crucial if you want to figure out what it is that Rails gets right but OOP theory gets wrong. And that's the real question driving this book.

One very important example: Rails is not good at telling you what Rails is doing. We're going to see several places where Rails misinforms you, in both its code and its documentation, about its own design.

The question that matters here is "where and why does Rails break OOP and get away with it?" But to get to the answer, we need to have a clear, articulate discussion, which means we have to dispell inaccuracies about Rails which Rails itself has propagated.


Growing Rails
=============

When you started working with Rails some years ago, it all seemed so easy. You saw the blog-in- ten-minutes video. You reproduced the result. ActiveRecord felt great and everything had its place.
Fast forward two years. Your blog is now a full-blown CMS with a hundred models and controllers. Your team has grown to four developers. Every change to the application is a pain. Your code feels like a house of cards.

Let’s talk about controllers. Nobody loves their controllers.

Developers burnt by large Rails applications often blame their pain on ActiveRecord. We feel that a lof of this criticism is misplaced. ActiveRecord can be a highly effective way to implement user- facing models, meaning models that back an interaction with a human user.


Fearless Refactoring: Rails Controllers
==================

It’s rare to find a Rails app with a test suite run below 3 minutes. Even more, it’s not uncommon to have a build taking 30 minutes. You can’t be agile this way. We should focus on getting the tests run as quickly as possible. It’s easy to say, but harder to do. This book introduces techniques, that make it possible. I’ve seen a project, for which a typical build time went from 40 minutes, down to 5 minutes. Still not perfect, but it was a huge productivity improvement. It all started with improving our controllers.

What I noticed is that once you start caring about the controllers, you start caring more about the whole codebase. The most popular way of having better controllers is through introducing the layer of service objects.
Service objects are like a gateway drug. In bigger teams, it’s not always easy to agree on refactoring needs. It’s best to start with small steps. Service objects are the perfect small step. After that you’ll see further improvements.

Frontend Friendly Rails
==================

Ruby on Rails is an awesome tool for crafting web applications from scratch. Built-in solutions allow you to quickly prototype your application. Asset pipeline is a great help with enhancing the user interface of your app with JavaScript sprinkles.
But Rails conventions are not that helpful when it comes to creating complex applications living in the user’s browser. Such applications require a bit different defaults than classical request-response solutions.
In this book I’d like to show you how you can prepare Ruby on Rails to be an awesome foundation for the backend solution of your frontend application.


Modular Rails
=============

My story with modularity started over two years ago when I was charged with the rewriting of an existing web application into something more configurable and modular. I’ve been working on a few modular applications since then while still creating regular apps when modularity was overkill.
I wrote this book because I couldn’t find any documentation when I created my first modular application. I was studying open source apps and even though reading code is awesome to learn something, you don’t always understand what’s going on. This is the book I wish I had at that time.

