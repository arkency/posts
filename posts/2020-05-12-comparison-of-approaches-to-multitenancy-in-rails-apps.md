---
title: Comparison of approaches to multitenancy in Rails apps
created_at: 2020-05-26T14:20:00.000Z
author: Tomasz Wróbel
tags: []
publish: true
---

You can implement multitenancy on a couple different levels. If you're on PostgreSQL:

1. Row level (putting `tenant_id` columns to every table and filtering everywhere).
2. Schema level (_namespaces_ is a more explanatory name, see [PostgreSQL schemas](https://www.postgresql.org/docs/9.1/ddl-schemas.html)). 
3. Database level (rarely practical - just for comparison).

For MySQL check next paragraph. Here's how these levels compare to each other:

|     | row-level | schema-level | db-level |
|-----|--------|------------|-----------|
| Tenant setup time | ⚡️ Create a record | 🐢 Slower (create schema, create tables) | 🐌 Even slower + possible operational overhead |
| Leaking data between tenants | 💥If you forget a `WHERE` clause | ✅ Get a couple things right and you'll be fine | ✅ You'd need to try hard to get one |
| Invasiveness | 🍝 `tenant_id` columns and filters all over the code | 👍 Fine | 👍 Fine |
| Need shared tables or merging data across tenants | ✅ No brainer | 👍 Can still be done in SQL | 🚫 In-app only, cannot do in SQL |
| Running DB migrations | ⚡️ O(1) | 🐢 O(n) | 🐌 O(n) |
| Conventionality | 👍 Standard Rails | 🛠 Occasionally at odds with Rails assumptions | 🤔 |
| Additional costs | 👍 Not really | 👍 Not really | ❓ What if pricing depends on the # of DBs? |
| Operational overhead | ✅ No | 👍 Occassionally | 🛠 You now have a lot of databases |
| Complexity | 🍝 `tenant_id` keys everywhere | 🌴 some exotic PG features, stateful `search_path` | 🤔 |
| Where possible | 🌍 Pretty much anywhere | ⚠️ Are you on a managed DB? Double check if all features and ops possible | ⚠️ Got rights to create databases on the fly? |
| Cost of switching | ⚡️ Set a variable | ⚡️ Set the `search_path` for the current db connection | 🐢 You need to establish a separate db connection |
| Dump a single tenant's data | 🛠 cumbersome | 👍 easy | 👍 no brainer |

### MySQL vs PostgreSQL schemas

MySQL has no feature like PostgreSQL schemas, but MySQL databases can be used in a similar way. You don't need to establish another connection to change the database in MySQL - you can switch via the `use` statement, similarly to what you'd do with PostgreSQL `set search_path`. You can also similarly mix data from different databases by prefixing the table names.

The drawback is that in MySQL you need to make sure there's no name collisions with other DBs. You also need to have create-database privileges to setup a new tenant. This can be a substantial difference if you don't fully control the DB server. In case of PostgreSQL you only need the privilege to create new schemas inside your existing DB (and name collisions are constrained to it). This can work fine even on managed databases.

## Quick reasons to pick one or another

| Condition | Recommendation |
| --- | --- |
| A lot of tenants? | consider row-level |
| A lot of low-value tenants (like abandoned accounts or free tiers) | consider row-level |
| Less tenants and they're high-value | schema-level more viable |
| Anxious about data isolation (ensuring no data leaks between tenants) | consider schema-level |
| Customers might require more data isolation for legal reasons | consider schema-level or even db-level |
| On a managed or cloud hosted database? | if you wanna go for schema-level make sure it all works for you |
| Multitenantizing an existing single-tenant code base? | schema-level might be easier to introduce |
| Greenfield project | row-level more viable |
| Need to combine a lot of data across tenants | row-level is a safer bet |

## Feel like contributing to this blogpost?

Feel free to [submit a pull request](https://github.com/arkency/posts/edit/master/posts/2020-05-12-comparison-of-approaches-to-multitenancy-in-rails-apps.md) to this blogpost!

Have comments? Ping me on twitter - [@tomasz_wro](https://twitter.com/tomasz_wro).
