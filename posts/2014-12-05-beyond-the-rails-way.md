---
title: "Beyond the Rails Way"
created_at: 2014-12-05 21:00:00 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :skip
tags: ['rails way']
---

<p>
  <figure>
		<img src="/assets/images/beyond-the-rails-way/image-fit.jpg" width="100%">
        <details>
          Source: <a href="https://www.flickr.com/photos/philakilla/">Justin Wolfe</a>
        </details>
  </figure>
</p>

What is Rails for you?

Is it just a technology? Is it about the community?

<!-- more -->

## Do you remember the first time you scaffolded a Rails application? 

How did it feel?

Were you proud of achieving so much in so little time? Did you impress anyone by using Rails?

Rails is no longer the youngest technology around. Did it change anything?

Did you ever think how Rails ideas helped to shape the world? Did you notice how many startups choose Rails as the technology? It’s amazing that sometimes those people don’t fully know their business idea yet, but they know it will be implemented in Rails!

## Rails changed the business world. For the better.

It was no longer so expensive to come up with a prototype or with an MVP. More ideas could be validated.

Some of the ideas were totally wrong. They didn’t have the market fit. Still, their authors lost less money than they would by choosing other (at that time) technology.

Many ideas (and their authors!) were validated positively. The MVP has proved to be interesting for the users. People wanted to pay for using it. Those ideas turned into businesses. Many of those still exist today.

As developers, we sometimes forget how much impact our work has on the world around us. All of the above wouldn’t have happened without us and Rails.

What about those less technical people? Did they have their chance in the Rails revolution?

Yes!

It was late 2007 when I was contacted by a potential client. He said he was a fashion designer and he needed help with Rails deployment.

What?

**A fashion designer needing help with Rails deployment!**

“What do you want to deploy?”, I asked, assuming he got some technical terminology wrong. “Oh, it’s a prototype of a web application which helps men choose good clothes for them.”

I looked at it and I was speechless. It was a fully working app, with a non-trivial algorithm implemented in Ruby.

It was actually ready for deployment. That’s all I was needed for here. This scared me. One year before, I decided to rely my programming career on Rails. Is this what I signed up for? Non-technical people being able to implement an application needing me just for the deployment?

I wanted to go back to my former Java world. To the world, where my job wasn’t threatened by fashion designers!

## I realised that something big is happening. 

I was lucky enough to be part of it. Rails enabled more people to be involved in creating web applications. I was very curious where it's all going to.

That was the time when new gems (they were called plugins at that time) started to pop up every week - acts\_as\_taggable, acts\_as\_anything, acts\_as\_hasselhoff (yes, there's [such plugin](https://github.com/lazyatom/acts_as_hasselhoff/) ). 

The fashion projects ended very well. When the client understood that I'm faster than him in developing the features, he took care of marketing and other stuff. I wasn't just the deployment person anymore.

**Creating new Rails projects in 2008 was like combining little pieces together.**

At the beginning it was fun. However, the whole new wave of Rails developers started creating new versions of their gems every week. Each version had different dependencies. The authentication libraries kept changing every month at that time. At some point, it wasn't just connecting the pieces, but also hard work on untangling the dependencies to make it all work together. 

## The Rails Way was born

This concept was never clearly defined. It was a term to describe the Rails approach. 

It's worth noting that at that time, everyone in Rails was coming from somewhere. I was from the Java world. Some people came from the PHP world. There were even some ex-Microsoft people. 

At that time there were no developers who "were born with Rails".

When The Rails Way concept was appearing it was a way of distinguishing it from "the architecture astronauts Java way" or the "PHP spaghetti way". We needed to be unique and have something to unite us.

Most of our community DNA was very good, but there was also something negative. A big part of the Rails community was united with the anti-Java slogans. Everything Java-like was rejected. XML? No, thank you, we've got yaml. Patterns? No, thanks. 

As a community, we entirely skipped the DDD movement, which took over the Java and .NET worlds. 

*"We don't need this"*

*"We've got ActiveRecord. We take the object from the database row and use it in all the three layers. Fat models or fat controllers? Whatever, let's just not create new layers."*

This way of thinking became more popular.

## The Rails Way was very successful

A new generation of developers started to appear. They were the ones who were born with Rails. Ruby was their first language. Rails was their first framework. The didn't bring the baggage of Java or PHP past life. 

They joined the Rails community and embraced what was presented to them. That was The Rails Way. 

## What is The Rails Way?

It's hard to define it easily. I tried to do it recently and I found a few features that make it so uniq:
- ActiveRecord objects everywhere, including the views
- External gems used for most of the features
- Non-trivial logic implemented with the combination of filters, callbacks, validations, state-machine - often in a non-easy-to-follow-way.
- Magic - Convention over Configuration, DRY, metaprogramming
- Only 3 layers - Models, Views, Controllers

## When is The Rails Way good?

It's really good for developers who start their career. I keep teaching The Rails Way to the students - at the beginning. That's the most efficient way to get a result. It's the best way to stay motivated while learning more. 

Within a project, The Rails Way is great at the beginning, when you're still not sure, where you go with the features and you need to experiment. In different project, the meaning of the beginning may be different. In some projects, I see the need to get out of the Rails Way as soon as the second month of development starts. In other projects it may be a year.

## When is The Rails Way not enough?

When you start wondering - does that code belong to the model or to the controller - it's a sign that you may be looking for something more than the Rails Way. 

When it's not clear how a feature works, because it's MAGIC - it's a sign the code controls you, not the other way round. You need something more to turn the magic into an explicit code.

When you start creating model classes which don't inherit from ActiveRecord::Base and you have problems explaining to the team, why you needed that.

When you try to test, but it either takes ages, because you need full integration tests, or you die by over-mocking.

When you try to switch to a hosted CI, but they are unable to run your test suite.

When you can only migrate data at nights, because the migrations lock the tables.

## Learning from mistakes

I've had the "luck" to review hundreds of Rails projects over the last 10 years. The same patterns were visible over and over again. An app was in quick development for the first months and then it started stagnating to the point where no one was happy with the speed.

I've started collecting those patterns. I grouped them into code smells, anti-patterns, magic tricks.

## Alternative architectures

Meanwhile, over the years, I was studying many non-Rails-Way architectures like DCI, DDD, CQRS, Hexagonal. 

Then I started to draw lines between those two.

- How can I get from the Rails code smells into DDD?
- Does DCI make sense in Rails apps?
- Is there place for the Hexagonal adapters?
- What are the aggregates in a Rails app?

Ruby and Rails are very unique and specific. Some things fit well into it, while others seem foreign to the way we write code.

## The Next Way techniques

- service objects
- adapters
- repository objects
- form objects
- domain objects
- events
- presenters

## From A to Z

I picked some of the building blocks of the architectures and tried to apply them in the Rails projects. The ones that didn't fit, I rejected. At the end, I only kept the ones which looked helpful for the typical problems.

This was just the beginning. Even if you know the starting problem (point A) and you know the end result (point Z), there's many steps in between that need to be made very carefully.

## Safety of changes

I assumed the code transformations will be done on production applications. No place for any risk here. Some of the changes may even be applied to untested code.

Your application needs to be safe, even when you apply the changes. Your boss and your clients will never allow introducing any bug "because I was improving the architecture". It's just not acceptable.

## Working on the recipes

It took me over a year to put together the refactoring recipes. Your code contains lots of small issues which make it harder to introduce a better design.

You won't introduce service objects if your controllers are filters-heavy. The dependencies will break your code.

You won't introduce service objects, if your views rely on @ivars magic. You need to be explicit with what you're passing to the views.

You won't make the build faster if it the tests still hit the database. You won't get rid of the real database as long as your ActiveRecord classes contain any logic. You need to introduce repository objects.

You won't introduce service objects easily, if your controller action can do different things, depending on the params (params[:action] anyone?). You need to use the routing constraints.

You won't find any shortcut, unless you know the SimpleDelegator trick which helps you move a lot of code into a temporary service object at once.

Those are some of the things I was working on. Those recipes are tested in big Rails projects by many different teams.

Those recipes work.
They will make your architecture improvement easier.

## The book

This all led to me to writing the "Fearless Refactoring: Rails Controllers" book. 

The core of the book are recipes. However, the recipes alone may leave you with just the mechanics, so we've added many chapters which explain the techniques in details. 

We've also added the "Big examples" chapters. They take you through some (ugly) code and apply the recipes, one by one. 

Thanks to all of you who bought the book when it was still beta since February I'm very confident about its quality. You sent me a great feedback. You sent me the before/after pieces of code. This book wouldn't happen without the people who trusted us so early. Thank you!

## 1.0 release

Some of you prefer to read books only when they are completed. Now is the best time to get it.

You can get the book at [http://rails-refactoring.com](http://rails-refactoring.com). Use the **REFACTORING** code and you will get it 20% off!

