---
title: How to make idempotent CREATE requests against a 3rd party http api
created_at: 2021-03-10T07:56:46.014Z
author: Tomasz Wróbel
tags: []
publish: false
---

It depends on what this particular api provides.

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


<!-- TODO: discerning response created vs was-already-there -->
