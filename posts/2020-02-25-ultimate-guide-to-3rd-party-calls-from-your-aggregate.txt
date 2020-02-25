---
title: "Ultimate guide to 3rd party calls from your Aggregate"
created_at: 2020-02-25 14:13:02 +0100
kind: article
publish: false
author: Szymon Fiedler
newsletter: :skip
---

If you ever wondered how to make 3rd party API call from Aggregate and not clutter it with dependencies, you may find this post interesting.

Some time ago I faced that problem while implementing `Payment` aggregate. Everything looked quite simple until the time a real request to payment gateway had to be performed.

I started wondering what is the right spot for that operation? Initially, I tried to do it in command handler. Let's take a look at the snippet below.

```ruby
class Payment
  include AggregateRoot

  CreditCardChargedAlready = Class.new(Error)

  def initialize(id)
    @id = id
  end

  def charge_credit_card(amount)
    raise CreditCardChargeAlready if charged?
    apply(CreditCardCharged.new(data: { payment_id: @id, amount: amount })
  end

  on CreditCartCharged do |event|
    @state = :charged
  end

  private

  def charged?
    @charged
  end
end

class OnChargeCreditCard
  def call(cmd)
    ApplicationRecord.transaction do
      gateway.purchase(Integer(cmd.amount * 100), cmd.credit_card, { payment_id: cmd.payment_id })
      with_aggregate(Payment, cmd.payment_id) do |payment|
        payment.charge_credit_card(cmd.total_amount)
      end
    rescue Payment::CreditCardChargedAlready => doh
      handle_disaster(doh)
    rescue PaymentGateway::Error => doh
      handle_payment_error(doh)
    end
  end
end
```

Command handler gets command, makes API call to the gateway and then event is applied to the aggregate. But what if another command happens and customer will be charged twice? That's why we used aggregate pattern here, to guard the invariants. But this won't work as expected with current implementation, since gateway request happens before aggregate gets called. Let's change the order then:

```ruby
def call(cmd)
  ApplicationRecord.transaction do
    with_aggregate(Payment, cmd.payment_id) do |payment|
      payment.charge_credit_card(cmd.total_amount)
    end
    gateway.purchase(Integer(cmd.amount * 100), cmd.credit_card, { payment_id: cmd.payment_id })
  end
end
```

This looks good at first sight. But what if payment doesn't get accepted because of invalid credit card data or random network error appear? We already applied an event, event handlers started processing it. In effect user has received e-mail about successful payment, he got link to download virtual products, etc. We could make compensating operation, of course. But it is additional complexity which we may not a possibility to deal with right now.

We could other way around and expose `Payment` internal state via `charged?` method to command handler and make the decision there. Even more, `CreditCardCharged` event could be published from command handler too. Introduction of aggregate wouldn't make any sense in such approach, it would be obsolete.

Passing gateway as a dependency and calling it inside Payment aggregate sounds tempting, let's see:

```ruby
class Payment
  include AggregateRoot

  CreditCardChargedAlready = Class.new(Error)
  CreditCardChargeFailed   = Class.new(Error)

  def initialize(id, gateway)
    @id      = id
    @gateway = gateway
  end

  def charge_credit_card(amount, credit_card)
    raise CreditCardChargeAlready if charged?
    @gateway.purchase(Integer(amount * 100), credit_card, { payment_id: @id })
    apply(CreditCardCharged.new(data: { payment_id: @id, amount: amount })
  rescue PaymentGateway::Error => doh
    raise CreditCardChargeFailed.new(doh)
  end

  on CreditCartCharged do |event|
    @state = :charged
  end

  private

  def charged?
    @charged
  end
end

class OnChargeCreditCard
  def call(cmd)
    ApplicationRecord.transaction do
      with_aggregate(Payment, cmd.payment_id, gateway) do |payment|
        payment.charge_credit_card(cmd.total_amount, cmd.credit_card)
      end
    rescue Payment::CreditCardChargedAlready => doh
      handle_disaster(doh)
    rescue Payment::CreditCardChargeFailed => doh
      handle_payment_failure(doh)
    end
  end
end
```

`Payment` class got cluttered and its responsibilities expanded. I'm not convinced that such technical details are the part of aggregate interests and I disliked this approach as soon as I implemented it. I started thinking how to make decision about the payment inside the aggregate but keep all the payment technicals out of it.

```ruby
class Payment
  include AggregateRoot

  CreditCardChargedAlready = Class.new(Error)
  CreditCardChargeFailed   = Class.new(Error)

  def initialize(id)
    @id = id
  end

  def charge_credit_card(amount, request)
    raise CreditCardChargeAlready if charged?
    response = request.()
    if response.success?
      apply(CreditCardCharged.new(data: { payment_id: @id, amount: amount })
    else
      raise CreditCardChargeFailed.new(response)
    end
  end

  on CreditCartCharged do |event|
    @state = :charged
  end

  private

  def charged?
    @charged
  end
end

class OnChargeCreditCard
  def call(cmd)
    ApplicationRecord.transaction do
      with_aggregate(Payment, cmd.payment_id) do |payment|
        payment.charge_credit_card(cmd.total_amount, cmd.credit_card, request)
      end
    rescue Payment::CreditCardChargedAlready => doh
      handle_disaster(doh)
    rescue Payment::CreditCardChargeFailed => doh
      handle_payment_failure(doh)
    end
  end

  private

  def request
    -> { gateway.purchase(Integer(cmd.amount * 100), cmd.credit_card, { payment_id: cmd.payment_id }) }
  end
end
```

Instead of passing gateway as a dependency, we pass a payment gateway call wrapped in lambda. The only thing we need to do is to check whether response is successful to decided whether apply `CreditCardCharged` event or not. We assume that payment gateway call returns `Response` object responding to `success?` method, but it's not a topic of this post and I believe that you know how wrap gateways response into Value Object.

Lambda gives us great possibility of currying arguments and getting some from inside of aggregate state. Let's use two-step payment scenario like CC _Authorization_ & _Capture_. Often you need to refer original transaction when capturing the real money. Just prepare `request` as a lambda with argument:

```ruby
def request
  ->(transaction_id) { gateway.capture(transaction_id, Integer(cmd.amount * 100), cmd.credit_card, { payment_id: cmd.payment_id }) }
end
```

As a bonus, you get nice and clean aggregate tests without messing with mocks, VCRs, massive fake gateway adapters. Aggregate can remain interested in single method of `Response` object only.

```ruby
class PaymentTest < ActiveSupport::TestCase
  def test_credit_card_charge_succeeded
    payment_id = SecureRandom.uuid
    payment    = Payment.new(payment_id)
    payment.charge_credit_card(amount, credit_card, successful_request)

    assert_changes(payment.unpublished_events, [
        CreditCardPaymentCharged.new(
          data: {
            payment_id:     payment_id,
            amount:         BigDecimal("123.45"),
            transaction_id: '53433'
          }
        )
      ]
    )
  end

  def test_credit_card_charge_failed
    payment = Payment.new(SecureRandom.uuid)

    assert_raises(Payment::AlreadyAuthorized) do
      payment.charge_credit_card(amount, credit_card, failure_request)
    end
  end

  private

  def amount
    BigDecimal("123.45")
  end

  def credit_card
    {
      name:               'Jane Doe',
      number:             '4111 1111 1111 1111',
      month:              1,
      year:               2028,
      verification_value: 123,
      brand:              'visa'
    }
  end

  def transaction_id
    '12345'
  end

  def successful_request
    ->(*) {Struct.new(:success?, :transaction_id).new(true, transaction_id)}
  end

  def failure_request
    ->(*) {Struct.new(:success?, :transaction_id).new(false, transaction_id)}
  end
end
```
