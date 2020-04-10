---
title: "3 ways to make your ruby object thread-safe"
created_at: 2018-09-18 11:38:49 +0200
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'thread-safe' ]
newsletter: arkency_form
---

Let's say you have an object and you know or suspect it might be used (called) from many threads. What can you do to make it safe to use in such a way?

<!-- more -->

## 1. Make it stateless & frozen

Here is the most basic approach which is sometimes the easiest to go with and also very safe.
Make your object _state-less_. In other words, forbid an object from having any long-term internal state.
That means, use only local variables and no instance variables (`@ivars`).

To be sure that you are not accidentally adding state, you can freeze the object. That way it's going to raise an exception if you ever try to refactor it.

```ruby
class MyCommandHandler
  def initialize
    make_threadsafe_by_stateless
  end
  
  def call(cmd)
    local_var = cmd.something
    output(local_var)
  end
  
  private
  
  def make_threadsafe_by_stateless
    freeze
  end
  
  def output(local_var)
    puts(local_var)
  end
end

CMD_HANDLER = MyCommandHandler.new
```

Since your object does not have any local state it can be freely used between multiple threads.
It's ok for example to use the same instance when processing different requests in a threaded application server such as Puma.

You can assign `MyCommandHandler.new` to a global variable or pass as a dependency to objects created in different threads and things should be fine. 

If someone from your team tries to refactor the code to: 

```ruby
class MyCommandHandler
  def initialize
    make_threadsafe_by_stateless
  end
  
  def call(cmd)
    @ivar = cmd.something
    output
  end
  
  private
  
  def make_threadsafe_by_stateless
    freeze
  end
  
  def output
    puts(@ivar)
  end
end
```

they are going to get an exception `can't modify frozen MyCommandHandler` unless they remove `make_threadsafe_by_stateless` in which case it's a conscious decision, not an accidental one.

For years I struggled a bit when thinking about thread-safety and which objects can be used between threads and which can't be and whether I need to make something thread-safe or not. Later I realized it's not as much about a single object's properties but rather about a graph of objects.

Imagine a situation like this:

```ruby
class MyCommandHandler
  def initialize(repository, adapter)
    @repository = repository
    @adapter = adapter
    make_threadsafe_by_stateless
  end
  
  def call(cmd)
    obj = @repository.find(cmd.id)
    obj.do_something
    @repository.update(obj)
    @adapter.notify(SomethingHappened.new(cmd.id))
  end
  
  private
  
  def make_threadsafe_by_stateless
    freeze
  end
end

CMD_HANDLER = MyCommandHandler.new(Repository.new, Adapter.new)
```

If `CMD_HANDLER` is used between multiple threads, then its dependencies are as well.
That means that thread-safety is more a property for a graph of objects (object and its dependencies and their dependencies etc) rather than a property of a single object.

In this case, it's not enough that `MyCommandHandler` is stateless and thread-safe. Its dependencies should be as well for the whole solution to work properly.

## 2. Use thread-safe structure for local state

If you know that an object can be used between multiple threads you can compartmentalize its state per thread. For that you can use `ThreadLocalVar` from `concurrent-ruby` project:

> ThreadLocalVar: Shared, mutable, isolated variable which holds a different value for each thread which has access. Often used as an instance variable in objects which must maintain different state for different threads

```ruby
require 'concurrent'

class Subscribers
  def initialize
    @subscribers = Concurrent::ThreadLocalVar.new{ [] }
  end

  def add_subscriber(subscriber)
    @subscribers.value += [subscriber]
  end
  
  def notify
    @subscribers.value.each(&:call)
  end
  
  def remove_subscriber(subscriber)
    @subscribers.value -= [subscriber]
  end
end

SUBSCRIBERS = Subscribers.new
```

`SUBSCRIBERS` can be used from within different threads because its state is different for every thread that uses it. `@subscribers.value` is a different `Array` for every thread. This might be useful and what you want/expect. But it also might not.

In [RailsEventStore](http://railseventstore.org/) we use this pattern to keep a list of short-term handlers interested in events published by the current thread. For example, an import process can collect stats about the number of `ProductImported` and `ProductImportErrored` events that occur when parsing and processing an XLSX file.

## 3. Protect the state with mutexes

In this approach, the object's state is shared between all threads but the access is limits to a single thread at once.

```ruby
require 'thread'

class Subscribers
  def initialize
    @semaphore = Mutex.new
    @subscribers = []
  end

  def add_subscriber(subscriber)
    @semaphore.synchronize do
      @subscribers += [subscriber]
    end
  end
  
  def notify
    @semaphore.synchronize do
      @subscribers.each(&:call)
    end
  end
  
  def remove_subscriber(subscriber)
    @semaphore.synchronize do
      @subscribers -= [subscriber]
    end
  end
end

SUBSCRIBERS = Subscribers.new
```

Although to be honest, I am not sure if `synchronize` is needed for a method which does not change the state such as `notify`... ([discussion on reddit](https://www.reddit.com/r/ruby/comments/9gvn48/3_ways_to_make_your_ruby_object_threadsafe/e67cemw/))

But instead of going that way, you might prefer to use already existing classes such as [`Concurrent::Array`](http://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/Array.html) and going with the previous method.

> A thread-safe subclass of Array. This version locks against the object itself for every method call, ensuring only one thread can be reading or writing at a time. This includes iteration methods like #each.

```ruby
require 'concurrent'

class Subscribers
  def initialize
    @subscribers = Concurrent::Array.new
  end

  def add_subscriber(subscriber)
    @subscribers << subscriber
  end
  
  def notify
    @subscribers.each(&:call)
  end
  
  def remove_subscriber(subscriber)
    @subscribers.delete(subscriber)
  end
end

SUBSCRIBERS = Subscribers.new
```

## 4. Bonus: New instance per usage

Your object does not need to be explicitly made thread safe if:

* you don't share it between threads ;)
* ie. by always creating a new instance when it's needed

```ruby
class MyCommandHandler
  def initialize(repository, adapter)
    @repository = repository
    @adapter = adapter
  end
  
  def call(cmd)
    @obj = @repository.find(cmd.id)
    @obj.do_something
    @repository.update(@obj)
    @adapter.notify(SomethingHappened.new(cmd.id))
  end
end

CMD_HANDLER = -> (cmd) { MyCommandHandler.new(Repository.new, Adapter.new).call(cmd) }
```

Here, in case our application threads use `CMD_HANDLER.call(...)` then we don't need to worry about thread-safety because every time we need `MyCommandHandler`, we instantiate a new object with the whole dependency tree. The dependencies (`repository, adapter`) can use any of the mentioned techniques to be thread-safe as well, or they can be new instances as well.

And here lies the reason that many classes are not thread-safe in Ruby by default. They are simply not expected to be used from multiple threads. The authors did not imagine such use-case for them. That's OK. The bigger issue, in my opinion, is that it's often hard to find info about classes coming from some gems about their thread-safety.

### Would you like to continue learning more?

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our every day struggles and solutions for building maintainable Rails apps which don't surprise you.

You might enjoy reading:

* [Ruby Event Store - use without Rails](/ruby-event-store-use-without-rails/) - did you know you can use RailsEventStore without Rails by going with RubyEventStore :)
* [Relative Testing vs Absolute Testing](/relative-testing-vs-absolute-testing/) - 2 modes of testing that you can switch between to make writing tests easier.
* [Using ruby parser and the AST tree to find deprecated syntax](/using-ruby-parser-and-ast-tree-to-find-deprecated-syntax/) - when grep is not enough for your refactorings.
* [Big events vs Small events - from the perspective of refactoring](/big-events-vs-small-events-from-the-perspective-of-refactoring/) - _after working for several years in an event sourced system, Andrew noticed many problems connected with big events_

**Also, make sure to check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.**

