---
title: "Rails connections, pools and handlers"
created_at: 2020-04-10 16:21:08 +0200
author: Tomasz Wróbel
tags: ['rails']
newsletter: skip
kind: article
publish: false
---

Speaking of connections in Active Record, we actually deal with three things: connections, connection pools and connection handlers. Here's how they relate to each other.

<!-- more -->

## Connection

This is what you most often directly interact with. You can get hold of it via `ActiveRecord::Base.connection` and, for example, use it to execute raw SQL:

```ruby
ActiveRecord::Base.connection.execute("select 1 as x").to_a
# => [{"x"=>1}]
```

If you're on PostgreSQL and inspect `connection`'s class, here's what you get:

```ruby
ActiveRecord::Base.connection.class            # => ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
ActiveRecord::Base.connection.class.superclass # => ActiveRecord::ConnectionAdapters::AbstractAdapter
```

## Connection pool

Connection pool is a bag with connections. Why do we need one? If you're using threads (e.g. on Puma server), every thread needs a separate db connection. Otherwise their conversations with the db could mix up. On the other hand, you want to control the number of db connections, because it typically increases the resources needed on the db server. That's why there's a pool of connections. If a thread wants to use AR, it gets a connection from the pool. If pool size is exceeded, `ActiveRecord::ConnectionTimeoutError` is raised.

You can get hold of it via `ActiveRecord::Base.connection_pool`. It's class:

```ruby
ActiveRecord::Base.connection_pool.class
# => ActiveRecord::ConnectionAdapters::ConnectionPool
```

You can list all your active connections:

```ruby
ActiveRecord::Base.connection_pool.connections
# => (an array with all active connections)
```

Note: this array can be empty - this can happen for example when you just started a console session and haven't yet interacted with AR.

Max pool size is controlled by the `pool` option in `config/database.yml`. By default it can be overridden by `ENV["RAILS_MAX_THREADS"]`. You can check max pool size via:

```ruby
ActiveRecord::Base.connection_pool.size                 # => 5
```

This number is not to be confused with the number of currently active connections:

```ruby
ActiveRecord::Base.connection_pool.connections.size     # => 1
```

When there's another connection in the pool? Open up a thread and talk to AR:

```ruby
User.count
Thread.new { User.count }
ActiveRecord::Base.connection_pool.connections.size     # => 2
```

Note: you may want to read about `with_connection` method. 

## Connection handler

```ruby
ActiveRecord::Base.connection_handler.class
# => ActiveRecord::ConnectionAdapters::ConnectionHandler
```

You can use it to get hold of all your pools:

```ruby
ActiveRecord::Base.connection_handler.connection_pools
# => (an array with all connection pools)
```

So if you wanna traverse the whole hierarchy, you end up with:

```ruby
ActiveRecord::Base.connection_handler.connection_pools.first.connections.first.execute("select 1 as a")
```

When can there be another connection pool? For example, when an AR model has it's own `establish_connection`:

```ruby
# TODO: example
```

TODOs

* `establish_connection` on AR subclasses; can be a problem especially when it's connected to the same database, because assumptions
* threads, max connections, exception, RAILS_MAX_THREADS
* rails version
* check in check out
* on fork
* counting number of threads
* when connection shows up in the list
* code create a thread and see another connection 
* code: create a thread and get pool exception
* spec.name
