---
created_at: 2026-06-02T10:00:00.000Z
author: Tomasz Patrzek
tags: [res, ruby, rails]
publish: true
---

# What's New in Rails Event Store 3.0

Rails Event Store 3.0 is primarily a cleanup release.

Throughout the 2.x series we introduced new features while gradually deprecating APIs we no longer wanted to maintain. In 3.0, those deprecated APIs are finally gone.

There are no major new concepts or APIs to learn. The public API is simply smaller, more consistent, and comes with a few stricter defaults.

If you've already addressed all deprecation warnings in 2.19, upgrading to 3.0 should be straightforward. This post summarizes what changed, while the [2.19 release announcement](/railseventstore-2-dot-19-starting-gun-for-3-dot-0/) explains the motivation behind each deprecation in more detail.

<!-- more -->

---

## Lean API: the deprecations are gone

The 2.x series was conservative — we kept old method names alive and just warned you about them. 3.0 removes the training wheels: every name kept around for compatibility is gone. Here's the at-a-glance list of what's removed and what replaces it (each row links to the reasoning in the 2.19 post):

| Removed | Use instead |
|---|---|
| `read.in_batches_of(100)` | `read.in_batches(100)` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code_in_batches_of__code_" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `read.of_types([Type])` | `read.of_type(Type)` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code_of_types__code_" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `RubyEventStore::ImmediateAsyncDispatcher` | `RubyEventStore::ImmediateDispatcher` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#dispatcher_naming" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `RailsEventStore::AfterCommitAsyncDispatcher` | `RailsEventStore::AfterCommitDispatcher` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#dispatcher_naming" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `RubyEventStore::Dispatcher` | `RubyEventStore::SyncScheduler` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#dispatcher_naming" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `subscribe(Handler, to: [Type])` | `subscribe(Handler.new, to: [Type])` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#class_based_subscribers" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `Mappers::NullMapper.new` | `Mappers::Default.new` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code_nullmapper__code_" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `def apply_order_placed(event)` | `on(OrderPlaced) { ... }` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code_apply____code__method_convention" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| `AggregateRoot::Configuration` | `AggregateRoot::Repository.new(event_store)` <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code_aggregateroot__configuration__code_____code_default_event_store__code_" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| <code style="display:block;white-space:pre-wrap">read.repository.rails_event_store<br>call.dispatcher.rails_event_store</code> | <code style="display:block;white-space:pre-wrap">read.repository.ruby_event_store<br>call.dispatcher.ruby_event_store</code> <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code___rails_event_store__code__instrumentation_events" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| <code style="display:block;white-space:pre-wrap">Projection<br>  .from_stream("Orders")<br>  .when(OrderPlaced, handler)<br>  .run(event_store)</code> | <code style="display:block;white-space:pre-wrap">Projection<br>  .init({ count: 0 })<br>  .on(OrderPlaced, &amp;handler)<br>  .call(event_store.read.stream("Orders"))</code> <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#projection_api" style="font-style:italic;color:#000;font-size:.85em">details</a> |
| <code style="display:block;white-space:pre-wrap">RailsEventStore::Event<br>RailsEventStore::Projection<br>RailsEventStore::InMemoryRepository</code> | <code style="display:block;white-space:pre-wrap">RubyEventStore::Event<br>RubyEventStore::Projection<br>RubyEventStore::InMemoryRepository</code> <a href="/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code_railseventstore_____code__constant_aliases" style="font-style:italic;color:#000;font-size:.85em">details</a> |

> **Note —** removing the aliases doesn't touch the genuinely Rails-specific classes. `RailsEventStore::Client` and `RailsEventStore::AfterCommitDispatcher` aren't re-exports of anything — they exist only because of Rails (ActiveRecord, transaction callbacks), so they stay. Only the constants that merely pointed at a `RubyEventStore::` original are gone.

The one replacement that isn't a rename is `EventClassRemapper` — its successor, upcasting, needs a real handler.

### EventClassRemapper is gone — use upcasting

In event sourcing, events are immutable facts — once written, a record's `event_type` stays as it was, a plain string you never go back and rewrite. By convention that string is the class name, and that's exactly what a rename breaks: move `OrderPlaced` into an `Ordering` module and the events already stored as `"OrderPlaced"` no longer resolve to `Ordering::OrderPlaced` on read.

In 2.x you patched this on read with the `events_class_remapping:` option — a string-to-string lookup:

```ruby
# 2.x — removed
RubyEventStore::Mappers::Default.new(
  events_class_remapping: { "OrderPlaced" => "Ordering::OrderPlaced" }
)
```

3.0 replaces it with the upcasting transformation. A `Record` is immutable, so the upcast lambda receives the old record and returns a brand-new one — for a rename you change only `event_type`:

```ruby
# 3.0
upcast = RubyEventStore::Mappers::Transformation::Upcast.new(
  "OrderPlaced" => ->(record) do
    RubyEventStore::Record.new(
      event_type: "Ordering::OrderPlaced",
      data:       record.data,
      event_id:   record.event_id,
      metadata:   record.metadata,
      timestamp:  record.timestamp,
      valid_at:   record.valid_at,
    )
  end
)

mapper = RubyEventStore::Mappers::Pipeline.new(
  upcast,
  RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
)

RailsEventStore::Client.new(mapper: mapper)
```

Starting from a full `Record` is the whole point: it lets you do far more than rename the type. You can reshape `data` between versions, split or merge fields, backfill a value that older events never carried — and chain entries so each record is upgraded step by step until it stops changing. That flexibility is what the few extra lines buy you over a one-line hash.

### Other removals

A handful of smaller cleanups round out the release, grouped by where they'd reach you — chances are most won't.

**If you subscribe to instrumentation**

- `serialize` / `deserialize` mapper events removed.<br>They were renamed to `event_to_record` / `record_to_event` (payload key `domain_event:` → `event:`); update any `ActiveSupport::Notifications` subscriptions on the old names.
- `events:` / `messages:` payload keys removed.<br>The `append_to_stream` and `update_messages` notifications now carry only `records:` — read that key instead.

**If you customize mappers or aggregates**

- `JSONMapper` removed.<br>It was a thin `Default` subclass — `Default` already handles JSON, so use that instead.
- `with_default_apply_strategy` / `with_strategy` removed.<br>The default strategy already comes with `include AggregateRoot`; for a custom one, use `AggregateRoot.with(strategy: …)`.

**Stricter by default**

- `nil` to `publish` / `append` / `link` is now rejected.<br>It used to warn and carry on — now it raises `ArgumentError`, so guard calls that might pass an empty result.
- `ensure_supported_any_usage` removed.<br>`InMemoryRepository` now always rejects mixing `expected_version: :any` with specific positions — matching the SQL repositories, so in-memory tests catch what production would.

And one warning simply went away — the spurious `rails_event_store_active_record` rename warning is gone ([backstory in the 2.19 post](/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#deprecation_warnings_in_tests)).

---

## Upgrade guide

Start on 2.19 and clear every deprecation warning first — once your test suite is quiet, the table above is your checklist and the rest of the upgrade is mostly find-and-replace. Three changes need a real edit rather than a rename.

**Projection API** — define the projection once, then call it with any scope:

```ruby
# before
Projection
  .from_stream("Orders")
  .when(OrderPlaced, handler)
  .run(event_store)

# after
Projection
  .init({ count: 0 })
  .on(OrderPlaced, &handler)
  .call(event_store.read.stream("Orders"))
```

**AggregateRoot `default_event_store`** — the global default is gone; wire the event store explicitly through `AggregateRoot::Repository.new(event_store)`. [Details in the 2.19 post](/railseventstore-2-dot-19-starting-gun-for-3-dot-0/#_code_aggregateroot__configuration__code_____code_default_event_store__code_).

**`EventClassRemapper`** — replace the `events_class_remapping:` hash with an upcasting transformation on your mapper, as shown in the [upcasting section](#eventclassremapper_is_gone___use_upcasting) above.
