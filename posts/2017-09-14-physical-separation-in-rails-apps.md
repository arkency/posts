---
title: "Physical separation in Rails apps"
created_at: 2017-09-14 18:56:18 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

I've been just following an interesting discussion within our Rails/DDD community. The particular topic which triggered me was a debate what kind of separation is possible within a Rails app which aims to be more in the DDD spirit.

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

This is a way, probably most in the spirit of The Rails Way. Which is both good and bad. Technically it can be a rational choice. However it's a tough sell, as usually people who jump into Rails+DDD are not so keen to rely on Rails mechanisms too heavily. Also, many people may think of that separation as at the controllers level, which doesn't have to be the case.

BTW, splitting at the web/controllers level is an interesting technique of splitting your app/infra layer, but it's less relevant to the "domain" discussions". I like to split the admin web app, as it's usually a separate set of controllers/UI. The same with API. But still, this split is rarely a good split for your domain, that's only the infra layer.

Anyway, Rails engines can be perfectly used as a physical separation of the domain bounded contexts. If you don't mind the dependency on Rails (for the physical separation mechanism) here, then that's a good option. 

This approach is recommended by our friends from Pivotal, they call it [Component-Based Rails Applications](http://shageman.github.io/cbra.info/).

# Microservices

This approach relies on having multiple nodes/microservices for our app. Each one can be a Rails application on its own. It can be that one microservice per bounded context, but it doesn't need to be like that. In my current project, we have 6 microservices, but >15 bounded contexts.

I wasn't a big fan of microservices, as they bring a lot of infrastructure overhead. This has changed after I worked more heavily with Heroku-based setup.
