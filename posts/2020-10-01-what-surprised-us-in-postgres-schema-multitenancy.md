---
title: What surprised us in Postgres-schema multitenancy
created_at: 2020-10-01T10:21:05.829Z
author: Tomasz Wróbel
tags: ['multitenancy', 'postgresql']
publish: true
---

# What surprised us in Postgres-schema multitenancy

You can implement multitenancy in [various ways](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/). In one of our projects we went for schema-based multitenancy, where each tenant has its own PostgreSQL schema - i.e. its own namespaced set of tables. This approach has many [pros and cons](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/), but we found it viable in certain situations. [Apartment](https://github.com/influitive/apartment) is a popular gem assisting with that (currently not actively maintained though).

<!-- more -->

I like this particular feature of Postgres, but one has to admit it introduces a little bit of **complexity** - after all it's not a conventional feature everyone uses.

The thing is that **complexity compounds**. One unconventional feature is not a big deal, but if there's more of them, **interesting things start to happen**. Here are some of the things that surprised us when we were implementing schema-based multitenancy.

1. PG schemas + PG extensions (like `pgcrypto` or `hstore`)

Postgres extensions need to be moved to a separate schema. The thing is that they need to be installed in one specific schema that is available in the search_path. Normally they reside in `public` schema, which will no longer be in search_path if you go multitenant. Typically you move the extensions to a new `extensions` schema which will always stay in search_path, regardless of current tenant. This is a just minor annoyance, but it's worth making sure you're authorized to make the operations in your particular DB setup. In our case (managed DB on Digital Ocean) it was a little tricky.

2. PG schemas + PgBouncer

PgBouncer is a popular tool to control the number of connections to your DB server. It runs in a couple pool modes: session mode, transaction mode, statement mode. Transaction mode is sometimes the recommended default. Anything else than session mode won't let you use search_path to switch tenants (nor any other postgres session features). If you try to use search_path in Transaction mode, you can even unknowingly mix tenant's data. Switching to session mode is the obvious solution, but it has its own set of consequences.

3. PG schemas + Delayed Job

I'm aware not many people use Delayed Job nowadays. It was used in the project we dealt it, though, and it has shown an interesting situation. Delayed Job is used to perform jobs by a background worker, just like Sidekiq. The difference is that the jobs are stored in a plain SQL table. Now if you go multitenant, you need to decide where to put the job that belongs to a specific tenant. Should every tenant's schema have its own table with jobs? Then you need to have N workers running in parallel (where N is the number of tenants), or make one worker somehow query all these tables. Alternatively you can go for a shared table with the jobs and put it to a shared schema - which is what we did. You can do it by explicitly prefixing the jobs table name with the schema name. 
