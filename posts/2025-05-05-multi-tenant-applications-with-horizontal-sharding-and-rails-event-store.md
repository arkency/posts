---
created_at: 2025-05-05 13:17:49 +0200
author: Mirosław Pragłowski
tags: ["multitenancy", rails_event_store', "database", "sharding", "rails"]
publish: false
---

# Multi tenant applications with horizontal sharding and Rails Event Store

Horizontal sharding has been introduced in Rails 6.0 (just the API, with later additions to support automatic shard selection). This enables us to easily build multi tenant applications with tenant's data separated in different databases. In this post I will explore how to build such an app with separate event store data for each tenant.

<!-- more -->

## Application idea

Let's sketch some non-functional requirements for our sample application.

- First: all tenant data is separated into a shard database,
- Second: tenant's management, shared data, cache & queues use a single shared database (admin's application),
- Third: embrace async, all event handlers will be async and implemented using Solid Queue,
- Fourth: each tenant uses separate domain.

And one last thing ... the tenant database setup will be static, defined in `config/database.yml` file. This means to add a new tenant requires database setup, config file update & application deployment.

So after generating new Rails 8 application let's make it work.

## Database configuration

[Rails documentation](https://guides.rubyonrails.org/v8.0/active_record_multiple_databases.html#horizontal-sharding) provides a very good description of how to configure your application to use horizontal sharding.

What you have to do is to define all shards (remember the `primary` one for the `default` shard, which we will use for the admin data) in each of the application environments.

Our application's `config/database.yml` file will look like this:

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  primary:
    <<: *default
    database: storage/development.sqlite3
    migrations_paths: db/migrate
  cache:
    <<: *default
    database: storage/development_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/development_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: storage/development_cable.sqlite3
    migrations_paths: db/cable_migrate
  arkency:
    <<: *default
    database: storage/development.arkency.sqlite3
    migrations_paths: db/shards
  railseventstore:
    <<: *default
    database: storage/development.railseventstore.sqlite3
    migrations_paths: db/shards
```

Remember to specify migration paths, or you'll end up with your schema messed up.

### Database schema

To create/setup/migrate the database you use the typical Rails database tasks.

By default the Rails tasks run for all shards. If you want to run it on a single shard just add a shard name after `:` to the task name, like in the example:

```
bin/rails db:migrate:<shard_name>
```

To generate migrations for a specific shard use the `--database` parameter to specify the shard where the generated migration should be executed:

```
bin/rails generate migration XXXX --database=<shard_name>
```

## Define models

Because we have a mix of ActiveRecord models, some reaching the `primary` shard for tenant's & shared data, and others used only to read/write to specific shards (just tenant's business data) we need to define different base abstract classes for this 2 kinds of model classes.

Mark you "default" base class with `primary_abstract_class` and sets it to always connect to the `primary` database (`default` shard).

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  connects_to database: { writing: :primary, reading: :primary }
end
```

For the sharded models we have to define the base class as:

```ruby
class ShardRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    arkency: { writing: :arkency, reading: :arkency },
    railseventstore: { writing: :railseventstore, reading: :railseventstore }
  }
end
```

Remember to add an entry here when a new tenant is defined.

## Rails Event Store setup

Having defined the shard and an abstract base class that allows us to connect to a selected shard (how it is selected will be explained below) we could setup our `RailsEventStore::Client` instance.

There are three things to notice in the RES setup that are not typical ones.

### 1st: Event repository

We have to define the RES repository as an instance of `RubyEventStore::ActiveRecord::EventRepository` with specific `model_factory`. The `ShardRecord` should be used here as the abstract base class. This will allow RES to connect to a specific shard database.

### 2nd: Asynchronous dispatcher

In the RES documentation the `RailsEventStore::AfterCommitAsyncDispatcher` is recommended to be used if you want to handle domain events asynchronously. However since Rails has introduced `enqueue_after_transaction_commit` in the `ActiveJob::Base` all we need is:

```ruby
class ApplicationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true
end
```

and then just `RubyEventStore::ImmediateAsyncDispatcher` with `RailsEventStore::ActiveJobScheduler` is enough.

... which is very convenient, as `RailsEventStore::AfterCommitAsyncDispatcher` does not check what database it is connected to :(

### 3rd: Store shard in domain event's metadata

The app uses an automatic shard selector & resolver (Rails feature). However this works only within the scope of a web request. All asynchronously executed application jobs, scripts, etc need to manually select the valid shard. That's why the current shard is stored in each domain event's metadata.

This information will be used in the event handlers. First to connect to the valid shard - the same as the handled domain event. Second to set up the RES client's metadata to keep the shard information in all domain events published by the event handler. This is implemented in the `ShardedHandler` module.

```ruby
module ShardedHandler
  def perform(event)
    shard = event.metadata[:shard] || :default
    ActiveRecord::Base.connected_to(role: :writing, shard: shard.to_sym) do
      Rails
        .configuration
        .event_store
        .with_metadata(shard: shard) { super }
    end
  end
end
```

### RES setup

The complete setup of `RailsEventStore::Client` looks like this:

```ruby
Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RubyEventStore::ActiveRecord::EventRepository.new(
      model_factory: RubyEventStore::ActiveRecord::WithAbstractBaseClass.new(ShardRecord),
      serializer: JSON,
    ),
    dispatcher: RubyEventStore::ComposedDispatcher.new(
      RubyEventStore::ImmediateAsyncDispatcher.new(
        scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: JSON)
      ),
      RubyEventStore::Dispatcher.new
    ),
    request_metadata: ->(env) do
      request = ActionDispatch::Request.new(env)
      { remote_ip: request.remote_ip, request_id: request.uuid, shard: ShardRecord.current_shard.to_s }
    end,
  )
end
```

## Automatic shard selection

[Rails documentation](https://guides.rubyonrails.org/active_record_multiple_databases.html#activating-automatic-shard-switching) describes how the Rails framework allows to define automatic database/shard selection.

First generate an initializer class using:

```
bin/rails g active_record:multi_db
```

In the sample application we need to modify it to match our needs.

```ruby
Rails.application.configure do
  config.active_record.shard_selector = { lock: false, class: "ShardRecord" }
  config.active_record.shard_resolver = ->(request) { Tenant.find_by(host: request.host)&.shard || :default }
end
```

We set `shard_selector` to use the `ShardRecord` class as the source of information about defined shards. The `lock: false` allows the application to read from multiple shards at the same time (we need to manually handle that - details how to do it are described in [Rails documentation](https://guides.rubyonrails.org/active_record_multiple_databases.html#using-manual-connection-switching)).

Rails documentation advises:

> For tenant based sharding, lock should always be true to prevent application code from mistakenly switching between tenants.

However we have the requirement to keep shared data in a separate database and only keep tenant's business data in its shards. That's why we allow switching shards.

The `shard_resolver` is very simple here - just use the request's host name to find the tenant in shared database and then use its `shard` method to find out which shard the tenant's data should be stored or read from.

## Event handlers

Rails handles shard selection for us during a web request. But as I've mentioned before this will not work in asynchronously processed application jobs - event handlers. RailsEventStore already defines async handler helper modules `RailsEventStore::AsyncHandler` to handle domain event asynchronously and `RailsEventStore::CorrelatedHandler` to ensure traceability by defining correlation & causation ids for published events. By defining (above) the `ShardedHandler` module we ensure the event handler code is executed using a valid shard connection and that each published domain event will still have shard information in event's metadata.

```ruby
class LogVisitsByIp < ApplicationJob
  prepend ShardedHandler
  prepend RailsEventStore::CorrelatedHandler
  prepend RailsEventStore::AsyncHandler

  def perform(event)
   ...
  end
end
```

By prepending the event handler's code with this 3 modules we have clean code, free from infrastructure "plumbing".

### Using SolidQueue

Because we have application jobs executing using a tenant's shard connection and we want to avoid separate queues for each tenant the setup of queue connections have to be defined:

It is set in `config/environments/<env>.rb` files. For each shard (including default) we have to define the database where SolidQueue will connect to.

```ruby
  ...
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = {
    shards: {
      default: { writing: :queue },
      arkency: { writing: :queue },
      railseventstore: { writing: :queue }
    }
  }
  ...
```

## Summary

The complete sample application for this post can be found in [RES examples repository](https://github.com/RailsEventStore/examples/tree/master/horizontal-sharding). You might also like my previous post, with [different way of separating data in Rails application](https://blog.arkency.com/rails-multiple-databases-support-in-rails-event-store/).
