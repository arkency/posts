---
title: "What I learnt today from reading gems' code"
created_at: 2017-06-23 08:11:27 +0200
kind: article
publish: true
author: Pankowecki
tags: [ 'chillout', 'sidekiq', 'gems', 'activesupport' ]
newsletter: :arkency_form
img: sidekiq-active_support-chillout-rails-metrics/pexels-photo-225769.jpeg
---

Today I was working on [chillout.io](http://get.chillout.io/) [client](https://github.com/chilloutio/chillout) and while I was debugging some parts, I had a look at some Ruby gems. This is always an interesting experience because you can learn how other developers design their API and how different it can be from your approach.

<!-- more -->

## Sidekiq

So here are some interesting bits from sidekiq code.

### Sidekiq::Client initializer

```
#!ruby
module Sidekiq
  class Client
    def initialize(redis_pool=nil)
      @redis_pool = redis_pool ||
      Thread.current[:sidekiq_via_pool] ||
      Sidekiq.redis_pool
    end
  end
end
```

Quoting the documentation:

> `Sidekiq::Client` normally uses the default Redis pool but you may
> pass a custom ConnectionPool if you want to shard your
> Sidekiq jobs across several Redis instances...

I generally don't like globals as a gem consumer but sometimes they are convenient and provide the convention over configuration magical feeling.

The nice thing about this global is that you don't need to use it. It is **easily overridable** with such constructor. If you have specific requirements, your own connection pool, special redis connection, multiple clients and multiple connections etc, etc, you can still get the work done.

```
#!ruby
Sidekiq::Client.new(ConnectionPool.new { Redis.new })
```

### Delegating class methods

Going further with global which you don't need to use.

```
#!ruby
module Sidekiq
  class Client
    def push(item)
      # ...
    end

    def self.push(item)
      new.push(item)
    end
  end
end
```

With this code, instead of

```
#!ruby
Sidekiq::Client.new().push(
  'queue' => 'one',
  'class' => MyWorker,
  'args'  => ['do_it']
)
```

you can do

```
#!ruby
Sidekiq::Client.push(
  'queue' => 'one',
  'class' => MyWorker,
  'args'  => ['do_it']
)
```

Again. No one forces you to use the class method. If for any reason, the first approach works better than the second, if you need to have a new instance with specific constructor arguments, do it. Sidekiq can handle both.

### Sidekiq.redis_pool

```
#!ruby
module Sidekiq
  def self.redis_pool
    @redis ||= Sidekiq::RedisConnection.create
  end

  def self.redis=(hash)
    @redis = if hash.is_a?(ConnectionPool)
      hash
    else
      Sidekiq::RedisConnection.create(hash)
    end
  end
end
```

This `redis=(hash)` setter can handle a `Hash` with redis configuration options or a `Sidekiq::ConnectionPool` instance.

### yielding for configuration

```
#!ruby
module Sidekiq
  def self.server?
    defined?(Sidekiq::CLI)
  end

  def self.configure_server
    yield self if server?
  end

  def self.server_middleware
    @server_chain ||= default_server_middleware
    yield @server_chain if block_given?
    @server_chain
  end

  def self.default_server_middleware
    Middleware::Chain.new
  end
end
```

Quoting the documentation:

> Sidekiq has a similar notion of middleware to Rack: these are small bits of code that can implement functionality. Sidekiq breaks middleware into client-side and server-side.
>
>  * **Server-side middleware** runs 'around' job processing.
>  * **Client-side middleware** runs before the pushing of the job to Redis and allows you to modify/stop the job before it gets pushed.

So the sidekiq client is the app (usually a Rails app) responsible for pushing jobs and scheduling them.

Sidekiq server is the worker process that execute on a different machine for processing jobs in the background.

Sidekiq needs to know which mode it is in, and it needs to have the ability to have different configurations for both of them. Especially considering that usually it is the same Rails application running either in client mode (http application server such as puma or unicorn) or server mode (worker process executed with `sidekiq` command).

The configuration can be set such as:

```
#!ruby
Sidekiq.configure_server do |config|
  config.redis = { namespace: 'myapp', size: 25 }
  config.server_middleware do |chain|
    chain.add MyServerHook
  end
end
Sidekiq.configure_client do |config|
  config.redis = { namespace: 'myapp', size: 1 }
end
```

So the `configure_server` method yields the block only when the if-statement evaluates we are in a server process. It uses block for lazy configuration. It is not evaluated when unnecessary (in the client).

`server_middleware` yields for nicer readability, I believe. Especially in the case of many middlewares.

BTW. [chillout.io](http://get.chillout.io/) [client](https://github.com/chilloutio/chillout) uses a middleware to schedule sending metrics when a background job is done.

## ActiveSupport

## ActiveSupport::TaggedLogging

`ActiveSupport::TaggedLogging` wraps any standard Logger object to provide tagging capabilities.

```
#!ruby
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged('BCX') { logger.info 'Stuff' }           # Logs "[BCX] Stuff"
logger.tagged('BCX', "Jason") { logger.info 'Puff' }   # Logs "[BCX] [Jason] Puff"
```

There is one method which brought my attention:

```
#!ruby
module ActiveSupport
  module TaggedLogging
    def flush
      clear_tags!
      super if defined?(super)
    end
  end
end
```

I've never seen this `super if defined?(super)` but it turns out it is useful to dynamically figure out if the ancestor defined given method and you should call it or this is the first module/class in inheritance chain which defines it.

```
#!ruby
class Fool
  def foo
    puts "foo from Fool"
  end
end

module Baron
  def bar
    puts "bar from Baron"
  end
end

module Bazinga
  def baz
    puts "baz from Bazinga"
    super if defined?(super)
  end
end

module Freddy
  def fred
    puts "fred from Freddy"
    super if defined?(super)
  end
end

class Powerful < Fool
  include Baron
  prepend Freddy

  def foo
    puts "foo from Powerful"
    super if defined?(super)
  end

  def bar
    puts "bar from Powerful"
    super if defined?(super)
  end

  def baz
    puts "baz from Powerful"
  end

  def fred
    puts "fred from Powerful"
  end

  def qux
    puts "qux from Powerful"
    super if defined?(super)
  end

  def corge
    puts "corge from Powerful"
    super
  end
end

p = Powerful.new
p.extend(Bazinga)

# inheritance
p.foo
# foo from Powerful
# foo from Fool

# module included in class
p.bar
# bar from Powerful
# bar from Baron

# object extended with module
p.baz
# baz from Bazinga
# baz from Powerful

# module prepended in class
p.fred
# fred from Freddy
# fred from Powerful

# nothing
p.qux
# qux from Powerful

# without `if defined?(super)`
p.corge
# corge from Powerful
# NoMethodError: super: no superclass method `corge' for #<Powerful:0x000000015e8390>
```

### self.new in a module

Also, check this out.

```
#!ruby
module ActiveSupport
  module TaggedLogging
    def self.new(logger)
      logger.formatter ||= ActiveSupport::Logger::SimpleFormatter.new
      logger.formatter.extend Formatter
      logger.extend(self)
    end
  end
end
```

`new` is not used to create a new instance of `TaggedLogging` (after all it is a module, not a class) that would delegate to the `logger` as one could expect based on the API. Instead it extends the `logger` object with itself.