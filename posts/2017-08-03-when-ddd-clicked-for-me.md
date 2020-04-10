---
title: "When DDD clicked for me"
created_at: 2017-08-03 10:08:44 +0200
publish: true
author: Robert Pankowecki
tags: [ 'ddd' ]
newsletter: arkency_form
---

It took me quite a time to grasp the concepts from DDD community and apply them in our Rails projects. This is a story of one of such "aha" moments.

<!-- more -->

Imagine a scenario which goes like this:

- payment is paid
  - this is simple
  - just a callback from a payment gateway
  - verified based on ip or token
- mark payment as successful

but it triggers a shitload of effects:

- changes in Orders
- generating tickets
- generating PDFs
- changing reporting
- validating additional domain rules, coupon usage
- etc, etc

In another project that I worked on, the effects of a successful payment were:

- giving access to purchased video content
- changing reporting
- recomputing average ratio of virtual platform currency to USD

In both cases, the teams experienced the same problems:

* long transaction times, the customer waited a lot for confirmation
* problems with big purchases (100s of tickets)
* very hard to handle errors properly due to so many intertwined concerns

DDD helped me realized that my teams tried to do too much during HTTP requests and too many unrelated concepts were coupled together. That _Payments, Delivery, Reporting_ and other concerns were too coupled.

But it also gave me tools and solutions to fix the situation:

* domain events to inform about important changes occurring in the system
* event handlers to react to them
* sagas/process managers to orchestrate complex flow of events originating from different subsystems
* read models for building reports

In this case, I realized that I can refactor the payment process as:

#### Handling Payments

  * getting webhook/redirect-callback from payment gateway
  * verifying its correctness
  * marking payment as paid and publishing domain event `PaymentPaid`
    * alternatively publishing `PaymentFailed`
  * now that made handling payments much simpler. When I look at this code it is only interested in payments and it only operates on this one record. Either it worked or not.

#### Handling Orders

  * Orders subsystem listens and reacts to `PaymentPaid` and `PaymentFailed`
  * In case of `PaymentPaid` it tries to transition to new state as well and checks the last part of business logic, guarding whether that is possible
  * publishes `OrderCompleted` when successful or `OrderCompletionFailure` when not
  * this made handling the last state transition for Orders simpler as well. When I look at the code I am no longer concerned about payments, how it was paid etc.

#### Saga

* reacts to `PaymentPaid`, `OrderCompleted`, `OrderCompletionFailure`
* when both subsystems have success and it receives `PaymentPaid`, `OrderCompleted`, it can trigger `CapturePayment` command (in credit card payments the process has 2 phases: authorization, which reserves the money, and capturing, which actually confirms you want to receive them).

    <%= img_fit("ddd-rails-ruby-saga-clicked/saga_diagram_ok_1.png") %>

* when the `Payment` is _Paid_ but we could not complete our `Order` and got `OrderCompletionFailure` for a brief moment of time (temporally) we have a discrepancy between two sub-systems. But DDD made me realize this is a natural situation. More importantly, DDD helped me realized this is a daily routine in businesses. There is never 100% agreement with the money you got and Orders you shipped/delivered. It just takes time.

    This might be obvious for you if you work on e-commerce system selling normal goods. But in systems dealing with virtual goods (book, coupons, accesses, videos, streaming) I noticed that the teams rarely make that distinction. The discrepancy can be easily fixed by triggering release/refund command for the payment. Just as you would do in normal business when you got the money but for some reason, but you could not send products to a customer.

    <%= img_fit("ddd-rails-ruby-saga-clicked/saga_diagram_fail_1.png") %>

### Consequences

What does it do for your system design, how does it split the responsibilities?

* _Payments_ deal only with the `Payment`
  * it does not care if we can or cannot ship the sold goods.
* _Orders_ deal only with the `Order`
  * it does not care how it was paid or not.
* Saga orchestrates the process of keeping Payments and Orders in sync and compensates in the case of failures.


## Learn More

Next week we are going to release our newest book "Domain-Driven Rails".

<div style="margin:auto; width: 480px;">
  <a href="/domain-driven-rails/">
    <img src="//blog-arkency.imgix.net/domain-driven-rails-design/cover7-100.png?w=480&h=480&fit=max">
  </a>
</div>

It already has 140 pages and we've simply waited too long with publishing. So many readers could have already benefited from it.

Subscribe to our [newsletter](http://arkency.com/newsletter) to always receive best discounts and free Ruby and Rails lessons every week.
