---
title: "Using domain events as success/failure messages"
created_at: 2015-05-15 12:59:51 +0200
kind: article
publish: false
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain', 'event', 'event sourcing' ]
newsletter: :skip
newsletter: :arkency_form
img: "/assets/images/events/failure_domain_event-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/events/failure_domain_event-fit.jpg" width="100%">
  </figure>
</p>

## When you publish an event on success make sure you publish one failure also

We had an issue recently with one of our internal gems used to handle all communication with external payment gateway. We are using gems to abstract bounded context (payments here) and to have abstract anti-corruption layer on top of external system's API.

<!-- more -->

When our code is triggered (no matter how in scope of this blog post) we are using our gem's method to handle payments.

```
#!ruby
...
payment_gateway.refund(transaction)
...
```

There are different payment gateways - some of them responds synchronously some of them prefer asynchronous communication. To  avoid coupling we publish an event when payment gateway responds.

```
#!ruby
class TransactionRefunded < RailsEventStore::Event

class PaymentGateway
  RefundFailed = Class.new(StandardError)

  def initialize(event_store = RailsEventStore::Client.new, api = SomePaymentGateway::Client.new)
    @api = api
    @event_store = event_store
  end

  def refund(transaction)
    api.refund(transaction.id, transaction.order_id, transaction.amount)
    transaction_refunded(transaction)
  rescue
    raise RefundFailed
  end
  # there are more but let's focus only on refunds now

  private
  attr_accessor :event_store, :api

  def transaction_refunded(transaction)
    event = TransactionRefunded.new({ data: {
      transaction_id: transaction.id,
      order_id:transaction.order_id,
      amount:transaction.amount }})
    event_store.publish(event, order_stream(transaction.order_id)
  end

  def order_stream(order_id)
    "order$#{order_id}"
  end
end
```
(very simplified version - payments are much more complex)


You might have noticed that when our API call fails we rescue an error and raise our one. It is a way to avoid errors from 3rd party client leak to our application code. Usually that's enough and our domain code will cope well with failures.

But recently we got a problem. Business requirements were: _When refunding a batch of transactions gather all the errors and send them by email to support team to handle them manually_.

That we have succeeded to implement correctly. But some day we have received a request to explain why there were no refunds for  a few transactions.

## And then it was trouble

First we've done was to check history of events for the aggregate performing the action (Order in this case). We have found entry that refund of order was requested (it is done asynchronously) but there were no records of any transaction refunds.

It could not be any. Because we did not published them :( This is how this code should look like:

```
#!ruby
class TransactionRefunded < RailsEventStore::Event
class TransactionRefundFailed < RailsEventStore::Event

class PaymentGateway
  RefundFailed = Class.new(StandardError)

  def initialize(event_store = RailsEventStore::Client.new, api = SomePaymentGateway::Client.new)
    @api = api
    @event_store = event_store
  end

  def refund(transaction)
    api.refund(transaction.id, transaction.order_id, transaction.amount)
    transaction_refunded(transaction)
  rescue => error
    transaction_refund_failed(transaction, error)
  end
  # there are more but let's focus only on refunds now

  private
  attr_accessor :event_store, :api

  def transaction_refunded(transaction)
    publish(TransactionRefunded, transaction)
  end

  def transaction_refund_failed(transaction, error)
    publish(TransactionRefundFailed, transaction) do |data|
      data[:error] = error.message
    end
  end

  def publish(event_type, transaction)
    event_data = { data: {
      transaction_id: transaction.id,
      order_id:       transaction.order_id,
      amount:transaction.amount
    }}.tap do |data|
      yield data if block_given?
    end
    event = event_type.new(data)
    event_store.publish(event, order_stream(transaction.order_id)
  end

  def order_stream(order_id)
    "order$#{order_id}"
  end
end
```

## But wait, why not just change error handling?

Of course we could do it without use of domain events that are persisted in [Rails Event Store](https://github.com/arkency/rails_event_store) but possibility of going back in the history of the aggregate is priceless. Just realise that a stream of domain events that are responsible for changing the state of an aggregate are the full audit log that is easy to present to the user.

And one more thing: you want to have a monthly report of failed refunds of transactions? Just implement handler for TransactionRefundFailed event and do you grouping, summing & counting and store the results. And by replaying all past TransactionRefundFailed events with use of your report building handler you will get report for the past months too!
