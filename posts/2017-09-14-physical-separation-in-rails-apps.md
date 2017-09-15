---
title: "Physical separation in Rails apps"
created_at: 2017-09-14 18:56:18 +0200
kind: article
publish: true
author: Andrzej Krzywda
tags: [ 'cbra', 'gem', 'bounded context', 'ddd' ]
newsletter: :skip
---

I've been just following an interesting discussion within our [Rails/DDD community](http://blog.arkency.com/domain-driven-rails/). The particular topic which triggered me was a debate what kind of separation is possible within a Rails app which aims to be more in the DDD spirit.

<!-- more -->

I remember, back in the school, I was taught about the difference between the physical separation of components vs conceptual separation. This was a part of a software engineering class I took. I hope I got it right.

If we translate it into Rails terminology + some bits of DDD, we want to have the conceptual separation at the level of Bounded Context. A Bounded Context is a world in its own. It has its own "model" (don't confuse it with the ActiveRecord models) which represents the domain.

Your typical Rails app can have 5-50 different bounded contexts, for things like Inventory, Invoicing, Ordering, Catalog. If you also go CQRS, then some of your read models (or collections of them) can also be considered bounded contexts, but that's more debatable.

Anyway, once you have the bounded contexts (some people like to call them modules or components), that's a conceptual concept. Often you implement it with Ruby namespaces/modules.

But what options do you have for a physical separation?

# Directories

You can just create a new directory for the bounded context files and keep the separation at this level. It can be at the top-level directory of your Rails app or at the level of `lib/`.  This usually works fine, however you need to play a bit with Rails autoloading paths to make it work perfectly.

This is probably the default option we choose for the Rails apps at Arkency.

# Gems

Another level is a gem. It can be still within the same app directory/repo, but you keep them in separate directories, but declare the dependency at the Gemfile level.

# Gems + repos

The same as above, but you also separate the repos. This can create some more separation, but also brings new problems, like frequent jumps between repos to make one feature.

# Rails engines

This is a way, probably most in the spirit of The Rails Way. Which is both good and bad. Technically it can be a rational choice. However, it's a tough sell, as usually people who jump into Rails+DDD are not so keen to rely on Rails mechanisms too heavily. Also, many people may think of that separation as at the controllers level, which doesn't have to be the case.

BTW, splitting at the web/controllers level is an interesting technique of splitting your app/infra layer, but it's less relevant to the "domain" discussions". I like to split the admin web app, as it's usually a separate set of controllers/UI. The same with API. But still, this split is rarely a good split for your domain, that's only the infra layer.

Anyway, Rails engines can be perfectly used as a physical separation of the domain bounded contexts. If you don't mind the dependency on Rails (for the physical separation mechanism) here, then that's a good option. 

It's worth noting that gems and engines were chosen as the physical separation by our friends from Pivotal, they call it [Component-Based Rails Applications](http://shageman.github.io/cbra.info/).

# Microservices

This approach relies on having multiple nodes/microservices for our app. Each one can be a Rails application on its own. It can be that one microservice per bounded context, but it doesn't need to be like that. In my current project, we have 6 microservices, but >15 bounded contexts.

I wasn't a big fan of microservices, as they bring a lot of infrastructure overhead. My opinion has changed after I worked more heavily with a Heroku-based setup. The tooling nowadays has improved and a lot is offered by the platform providers.

It's worth noting that you can separate the code among several repos. However, you can also keep them in one monorepo. With a heroku-based setup, it seems to be simpler to keep them separated, but one repo should also be possible.

Microservices also allow another separation - at the programming language level. You can write each microservice in different languages, if it makes sense for you. It's an option not possible in previous approaches.

# Serverless aka Function as a Service

This is a relatively new option and probably not mostly considered. Especially that the current serverless providers don't support Ruby out of the box.
Serverless is quite a revolution happening and they can change a lot in regards to the physical separation.

What's possible with serverless is to not only separate physically bounded contexts, but also the smaller building blocks, like aggregates, read models, process managers (sagas). 

I'm not yet experienced enough with how to use it with Rails, but I'm excited about this option. As with microservices, this gives an option to use a different programming language, but at a lower scale. While, I'd be scared to implement a whole app in Haskell, I'm super ok, if we implement one read module or one aggregate in Haskell. In the worst case, we can rewrite those 200 LOC.
Another big deal with serverless is the fact that they handle the HTTP layer for you. Does it mean "good bye Rails"? I'm not sure yet, but possibly it can reduce the HTTP-layer of our codebases to a minimum.

# Summary

The nice thing with a DDD-based architecture of your application is that it mostly works with whichever physical separation you choose. It's worth noting that those physical mechanisms can change over time. You can start with a Rails engine, then turn it into a microservice and then split it into several serverless functions.

How about you, how do you physically separate the modules/bounded contexts of your Rails apps?