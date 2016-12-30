---
title: "Event sourced domain objects in less than 150 LOC"
created_at: 2016-12-30 17:58:23 +0100
kind: article
publish: false
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain', 'event', 'event sourcing' ]
newsletter: :arkency_form
---

Some say: "Event sourcing is hard". Some day: "You need a framework to use Event Sourcing".
Some say: ... Bulshit. You aren't gonna need it.

<!-- more -->

# Start with just a PORO object

Let's use `Payment` as a sample here. The "story" is simple. Customer place an order.
When order is validated the payment is authorized. We do not just create it.
Create is not a word our business experts will use here (hopefully). The customer
authorizes us to charge him some amout of money.
Read this [Udi Dahan's post](http://udidahan.com/2009/06/29/dont-create-aggregate-roots/).

```ruby
class Payment
  InvalidOperation = Class.new(StandardError)

  def self.authorize(amount:, payment_gateway:)
    transaction_id = payment_gateway.authorize(amount)
    puts "Domain model: create new authorized payment #{transaction_id}"
    Payment.new.tap do |payment|
      payment.transaction_id = transaction_id
      payment.amout          = amount
      payment.state          = :authorized
    end
  end

  def success
    puts "Domain model: handle payment gateway OK notification #{transaction_id}"
    raise InvalidOperation unless state == :authorized
    schedule_capture
    state = :successed
  end

  def fail
    puts "Domain model: handle payment gateway NOK notification #{transaction_id}"
    raise InvalidOperation unless state == :authorized
    state = :failed
  end

  def capture(payment_gateway:)
    puts "Domain model: get the money here! #{transaction_id}"
    raise InvalidOperation unless state == :successed
    payment_gateway.capture(transaction_id)
    state = :captured
  end

  private
  attr_reader :transaction_id, :amount, :state

  def schedule_capture
    puts "Domain model: schedule caputre #{transaction_id}"
    # send it to background job for performance reasons
  end
end
```

The payment logic is pretty simple (for a sake of this example, in real life it is much more complicated).
Customer authorizes payment for specified amount. We send the authorization to payment gateway.
After some time (async FTW) payment gateway will respond with OK or NOT OK messsage.
If payment gateway informs us about successful payment it means it has been able to charge customer and
the money is waiting reserved for us.
Successful payments could be then captured (what means asking payment gateway to give us our money).

Ok, so we have our business logic.

# Introducing domain events

First we need to define our domain events.

```ruby
PaymentAuthorized = Class.new(RailsEventStore::Event)
PaymentSuccessed  = Class.new(RailsEventStore::Event)
PaymentFailed     = Class.new(RailsEventStore::Event)
PaymentCaptured   = Class.new(RailsEventStore::Event)
```

Then let's use them to implement our `Payment` domain model.

```ruby
class Payment
  InvalidOperation = Class.new(StandardError)
  include AggregateRoot

  def self.authorize(amount:, payment_gateway:)
    transaction_id = payment_gateway.authorize(amount)
    puts "Domain model: create new authorized payment #{transaction_id}"
    Payment.new.tap do |payment|
      payment.apply(PaymentAuthorized.new(data: {
        transaction_id: transaction_id,
        amount:         amount,
      }))
    end
  end

  def success
    puts "Domain model: handle payment gateway OK notification #{transaction_id}"
    raise InvalidOperation unless state == :authorized
    schedule_capture
    apply(PaymentSuccessed.new(data: {
      transaction_id: transaction_id,
    }))
  end

  def fail
    puts "Domain model: handle payment gateway NOK notification #{transaction_id}"
    raise InvalidOperation unless state == :authorized
    apply(PaymentFailed.new(data: {
      transaction_id: transaction_id,
    }))
  end

  def capture(payment_gateway:)
    puts "Domain model: get the money here! #{transaction_id}"
    raise InvalidOperation unless state == :successed
    payment_gateway.capture(transaction_id, amount)
    apply(PaymentCaptured.new(data: {
      transaction_id: transaction_id,
      amount:         amount,
    }))
  end

  attr_reader :transaction_id
  private
  attr_reader :amount, :state

  def schedule_capture
    puts "Domain model: schedule caputre #{transaction_id}"
    # send it to background job for performance reasons
  end

  def apply_payment_authorized(event)
    @transaction_id = event.data.fetch(:transaction_id)
    @amount         = event.data.fetch(:amount)
    @state          = :authorized
    puts "Domain model: apply payment authorized #{transaction_id}"
  end

  def apply_payment_successed(event)
    @state          = :successed
    puts "Domain model: apply payment successed #{transaction_id}"
  end

  def apply_payment_failed(event)
    @state          = :failed
    puts "Domain model: apply payment failed #{transaction_id}"
  end

  def apply_payment_captured(event)
    @state          = :captured
    puts "Domain model: apply payment captured #{transaction_id}"
  end
end
```

With a little help from [RailsEventStore](http://railseventstore.arkency.com) & [AggregateRoot](https://github.com/arkency/aggregate_root) gems we have now full functional event sourced `Payment` aggregate.

# Plumbing

`RailsEventStore` allows to to read & store domain events. `AggregateRoot` is just a module to include in your aggregate root classes. It provides just 3 methods: `apply`, `load` & `store`. Check the [source code](https://github.com/arkency/aggregate_root/blob/master/lib/aggregate_root.rb) to understand how it works. It's quite simple.

## How to make it work?

The typical lifecycle of that domain object is:

* initialize new or restore it from domain events
* perform some business logic by invoking a method
* store domain events generated

Let's define our process. To help us use it later we will define an application service class that will handle all "plumbing" for us.

```ruby
class PaymentsService
  def initialize(event_store:, payment_gateway:)
    @event_store     = event_store
    @payment_gateway = payment_gateway
  end

  def authorize(amount:)
    payment = Payment.authorize(amount: amount, payment_gateway: payment_gateway)
    payment.store("Payment$#{payment.transaction_id}", event_store: event_store)
  end

  def success(transaction_id:)
    payment = Payment.new
    payment.load("Payment$#{transaction_id}", event_store: event_store)
    payment.success
    payment.store("Payment$#{transaction_id}", event_store: event_store)
  end

  def fail(transaction_id:)
    payment = Payment.new
    payment.load("Payment$#{transaction_id}", event_store: event_store)
    payment.fail
    payment.store("Payment$#{transaction_id}", event_store: event_store)
  end

  def capture(transaction_id:)
    payment = Payment.new
    payment.load("Payment$#{transaction_id}", event_store: event_store)
    payment.capture(payment_gateway: payment_gateway)
    payment.store("Payment$#{transaction_id}", event_store: event_store)
  end

  private
  attr_reader :event_store, :payment_gateway
end
```

Now we need only adapter for our payment gateway & instance of `RailsEventStore::Client`.

```ruby
class PaymentGateway
  def initialize(transaction_id_generator)
    @generator = transaction_id_generator
  end

  def authorize(amount)
    puts "Payment gateway: authorize #{amount}"
    @generator.call # let's pretend we starting some process here and generated transaction id
  end

  def capture(transaction_id, amount)
    # always ok, yeah we just mock it ;)
    puts "Payment gateway: capture #{amount} for #{transaction_id}"
  end
end

event_store = RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
```

# Happy path

```ruby
random_id = SecureRandom.uuid
gateway = PaymentGateway.new(-> { random_id })
service = PaymentsService.new(event_store: event_store, payment_gateway: gateway)
service.authorize(amount: 500)
# here we wait for notification from payment gateway and when it is ok then:
service.success(transaction_id: random_id)
# now let's pretend our background job has been scheduled and performed:
service.capture(transaction_id: random_id)
```

Complete code (149 LOC) is available [here](https://gist.github.com/mpraglowski/e744d720e5340ec87aedc6e4c82dd86f).

# Is it worth the effort?

Of course it is additional effort. Of course it requires more code (and probably even more as I have not shown read models here).
Of course it required a change in Your mindset. But is it worth it?

I've posted [Why use Event Sourcing](http://blog.arkency.com/2015/03/why-use-event-sourcing/) some time ago.
The auditability of all actions is priceless (especially when you deal with customers money). All state changes are made only by applying domain event, so you will not have any change that is not stored in domain events (which are your audit log).
Avoiding impedance mismatch between object oriented and relational world & not having `ActiveRecord` in your domain model - another win for me. By using CQRS and read models (maybe not just a single one, polyglot data is BIG win here) you could make your application more scallable, move available. Decoupling different parts of the system (bounded contextx) is also much easier.

# Wants to learn more?

This is a very basic example. There is much more to learn here, naming some only:
* defining bounded contexts
* using sagas / process managers to hadle long running processes
* CQRS architecture & using read models
* patterns how to use strentch of event sourcing
* and when not to use it

If you are interested join our upcomming [Rails + Domain Driven Design Workshop](http://blog.arkency.com/ddd-training/). Next edition will be held on **12-13th January 2017** (Thursday & Friday) in Wrocław, Poland. Workshop will be held in English.
