---
title: "Rails connections, pools and handlers"
created_at: 2020-04-10 16:21:08 +0200
author: Tomasz Wróbel
tags: ['rails']
kind: article
publish: true
---

In Active Record there are db connections, connection pools and handlers. To put it shortly:

**Connection Handler** _has many_ **Connection Pools** _has many_ **Connections**

<%= img_fit("rails-connections-john-barkiple-l090uFWoPaI-unsplash.jpg") %>

<!-- more -->

## Connection

This is what you most often directly interact with. You can get hold of it via `ActiveRecord::Base.connection` and, for example, use it to execute raw SQL:

```ruby
ActiveRecord::Base.connection.execute("select 1 as x").to_a
# => [{"x"=>1}]
```

If you're on PostgreSQL and inspect `connection`'s class, here's what you get:

```ruby
ActiveRecord::Base.connection.class
# => ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
ActiveRecord::Base.connection.class.superclass
# => ActiveRecord::ConnectionAdapters::AbstractAdapter
```

## Connection pool

Connection pool is a bag with connections. Why do we need one? If you're using threads (e.g. on Puma server), every thread needs a separate db connection. Otherwise their conversations with the db could mix up.

On the other hand, you want to control the number of db connections, because it typically increases the resources needed on the db server. That's why there's a pool of connections. If a thread wants to use AR, it gets a connection from the pool. If pool size is exceeded, `ActiveRecord::ConnectionTimeoutError` is raised. See [Object pool pattern](https://en.wikipedia.org/wiki/Object_pool_pattern).

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

Now a plot twist: you can have many connection pools in your Rails app. Connection handler manages them.

```ruby
ActiveRecord::Base.connection_handler.class
# => ActiveRecord::ConnectionAdapters::ConnectionHandler
```

When can there be multiple connection pools? For example when there's an AR model which makes its own `establish_connection` - usually to another database. Note: each connection pool has its own max pool size.

You can use connection handler to get hold of all your pools:

```ruby
ActiveRecord::Base.connection_handler.connection_pools
# => (an array with all connection pools)
```

So if you wanna traverse the whole hierarchy, you end up with:

```ruby
ActiveRecord::Base
  .connection_handler
  .connection_pools.first
  .connections.first
  .execute("select 'Do not execute SQL on random connections' as helpful_hint")
```

### Want to contribute to this blogpost?

You can do it [right here](https://github.com/arkency/posts/edit/master/posts/2020-04-10-rails-connections-pools-and-handlers.md)!

### More resources

* [How rails sharding connection handling works](https://github.com/hsgubert/rails-sharding/wiki/How-rails-sharding-connection-handling-works)
* [Rails Connection Pool API doc](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html)

<!--
Todos
* forking processes
* adjusting pool size
-->
