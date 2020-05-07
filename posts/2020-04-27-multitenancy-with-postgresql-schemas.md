---
title: Multitenancy with PostgreSQL schemas
created_at: 2020-04-27T09:26:33.075Z
author: Tomasz Wróbel
tags: []
publish: false
---

<!--

Alternative titles:
* Multitenancy with PostgreSQL schemas - navigating the minefield
* Multitenancy with PostgreSQL schemas - read before you go there

a series of blogposts?
* approaches to multitenancy
* pg schemas pitfalls
* performance

-->


**PostgreSQL extensions**.


**PgBouncer transaction mode doesn't let you use search_path**. Got PgBouncer in your stack? If you're using a managed database (like on Digital Ocean), PgBouncer might be there by default. You need to set the pool mode to _Session_ (which has its own consequences) to use any PostgresSQL session features - search_path being one of them. Otherwise you can end up with tenants mixed up.

**Other db connections need to be dealt with**. Do you do another `establish_connection` to your multitenanted db? Why would anyone do that? You know, in legacy codebases there are weird things done for weird reasons. If that's the case - you need to account for it when switching the tenant. 

```ruby
# TODO: example
```


Statefullness

Rails-schemas impedance

Other

* row level security https://www.postgresql.org/docs/9.5/ddl-rowsecurity.html
