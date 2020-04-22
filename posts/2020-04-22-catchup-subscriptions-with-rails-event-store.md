---
title: "Catchup subscriptions with Rails Event Store"
created_at: 2020-04-22 17:25:51 +0200
author: Mirosław Pragłowski
tags: ['ddd', 'events', 'rails event store']
publish: false
---

The usual way of handling domain events in Rails Event Store is using the included pub-sub mechanism. And in most cases, especially when you have majestic monolith application it is enough. It is also easiest to grasp by the team and use in legacy applications implemented using Rails Way. But sometimes it is not enough, sometimes this way of handling events become an obstacle.

<!-- more -->

Let me define the domain problem. The feature we want to implement is described by requirements:

* every time a blog post is published its metadata (slug, title, time of creation, author, tags) should be sent to external system to index our articles
* when blogpost is updated the metadata in external index must be also updated

At the beginning it looks very simple. And a first, naive, implementation of this requirements could look like:

Let's start with new Rails application with RailsEventStore template:

```bash
rails new -m https://railseventstore.org/new blog.yourdomain.com
```

Then let's create a modules (bounded contexts) because we don't want to end up in Big Ball Of Mud quickly:

```bash
rails generate bounded_context:bounded_context blogging
rails generate bounded_context:bounded_context index
```

Next, we need to define domain events, implement the blogging logic (omitted here because that's different topic for another post):

File ./blogging/lib/blogging.rb

```ruby
module Blogging
  class ArticlePublished < RailsEventStore::Event
    # ... the schema of events should be defined here
  end

  class ArticleChanged < RailsEventStore::Event
    # ... and here ;)
  end
end
```

Define subscriptions, to connect our domain events to handlers:

File: ./config/initializers/rails_event_store.rb

```ruby
Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    dispatcher: RubyEventStore::ComposedDispatcher.new(
      RailsEventStore::AfterCommitAsyncDispatcher.new(
        scheduler: RailsEventStore::ActiveJobScheduler.new),
      RubyEventStore::Dispatcher.new
    )
  )
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Rails.configuration.event_store.tap do |store|
    store.subscribe(Index::PushArticleToIndex,
      to: [
        Blogging::ArticlePublished,
        Blogging::ArticleChanged,
      ]
    )
  end
end
```

And finally our handler to send articles to external indexing service:

File: ./index/lib/index/publish_article_to_index.rb

```ruby
module Index
  class PushArticleToIndex < ActiveJob::Base
    prepend RailsEventStore::AsyncHandler

    def initialize(index_adapter = Rails.configuration.index_adapter)
      @index = index_adpater
    end

    def perform(event)
      @index.push(build_index_data(event))
    end

    private
    def build_index_data(event)
      # ... does not matter here, some hash probably ;)
    end
  end
end
```

## A few things to notice

### 1st: embrace async!

The `Index::PushArticleToIndex` is asynchronous event handler. It is inherited from `ActiveJob::Base` and implements `perform(event)` method. This will allow to use it by `RailsEventStore::ActiveJobScheduler` and schedule sending to an index asynchronously, without blocking the execution of main logic. Because we do not want to fail publishing our new article just because indexing service is down :)

### 2nd: beware of transaction rollbacks!

Some background jobs adapters (i.e. Sidekiq) use Redis to store information about scheduled jobs. That's why we should change default dispatcher in Rails Event Store client to `RailsEventStore::AfterCommitAsyncDispatcher`. It ensures that the async handlers will be scheduled only after commit of current database transaction. Your handlers won't be triggered when transaction is rolled back.

### 3rd: subscribing to async handers is different

Rails Event Store uses `call(event)` method to invoke an event handler's logic. By default you need to pass a callable instance of handler or lambda to `subscribe` method. But this is not the same when using `RailsEventStore::ActiveJobScheduler`. If you want to have your handler processed by this scheduler it must be a class and must inherit from `ActiveJob::Base`. Otherwise (thanks to the `RubyEventStore::ComposedDispatcher`) it will be handed by default `RubyEventStore::Dispatcher`.

## Where is the drawback?

This solution has some drawback. Let's imagine that your blogging platform become extremely popular and you need to handle hundreds of blog posts per second. That's to async processing you might event be able to cope with that. But then your index provider accounted it has ended his "amazing journey" and you need to move your index to a new one. Do I have to mention that your paying customers expect the platform will work 24/7 ? ;)

## Making things differently

Catchup subscription is a subscription where client defines a starting point and a size of dataset to handle. Basically it's a while loop reading through a stream of events with defined chunk size.
It could be a separate process, maybe even on separate node which we will spin on only to handle incoming events and push the articles to the external index provider.

### First things first

The catchup subscription is easy to implement when you read from a single stream. But your `Blogging` context should not put all events into single stream. That's obvious.
In this case we could use [linking to stream](https://railseventstore.org/docs/link/) feature in Rails Event Store.

Change file: ./config/initializers/rails_event_store.rb

```ruby
Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    dispatcher: RubyEventStore::ComposedDispatcher.new(
      RailsEventStore::AfterCommitAsyncDispatcher.new(
        scheduler: RailsEventStore::ActiveJobScheduler.new),
      RubyEventStore::Dispatcher.new
    )
  )
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Rails.configuration.event_store.tap do |store|
    store.subscribe(Index::LinkToIndex.new(store),
      to: [
        Blogging::ArticlePublished,
        Blogging::ArticleChanged,
      ]
    )
  end
end
```

And instead of file: ./index/lib/index/publish_article_to_index.rb use ./index/lib/index/link_to_index.rb:

```ruby
module Index
  class LinkToIndex
    def initialize(event_store)
      @event_store = event_store
    end

    def call(event)
      @event_store.link(event.event_id, "indexable-articles")
    end
  end
end
```

This time we will use simple synchronous handler. Thanks to `RubyEventStore::ComposedDispatcher` we do not need to change anything. It won't match the handlers handled by `RailsEventStore::ActiveJobScheduler` so default `RubyEventStore::Dispatcher` will trigger the event handler.

## Implementing catchup subscription

When started, the catchup subscription should start reading from the last processed event and handle read events (pushing them to the external index).

Here a sample implementation:

```ruby
module Index
  class PushArticlesToIndex
    def initialize(event_store, index_adapter, chunk_size = 1000)
      @event_store = event_store
      @index = index_adpater
      @chunk_size = chunk_size
    end

    def call(starting_point = determine_starting_point)
      while(!(events = fetch_from(starting_point)).empty?)
        events.each do |event|
          @index.push(build_index_data(event))
          store_processed(event.event_id)
        end
      end
    end

    private
    def fetch_from(event_id)
      scope = @event_store.read
        .stream('indexable-articles')
      scope = scope.from(event_id) if event_id
      scope.limit(@chunk_size)
    end

    def determine_starting_point
      # ... read last processed event id
    end

    def store_processed(event_id)
      # ... store processed event id
    end

    def build_index_data(event)
      # ... does not matter here, some hash probably ;)
    end
  end
end
```

### Why separate process?

Let's start with cons of this solution. The obvious one is you need a separate process :) Maybe with separate deployment, separate CI etc. Probably more time will pass between publication of article and indexing it. So why bother?

### Rebuilding an index

The external index is basically a read model of your articles metadata. Tailor made, aligned with capabilities of external index provider. **Recreateable.**

This is what make a difference here. To rebuild an index from scratch all you need to do is to remove stored starting point for the catchup subscription and wait some time. The indexing will start from beginning and will go though all published articles until index will be up to date.

### But there is more!

I've mention before a scenario where you change external index provider. Using catchup subscription it will be quite easy. Just create new instance of the subscription process with different index adapter. Run it and wait until it catch up and index all published articles. And then just switch your application to new external index and drop old subscription.
