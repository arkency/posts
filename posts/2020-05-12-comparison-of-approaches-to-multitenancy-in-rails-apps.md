---
title: Comparison of approaches to multitenancy in Rails apps
created_at: 2020-05-26T14:20:00.000Z
author: Tomasz Wróbel
tags: [ 'ruby on rails', 'multitenancy', 'postgresql' ]
publish: true
cta: 'hireus'
---

Multitenancy means serving multiple independent customers from one app. Pretty typical for SaaS model.
You can implement it on several different levels:

1. **Row level** - you put a `tenant_id` column into every DB table and filter by `tenant_id` in every query.
2. **Schema level** - for every tenant you create a separate namespaced set of tables inside one database. Easily achievable with [PostgreSQL schemas](https://www.postgresql.org/docs/9.1/ddl-schemas.html). See next paragraph on how this relates to MySQL.
3. **Database level** - you setup a whole new DB for every tenant.

Here's how they compare to each other:

|     | row-level | schema-level | db-level |
|-----|--------|------------|-----------|
| Tenant setup time | ⚡️ Just create a record | 🐢 Slower (need to create schema, create tables) | 🐌 Even slower + possible operational overhead |
| Leaking data between tenants | 💥 If you forget a `WHERE` clause | ✅ Get a couple things right and you'll be fine | ✅ You'd need to try hard to get one |
| Invasiveness | 🍝 `tenant_id` columns and filters all over the code | 👍 Fine | 👍 Fine |
| Need shared tables or merging data across tenants | ✅ No brainer | 👍 Can still be done in SQL | 🚫 In-app only, cannot do in SQL |
| Running DB migrations | ⚡️ O(1) | 🐢 O(n) | 🐌 O(n) |
| Conventionality | 👍 Standard Rails | 🛠 Occasionally at odds with Rails assumptions | 🤔 |
| Additional costs | 👍 Not really | 👍 Not really | ❓ What if pricing depends on the # of DBs? |
| Operational overhead | ✅ No | 👍 Occasionally. You have an ever growing number of db tables. | 🛠 You now have a lot of databases |
| Complexity | 🍝 `tenant_id` keys everywhere | 🌴 an exotic PG feature & stateful `search_path` | 🤔 |
| Where possible | 🌍 Pretty much anywhere | ⚠️ Are you on a managed DB? Double check if all features and ops possible | ⚠️ Got rights to create databases on the fly? |
| Cost of switching | ⚡️ Just set a variable | ⚡️ Set the `search_path` for the current db connection | 🐢 You need to establish a separate db connection |
| Extract a single tenant's data | 🛠 Cumbersome | 👍 Easy | 👍 No brainer |

### MySQL vs PostgreSQL schemas

MySQL has no feature like PostgreSQL schemas, but MySQL databases can be used in a similar way. You don't need to establish another connection to change the database in MySQL - you can switch via the `use` statement, similarly to what you'd do with PostgreSQL's `set search_path`. You can also similarly mix data from different databases by prefixing the table names.

The drawback is that in MySQL you need to make sure there's no name collisions with other DBs. You also need to have create-database privileges to setup a new tenant. This can be a substantial difference if you don't fully control the DB server. In case of PostgreSQL you only need the privilege to create new schemas inside your existing DB (and name collisions are constrained to it). This can work fine even on managed databases.

## Quick reasons to pick one or another

| Condition | Recommendation |
| --- | --- |
| A lot of tenants? | consider row-level |
| A lot of low-value tenants? (like abandoned accounts or free tiers) | consider row-level |
| Less tenants and they're high-value? | schema-level more viable |
| Anxious about data isolation? (ensuring no data leaks between tenants) | consider schema-level |
| Customers might require more data isolation for legal reasons? | consider schema-level or even db-level |
| On a managed or cloud hosted database? | if you wanna go for schema-level make sure it all works for you |
| Multitenantizing an existing single-tenant code base? | schema-level might be easier to introduce |
| Greenfield project? | row-level more viable |
| Need to combine a lot of data across tenants | schema-level possible, but row-level is a safer bet |
| Some customers may have exceptional performance/capacity requirements | consider enabling db-level |

## Other possibilities

These three options don't constitute the whole spectrum of approaches. For example:

* Even if you have db-level separation you can still choose whether to share application servers between tenants - which makes them run in the same process. If you don't, you achieve even higher level of separation, which most people wouldn't call multitenant.
* Even if a DB engine doesn't facilitate namespaces (like PG schemas), it can still be done manually by prefixing table names like `tenant_123_users`. Reportedly, this is how WordPress.com works.
* In row-level approach you can employ Row Level Security and achieve a higher level of isolation, but this can have implications on reusing db connections. [Docs for PostgreSQL](https://www.postgresql.org/docs/current/ddl-rowsecurity.html).
* With schema-level approach, you can start sharding larger numbers of schemas into multiple db servers - e.g. when reaching performance limits or when a particular tenant has higher data isolation requirements.
* Hybrid approach. It's also possible to implement row-level multitenancy and still store the data in separate schemas/DBs (for some or all tenants). This way it's easier to migrate one way or the other according to security/scaling needs.

## Feel like contributing to this blogpost?

🛠 Feel free to [submit a pull request](https://github.com/arkency/posts/edit/master/posts/2020-05-12-comparison-of-approaches-to-multitenancy-in-rails-apps.md) to this blogpost. It can be a nuanced remark, better wording or just a typo.

💬 Have comments? [Reply under this tweet](https://twitter.com/tomasz_wro/status/1265289214960308224) or ping me on twitter - [@tomasz_wro](https://twitter.com/tomasz_wro). 

🗞 There are at least two other multitenancy-related blogposts we're going to publish soon: _Caveats and pitfalls of PostgreSQL schema-based multitenancy_ and _A gentle introduction to schema-based multitenancy with basic concepts explained_. If you don't want to miss anything, [subscribe to our newsletter](https://arkency.com/newsletter/).
