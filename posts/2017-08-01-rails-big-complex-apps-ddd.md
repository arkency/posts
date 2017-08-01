---
title: "Can you use Rails for complex apps?"
created_at: 2017-08-01 10:54:43 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'rails', 'ddd' ]
newsletter: :arkency_form
---

For years Rails was praised as a great tool for new apps, startups and building prototypes. And I still believe it is. But is it a good fit for complex apps with lots of non-trivial logic? Notice that I didn't mention just big apps. Some apps are big and have tons of functionality but they are rather wide than deep. I am talking about complex apps where almost every feature needs to work nicely with every other feature and they can be combined together in tons of different combinations.

<!-- more -->

One app that I worked with suffered exactly from this problem. You have N features and separately they all worked OK, two enabled features sometimes worked together and sometimes not. Three features enabled together almost never worked as expected. I believe this can be a typical problem with highly configurable, complex apps which try to cater for the needs of a few enterprise businesses.

But is that Rails fault? Of course not. It is almost always a problem of architecture or implementation. And while DHH can claim that Rails is Omakase, the open-source community made it a very flexible ecosystem and the creator admits that configuring it to your taste is very easy.

By adding certain ingredients you can easily extend it so that it better caters for the needs of your more complex app or just different apps, with different needs and different focus.

The JavaScript ecosystem is now full of solutions such as React, Angular, Vue, Ember and languages such as Elm or ClojureScript. We went with React and just recently I started working on a new project that we want to release soon: https://devmemo.io/ - flashcards for Ruby and Rails developers. I just went with:

```
rails new DevMemo --skip-turbolinks --webpack=react`
```

and I was nicely surprised how the integration between React and Rails app just worked. [Webpacker](https://github.com/rails/webpacker) comes with [React, Angular, Vue and Elm integrations](https://github.com/rails/webpacker#integrations) working out of the box. Omakase? That's awesome a la carte for me :) I wish the React defaults were closer to what's in [create-react-app](https://github.com/facebookincubator/create-react-app) but maybe soon. Maybe webpacker will use just that in the future.

On the other hand, CoffeeScript in 2017? Thanks, but no thanks :) (`--skip-coffee`). I think JavaScript community made a tremendous progress and it no longer servers our projects as much as it did when it was introduced.

I think different approaches to frontend and backend require unlearning and changing our point of view. For me, React thought me to focus more on interacting with the site, making the task easier for the users, usually by providing better and more dynamic form inputs, handling interactions faster (before pressing save), instead of just thinking in terms of forms being presented and forms being sent. BTW, if you are fascinated by the plasticity of our brain, I recommend reading [The Brain that changes itself](http://amzn.to/2f3CS4Y). Great stuff about learning and unlearning.

Ok, but what about the backend and all the complexity there?

I believe the .NET and JVM community, which started earlier than Rails and were more often targeting enterprise businesses hit the complexity wall sooner than we did. At least because of the mere fact that they started earlier and had more time to accumulate a certain threshold of features. Also as bigger communities, they hit such walls more often.

And both communities invested heavily in DDD: Doman-Driven Design. Even [DHH recommends reading about it](https://signalvnoise.com/posts/3375-the-five-programming-books-that-meant-most-to-me).

But you can read all 3 most important books about the topic:

* [Domain-Driven Design by Eric Evans (DDD)](https://www.amazon.com/gp/product/0321125215/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0321125215&linkCode=as2&tag=arkency-20&linkId=0232df31187d4161a608a517d66d7a04) - where it all started
* [Implementing Domain-Driven Design by Vaughn Vernon (IDDD)](https://www.amazon.com/gp/product/0321834577/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0321834577&linkCode=as2&tag=arkency-20&linkId=3155894f09101a9da242cf5cb6d9bee7) - highest amount of code
* [Domain-Driven Design Distilled by Vaughn Vernon (DDDD)](https://www.amazon.com/gp/product/0134434420/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0134434420&linkCode=as2&tag=arkency-20&linkId=12c564c85da17f918d275bdc51626bde) - easiest to begin with

And still have no idea how to combine all that deep and useful knowledge expressed in these books with the knowledge you already have about Rails apps and Rails ecosystem. There are many reasons for it:

* DDD has not yet become wildly popular in Rails community. There are not many blog-posts and books about this topic.
* The language used by the books is not similar to the language we use in our community
* The tooling and practices of Rails community are different than those from JVM and .NET

That's why after years of testing DDD in our projects (legacy few years old apps and fresh projects) we decied to first organize [workshops (next edition in Berlin, September 21-22)](http://blog.arkency.com/ddd-training/) and now write a book.

We decided to call it "Event-Driven Rails" because we believe "Domain events" is the most important concept in the book and in the DDD community as well. It's easy to introduce and enables many other techniques as a result.

Just as learning new frontend frameworks and techniques requires certain amount of unlearning or re-mapping, similary DDD will re-orient you to focus on finding and tackling complexity, modeling business processes and finding what's important in it, what events occur, instead of storing and transforming the state via database.

####

Notes to myself:

Unlearn, unfocus on CRUD, forms and saving. More focus on business processes
React - unfocus on forms, focus on interactions, more dynamic UIs which make easier to finish a task


.net / java / php discovered DDD invented, discovered, talked for years
not that popular in Rails community because startups
but what if your project succeeds for years
but DDD costs more.
 no, it does not.
