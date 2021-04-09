---
title: How to call 3rd party APIs idempotently
created_at: 2021-03-10T07:56:46.014Z
author: Tomasz Wróbel
tags: []
publish: false
---

Why?

* we make more and more 3rd party api calls in our apps these days, mostly in background jobs
* background jobs cannot be assumed to be run only once - there's no way around that (why? job can be retried because of an exception or even run twice in parallel in some weird scenarios)
* that's why jobs need to be designed to be idempotent, i.e. safe to run any number of times, while still producing the desired end state on the 3rd party system - if a job that sends emails is retried 10 times, it should still send only 1 email, not 10

Now how to make an 3rd party api call idempotent? It depends on what this particular api provides.

Some requests are easily made idempotent, like updating the status to `COMPLETED` (provided it should never go back).

Some request are harder to make idempotent, in particular adding an item to a collection. How not to end up with a bunch of unnecessary objects created when your job is being retried for some reason?

## Case 1 — 3rd party api support generic idempotency keys

Just like Stripe API here: https://stripe.com/docs/api/idempotent_requests

This is the best for you. Just add the idempotency key and you're good.

## Case 2 — client side generated id

If the 3rd party api allows you to set a client side generated id which is guaranteed to be unique, it works pretty much as an idempotency key.

## Case 3 — objects in _draft_ state

Some APIs may allow you to create an object in some kind of _draft_ state. If you split your creation request into two: (1) create a draft, (2) transition the draft to the target state (which is idempotent "by nature") — you're good too. In worst case you can end up with some unnecessary drafts, which most often should be a problem.

<!-- TODO: if api does does not support drafts, can some other attribute be abused for it? or some other api functionality? -->

## Case 4 — existence check

If your api lets you check for existence.

But here you need to deal with potential race conditions around concurrency, if your job runs twice in parallel, which you can never rule out.

<!-- TODO: how to mitigate race conditions -->

## Random points, to be edited

<!-- from @swistak35 -->

* make a DB lock to ensure that only 1 request for a specific ID can happen in a single moment
* being able to add an identifier to resource metadata might be helpful
* sidekiq limiter


<!-- TODO: discerning response created vs was-already-there -->

<!-- from swistak: generally: locks (pessimistic?) (+ querying if exists(???)) -->
<!-- can optimistic go in place of optimistic? -->
