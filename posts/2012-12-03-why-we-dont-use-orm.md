---
title: "Why we don't use ORM"
created_at: 2012-12-03 11:25:59 +0100
kind: article
publish: true
author: 'Jan Filipowski'
newsletter: :arkency_form
tags: [ 'ruby', 'storage', 'repository', 'orm' ]
---

You've probably already read that [we don't use Rails](http://blog.arkency.com/2012/11/not-rails/) or any other framework to build [chillout.io](http://chillout.io). Having that said I must add we neither use ORM.

<!-- more -->

## Storage-less model

First of all - your business models shouldn't know anything about storage. Why? Single Responsibility Principle could be one of valid answers. But I'd rather argue it's because storage responsibility is to extend app state, in which models live - **your models don't know anything about memory management, so why should they be interested in persistent memory?**

## Database-less perspective

There's something more: [forget about your storage default - database](http://blog.8thlight.com/uncle-bob/2012/05/15/NODB.html). Imagine, that data from your domain model could be persisted in many ways - to simple files, to key-value stores, to relational databases and so on. In application with high-quality architecture you can defer decision which one to choose - some models will need to be restored in very short time, and for some of them it won't matter. Maybe one model will look like relational record, and another like document?

## That's why we don't use ORM

To be accurate - that's why we don't use ORM on domain-level: we don't want to mix storage with our business, we don't want to depend on non-domain interface of our models. But to be honest - we also don't use ORMs on app-level, because we didn't find any tool that only map object by interface description to storage and vice versa. [DataMapper 2 looks promising](https://github.com/datamapper/dm-core/wiki/Roadmap), but it's not there yet.

## Classic approach - repository

So how do we handle storage? We use [repository objects](http://martinfowler.com/eaaCatalog/repository.html) that encapsulate information how to map models into storage entities and acts like domain collection.

Each domain model should have own repository (or none, if we don't have to store it) - that way the only reason to modify repository implementation is change in model interface. Each of repositories can have different interface, based on your domain needs. Each of them can use different storage, but all storage adapters should have same API to make them easy to change to other.

## Conclusion

Storage is not a part of your domain, even if most of your domain objects have to be persisted. It's just one of the details that you should change easily.

Do you think I'm wrong and that's too complicated to handle data? Leave a comment and tell your story.
