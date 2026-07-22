---
created_at: 2026-07-17 17:47:40 +0200
author: Jakub Kosiński
tags: ['rails event store', 'transactional outbox', 'durable delivery', 'at least once']
publish: false
---

# Durable event delivery for your asynchronous subscribers


When your web application grows, you often start seeing that some of your endpoints' response times are not satisfactory anymore. One of the possible solutions for this problem is to move some parts of the endpoint logic outside the main request-response cycle. Usually you start to implement some asynchronous jobs that are executed by a separate process outside your web server. Similarly, when you are using [RailsEventStore](https://railseventstore.org) with only synchronous handlers you may find them taking too long to execute and you start moving them to asynchronous ones.
Usually, in order to prevent failures caused by starting jobs too early (before the transaction that enqueues jobs commits or in case of a rollback), most developers start enqueueing jobs in the after commit callback. The same approach may be used with asynchronous handlers using RailsEventStore's `AfterCommitDispatcher` configured with e.g. `RailsEventStore::ActiveJobScheduler`. The sequence diagram below illustrates the flow for such a scenario:

<img class="w-full" src="<%= src_fit("durable-event-delivery/without-outbox.png") %>" width="70%">

<!-- more -->

## The problem with after commit

This simple flow allows you to postpone enqueuing handlers until after the main transaction is committed so you don't need to care about errors from your workers that tried to load entities that were not written to the database yet or - even worse - have loaded stale state from the DB (as the up-to-date one has not been committed yet). But there is one serious issue with this solution - you cannot guarantee that your code executed after the commit will always execute successfully. There are many things that may fail here, including network errors, out-of-memory issues, Redis running out of space and many other things that may happen, and as a result you end up with an inconsistent state of the whole system - your business logic was executed, domain events were published but some or all side effects failed:

<img class="w-full" src="<%= src_fit("durable-event-delivery/after-commit-issue.png") %>">

## Transactional outbox

In most cases you would like to achieve durable event delivery - once you subscribe to an event, you want the handler to be called _at least once_ for each event, without losing any of them. One of the patterns that solves this problem in distributed systems is the [transactional outbox](https://microservices.io/patterns/data/transactional-outbox.html), where we store events or messages that need to be sent to a message broker in the database as a part of the same transaction that executes the business logic. Then we add a separate message relay process that reads those events and delivers them to the broker.

### The simplest RailsEventStore outbox 

If you want to implement the transactional outbox pattern in your application that uses RailsEventStore and Sidekiq for running asynchronous handlers, there is a [`ruby_event_store-outbox`](https://github.com/RailsEventStore/rails_event_store/tree/master/contrib/ruby_event_store-outbox) gem that helps you achieve this. However, it works only with Sidekiq and requires a new table where you serialize the whole event with full payload in a format Sidekiq understands. Then you run a separate process that reads data from that table and sends it to Redis. Once events are marked as sent to Redis (where Sidekiq workers will take them from), they are periodically removed from the database by a cleanup task.

### A better RailsEventStore outbox

If you want to have less overhead and more configuration, we have something for you - a new `ruby_event_store-outbox_relay` gem that doesn't require dual-write and needs only a new column added to your `event_store_events` table. It's designed to work with SQLite, MySQL 8+ and PostgreSQL. The new column `published_at` stores the timestamp when a specific event has been delivered to a message broker - so you can measure the latency to find out if you need to scale your message relay up. The message relay uses a `SELECT … FOR UPDATE SKIP LOCKED` clause with MySQL and PostgreSQL, which lets many relay processes run in parallel.

The new gem modifies only the handling of asynchronous handlers - your temporary or synchronous handlers work the same way as before.

<img class="w-full" src="<%= src_fit("durable-event-delivery/outbox-relay.png") %>">

For asynchronous subscribers, the message relay process fetches unpublished events from the database and dispatches them to the broker. Once a broker accepts events, they are marked as published. Events are read in the global position order so if you are using only a single relay process, they are delivered to a broker in the same order as they were published. Please note that they don't need to be handled in the same order, though. All event metadata is preserved so you won't lose your `correlation_id`, `causation_id` and other metadata. If a broker fails, events are re-read in the next loop. This guarantees at least once delivery, so it's your responsibility to make your handlers idempotent as they might be called more than once with the same event. To enable idempotency, you may e.g. store processed event IDs for some time and use them as the idempotency key.

By default, `ruby_event_store-outbox_relay` uses a broker configured with `ImmediateDispatcher` and `ActiveJobScheduler`. When a relay processes an event, it checks which handlers are subscribed to a specific event type and pushes new jobs to the corresponding `ActiveJob` queues. Once jobs are enqueued, events are marked as published and another cycle of the relay loop is executed. You can also bring your own broker and dispatch your events to Apache Kafka or another event streaming platform.

#### Everything comes with a cost

As always, this gem has some trafe-offs you need to know. It uses an infinite loop where we poll the database for new unpublished events. This means your database server will have an additional constant load so you might need to increase resources on your DB server. Polling will also add a small latency to your handlers.

Another important thing you should know is to use `ImmediateDispatcher` in the relay process - if you use `AfterCommitDispatcher` in the relay, there would be no transactional outbox as your events would still be sent outside the transaction. Another thing is adding the outbox to an existing application - the migration that adds the `published_at` column has a default value set to the current timestamp - we have added this in order to assume all existing events as „published" - the gem modifies the code that inserts new events into the database so that the `published_at` column is explicitly set to `NULL` for newly published events.

#### Show me the code

If you'd like to start using this in your application, there are only a few changes from the regular setup you need to make.

1. You should differentiate how you subscribe events - now you should explicitly use `subscribe_sync` (or `subscribe`) to define synchronous handlers and `subscribe_async` for asynchronous ones. 
2. You need to create a configuration file for the relay process.

You can find an example you can use in your Rails application below:

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new.tap do |event_store|
      event_store.subscribe_sync(OrderLogger, to: [OrderPlaced, OrderCompleted])
      event_store.subscribe_async(OrderNotifier, to: [OrderCompleted])
    end
    # ...
  end
end

# config/outbox_relay.rb

require_relative './boot'
require_relative './application'
require "ruby_event_store/outbox_relay"

RubyEventStore::OutboxRelay::Configuration.configure do |batch_size:, poll_interval:, logger:|
  RubyEventStore::OutboxRelay::Relay.new(
    client: Rails.configuration.event_store,
    batch_size: batch_size,
    poll_interval: poll_interval,
    logger: logger,
  )
end
```

You can run the relay process as a rake task:

```
OUTBOX_RELAY_ARGS="--require=config/outbox_relay.rb --database-url=$DATABASE_URL" bundle exeec rake ruby_event_store:outbox_relay:run
```

or using the `res_outbox_relay` command:

```
bundle exec res_outbox_relay --require=config/outbox_relay.rb --database-url="$DATABASE_URL"
```

If your application needs durable event delivery for your asynchronous subscribers, `ruby_event_store-outbox_relay` is definitely something you should try!