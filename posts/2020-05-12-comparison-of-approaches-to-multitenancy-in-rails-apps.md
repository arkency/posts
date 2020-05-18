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

|     | row-level | schema-level | db-level |
|-----|--------|------------|-----------|
| Running DB migrations | O(1) | O(n) | O(n)++ |
| Tenant setup time | Non existent | Slower | Slower + possible operational overhead |
| Leaking data between tenants | Forget a `WHERE` clause and 💥 | Get a couple things right and you'll be fine | You'd need to try hard to get one |
| Dump a single tenant | super cumbersome | easy | no brainer |
| Conventionality | Standard Rails | Sometimes at odds with Rails assumptions | Pretty much |
| Additional costs | no | not really | Can be higher if pricing depends on # of dbs |
| Operational overhead | no | sometimes | You have a lot of databases |
| Need to merge data across tenants or shared tables | no brainer | not a big problem, can do in SQL | in-app only, cannot do in SQL |
| Complexity | tenant_id keys everywhere | some exotic PG features, stateful `search_path` | |
| Where possible | | Are you on a managed DB? Double check if it's possible | |
| Cost of switching | Not at all | Just set the `search_path` for the current session | You need to establish a separate db connection |
| Invasiveness | `tenant_id` columns and filters all over the code | Fine | Fine |

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
