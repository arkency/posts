---
created_at: 2018-03-03 12:08:25 +0100
publish: true
author: Robert Pankowecki
tags: [ 'rails_event_store', 'ruby_event_store', 'ddd', 'release' ]
newsletter: arkency_form
---

# Rails Event Store - better APIs coming

[Rails Event Store v0.26](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.26) is here with new, nicer APIs. Let's have a look at some of those changes:

<!-- more -->

## Persistent subscribers/handlers

`subscribe` used to take 2 arguments: `handler` (instance or class or proc) and `event_types` (that the handler was subscribed to).

```ruby
class OrderSummaryEmail
  def call(event)
    order = Order.find(event.data.fetch(:event_id))
    OrderMailer.summary(order).deliver_later
  end
end

client = RailsEventStore::Client.new
client.subscribe(OrderSummaryEmail.new, [OrderPlaced])
```

This can be now used as

```ruby
client.subscribe(OrderSummaryEmail.new, to: [OrderPlaced])
```

I think this named argument `to:` makes it much more readable.

We also made it possible to subscribe `Proc` in much nicer way. Instead of:

```ruby
OrderSummaryEmail = -> (event) {
  order = Order.find(event.data.fetch(:event_id))
  OrderMailer.summary(order).deliver_later
}

client = RailsEventStore::Client.new
client.subscribe(OrderSummaryEmail, [OrderPlaced])
```

you can now pass the block directly.

```ruby
client = RailsEventStore::Client.new
client.subscribe(to: [OrderPlaced]) do |event|
  order = Order.find(event.data.fetch(:event_id))
  OrderMailer.summary(order).deliver_later
end
```

## Temporary subscribers/handlers

I really didn't like the API that we had for temporary subscribers. It looked like this:

```ruby
client = RailsEventStore::Client.new
client.subscribe(OrderSummaryEmail, [OrderPlaced]) do
  PlaceOrder.call
end
```

It was inconvenient because there was no idiomatic way to pass two blocks of code. One for the subscriber and one for the part of code during which we want the temporary subscribers to be active:

```ruby
order_summary_email = -> (event) {
  order = Order.find(event.data.fetch(:event_id))
  OrderMailer.summary(order).deliver_later
}

client = RailsEventStore::Client.new
client.subscribe(order_summary_email, [OrderPlaced]) do
  PlaceOrder.call
end
```

Interestingly, `ActiveSupport::Notifications` have a similar limitation:

```ruby
subscriber = lambda {|*args| ... }
ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
  # ...
end
```

Here is the new API that you can use.

```ruby
client = RailsEventStore::Client.new
client.within do
  PlaceOrder.call
end.subscribe(to: [OrderPlaced]) do
  order = Order.find(event.data.fetch(:event_id))
  OrderMailer.summary(order).deliver_later
end.call
```

It's a chainable API which could be used in controllers or imports to find out what happened inside them:

```ruby
client.within do
  PlaceOrder.call
end.subscribe(to: [OrderPlaced]) do |ev|
  head :ok
end.subscribe(to: [OrderRejected]) do |ev|
  render json: {errors: [...]}
end.call
```

```ruby
success = 0
failure = 0
client.within do
  ImportCustomer.call
end.subscribe(to: [CustomerImported]) do |_|
  success += 1
end.subscribe(to: [CustomerImportFailed]) do |_|
  failure += 1
end.call
```

Of course, you can still pass the subscriber as a first argument. It does not have to be a block.

```ruby
client.within do
  PlaceOrder.call
end.subscribe(order_summary_email, to: [OrderPlaced]).call
```

## AggregateRoot#on

AggregateRoot now allows to easily define handler methods (reacting to an event being applied on an object). So instead of using underscored method names such as `def apply_order_submitted(event)` which follow our default convention, you can just say `on OrderSubmitted do |event|`.

That's how it was (and is still supported):

```ruby
class Order
  include AggregateRoot
  class HasBeenAlreadySubmitted < StandardError; end
  class HasExpired < StandardError; end

  def initialize
    @state = :new
  end

  def submit
    raise HasBeenAlreadySubmitted if state == :submitted
    raise HasExpired if state == :expired
    apply OrderSubmitted.new(data: {delivery_date: Time.now + 24.hours})
  end

  def expire
    apply OrderExpired.new
  end

  private
  attr_reader :state

  def apply_order_submitted(event)
    @state = :submitted
    @delivery_date = event.data.fetch(:delivery_date)
  end

  def apply_order_expired(_event)
    @state = :expired
  end
end
```

That's the new way:

```ruby
class Order
  include AggregateRoot
  class HasBeenAlreadySubmitted < StandardError; end
  class HasExpired < StandardError; end

  def initialize
    @state = :new
  end

  def submit
    raise HasBeenAlreadySubmitted if state == :submitted
    raise HasExpired if state == :expired
    apply OrderSubmitted.new(data: {delivery_date: Time.now + 24.hours})
  end

  def expire
    apply OrderExpired.new
  end

  on OrderSubmitted do |event|
    @state = :submitted
    @delivery_date = event.data.fetch(:delivery_date)
  end

  on OrderExpired do |_event|
    @state = :expired
  end

  private

  attr_reader :state
end
```

The nice thing about `on OrderSubmitted do |event|` is that it makes your codebase more grep-able when you are looking for where `OrderSubmitted` is used.

We have some other interesting ideas on how to make the code using Rails Event Store more readable and easier to follow and adapt to your needs:

* [We are working on improving the API for reading events](https://github.com/RailsEventStore/rails_event_store/issues/184)
* [and on streamlining the configuration](https://github.com/RailsEventStore/rails_event_store/issues/153)

## Read more

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our everyday struggles and solutions for building maintainable Rails apps which don't surprise you.

Also worth reading:

* [Why Event Sourcing basically requires CQRS and Read Models](/why-event-sourcing-basically-requires-cqrs-and-read-models/) - Event sourcing is a nice technique with certain benefits. But it has a big limitation. As there is no concept of easily available current state, you can’t easily get an answer to a query such as _give me all products with available quantity lower than 10_.
* [Application Services - 10 common doubts answered](/application-service-ruby-rails-ddd/) - You might have heard about the Domain-Driven Design approach to building applications. In this approach, there is this horizontal layer called Application Service. But what does it do?
* [On ActiveRecord callbacks, setters and derived data](/on-activerecord-callbacks-setters-and-derived-data/) - Callbacks are still being used in the wild in many scenarios, so why not write about this topic a bit one more time with different examples.
