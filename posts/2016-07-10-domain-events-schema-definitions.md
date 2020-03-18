---
title: "Domain Events Schema Definitions"
created_at: 2016-07-10 15:40:11 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ddd', 'schema', 'rails_event_store' ]
newsletter: arkency_form
---

When we started three years ago publishing Domain Events
in our applications, we were newbies in
the DDD world. I consider the experiment to be
very successful but some lessons that had to
be learned the hard way.

<!-- more -->

At the very beginning, we were just publishing events.
We didn't think much about consuming them.
We haven't yet considered them a very powerful
mechanism for communication between the application
subsystems (called Bounded Contexts in DDD world).
And we didn't think much about how those events
would evolve in the future.

Nowadays, one of our events has 18 handlers. And I believe
this number will continue growing.

We also started using domain events in many smaller
test i.e. tests for one class or one sub-system.

So at some point in time, it became necessary that what
we publish in code, what we expect in tests and what
we use to set up a state in tests has the same interface.
All those events should contain the same attribute names
and the same types of values in them.

For that I used `classy_hash` gem which raises
useful exceptions when things don't match.

```ruby
class PaymentNeedsMoreTime < RailsEventStore::Event
  SCHEMA = {
    order_id:             Integer,
    payment_id:           Integer,
    payment_gateway_name: String,
    seconds_needed:       Integer,
  }

  def self.strict(data, **attr)
    ClassyHash.validate(data, SCHEMA)
    new(data, **attr)
  end
end
```

I tried an approach in which the event schema is validated
in a constructor phase `(new/initialize)` but later decided against
it. In a few very rare cases we might be OK with an event
which is not completely full (not all attributes are present).
When we get historical events
from event store we don't want (or need) to verify the schema as well.

So instead when you want to verify the schema (in 97% of cases)
you should just use the `strict` method to create the event
instead of `new`.

```ruby
stream_name = "payment_#{payment.id}"
event = PaymentNeedsMoreTime.strict(
  order_id: payment.order_id,
  payment_id: payment.id,
  payment_gateway_name: "v8",
  seconds_needed: 30*60*60,
)
client.publish_event(event, stream_name)
```

`classy_hash` supports nullable keys (value is nil), optional keys (value not present),
multiple choices, regular expressions, ranges, lambda validations, nested arrays and hashes.

I know some people who use `dry-types` for defining events' schema
and they were happy with that library as well.

With 220 domain events that we already publish, with every new
that I add, I remember to define its schema. That way it's much
easier for every other team member to know what they can expect
in those events just by looking at their definition.

Check out our [`rails_event_store`](http://railseventstore.arkency.com)
gem if you want to start publishing domain events as well.
