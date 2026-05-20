---
created_at: 2026-05-19 14:56:25 +0200
author: Szymon Fiedler
tags: [res, ruby, rails]
publish: false
---

# RailsEventStore 2.19: Starting Gun for 3.0

RailsEventStore 2.19.1 is out — grab that one, not 2.19.0 (more on why below).

This release is the starting gun for 3.0. We've added deprecation warnings for everything we're removing in the next major version. Run your test suite — every warning you see is a hard error in 3.0.

<!-- more -->

## Deprecations

We're deprecating a batch of APIs in 2.19 that will be removed in 3.0.

### RubyEventStore

#### `in_batches_of`

Renamed to `in_batches` for consistency with the rest of the API.

```ruby
# deprecated
event_store.read.in_batches_of(100).each { |batch| ... }

# use instead
event_store.read.in_batches(100).each { |batch| ... }
```

#### `of_types`

Renamed to `of_type`. Singular, consistent with other query methods.

```ruby
# deprecated
event_store.read.of_types([OrderPlaced, OrderShipped])

# use instead
event_store.read.of_type([OrderPlaced, OrderShipped])
```

#### Projection API

The old API coupled projection definition to the data source upfront — you had to specify the stream when building the projection. The new API separates these concerns: define the projection once, call it with any scope from `event_store.read`.

```ruby
# deprecated
Projection
  .from_stream("Order$1")
  .init(-> { 0 })
  .when(OrderPlaced, ->(state, event) { state + 1 })
  .run(event_store)

# use instead
Projection
  .init(-> { 0 })
  .on(OrderPlaced, ->(state, event) { state + 1 })
  .call(event_store.read.stream("Order$1"))
```

Also deprecated: calling `Projection#call` with multiple scopes — pass a single scope. Use `Projection.init` instead of `Projection.new`.

#### Class-based subscribers

Passing a class as a subscriber hides the lifecycle — RES had to decide when and how to instantiate it, with no control from the caller. An instance or lambda is explicit about what gets called and when.

```ruby
# deprecated
event_store.subscribe(SendOrderConfirmation, to: [OrderPlaced])

# use instead
event_store.subscribe(SendOrderConfirmation.new, to: [OrderPlaced])
```

#### `EventClassRemapper` / `events_class_remapping:`

Upcasting has been available since RES 2.1.0 and is the proper way to handle renamed or evolved event classes. It's composable, co-located with the transformation logic, and doesn't require configuring the mapper globally. `EventClassRemapper` is being removed.

#### `NullMapper`

`Mappers::Default.new` without arguments does exactly what `NullMapper` did, with a name that doesn't imply it does nothing.

```ruby
# deprecated
mapper: RubyEventStore::Mappers::NullMapper.new

# use instead
mapper: RubyEventStore::Mappers::Default.new
```

### RailsEventStore

#### `RailsEventStore::*` constant aliases

The `rails_event_store` gem is an integration layer — it wires RES into Rails. The domain objects (events, client, projections) live in `ruby_event_store`. Aliasing them under the `RailsEventStore` namespace implied they were Rails-specific, which caused confusion about what's portable and what isn't. In 3.0 those aliases are gone — use the source namespace directly.

```ruby
# deprecated
RailsEventStore::Event
RailsEventStore::JSONClient

# use instead
RubyEventStore::Event
RubyEventStore::JSONClient
```

#### `*.rails_event_store` instrumentation events

Same reason as above — the implementation is in `ruby_event_store`, so the instrumentation namespace should be too. During the 2.19 transition period both `*.rails_event_store` and `*.ruby_event_store` are dual-fired. After 3.0 only `*.ruby_event_store` remains — update your `ActiveSupport::Notifications` subscriptions.

#### Dispatcher naming

The `Async` in `ImmediateAsyncDispatcher` and `AfterCommitAsyncDispatcher` described the handler (a background job), not the dispatcher itself. The new names drop the misleading qualifier. `Dispatcher` becomes `SyncScheduler` — a more accurate description of what it actually does.

| Deprecated | Use instead |
|---|---|
| `ImmediateAsyncDispatcher` | `ImmediateDispatcher` |
| `AfterCommitAsyncDispatcher` | `AfterCommitDispatcher` |
| `Dispatcher` | `SyncScheduler` |

### AggregateRoot

#### `apply_*` method convention

The old convention mapped event handlers by method name — `apply_order_placed` would handle `OrderPlaced`. The problem, which we even documented at the time: you can't grep for usages of the event class. The `on` DSL references the event class explicitly.

```ruby
# deprecated
class Order
  include AggregateRoot

  def apply_order_placed(event)
    @status = :placed
  end
end

# use instead
class Order
  include AggregateRoot

  on OrderPlaced do |event|
    @status = :placed
  end
end
```

#### `AggregateRoot::Configuration` / `default_event_store`

Global state with a hidden dependency on the event store. Makes testing harder, makes the dependency invisible at the call site. Pass the event store explicitly to `Repository.new`.

```ruby
# deprecated
AggregateRoot::Configuration.new.tap do |c|
  c.default_event_store = Rails.configuration.event_store
end

# use instead
repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
```

---

## PostgreSQL `valid_at` index

If you use bi-temporal queries (`as_of`), add this index.

PostgreSQL can't use a regular column index for an expression in ORDER BY — it needs a dedicated functional index. Without it, `as_of` queries fall back to a sequential scan. On a table with ~100k events that's ~6 seconds. On tables with millions of events, even small result sets take 800ms–1600ms. The mechanics are covered in detail in [How to add index to a big table of your Rails app](https://blog.arkency.com/how-to-add-index-to-big-table-of-your-rails-app/).

New installations get a functional index on `COALESCE(valid_at, created_at)` automatically. Existing installations:

```
bin/rails generate rails_event_store_active_record:migration_for_valid_at_index
bin/rails db:migrate
```

The generator in 2.19.0 used a plain `CREATE INDEX` — which locks the table for the duration of the build. We caught it and shipped 2.19.1 the next day with `algorithm: :concurrently` and `disable_ddl_transaction!`.

PostgreSQL only — MySQL and SQLite use different syntax for expression indexes.

---

## Under the hood

The CI matrix now covers **Ruby 4.0**, **Rails 8.1**, **Redis 8**, **PostgreSQL 18**, and **MySQL 9.7**. We've dropped EOL versions: Ruby 3.2 (EOL March 2026), old Rails and ActiveRecord versions, PostgreSQL 13, MySQL 8.0.

The test suite previously used multiple per-version dummy Rails apps. We've consolidated these into a single app driven by different Gemfiles across the CI matrix.

Mutation coverage gaps have been closed — some after the tag cut.

---

## Upgrading

```
gem 'rails_event_store', '~> 2.19'
```

Full release notes: [v2.19.0](https://github.com/RailsEventStore/rails_event_store/releases/tag/v2.19.0), [v2.19.1](https://github.com/RailsEventStore/rails_event_store/releases/tag/v2.19.1)

