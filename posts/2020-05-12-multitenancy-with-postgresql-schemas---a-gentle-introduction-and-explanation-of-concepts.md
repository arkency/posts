---
title: Multitenancy with PostgreSQL schemas - a gentle introduction and explanation of concepts
created_at: 2020-05-12T14:41:14.296Z
author: Tomasz Wróbel
tags: []
publish: false
---

**PostgreSQL schema**. Basically a namespace. Sometimes also called this way internally (schema is a confusing name).

**Postgres session/connection/backend**. `pg_stat_activity`, pid, `ps aux`.

**PostgreSQL search_path**.

**Rails connection, connection pool, connection handler**. In short: _Connection Handler_ has many _Connection Pools_ has many _Connections_. [More here](https://blog.arkency.com/rails-connections-pools-and-handlers/).

**PgBouncer pooling**.
