---
title: "Why would you even want to listen about DDD?"
created_at: 2016-12-26 08:15:56 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ddd' ]
newsletter: :arkency_form
img: "rails-ddd-listen/why-ddd-rails.png"
---

You might have heard about this thing called DDD which stands for _Domain-Driven Design_.
The name does not reveal much about itself. So maybe you wonder why should you listen
about it. What's so good in it? What problems does it try to solve?

<!-- more -->

If you look at the cover of the book (often referred to as the _Blue Book_) which brought
a lot of attention to DDD you will see the answer.

![](http://t0.gstatic.com/images?q=tbn:ANd9GcRMZdy6ljlwtPjLnytZhArgnMkeQX9SusHSVtmIur3sTlNOhp2E)

The subtitle says "Tackling Complexity in the Heart of Software". That's what DDD is all about.
Managing, fighting and struggling with complexity. Building software according to certain
principles which help us build *maintainable* code.

So... If every 3 months you start a new simple Rails application, a new prototype which may or may
not is successful then probably DDD is not for you. You don't accumulate enough complexity in 3
months probably. If you work on short projects (in terms of development and time to live)
for example, because you work for a marketing agency and that's the kind of applications you develop
then DDD is probably not for you.

When is DDD most useful in my opinion? In the long term. When you work on years-long projects
which are supposed to have even more years-long time of usage. When the cost of maintenance
and expanding is much more important than the cost of development. But even there you start to
introduce the techniques gradually when the need arises. When you see the complexity reaching a certain level. When you understand the domain better.

DDD is just a name for a set of techniques such as:

* Bounded Contexts
* Domain Events
* Aggregates
* Entities
* Repositories
* Value Objects
* Sagas
* Read models

As with every programming technique, you don't need to use all of them. You can cherry pick those that you benefit most from and start using them at the beginning. In my projects, the most beneficial were Bounded Contexts, Domain Events, Sagas.

So if you are wondering... Are [DDD books](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215) for me? Is [Arkency's DDD workshop](/ddd-training/) for me? Should I invest my
time and money into learning those techniques? Then the first questions you should ask yourself is

* Do I have complexity in my application that I struggle with?
* Do I feel the pain of developing this application?

Because if not then you can watch DDD from distance, with curiosity, but without much commitment to it.
You simply have other problems in life :)

But DDD was one of the [5 most important books for DHH](https://signalvnoise.com/posts/3375-the-five-programming-books-that-meant-most-to-me)
so definitelly you will benefit from learning it as well. Join our [upcoming DDD workshop](/ddd-training/)
in January to spend 2 days practicing those techniques in Rails applications.
