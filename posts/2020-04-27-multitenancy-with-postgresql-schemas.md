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

**PostgreSQL extensions can no longer reside in public schema** - if you use any extensions (like `pgcrypto`, `ltree`, `hstore`) you need to put them to a separate schema - e.g. `extensions` and always have it in the search_path (alongside the chosen tenant). In Apartment you do this via:

```ruby
Apartment.configure do |config|
  config.persistent_schemas = ["extensions"]
end
```

This is needed because of three conditions:

1. PG extensions have to be installed in a specific schema - normally you put them to `public`. Actually the extension is global, but its objects (like functions) need to belong to a specific schema.
2. It can only be one schema.
3. In order to use an extension, current `search_path` must include the schema which hosts this extension.

You can temporarily work it around by adding `public` to `persistent_schemas` which is obviously bad, but perhaps useful for a quick PoC. It won't take you very far - Rails will complain when making a migration which creates an index (Rails checks if the index already exists in the search path and it'll refuse to create it the tenant's schema).

**Every migration needs to run for each tenant separately**. Probably not a problem if you have 10 tenants. Brace yourself if you have 1000 tenants. Also the default behaviour in Apartment is that when a migrations fails for a tenant the next ones are not attempted, and previous stay migrated (they're not reverted and not wrapped in a transaction - not even sure if it's possible to have a cross schema transaction. TODO: check).

**What about migrations not meant per tenant?** Perhaps you'll rarely need it. If you do, you can either run the SQL script by hand (the traditional YOLO way), or have a guard statement:

```ruby
class AGlobalMigration < ActiveRecord::Migration[5.2]
  def change
    Apartment::Tenant.current == "public" || (puts "This migration is only meant for public schema, skipping."; return)
    # ...
  end
end
```

**PgBouncer transaction mode doesn't let you use search_path**. Got PgBouncer in your stack? If you're using a managed database (like on Digital Ocean), PgBouncer might part of the default setup. It has [3 pool modes](https://www.pgbouncer.org/features.html). You need to set the pool to _Session Mode_ (which has its own consequences) to use any PostgresSQL session features - search_path being one of them. If you run on _Transaction Mode_ you can end up with tenants mixed up.

**Other db connections need to be dealt with**. Do you do another `establish_connection` to your multitenanted db? Why would anyone do that? You know, in legacy codebases there are weird things done for weird reasons. If that's the case - you need to account for it when switching the tenant. 

**Where do you put Delayed Jobs**. Sure, not everyone uses Delayed Job with Active Record backend, but if you do, an interesting issue arises: where do you put the table with the jobs. In each tenants schema? This would mean you need to have a worker for every tenant. Or to hack the backend to keep polling tables from all schemas. The other solution is to put it to a shared table, for example in the `public` schema. Apartment facilitates shared tables by using qualified table names (`set_table_name` to `public.delayed_jobs` under the hood - which you can do by hand). You also need to specify the tenant in job's metadata. Initially we wanted to avoid shared tables (because KISS), but we eventually went for the 2nd solution.

```ruby
config.after_initialize do
  Delayed::Backend::ActiveRecord::Job.table_name = 'public.delayed_jobs'
end
```

**Where do you store your tenant list**. A lot of people might wanna put it to the db to be able to manipulate it just as the rest of the models. But which schema? If you put it to `public`, all of your tenants' schemas will also have the tenants table (hopefully empty). Probably not a problem, but it's a little unsettling. If you think about it more, tenant management is logically a separate application and shouldn't be handled by the same Rails codebase, but a lot of people will do it for convenience reasons. Just beware of accruing to many hacks around that. It's related to the _Rails vs PG schemas impedance_ issue.

**Rails vs PG schemas impedance**. Rails is not really meant to be used with multiple schemas. On the surface it looks fine, but then there little nuances coming up. For example `db/structure.sql`. 

**The main disadvantage with search_path is its statefullness**. PG schemas are one thing. The other thing is how to switch them. The standard way is to use `search_path` - which is stateful (state resides in PG session), which brings about many of these pitfalls. Perhaps stateless schema-switching could be viable by using qualified table names: `SELECT * FROM my_schema.my_table`, which could be somehow hacked into AR's `set_table_name`. We haven't tried it, but it might be worth exploring. Apartments `exclude_models` relies on this to facilitate tables shared between tenants.

**Remember you have to multitenantize other 3rd party services**. SQL DB is not everything.

**What is the role of the default schema?**. Which is `public`.

**How do you write the tests**. Mind: setting up a tenant in every test can be a costly operation. Perhaps there are other approaches.

**Do you in-memory cache/memoize anything that needs to be invalidated on tenant switch?**. Apartment already deals with clearing AR's query cache. But we had other app-specific things memoized in memory. You can use apartment callbacks for it:

```ruby
module Apartment
  module Adapters
    class AbstractAdapter
      set_callback :switch, :after do
        invalidate_my_cache
      end
    end
  end
end
```

Another solution would be to scope the cache per tenant and serve it with regards to the current tenant.

**Make sure to install the middleware above anything interacting with ActiveRecord**. We used AR session store so we had to put the middleware above `ActionDispatch::Session::ActiveRecordStore`.


## Comparison of approaches to multitenancy

| PG schemas (schema-level) | Filtering (row-level) |
|------------|-----------|
| Slower migrations | Normal migrations |
| Slower tenant setup | Quicker tenant setup |
| Easier to avoid data leaks | Data leaks more likely |
| Easier to dump single tenant's data | |
| No tenant_id keys everywhere | |
| Sometimes at odds with Rails assumptions | Standard Rails |

* A lot of tenants? consider row-level. Especially if a lot of low-value tenants (like abandoned accounts or free tiers)
* Less tenants (especially high-value) - schema-level more viable.
* Data isolation crucial (no leaks). Consider schema-level.


