---
title: How schema-based multitenancy works
created_at: 2020-10-01T09:29:21.528Z
author: Tomasz Wróbel
tags: ['postgresql', 'multitenancy']
publish: false
---

PostgreSQL _schemas_ let you hold multiple instances of the same set of tables inside a single database. They're essentially namespaces for tables. Sounds like a simple way to implement multitenancy — at least in [specific cases](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/). But if you're like me, you'd rather know exactly how it works before you rush to implement it. Let's explain basic concepts first.

*PostgreSQL schema* — default schema

*PostgreSQL search_path* session based - but not only

*PostgreSQL session/connection/backend* - pg "session features". `pg_stat_activity`, pid, `ps aux`.

*Rails DB connection* - not always 1-1 with pg connections

*Rails DB connection pool* — in short: _Connection Handler_ has many _Connection Pools_ has many _Connections_. [More here](https://blog.arkency.com/rails-connections-pools-and-handlers/).

How do you typically switch to a different tenant in a Rails app?

How do you do it in ActiveRecord?



