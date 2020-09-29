---
created_at: 2020-05-12T14:52:02.222Z
author: Tomasz Wróbel
tags: ["multitenancy"]
publish: false
---

# Multitenancy with PostgreSQL schemas - what you'd rather know before

<!--

categorize issues
tell if it only applies when on structure.sql or only brownfield
add code chunks

TODO: mind large shared tables - reuse?
TODO: where do you store tennat config
TODO: mention gradual automation for tenant setup

Make sure you have separate sessions for domains (assuming you separate tenants by domain)
Rails.application.config.session_store :active_record_store, key: '_my_app_session'
as long as no domain its ok
show the test

alternative way to separate - associate user account?

will you need customisations per tenant? (one of some good questions to ask)

separate pools for ad hoc and regular

apartment: what do you  do when non existent tenant? default apartment falls back to public, you can customize and throw exception

Apartment::Tenant.current,
ActiveRecord::Base.connection.schema_search_path,
ActiveRecord::Base.connection.execute("show search_path").first["search_path"],
ActiveRecord::Base.connection.execute("select pg_backend_pid()").first["pg_backend_pid"],

got any in memory caches?

It seems to me that the (let’s call it) “dispatcher app” (register new tenant and login) is logically something different from the “actual app”. Meaning that, theoretically, they should probably be separate Rails apps. Not sure if it’s practical, though.
If we wanna stay with one Rails app doing both functions, we can try using the public schema for that, but public schema has to have the same db structure as all the tenants' schemas (to not confuse Rails etc). 

- what needed when you wanna redirect users to their subdomains?

- when tenant should be accessible

when you open up a console, what tenant https://github.com/influitive/apartment/issues/521#issuecomment-526587752

jobs generally: your job needs to know which tenant it is (you can use metadata and then switch)
with dj: where do you put it: public schema (use excluded models); or have the worker pick from all schemas (you don't need metadata then). or redis (???)
https://github.com/influitive/apartment-activejob

counting connections:
- count rmt; in our case new relic needed more; mind threads in requests
- reducing rmt to 1
- when sessions exceeded you get a timeout, a little bogus error

ERROR:  query_wait_timeout
SSL connection has been closed unexpectedly

PG::UnableToSend: no connection to the server (ActiveRecord::StatementInvalid)
: SET client_min_messages TO 'warning'

testing existing features on multitenant setting (makes sense in the post?)

shared tables across tenants - they work by substituting table names; complexity; what if handcrafted sql

deleting public; but rails; but seeding tables

problems with structure.sql

When dumping structure.sql, all pg schemas dump (eg. when I got a tenant locally, it’ll dump all public.* tables, and all tenant’s tables).
you can use dump_schemas option
-> if you change schema_search_path which then does dump_schemas option
if you're on extensions, you put this there too

Normally, when creating a tenant with Apartment::Tenant.create, a new pg schema gets created. Then we need to load the tables' schema somehow. Normally schema.rb is used, but we don’t have one since we use structure.sql. To deal with situations when there’s no schema.rb, apartment offers an option to pg_dump (with --schema option) & restore the schema’s tables. No option to use structure.sql so far, probably because the topic is not yet sorted out on their side.

questions: how do you seed schema


-->

A list of random things you may want to know before you set out to implement schema-level

### Every migration needs to run for each tenant separately

Probably not a problem if you have 10 tenants. Brace yourself if you have 1000 tenants. Also the default behaviour in Apartment is that when a migration fails for one tenant the next ones are not attempted, and previous ones stay migrated. They're not reverted and not wrapped in a transaction. 

<!-- not even sure if it's possible to have a cross schema transaction. TODO: check. -->

### On schema-based multitenacy PostgreSQL extensions can no longer reside in public schema

If you use any extensions (like `pgcrypto`, `ltree`, `hstore`) you need to put them to a separate schema - e.g. `extensions` and always have it in the search_path (alongside the chosen tenant). In Apartment gem you do this via:

```ruby
Apartment.configure do |config|
  config.persistent_schemas = ["extensions"]
end
```

This is needed because of three conditions. (1) PG extensions have to be installed in a specific schema - normally they're in the `public` schema. Actually the extension is global, but its objects (like functions) need to belong to a specific schema. (2) An extension can only belong to one schema. (3) In order to use an extension, current `search_path` must include the schema which hosts this extension.

You can temporarily work it around by adding `public` to `persistent_schemas` which is obviously bad, but perhaps useful for a quick PoC. It won't take you very far - Rails will complain when making a migration which creates an index (Rails checks if the index already exists in the search path and it'll refuse to create it the tenant's schema).

TODO:

```sql
CREATE SCHEMA IF NOT EXISTS extensions;
ALTER EXTENSION pgcrypto SET SCHEMA extensions;
-- or
DROP EXTENSION pgcrypto;
CREATE EXTENSION pgcrypto SCHEMA extensions;
```

### PgBouncer transaction mode doesn't let you use search_path

Let's say you open up two Rails consoles:

```ruby
# On the first console, set the search path to another schema
ActiveRecord::Base.connection.execute("set search_path = tenant_123")

# On the second console, check the current schema
ActiveRecord::Base.connection.execute("show search_path").to_a
# => [{"search_path"=> ???}]
```

Of course normally on the second console you should just get `public` (or whatever is the default). The two consoles use separate DB connections and `set` only affects the current connection, so the effect from the first console shouldn't affect the second. Well, not always. If you run on PgBouncer and it's configured to anything else than _Session Mode_ (for example _Transaction Mode_), you can easily end up with `tenant_123` in the second console. You can also check `pg_backend_pid()` in each simultaneously open connection:

```ruby
ActiveRecord::Base.connection.execute("select pg_backend_pid()").to_a
# => [{"pg_backend_pid"=>4781}]
```
In _Session Mode_ you should get a different pid for each simultaneously open connection. In _Transaction Mode_ - not necessarily so.

PgBouncer has [3 pool modes](https://www.pgbouncer.org/features.html). Basically, to use any PostgresSQL session features (`search_path` being one of them), you need to run on _Session Mode_.

Double check if you're on a managed database. On Digital Ocean, for example, PgBouncer is part of the default setup, and _Transaction Mode_ is the recommended option. Understandable because of performance reasons, but quite a deal breaker for switching tenants via setting the `search_path`.

The obvious fix is to configure PgBouncer to _Session Mode_, but then you usually need to allocate significantly more connections in the PgBouncer pool, so that there's enough of them for each connection simultaneously opened from a Rails process. Mind web processes, jobs, threads. Also ad hoc processes (consoles, deployments).

Another potential alternative is to avoid `search_path` and use fully qualified table names in your queries (`select * from tenant_123.my_table`), which is described in another paragraph below.


### Other db connections need to be dealt with

Do you do another `establish_connection` to your multitenanted db? Why would anyone do that? You know, in legacy codebases there are weird things done for weird reasons. If that's the case - you need to account for it when switching the tenant. 

### Where do you put Delayed Jobs

Sure, not everyone uses Delayed Job with Active Record backend, but if you do, an interesting issue arises: where do you put the table with the jobs. In each tenants schema? This would mean you need to have a worker for every tenant. Or to hack the backend to keep polling tables from all schemas. The other solution is to put it to a shared table, for example in the `public` schema. Apartment facilitates shared tables by using qualified table names (`set_table_name` to `public.delayed_jobs` under the hood - which you can do by hand). You also need to specify the tenant in job's metadata. Initially we wanted to avoid shared tables (because KISS), but we eventually went for the 2nd solution.

```ruby
config.after_initialize do
  Delayed::Backend::ActiveRecord::Job.table_name = 'public.delayed_jobs'
end
```

### Where do you store your tenant list

A lot of people might wanna put it to the db to be able to manipulate it just as the rest of the models. But which schema? If you put it to `public`, all of your tenants' schemas will also have the tenants table (hopefully empty). Probably not a problem, but it's a little unsettling. If you think about it more, tenant management is logically a separate application and shouldn't be handled by the same Rails codebase, but a lot of people will do it for convenience reasons. Just beware of accruing to many hacks around that.

### What about migrations not meant per tenant?

Perhaps you'll rarely need it. If you do, you can either run the SQL script by hand (the traditional YOLO way), or have a guard statement:

```ruby
class AGlobalMigration < ActiveRecord::Migration[5.2]
  def change
    unless Apartment::Tenant.current == "public"
      puts "This migration is only meant for public schema, skipping."
      return
    end
    # ...
  end
end
```


### Rails vs PG schemas impedance

Rails is not really meant to be used with multiple schemas. On the surface it looks fine, but then there little nuances coming up. 

* `db/structure.sql`
* migrations per tenant or global


### Remember you have to multitenantize other 3rd party services

SQL DB is not everything.

**TODO**: not really schema-related.


### What is the role of the default schema?

Which is `public`.

### How do you write the tests

Mind: setting up a tenant in every test can be a costly operation. Perhaps there are other approaches.

### Do you in-memory cache/memoize anything that needs to be invalidated on tenant switch?

Apartment already deals with clearing AR's query cache. But we had other app-specific things memoized in memory. You can use apartment callbacks for it:

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

### Make sure to install the middleware above anything interacting with ActiveRecord

We used AR session store so we had to put the middleware above `ActionDispatch::Session::ActiveRecordStore`.

### Creating threads inside a request or job?

It won't have the `search_path` set:

```ruby
Apartment::Tenant.switch!("tenant_1")
p ActiveRecord::Base.connection.execute("show search_path").to_a
# => [{"search_path"=>"tenant_1"}]
Thread.new do
  p ActiveRecord::Base.connection.execute("show search_path").to_a
end
# => [{"search_path"=>"public"}]
```

You need to set it manually. Not sure if your code uses threads in a weird piece of code or lib? Setting pool size to 1 can help - you'll get an exception if that's the case. Not the best idea when you're on a threaded server, though.

### State of Apartment gem

* [`ros-apartment` fork](https://github.com/rails-on-services/apartment)
* ejecting


## Partial alternatives

**Sharding the db**.

**Ejecting Apartment**.

**The main disadvantage of search_path is its statefullness**. PG schemas are one thing. The other thing is how to switch them. The standard way is to use `search_path` - which is stateful (state resides in PG session), which brings about many of these pitfalls. Perhaps stateless schema-switching could be viable by using qualified table names: `SELECT * FROM my_schema.my_table`, which could be somehow hacked into AR's `set_table_name`. We haven't tried it, but it might be worth exploring. Apartments `exclude_models` relies on this to facilitate tables shared between tenants.

```ruby
def switch_tenant(new_tenant)
  ActiveRecord::Base.connection.execute("SET search_path TO #{ new_tenant }")
end
```

```ruby
# PoC, perhaps it's an overkill do it on each request. Also, thread safety.
# Alternative: monkey patch table name getter.
def switch_tenant(new_tenant)
  ActiveRecord::Base.descendants.each do |model|
    model.table_name = "#{ new_tenant }.#{ model.table_name }"
  end
end
```

TODO: Also, how do you ensure no stuff like raw sql bypasses that? Empty public schema?

TODO:

```ruby
class Product < ApplicationRecord
  establish_connection(ENV['DATABASE_URL'])

  # ...
end
```

## Feel like contributing to this blogpost?

TODO: link to contribute

Have comments? Reply here TODO: link to the tweet 

TODO: multitenancy landing

TODO: link to other blogposts
