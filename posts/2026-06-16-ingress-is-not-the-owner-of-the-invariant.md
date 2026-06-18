---
created_at: 2026-06-16 15:21:30 +0200
author: Szymon Fiedler
tags: [rails, ruby, event-driven, ddd, res, architecture]
publish: true
---

# Ingress is not the owner of the invariant

A polemic with [Callbacks Are Not Invariants](https://baweaver.com/writing/2026/06/13/rails-sharp-parts-callbacks-are-not-invariants/) by Brandon Weaver.

> A disclaimer: I’m a [RailsEventStore](https://railseventstore.org) maintainer and this article ends up on the Arkency blog — so cards are on the table. Despite this, I’m keeping the core of my argument in pure `ActiveRecord`: no step of the reasoning requires _RES_. I only show the _RES_ version at the end, separately, as "and this is what it looks like when you’re not typing it in manually". If you’re convinced by the bare-metal _AR_ reasoning, not the library, that’s what matters.

<!-- more -->

## We agree about the disease

I enjoy reading Brandon’s _Rails: The Sharp Parts_ series and sending it to the team — it’s one of the better pieces on the sharp edges of Rails that’s come out lately. The one about callbacks is no exception and the diagnosis is spot on. Census `_save_callbacks`, which shows eleven entries with two association lines and zero callbacks of its own. A mismatch between what fires before and after `COMMIT`. The best sentence in the entire text: "a callback is an invariant with a published bypass list" — `update_all`, `insert_all`, `update_column` are holes in something that was supposed to _always happen_.

I’m not here to defend the callbacks. I hate them myself, for the same reasons. The dispute is about the cure.

And I have one reservation for the cure Brandon proposes — and it doesn’t concern what he built, but how he named it. Because the name will travel beyond a single file, to anyone who copies the template.

## A name that promises more than it delivers

What the author calls `Command` is Fowler’s `Transaction Script`. One public call, a private `execute`, a procedure orchestrating `ActiveRecord` calls. And that’s a good pattern — it’s forty years old and still going strong. The thing is, he calls it a command (suggesting CQRS, which itself announces _next time_) and calls `ActiveSupport::Notifications` events.

A name isn’t cosmetic. A name is a mental contract. When 500 engineers work in a monolith — and that’s the scale Weaver explicitly writes for — names are the only documentation anyone reads. If you tell them they’re building _commands_ and _events_, in a year, half the company will think they’re building an event-driven architecture with procedures in their hands. That’s worse than no name, because it installs a mental model that doesn’t match the code.

And this isn’t about arguing with its values but about appealing to them. Brandon writes about himself that his goal is to make the invisible visible — and that the next person reading the code shouldn’t have to wonder what the author meant. I agree with that with both hands. And that’s precisely why calling a _procedure_ a _command_ and a _notification_ an _event_ plays against what he wants: it forces the reader to assume a contract — a serializable intent with a separate handler, a persistent domain fact — that doesn’t exist in the code. Correcting the names isn’t a quarrel with Weaver; it’s the completion of his own goal.

## Core: ingress doesn’t own the invariant

Single-ingress is correct — one write path per operation, one entry point that owns the state change. But look where the "space cannot be reserved twice" invariant lives after the refactor:

```ruby
def reserve
  seat = Seat.find(seat_id)
  seat.with_lock do
    raise AlreadyReserved, "seat #{seat_id} is already reserved" if seat.reserved?
    seat.update!(reserved: true, reserved_by: by)
    Ledger::RecordReservation.call(seat: seat, by: by)
  end
  seat
end
```

The rule is spread across three layers:
* a check in runtime (`if seat.reserved?`) 
* a row lock (`with_lock`)
* a constraint in the database — as Brandon rightly writes elsewhere.

This isn't a domain model. It's a `Seat.find` + `update!` wrapped in a procedure. Infrastructure-first, just repurposed from a callback to a service object. The question "who owns the reservation rule" still doesn't have a single answer.

The coupling is now deliberate and visible — but it's still there. One trade-off and one naming issue:

**Side effects inline in `execute`**. Weaver is explicit about this: `announce` belongs to the command body by design, not by accident — subscribers are reserved for observability only and cannot veto a write or introduce ordering dependencies. That's a defensible trade-off: visible coupling beats hidden coupling every time. My claim is narrower: `announce` fires after `with_lock` commits, so the timing is fine — but if the process dies between commit and `deliver_later`, the effect is gone forever. There is nothing to replay from, because the fact was never persisted.

**`event_name` from the namespace system**. The event name extracted from `module_parent_name` ties the _event_ taxonomy — that is, _the contract_ — to the directory structure in the code. Move a module, and the names of events that someone might already be subscribed to change. This is exactly the kind of invisible coupling he's been fighting against throughout this article — only this time it moves a layer higher.

## What it looks like when an invariant has an owner

I'll show the difference in code, because otherwise, it's just adjectives. Pure `ActiveRecord`, without `RailsEventStore`.

First, the aggregate. It — and only it — decides whether the reservation is allowed and produces the fact. No *IO*, no *mailer*, no *webhook*:

```ruby
class Seat < ApplicationRecord
  class AlreadyReserved < StandardError; end

  # Invariant lives here. In one place. The method always returns an event,
  # and doesn't fire side effects.
  def reserve(by:)
    raise AlreadyReserved, "seat #{id} is already reserved" if reserved?

    self.reserved    = true
    self.reserved_by = by
    self.reserved_at = Time.current

    SeatReserved.new(seat_id: id, reserved_by: by, reserved_at: reserved_at)
  end
end
```

An _event_ is a fact. Past tense. Payload is a result, not a request:

```ruby
SeatReserved = Data.define(:seat_id, :reserved_by, :reserved_at) do
  def event_name = "seat_reserved"
end
```

The _handler_ is a simple _PORO_ — one application use-case, one entrance for write. We're keeping Brandon's single-entry discipline because it's good; we're not inheriting his `ApplicationCommand` base — its only job was `announce`, and that role is now taken by the explicit `SeatReserved` with persistent log write and subscribers. There's no constructor, no ivars, and no `self.call` to `new.call` relay — the handler is so thin that there's nothing to decompose. And that's the point: the rule has been moved to the aggregate, so orchestration remains trivial, and everything happens on the correct side of the commit.

```ruby
module Seats
  class ReserveSeat
    def self.call(seat_id:, by:)
      Seat.transaction do
        seat  = Seat.lock.find(seat_id)
        event = seat.reserve(by:)   # aggregate guards the invariant 
        seat.save!
        Events.publish(event)       # fact in the same transaction
        event
      end
    end
  end
end
```

`Events.publish` does two things, both in the caller's transaction: it writes the event to a persistent log and synchronously calls subscribers. First, the log: append-only, the source of truth, from which you replay:

```ruby
# Persistent event log — source of truth. 
# As long as the event lives here, it can be replayed.

class StoredEvent < ApplicationRecord
  def self.append(event)
    create!(name: event.event_name, payload: event.to_h, occurred_at: Time.current)
  end
end
```

And the _dispatcher_. No magic at all: `publish` stores the fact, and then calls _handlers_ subscribed to the _event name_ — in the same thread, and in the same transaction:

```ruby
# publish: persistent fact + sync subscribers, atomically with the state change.
module Events
  HANDLERS = Hash.new { |h, k| h[k] = [] }

  def self.publish(event)
    StoredEvent.append(event)
    HANDLERS[event.event_name].each { |handler| handler.call(event) }
  end

  def self.subscribe(event_name, &handler)
    HANDLERS[event_name] << handler
  end
end
```

Here's all the persistence I need: `StoredEvent.append` runs in the same transaction as `seat.save!` — because `publish` doesn't open its own transaction, the INSERT inherits the active one from the caller. The fact commits with the state change or not at all. Since the fact remains, any reaction can be recreated — handler retry, log replay. This is the invariant, and you have it without any additional machinery.

One fair boundary. The subscribers above execute synchronously, in a transaction — which is exactly what you want for reactions intended to be atomic with the fact. But a subscriber doing heavy or external IO (mail, webhook) shouldn't block the transaction; it schedules the work asynchronously, via `deliver_later`. And here comes the only gap Weaver worries about: the very scheduling of this asynchronous work isn't atomic by default with the fact's save. This narrow gap — and nothing else — is patched by the transactional outbox. It doesn't patch the persistence of the fact, because that's already taken care of. 

And the mailer and the webhook? They react to the fact. They're not steps in the write path — they're subscribers. You can add, remove, or replace one without touching the `ReserveSeat`:

```ruby
Events.subscribe("seat_reserved") do |event|
  ReservationMailer.confirmed(event.seat_id).deliver_later
end

Events.subscribe("seat_reserved") do |event|
  Webhooks::Emit.call(event: :seat_reserved, payload: event.to_h)
end
```

Let's compare both approaches:

| | Weaver | Here|
| --- | --- | --- |
| Invariant | runtime check + `with_lock` + constraint | `Seat#reserve`, single place |
| Event | `reserve_seat.seats` from namespace, payload = input | `seat_reserved`, explicit, payload = result |
| Side-effects | inline in `announce` (deliberate — observability subscribers can't veto writes) | subscribers react to the persisted fact | 
| Delivery | fire-and-forget after commit, can be lost | event in a transaction, always replayable | 

And here's the point I care about most — because it affects the domain I'm currently working on: persisting the fact isn't an add-on — it's a day-one invariant. Weaver himself is clear: _"If you need durable event delivery (guaranteed at-least-once), that's a transactional outbox or CDC, not a subscriber."_ So we agree on the destination. Where I part ways is the framing: he presents it as something you reach for at scale. When `SeatReserved` is saved in the same transaction as the state change, no effect can be lost forever: since the fact remains, the reaction can always be recreated — retry the handler, replay from the log. Outbox doesn't create this persistence — it only uses it, automating the delivery with an at-least-once guarantee — which means subscribers must be idempotent. You don't persist the fact because you scaled; you persist it from the first INSERT and harden delivery when the async scheduling gap becomes relevant.

## And if you don't want to write it by hand

The above is on bare *AR* intentionally, so the argument can stand up without any library. But you get the same structure off the shelf. *Aggregate* with *AggregateRoot*:

```ruby
class Seat
  include AggregateRoot

  AlreadyReserved = Class.new(StandardError)

  def reserve(by:)
    raise AlreadyReserved if @reserved
    apply SeatReserved.new(data: { seat_id: @id, reserved_by: by })
  end

  on SeatReserved do |event|
    @reserved    = true
    @reserved_by = event.data.fetch(:reserved_by)
  end
end
```

An invariant in `reserve`, a fact in `SeatReserved`, a state mutation in `on` — and this is an *event* that actually lands in the event store, with versioning and replay, not a notification whose name is derived from a namespace. You attach handlers (mailer, webhook) as subscribers exactly as above.

And delivery? _RES_ publish is exactly `Events.publish`: atomic write to the _event store_ plus synchronous dispatch, inside the caller's transaction. `ruby_event_store-outbox` patches the one gap I named above — transactional scheduling of async handlers — maintained, safe under concurrent workers, covered with mutation tests.

A complete walkthrough of *RES* — aggregates, subscriptions, outbox, strangler on an existing monolith — is a topic for a separate, much longer text. Let me preface this point, as Brandon rightly dislikes rewrites; this path isn't rewriting. It's strangler — precisely the incremental movement it describes, callback by callback, flag by flag. The punchline here is enough: the structure he's approaching is available as a ready-made library, not an exotic one.

## Where Weaver is right — and what I'm not saying

I'm not advocating "always event sourcing". That would be precisely the dogmatic approach I combat in people who sell _event sourcing_ as a religion.

His _Transaction Script_ is sufficient for most applications. One team, one write path, reasonable discipline — and a procedure with a single input carries water for years. The Strangler fig + Flipper migrations he describes are really good. Normalizes for pure transformations — agree. Constraints as truth in the database — agree, and strongly so. His `CommandSingleEntrant` RuboCop cop makes the single-entry rule structural rather than disciplinary — and he's honest about its reach: "Both catch the common mistakes", with `class << self` patterns as a known blind spot.

My point isn't "your pattern is too weak". It's: don't call it a _command_ and _event_ when it isn't. Because the difference between a _procedure_ and a _command_, and between _notification_ and a _domain event_, isn't pedantry — it's the difference between "an invariant has an owner" and "an invariant is smeared, but nicely named".

I anticipate three counterarguments:

"It's a dispute about names." Yes — and names are a contract that will reach 500 people. A bad mental model scales worse than bad code, because code gets refactored, but beliefs don't.

"ES is overkill." Agreed, for most people. But a persistent record of a fact isn't _event sourcing_ — it's a single `INSERT` in the same transaction as a state change, turning "effect can be lost" into "effect always recoverable". You don't skip this because you're not doing event sourcing; it's record path hygiene, not architecture.

Steelman 37signals — whom Weaver honestly quotes — says that disciplined callbacks scale further than they're given credit for. In a single, cohesive team: they're not wrong. But the same caveat applies to his solution: _Transaction Script_ without an invariant owner also relies on discipline, which is generally absent with 500 people. The aggregate approach doesn't ask for discipline — the structure enforces the rule.

## Landing

Single-ingress is correct. But an ingress that doesn't own the invariant isn't a fix — it's moving the same rule spread from a callback to a procedure. And calling that _procedure_ a _command_ and the _notification_ an _event_ installs a mental model for 500 engineers that doesn't fit the code they have in their hands.

The strongest version of his own argument isn't the one he wrote — it's the one he's getting closer to: an _aggregate_ that monitors the _invariant_, a true _domain event_, and a fact persisted in the same _transaction_ as the state change. Weaver ends with a CQRS announcement "next time," and it's a good announcement, because single-ingress without an invariant owner is only halfway down the road he's charted.

I look forward to the continuation of the series — honestly, without irony.
