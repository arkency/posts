---
created_at: 2026-04-24 12:00:00 +0200
author: Andrzej Krzywda
tags: ['rails', 'ddd']
publish: false
---

# The Rails Way in 2026

We had an interesting discussion at the Arkency weekly call today. The topic was how to define "the Rails Way" in 2026. The discussion branched in many directions, but I want to capture the result here.

<!-- more -->

We get to see a lot of Rails repositories. There's a pattern that shows up so consistently that I think it now deserves to be called "the Rails Way" of 2026:

**A fat model with a callback. The callback triggers a service object. The service object is executed as a background job.**

That's the clue of this post. If you zoom out across the Rails applications written or maintained in 2026, that's the shape.

## The disclaimer

A word about where we're coming from. Arkency is a company that often gets called in to fix existing large Rails applications. We help with performance, we help with improving the velocity, we also introduce domain-driven design and event-driven architecture where it makes sense. So our view is biased - we tend to see the apps that have grown past the point where the default Rails shape still fits.

That bias is also what makes the pattern above so visible to us. We see it again and again.

## Processes and workflows inside Active Record

Part of the weekly discussion was specifically about how processes or workflows are implemented in Rails applications nowadays.

The conclusion: they are implemented as part of the existing Active Record.

Active Record is not only the state of an entity. It's very often the state of a process. Sometimes it's a shared state, because we're talking about multiple entities collaborating together via `has_many`.

If you look at the columns of a typical Active Record table, you can see both kinds of state mixed together. Some columns describe the entity — often as enums:

```ruby
class Order < ApplicationRecord
  enum status: { pending: 0, confirmed: 1, paid: 2, shipped: 3, delivered: 4, cancelled: 5 }
end
```

That looks like entity state. But sit with it for a moment - `pending → confirmed → paid → shipped → delivered` is not really the state of a thing. It's the state of a process the thing is going through.

And next to these enum columns, you'll almost always find columns that are openly about the process:

```ruby
# columns on the same orders table
t.datetime :last_reminder_email_sent_at
t.datetime :payment_retry_scheduled_at
t.integer  :failed_payment_attempts, default: 0
t.datetime :confirmation_email_sent_at
```

`last_reminder_email_sent_at` is not a property of the order. It's a checkpoint in a workflow, "the dunning process has progressed this far." The same goes for retry counters, "sent_at" timestamps, and "scheduled_at" fields. They're persisted process state, living on the entity table because there's nowhere else for them to live.

So the Active Record row ends up being a blend: enum columns that look like entity state but actually track a workflow, plus auxiliary columns that openly admit they're tracking a process.

A single Active Record class ends up carrying:

- the data of the entity (the original purpose),
- the current step of a workflow the entity is going through,
- callbacks that advance that workflow,
- service objects triggered from those callbacks,
- background jobs scheduled from those service objects,
- and associations to other records that are part of the same process.

The process is not an object. The workflow is not an object. They live as emergent behavior across a model, its callbacks, its associations, and the jobs they enqueue.

## One more piece: concerns

There's one more part of the Rails Way that deserves a mention — concerns.

We don't see them as often as we see the fat-model-plus-callback-plus-background-job pattern in the codebases we get called into. But concerns are definitely a significant part of the Rails Way too. Maybe they are more of the *official* Rails Way than the Rails Way we see in the wild.

A good example is the Fizzy codebase from 37signals. We recorded a walkthrough of it on our YouTube channel: [How we architect Rails apps at 37signals: a Fizzy tour](https://www.youtube.com/watch?v=-L6fjY3HlBI). Fizzy leans on concerns to structure behavior across models. It's worth watching to see the pattern applied intentionally rather than as accidental accumulation.

So the full picture of the Rails Way in 2026 is probably: fat model, callback, service object, background job, process state living on Active Record and, where teams lean closer to the official Rails style, concerns as the way to organize all of that.

## Why this matters

I'm not using this post to argue against the pattern. I'm using it to name it. If we can't describe what the Rails Way looks like today, we can't have an honest conversation about when it serves us and when it doesn't.

So: fat model, callback, service object, background job and processes that live inside Active Record rather than beside it.

That's the shape of Rails in 2026.
