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


## 1. PostgreSQL extensions need to live in a separate schema

```ruby
Apartment.configure do |config|
  config.persistent_schemas = ["extensions"]
end
```

## 2. Migrating the extensions may be tricky

```sql
CREATE SCHEMA IF NOT EXISTS extensions;
ALTER EXTENSION pgcrypto SET SCHEMA extensions;
-- or
DROP EXTENSION pgcrypto;
CREATE EXTENSION pgcrypto SCHEMA extensions;
```

## 3. If there's PgBouncer, it needs to run in Session Mode

```ruby
# On the first console, set the search path to another schema
ActiveRecord::Base.connection.execute("set search_path = tenant_123")

# On the second console, check the current schema
ActiveRecord::Base.connection.execute("show search_path").to_a
# => [{"search_path"=> ???}]
```

## 4. If on a SQL-backed queue (like Delayed Job), you need a shared table

```ruby
config.after_initialize do
  Delayed::Backend::ActiveRecord::Job.table_name = 'public.delayed_jobs'
end
```

## 5. Migrations run for every tenant, obviously

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

## 6. Make sure to invalidate in-memory caches when switching tenants

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

## 7. If you run threads inside requests or background jobs...

```ruby
Apartment::Tenant.switch!("tenant_1")
p ActiveRecord::Base.connection.execute("show search_path").to_a
# => [{"search_path"=>"tenant_1"}]
Thread.new do
  p ActiveRecord::Base.connection.execute("show search_path").to_a
end
# => [{"search_path"=>"public"}]
```


## 8. Are you sure there's only one Connection Pool in your app?

```ruby
class Product < ApplicationRecord
  establish_connection(ENV['DATABASE_URL'])

  # ...
end
```
