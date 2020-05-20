---
title: Multitenancy with PostgreSQL schemas - what you'd rather know before
created_at: 2020-05-12T14:52:02.222Z
author: Tomasz Wróbel
tags: []
publish: false
---

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

**Where do you store your tenant list**. A lot of people might wanna put it to the db to be able to manipulate it just as the rest of the models. But which schema? If you put it to `public`, all of your tenants' schemas will also have the tenants table (hopefully empty). Probably not a problem, but it's a little unsettling. If you think about it more, tenant management is logically a separate application and shouldn't be handled by the same Rails codebase, but a lot of people will do it for convenience reasons. Just beware of accruing to many hacks around that.

**Rails vs PG schemas impedance**. Rails is not really meant to be used with multiple schemas. On the surface it looks fine, but then there little nuances coming up. 

* `db/structure.sql`
* migrations per tenant or global


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

## Partial alternatives

**Sharding the db**.

**Ejecting Apartment**.

**The main disadvantage of search_path is its statefullness**. PG schemas are one thing. The other thing is how to switch them. The standard way is to use `search_path` - which is stateful (state resides in PG session), which brings about many of these pitfalls. Perhaps stateless schema-switching could be viable by using qualified table names: `SELECT * FROM my_schema.my_table`, which could be somehow hacked into AR's `set_table_name`. We haven't tried it, but it might be worth exploring. Apartments `exclude_models` relies on this to facilitate tables shared between tenants.

```ruby
# PoC, perhaps it's an overkill do it on each request
ActiveRecord::Base.descendants.each do |model|
  model.table_name = "#{ current_tenant }.#{ model.table_name }"
end
# Better: patch table name resolution
```

TODO: Also, how do you ensure no stuff like raw sql bypasses that? Empty public schema?

**Creating threads inside a request or job?** It won't have the `search_path` set:

```ruby
Apartment::Tenant.switch!("tenant_1")
p ActiveRecord::Base.connection.execute("show search_path").to_a
# => [{"search_path"=>"tenant_1"}]
p Thread.new { p ActiveRecord::Base.connection.execute("show search_path").to_a }
# => [{"search_path"=>"public"}]
```

You need to set it manually. Not sure if your code uses threads in a weird piece of code or lib? Setting pool size to 1 can help - you'll get an exception if that's the case. Not the best idea when you're on a threaded server, though.

## Feel like contributing to this blogpost?

TODO: link

Have comments? Reply here TODO: link to the tweet 
