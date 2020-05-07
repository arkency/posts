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

**PostgreSQL extensions cannot stay in public schema** - if you use any extensions (like `pgcrypto`, `ltree`, `hstore`) you need to put them to a separate schema - e.g. `extensions` and always have it in the search_path (alongside the chosen tenant). It's because of three conditions: (1) PG extensions have to be installed in a specific schema - normally you put them to `public`. Actually the extension is global, but its objects (like functions) need to belong to a specific schema. (2) It can only be one schema. (3) In order to use an extension, current `search_path` must include the schema which hosts this extension.

**PgBouncer transaction mode doesn't let you use search_path**. Got PgBouncer in your stack? If you're using a managed database (like on Digital Ocean), PgBouncer might be there by default. You need to set the pool mode to _Session_ (which has its own consequences) to use any PostgresSQL session features - search_path being one of them. Otherwise you can end up with tenants mixed up.

**Other db connections need to be dealt with**. Do you do another `establish_connection` to your multitenanted db? Why would anyone do that? You know, in legacy codebases there are weird things done for weird reasons. If that's the case - you need to account for it when switching the tenant. 

**Where do you put Delayed Jobs**. Sure, not everyone uses Delayed Job with Active Record backend, but if you do, an interesting issue arises: where do you put the table with the jobs. In each tenants schema? This would mean you need to have a worker for every tenant. Or to hack the backend to keep polling tables from all schemas. The other solution is to put it to a shared table, for example in the `public` schema. Apartment facilitates shared tables by using qualified table names (`set_table_name` to `public.delayed_jobs` under the hood - which you can do by hand). You also need to specify the tenant in job's metadata. Initially we wanted to avoid shared tables (because KISS), but we eventually went for the 2nd solution.

**Where do you store your tenant list**. A lot of people might wanna put it to the db to be able to manipulate it just as the rest of the models. But which schema? If you put it to `public`, all of your tenants' schemas will also have the tenants table (hopefully empty). Probably not a problem, but it's a little unsettling. If you think about it more, tenant management is logically a separate application and shouldn't be handled by the same Rails codebase, but a lot of people will do it for convenience reasons. Just beware of accruing to many hacks around that. It's related to the _Rails vs PG schemas impedance_ issue.

**Rails vs PG schemas impedance**. Rails is not really meant to be used with multiple schemas. On the surface it looks fine, but then there little nuances coming up. For example `db/structure.sql`. 

**The main disadvantage with search_path is its statefullness**. PG schemas are one thing. The other thing is how to switch them. The standard way is to use `search_path` - which is stateful (state resides in PG session), which brings about many of these pitfalls. Perhaps stateless schema-switching could be viable by using qualified table names: `SELECT * FROM my_schema.my_table`, which could be somehow hacked into AR's `set_table_name`. We haven't tried it, but it might be worth exploring. Apartments `exclude_models` relies on this to facilitate tables shared between tenants.

**Remember you have to multitenantize other 3rd party services**. SQL DB is not everything.
