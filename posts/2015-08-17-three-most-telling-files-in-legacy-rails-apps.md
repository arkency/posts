---
title: "Three most telling files in legacy Rails apps"
created_at: 2015-08-17 20:34:48 +0200
kind: article
publish: true
author: Marcin Grzywaczewski
tags: [ 'legacy', 'rails', 'techniques', 'ruby' ]
newsletter: :fearless_refactoring_1
img: "/assets/images/three-most-telling-files-in-legacy-rails-apps/header-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/three-most-telling-files-in-legacy-rails-apps/header-fit.jpg" width="100%" />
    <span style="text-align: right; font-size: 9px;"><a href="https://www.flickr.com/photos/wackybadger/8300188897/in/photolist-dDsCZ8-dDxNcY-8qq5qQ-naJzLg-dbPm6A-doWgui-doW95r-9H6Ppb-8ZSmvo-ccFCcW-4KC6oX-hrdbHV-9CgHN-9mcB8F-emeyU1-a2Gqjs-esSPb5-nnvwD8-4k5FK7-qGz5su-naLDim-9mfTvW-9mcDA6-hvWcJg-oQ8iaz-9aZQc9-hvWuxC-doWm6q-br3M1z-4k5FKb-5hLzzx-514DWr-9aWFZ2-sa4Esa-8ZPgXv-9mgfxE-9mcTo4-vq7eDN-doWgN3-a7GndJ-mT7Wso-5hQFV5-m4NnDV-6cHmvc-9mgmYy-dLiMs8-vKRsx2-7ULqa1-doWhoK-doWkjw">Photo</a> available thanks to the courtesy of <a href="https://www.flickr.com/photos/wackybadger/">wackybadger</a>. License: <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA 2.0</a></span>
  </figure>
</p>

When working in a consultancy agency the ability to work with legacy applications is necessary. Your clients very often come with their codebases. If the app is already in use a rewrite doesn't sound like a good idea - it's best to approach to make improvements incrementally.

But the truth is that this skill is very important for every Rails developer. Even if you're working on your own projects or creating the Rails-based startup from scratch after some time your code will grow. Tests are very likely to become slower. There will be more and more implicitness within your code. You accept that because you are within the context for a long time. You know tradeoffs, assumptions and decisions - often you made them by yourself. It's good to have skills to measure the situation and have some kind of guidelines to protect yourself from mistakes while refactoring.

In this blog post, I want to show you three simple techniques we use to get ourselves a solid starting point for working with legacy Rails apps. You will be able to apply it to projects you're working on and improve your planning and refactoring thanks to it.

<!-- more -->

## What can you do without reading the code?

There are some steps you can take while working with legacy Rails apps to get an idea what problem you'd likely face when working with them. They are great because they give you some kind of overview with a very little commitment - you don't need to read the application code at all.

They may seem obvious to you. But having a structured approach (even in a form of a checklist) to those steps can be really beneficial for you.

## Take a look at project's `Gemfile`

This is the first step you can do when investigating a legacy app. `Gemfile` tends to be a great source of knowledge when it comes to Rails apps. Since Rails ecosystem is so rich, people are accustomed to not reinventing the wheel but using gems made by the community.

It's especially true when the codebase was left by a Rails software shop. With codebases written by people with a smaller expertise you can still find code like external services integration reimplemented by previous codebase's developers.

`Gemfile` can also provide you heuristic about how the code was made. With projects with many (like 80-90+ gems) gems within the `Gemfile` it's likely you'll see smells like dead code, gems included but unused (left after refactoring) and different approaches to structuring the same pieces of architecture (which is not that bad).

While reviewing the `Gemfile`, you should take a great focus about those things:

* Gems that are used to implement generic application concerns (like authentication, batch jobs, file uploading).
* Gems with duplicated responsibilities. Such situation often indicates that one of the gems are unused, or you should constrain the usage of such gems to one gem and drop the others.
* Gems that introduce bigger DSLs. You should ask why DSLs is needed in the first place.
* Custom vendor gems. If they aren't simple they are first candidates to be discussed with the previous team or technical people on your client's side.
* Gems changing the programming model of the application like `event_machine`. They require different commitment and care while testing and refactoring - so you need to take this into consideration.

<%= inner_newsletter(:fearless_refactoring_1) %>

## Take a look at `db/schema.rb`

Your applications usually are all about the data you store and process. Since by default Rails apps use relational databases, they maintain a _schema_. It is a great help when restoring the database structure on a new workplace. But it can also have benefits when it comes to analyzing legacy applications.

With `schema.rb` it is easy to see common smells with typical Rails apps:

* God models - a.k.a. hundreds-line-of-code models. They are often naturally created near generic responsibilities of your app - `User` is the most common god model I've seen. Database models representing them also tend to be huge. By investigating the size of the table schema, you can take many assumptions about how complicated the representing model would be. Such models are often first targets of refactoring - but be careful since they also tend to be the most coupled ones.
* Denormalised data. While denormalised data is not bad _per se_, it can be hard to refactor and rewrite features with denormalized schemas. They are often denormalized for performance reasons - it's worth investigating whether such performance improvement is needed or not.
* Non-existing indexes. They are the most common reason of database performance problems with Rails apps. If you see a table which has a natural candidate for an index (like `title` field or `id` field) but there is no index, adding it may be the first step to fix performance problems of such legacy app. Be sure to communicate when you create such migration - adding an index in a production database can be a very lengthy process.
* Dead tables. You can always take the database table name (like `users`) and search the project for the conventional model counterpart (`User`) occurrences. You should also search for the table name itself since it can be connected with a model with a custom table name. It can be a very quick scan that will make dead code elimination much simpler - and eliminating dead code is one of the safest operations you can do in the legacy codebase.

## Take a look at `config/routes.rb`

Routes file is another great source of knowledge when it comes to legacy Rails apps. If you treat a controller action as a C `main` method equivalent, taking a quick glimpse on routes can show you how complex in terms of _starting points_. This is an important measure. Apart from investigating a number of routes, you should take attention to following things:

* Namespaces. Often they indicate that there was some effort in the past to create more modular segregation of the app. You can take it as a point of discussion with the client.
* Auto-generated routes. They often indicate that there are routes and parts of the code that are beyond your control or you need to take an effort to do so. The best example here is a `devise_for` used by a popular authentication gem called [devise](https://github.com/plataformatec/devise).
* Routing constraints. While not popular, they can change the flow of your app - so take care when you see them.
* `resources` with `only` and `except` modifiers. It's rather popular for Rails apps to have those modifiers when defining resources in routes. Such routes allow you to measure a number of potential queries (GET actions that only return data) and commands (POST/PUT/DELETE actions that modify the data) in the app. It's another measure of a complexity of the legacy app.
* Custom routes (using `get` / `post` / etc. methods). They indicate whether there is something in the app which is not a resource. You'd like to check whether it's the case or not. It's often an indicator of a missing concept in the app itself.

## Summary

As you can see there is a lot that can be read without even touching the logic of a legacy app. Examining those three files helped us in a lot of situations - we got first points to discuss with clients and an overview what we can expect from an app itself.

Applying such analysis to your app can bring you many ideas and knowledge about what can be done to improve maintainability of it. I greatly encourage you to try it out - it can save you a lot of work later.
