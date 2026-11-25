---
created_at: 2026-11-25 23:15:40 +0100
author: Jakub Kosiński
tags: ['rails event store', 'transactional outbox', 'durable delivery', 'at least once']
mermaid: true
publish: false
---

# Durable event delivery for your asynchronous subscribers


When your web application grows, you often start seeing that some of your endpoints' response times are not satisfactory anymore. One of the possible solutions for this problem is to move some parts of the endpoint logic outside the main request-response cycle. Usually you start to implement some asynchronous jobs that are executed by a separate process outside your web server. Similarly, when you are using [RailsEventStore](https://railseventstore.org) with only synchronous handlers you may find them taking too long to execute and you start moving them to asynchronous ones.
Usually, in order to prevent failures caused by starting jobs too early (before the transaction that enqueues jobs commits or in case of a rollback), most developers start enqueueing jobs in the after commit callback. The same approach may be used with asynchronous handlers using RailsEventStore's `AfterCommitDispatcher` configured with e.g. `RailsEventStore::ActiveJobScheduler`. The sequence diagram below illustrates the flow for such a scenario:

<pre class="mermaid">
---
config:
  look: handDrawn
  theme: neutral
---
  sequenceDiagram
      participant App
      participant DB
      participant Broker

      App->>DB: INSERT event
      Note over DB: transaction commits ✓
      App-->Broker: MyAsyncHandler.perform_later(serialized_event) — outside the transaction
</pre>

<!-- more -->

## The problem with after commit

This simple flow allows you to postpone enqueuing handlers until after the main transaction is committed so you don't need to care about errors from your workers that tried to load entities that were not written to the database yet or - even worse - have loaded stale state from the DB (as the up-to-date one has not been committed yet). But there is one serious issue with this solution - you cannot guarantee that your code will always execute successfully. There are many things that may fail here, including network errors, out-of-memory issues, Redis running out of space and many other things that may happen, and as a result you end up with an inconsistent state of the whole system - your business logic was executed, domain events were published but some or all side effects failed:

<pre class="mermaid">
---
config:
  look: handDrawn
  theme: neutral
---
  sequenceDiagram
      participant App
      participant DB
      participant Broker

      App->>DB: INSERT event
      Note over DB: transaction commits ✓
      App--xBroker: MyAsyncHandler.perform_later(serialized_event) — outside the transaction
      Note over Broker: process crashes, or the broker<br/>raises, right here
      Note over App,Broker: The event exists in the database.<br/>No subscriber ever heard about it.
</pre>

## Transactional outbox

In most cases you would like to achieve durable event delivery - once you subscribe to an event, you want the handler to be called _at least once_ for each event, without losing any of them. One of the patterns that solves this problem in distributed systems is the [transactional outbox](https://microservices.io/patterns/data/transactional-outbox.html), where we store events or messages that need to be sent to a message broker in the database as a part of the same transaction that executes the business logic. Then we add a separate message relay process that reads those events and delivers them to the broker.

### The simplest RailsEventStore outbox 

If you want to implement the transactional outbox pattern in your application that uses RailsEventStore and Sidekiq for running asynchronous handlers, there is a [`ruby_event_store-outbox`](https://github.com/RailsEventStore/rails_event_store/tree/master/contrib/ruby_event_store-outbox) gem that helps you achieve this. However, it works only with Sidekiq and requires a new table where you serialize the whole event with full payload in a format Sidekiq understands. Then you run a separate process that reads data from that table and sends it to Redis. Once events are marked as sent to Redis (where Sidekiq workers will take them from), they are periodically removed from the database by a cleanup task.

### A better RailsEventStore outbox

If you want to have something more configurable, we have something for you - a new `ruby_event_store-outbox_relay` gem. It doesn't copy your event data anywhere and doesn't touch your `event_store_events` table. Instead it adds two small tables next to it:

- `event_store_outbox_messages` - the work still to do: one row per (event, asynchronous subscriber), holding the event ID, the topic, the subscriber's class name and the retry state,
- `event_store_outbox_dead_letters` - deliveries the relay has given up on.

When you publish an event, the outbox messages for its asynchronous subscribers are written in the very same transaction as the event itself. Either both are persisted or none of them is. A separate relay process then delivers the messages and deletes them, so the outbox table stays small. Event types without asynchronous subscribers don't write any messages at all.

The gem is designed to work with PostgreSQL, MySQL 8+ and SQLite. With PostgreSQL and MySQL the relay uses a `SELECT … FOR UPDATE SKIP LOCKED` clause, which lets many relay processes run in parallel. SQLite has no row locks, so you can run only a single relay with it.

The new gem modifies only the handling of asynchronous handlers - your temporary or synchronous handlers work the same way as before.

<pre class="mermaid">
---
config:
  look: handDrawn
  theme: neutral
---
  sequenceDiagram
      participant App
      participant Client as RubyEventStore::Client
      participant DB as event_store_events + outbox
      participant SyncSub as Sync subscribers
      participant Relay
      participant AsyncSub as Async subscribers

      App->>Client: publish(event)
      Client->>DB: BEGIN#59; INSERT event#59; INSERT outbox message per async subscriber#59; COMMIT
      Client->>SyncSub: broker.call(...) — immediate, unchanged

      loop relay poll loop
          Relay->>DB: claim due messages<br/>FOR UPDATE SKIP LOCKED, move next_attempt_at to the end of a lease
          Note over Relay,DB: short transaction, then no transaction open
          Relay->>DB: read the events
          Relay->>AsyncSub: dispatch each message to its subscriber
          Relay->>DB: DELETE delivered messages — one statement per batch
      end
</pre>

The relay claims a batch of messages in a short transaction which only hides them from other relays for the time of a _lease_ (five minutes by default). Then it reads the events and delivers them with no transaction open, so a slow subscriber never holds database locks. Delivered messages are deleted. If a relay crashes in the middle of a batch, there is nothing to clean up - its messages become available again once the lease runs out.

All event metadata is preserved, so you won't lose your `correlation_id`, `causation_id` and other metadata. Delivery is guaranteed _at least once_, so it's your responsibility to make your handlers idempotent, as they might be called more than once with the same event. To enable idempotency, you may e.g. store processed event IDs for some time and use them as the idempotency key.

Delivery is tracked per subscriber, not per event. If one of three subscribers of an event fails, only that one is retried and the other two are not called again.

By default, the relay pushes new jobs to your `ActiveJob` queues, enqueuing a whole batch at once with `ActiveJob.perform_all_later`. Jobs that define enqueue callbacks are enqueued one by one, so their callbacks still run. You can also bring your own dispatcher and send your events to Apache Kafka or another event streaming platform.

#### When something goes wrong

A failed delivery is retried with an exponential backoff, and a failing message never blocks the other ones. With the default retry policy, after 25 attempts spread over ~13 hours, the message is moved to the dead letters together with the error and its backtrace. You can configure the policy, including a list of errors that should send a message to the dead letters immediately.

Once you fix the cause, you can put dead letters back into the outbox, or discard them:

```
bundle exec rake ruby_event_store:outbox_relay:dead_letters:list
bundle exec rake "ruby_event_store:outbox_relay:dead_letters:retry[42]"
bundle exec rake "ruby_event_store:outbox_relay:dead_letters:retry[all]"
bundle exec rake "ruby_event_store:outbox_relay:dead_letters:discard[42]"
```

To know whether your relay keeps up, subscribe to the `ActiveSupport::Notifications` it publishes. The `stats.outbox_relay.ruby_event_store` notification carries the size of the backlog, the age of the oldest message waiting for delivery and the number of dead letters:

```ruby
ActiveSupport::Notifications.subscribe("stats.outbox_relay.ruby_event_store") do |event|
  StatsD.gauge("outbox.oldest_due_age", event.payload[:oldest_due_age].to_f)
  StatsD.gauge("outbox.dead_letters", event.payload[:dead_letters])
end
```

Alert on a growing `oldest_due_age` (you may need more relay processes) and on any dead letters.

#### Everything comes with a cost

As always, this gem has some trade-offs you need to know. It uses an infinite loop where we poll the database for new messages. This means your database server will have an additional constant load, so you might need to increase resources on your DB server. An idle relay costs one short transaction per second by default. Polling will also add a small latency to your handlers. On the publishing side, you pay with one additional `INSERT` statement for every `publish` of events that have asynchronous subscribers.

There is no ordering guarantee. Messages are claimed oldest first, but with several relays, retries and `ActiveJob`, your handlers can observe events out of order.

You also need to keep the lease longer than the time it takes to deliver a batch. Otherwise another relay may claim a message that is still being delivered.

#### Show me the code

The gem requires Ruby 3.3+ and RailsEventStore 3.x. Add it to your `Gemfile`:

```ruby
gem "ruby_event_store-outbox_relay", require: "ruby_event_store/outbox_relay/rails"
```

and create the outbox tables:

```
bundle exec rake ruby_event_store:outbox_relay:install_migration
bin/rails db:migrate
```

There is no need to backfill anything in an existing application, as your events table stays as it is. Requiring the gem changes nothing by itself, so there are only a few changes from the regular setup you need to make:

1. Build your event store client with `RubyEventStore::OutboxRelay::RailsClient` (or `RubyEventStore::OutboxRelay::Client` outside of Rails).
2. Differentiate how you subscribe handlers - use `subscribe_sync` (or `subscribe`) for synchronous handlers and `subscribe_async` for asynchronous ones. An asynchronous handler must be a named class (blocks are not accepted) and, with the default dispatcher, an `ActiveJob` class.
3. Create a configuration file for the relay process.

You can find an example you can use in your Rails application below:

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RubyEventStore::OutboxRelay::RailsClient.new.tap do |event_store|
      event_store.subscribe_sync(OrderLogger, to: [OrderPlaced, OrderCompleted])
      event_store.subscribe_async(OrderNotifier, to: [OrderCompleted])
    end
    # ...
  end
end
```

```ruby
# config/outbox_relay.rb

require_relative "environment"

RubyEventStore::OutboxRelay::Configuration.configure do |**options|
  RubyEventStore::OutboxRelay::Relay.new(client: Rails.configuration.event_store, **options)
end
```

The relay uses the very same client as your application, so you define your asynchronous subscribers in one place only.

You can run the relay process using the `res_outbox_relay` command:

```
DATABASE_URL="postgres://relay@db/app" bundle exec res_outbox_relay --require=config/outbox_relay.rb
```

or as a rake task:

```
DATABASE_URL="postgres://relay@db/app" OUTBOX_RELAY_ARGS="--require=config/outbox_relay.rb" bundle exec rake ruby_event_store:outbox_relay:run
```

The database is taken from the `DATABASE_URL` environment variable and there is deliberately no command line option for it, so your credentials don't show up in the process list. The gem also ships with a systemd unit template you can start with.

If your application needs durable event delivery for your asynchronous subscribers, `ruby_event_store-outbox_relay` is definitely something you should try! We have just released its first version, 0.1.0, and the [full documentation](https://railseventstore.org/docs/advanced-topics/outbox-relay) covers retries, observability, throughput and security in more detail.
