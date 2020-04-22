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
ActiveRecord::Base.connection.execute("select 1 as a").to_a
# => [{"a"=>1}]
```

If you're on PostgreSQL and inspect `connection`'s class, here's what you get:

```ruby
ActiveRecord::Base.connection.class
# => ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
ActiveRecord::Base.connection.class.superclass
# => ActiveRecord::ConnectionAdapters::AbstractAdapter
```

## Connection pool

A bag with connections. You can access it via `ActiveRecord::Base.connection_pool`. It's class:

```ruby
ActiveRecord::Base.connection_pool.class
# => ActiveRecord::ConnectionAdapters::ConnectionPool
```

You can, for example, list all your active connections:

```ruby
ActiveRecord::Base.connection_pool.connections
# => (an array with all active connections)
```

This gives you your max number of connections (as defined by `pool` in `database.yml`, or `ENV["RAILS_MAX_THREADS"]`):

```ruby
ActiveRecord::Base.connection_pool.size
# => 5
```

This, on the other hand, gives you the number of connections currently in use:

```ruby
ActiveRecord::Base.connection_pool.connections.size
# => 1
# It can be `0` too - for example when you haven't yet interacted with AR
```

Why do we need a connection pool? If you're using threads, every one of them needs a separate db connection (otherwise their conversations with the db could mix up. On the other hand, you want to control the number of db connections, because it typically increases the resources needed on the db server.

TODO: when there's another connection in the pool? Open up a thread.

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
