---
title: Story of Postgres schema multitenancy told in 9 snippets of code
created_at: 2020-10-13T15:47:40.336Z
author: Tomasz Wróbel
tags: ['postgresql', 'multitenancy']
publish: false
---

# Story of Postgres schema multitenancy told in 9 snippets of code

> Find me on twitter [here](https://twitter.com/tomasz_wro). Also, check our upcoming free webinar: [Multitenancy Secrets](https://arkency.com/multitenancy-secrets/).

Let me tell you the story of how we implemented [Postgres-schema based multitenancy](https://blog.arkency.com/multitenancy-with-postgres-schemas-key-concepts-explained/) in one of the projects we dealt with. It was an existing single tenant system — [though definitions vary](https://twitter.com/tomasz_wro/status/1313506993852878852). We were meant to _multitenantize_ this system. That was the main precondition that made us pick schema-based approach, but overall, the [decision is not obvious](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/). We also went for the [Apartment gem](https://github.com/influitive/apartment), as it was the most mature and popular — but it's not currently maintained, so we ended up [on one of the forks](https://github.com/rails-on-services/apartment).

You can tell a story with a wall of text, but it's not optimal for everyone. For example, children would rather see some pictures. When it comes to programmers, I guess a lot of you will prefer a snippet of code rather than a wall of text. So let me build the story around those.

Please bear with the greek letters — I wanted to use something more fun than plain digits :)

### α

```ruby
def switch_tenant(new_tenant)
  ActiveRecord::Base.connection.execute("SET search_path TO #{new_tenant}")
end
```

Just to keep everyone on the same page — the simplified snippet above shows the most common solution to switch the tenant's schema in a Rails app. You basically set a special Postgres session variable whose scope is the current DB connection. This typically happens in a piece of middleware.

### β

```ruby
Rails.application.config.middleware.insert_before(
  Warden::Manager,
  Apartment::Elevators::Subdomain
)
```

Apartment integrates with Rails via middleware that switches the tenant as depicted in the first snippet, e.g. according to the subdomain of the current request. Just make sure you plug it in "high enough" in the middleware stack, so that any middleware that happens to contact the DB, is embraced by the tenant switch. In our case it was `ActionDispatch::Session::ActiveRecordStore`.

### γ

```ruby
Apartment.configure do |config|
  config.persistent_schemas = ["extensions"]
end
```

This is how you configure Apartment, to always append `extensions` schema to current `search_path` (which changes as you change tenants). `extensions` schema needs to contain your PostgreSQL extensions, like `hstore` or `ltree`, if you happen to use them.

### δ

```sql
CREATE SCHEMA IF NOT EXISTS extensions;
ALTER EXTENSION pgcrypto SET SCHEMA extensions;
-- or
DROP EXTENSION pgcrypto;
CREATE EXTENSION pgcrypto SCHEMA extensions;
```

This is how you move the extensions to the `extensions` schema. You probably need to move them, because typically they reside in `public` — the default schema. This may be more tricky than the above snippet — e.g. because of roles and ownership. Make sure you can do it on your DB setup.

### ε

```ruby
# On the first console, set the search path to another schema
ActiveRecord::Base.connection.execute("set search_path = tenant_123")

# On the second console, check the current schema
ActiveRecord::Base.connection.execute("show search_path").to_a
# => [{"search_path"=> ???}]
```

It's worth double checking what happens if you access the DB from another app process — you'd assume you're on another DB connection with an independent search_path — but this might not be the case, when, for example, you run PgBouncer in anything else than Session Mode. More [here](https://blog.arkency.com/multitenancy-with-postgres-schemas-key-concepts-explained/) and [here](https://blog.arkency.com/what-surprised-us-in-postgres-schema-multitenancy/).

### ζ

```ruby
config.after_initialize do
  Delayed::Backend::ActiveRecord::Job.table_name = 'public.delayed_jobs'
end
```

This is what you can do when you're on a SQL backed background job queue, like Delayed Job. You tell it to always put the jobs in a shared schema (`public` in this case), by using a fully qualified table name, which overrides `search_path`.

### η

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

This little snippet tells a couple things. First — a short reminder that your migrations will need to be run against every schema separately (consider time, errors and rollbacks). Second — if you need something like a global migration, you can make an ugly if. Third — employing Postgres schemas is sometimes at odds with Rails assumptions, which leads to some nuances. Mostly solvable, though. For example, what exactly should your `db/structure.sql` contain.

### θ

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

If you have any handcrafted in-memory caches in your app, make sure to invalidate them on tenant switch. That might be the case when you're transitioning an existing system.

### ι

```ruby
Apartment::Tenant.switch!("tenant_1")
p ActiveRecord::Base.connection.execute("show search_path").to_a
# => [{"search_path"=>"tenant_1"}]
Thread.new do
  p ActiveRecord::Base.connection.execute("show search_path").to_a
end
# => [{"search_path"=>"public"}]
```

If you spawn threads inside your requests or background jobs, make sure to set the `search_path` on their connections too. That should be pretty rare, but you don't want this to surprise you.

### κ

```ruby
class Product < ApplicationRecord
  establish_connection(ENV['DATABASE_URL'])

  # ...
end
```

Now this piece of code is even weirder — why would you set up another connection to the same DB? But I'm sure you know pretty well that a lot of weird things can be found in the legacy systems we deal with. We had such a situation, actually with a legitimate reason to it. It basically results in [another connection pool](https://blog.arkency.com/rails-connections-pools-and-handlers/), where you need to set the `search_path` too.

### λ

```ruby
# PoC, perhaps it's an overkill do it on each request. Also, thread safety.
# Alternative: monkey patch table name getter.
def switch_tenant(new_tenant)
  ActiveRecord::Base.descendants.each do |model|
    model.table_name = "#{ new_tenant }.#{ model.table_name }"
  end
end
```

Now this is a PoC — a way of switching tenants alternative to the default way described in the first snippet. If you've followed along, you could see that a lot of the issues we had were related to _statefullness_ of the `search_path`. Or, more precisely, to the fact that current state lives in a DB connection. Keeping this piece of state in-process could make the solution more robust. We haven't tried this in production, but I can imagine going for it under special circumstances.
