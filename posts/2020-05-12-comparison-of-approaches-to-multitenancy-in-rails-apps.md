---
title: Comparison of approaches to multitenancy in Rails apps
created_at: 2020-05-12T14:47:33.033Z
author: Tomasz Wróbel
tags: []
publish: false
---

In PostgreSQL you can implement multitenancy on a couple different levels:

1. Database level (rarely practical - just for comparison).
2. Schema level (_namespaces_ is a more explanatory name, see [PostgreSQL schemas](https://www.postgresql.org/docs/9.1/ddl-schemas.html)).
3. Row level (putting `tenant_id` columns to every table and filtering everywhere).

Here's how they compare to each other:

|     | db-level | schema-level | row-level |
|-----|--------|------------|-----------|
| Running DB migrations | O(n)++ | O(n) | O(1) |
| Tenant setup time | Slower + possible operational overhead | Slower |  Non existent |
| Leaking data between tenants | You'd need to try hard to get one | Get a couple things right and you'll be fine | Forget a `WHERE` clause and 💥 |
| Dump a single tenant | no brainer | easy | super cumbersome |
| Conventionality | Pretty much | Sometimes at odds with Rails assumptions | Standard Rails |
| Additional costs | Can be higher if pricing depends on # of dbs | not really | no |
| Operational overhead | You have a lot of databases | sometimes | no |
| Need to merge data across tenants or shared tables | in-app only, cannot do in SQL | not a big problem, can do in SQL | no brainer |
| Complexity | | some exotic PG features, stateful `search_path` | tenant_id keys everywhere |
| Where possible | | Are you on a managed DB? Double check if it's possible | |
| Cost of switching | You need to establish a separate db connection | Just set the `search_path` for the current session | Not at all |
| Invasiveness | Fine | Fine | `tenant_id` columns and filters all over the code |

### MySQL vs PostgreSQL schemas

MySQL has no feature like PostgreSQL schemas, but MySQL databases can be used in a similar way. You don't need to establish another connection to change the database in MySQL - you can switch via the `use` statement, similarly to what you'd do with PostgreSQL `set search_path`. You can also similarly mix data from different databases by prefixing the table names.

The drawback is that in MySQL you need to make sure there's no name collisions with other DBs. You also need to have create-database privileges to setup a new tenant. This can be a substantial difference if you don't fully control the DB server. In case of PostgreSQL you only need the privilege to create new schemas inside your existing DB (and name collisions are constrained to it). This can work fine even on managed databases.

## Quick reasons to pick one or another

| Condition | Recommendation |
| --- | --- |
| A lot of tenants? Especially if a lot of low-value tenants (like abandoned accounts or free tiers) | consider row-level |
| Less tenants (especially high-value) | schema-level more viable |
| Anxious about data isolation (ensuring no data leaks between tenants) | consider schema-level |
| Customers might require more data isolation for legal reasons | consider schema-level or even db-level |
| On a managed or cloud hosted database? | if you wanna go for schema-level make sure it all works for you |
| Multitenantizing an existing single-tenant code base? | consider schema-level |
| Greenfield project | row-level may be easier to introduce |
| Need to combine a lot of data across tenants | row-level is a safer bet |


## Feel like contributing to this blogpost?

TODO: link

Have comments? Reply here TODO: link to the tweet 
