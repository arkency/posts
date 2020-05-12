---
title: Comparison of approaches to multitenancy in Rails apps
created_at: 2020-05-12T14:47:33.033Z
author: Tomasz Wróbel
tags: []
publish: false
---

| | db-level | PG schemas (schema-level) | Filtering (row-level) |
|-----|--------|------------|-----------|
| Migrations | O(n)++ | O(n) | O(1) |
| Tenant setup time | Slower + possible operational overhead | Slower | Non existent |
| Leaking data between tenants | You'd need to try hard to get one | Get a couple things right and you'll be fine | Forget a `WHERE` clause and 💥 |
| Dump a single tenant | no brainer | easy | super cumbersome |
| Conventionality | Pretty much | Sometimes at odds with Rails assumptions | Standard Rails |
| Additional | Can be higher if pricing depends on # of dbs | not really | no |
| Operational overhead | You have a lot of databases | sometimes | no |
| Need to merge data across tenants or shared tables | rocket science | not a big problem | no brainer |
| Complexity | | some exotic PG features | tenant_id keys everywhere |

TODO: db-level - how do you actually do it from 1 rails app? separate db connections? (and limited number). easier in mysql?

* A lot of tenants? consider row-level. Especially if a lot of low-value tenants (like abandoned accounts or free tiers)
* Less tenants (especially high-value) - schema-level more viable.
* Data isolation crucial (no leaks). Consider schema-level.
* Cloud hosted DB with a lot of restrictions? Consider row-level.
* Anxious about data leaks? Consider schema-level.
* Customers require more data isolation for whatever reasons? Consider schema-level.


## Feel like contributing to this blogpost?

TODO: link

Have comments? Reply here TODO: link to the tweet 
