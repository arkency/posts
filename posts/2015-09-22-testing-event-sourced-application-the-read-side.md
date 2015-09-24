---
title: "Testing Event Sourced application - the read side"
created_at: 2015-09-22 09:19:36 +0200
kind: article
publish: false
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain', 'event', 'event sourcing', 'tests', 'TDD' ]
newsletter: :skip
newsletter_inside: :rails_event_store
img: "/assets/images/events/black-and-white-car-vehicle-vintage-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/events/black-and-white-car-vehicle-vintage-fit.jpg" width="100%">
  </figure>
</p>

In my last post, I've presented a way how to test an Event Sourced application. But again (yes, again and again) some part was missing there. It is clearly visible when you look at test coverage:

<img src="/assets/images/events/sample-test-coverage.png"/>

The missing part, of course, is the read side.

<!-- more -->

This application uses read model that are build by a set of event denormalisers based on an events published by write side (an Aggregate to be specific). Current flow is as follows:

* Aggregate’s method produces a domain event
* When command handler is about to finish it published all domain events produced by the aggregate to Event Store
* Rails Event Store publishes received domain events to all subscribers that have been subscribed for a specific event type.
* Denormalisers (in our application the subscribed event handlers) handle the domain event and prepare a read model so it could be easily and quickly read by a website.

The read model (a.k.a **projection** because it is a projection of domain events) should be build based on the set of domain events.
The subset of domain events needed to handle depends on the needs, depends on which domain events have the impact on a projection state.
The source of domain events could be a single aggregate’s stream, a class of streams (i.e. all streams of Order’s aggregates) or all domain events cherry-picked by a projection.

## Given current state
How to build an initial state when you don’t have a state?
This should be quite easy. Any state is a derivative of domain events. You could build any state by applying domain events.

To build a state you just need some events:

```
#!ruby
require 'test_helper'

module Denormalizers
  class ItemRemovedFromBasketTest < ActiveSupport::TestCase
    include EventStoreSetup

    test 'remove item when quantity > 1' do
      product = Product.create(name: 'something')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "123/08/2015"
      # arrange
      event_store.publish_event(Events::OrderCreated.create(
                                order_id, order_number, customer.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(
                                order_id, product.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(
                                order_id, product.id))

      # act ...

      # assert ...
    end
  end
end
```

There is always a problem how initial state for a test should be build. With the use of event handlers it should be easy to build it - all you need is to define a set of domain events and pass them through the event handler.

## When an event happened

Each event handler is a function: `f(state, event) -> state`
In our case, the acting part of the test will be sending a domain event to an event handler and by knowing the initial state and payload of the domain event we could define our expected state.

```
#!ruby
require 'test_helper'

module Denormalizers
  class ItemRemovedFromBasketTest < ActiveSupport::TestCase
    include EventStoreSetup

    test 'remove item when quantity > 1' do
      # ...
      # arrange
      event_store.publish_event(Events::OrderCreated.create(
                                order_id, order_number, customer.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(
                                order_id, product.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(
                                order_id, product.id))

      # act
      event_store.publish_event(Events::ItemRemovedFromBasket.create(
                                order_id, product.id))

      # assert ...
    end
  end
end
```

## Expect stage change

There could be various types of event handlers. There is no one way of asserting the output. In this case, where event handlers (denormalisers) produce relational denormalised model the thing we check is if the model is build as expected.

```
#!ruby
require 'test_helper'

module Denormalizers
  class ItemRemovedFromBasketTest < ActiveSupport::TestCase
    include EventStoreSetup

    test 'remove item when quantity > 1' do
      product = Product.create(name: 'something')
      customer = Customer.create(name: 'dummy')
      order_id = SecureRandom.uuid
      order_number = "123/08/2015"
      # arrange
      event_store.publish_event(Events::OrderCreated.create(
                                order_id, order_number, customer.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(
                                order_id, product.id))
      event_store.publish_event(Events::ItemAddedToBasket.create(
                                order_id, product.id))

      # act
      event_store.publish_event(Events::ItemRemovedFromBasket.create(
                                order_id, product.id))

      # assert
      assert_equal(::OrderLine.count, 1)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product.id)
      assert_equal(order_line.product_name, 'something')
      assert_equal(order_line.quantity , 1)
    end
  end
end
```

## ... or an exception?

No errors here - what has happened it has happened - you could not change the past. If you could not handle event you should fail? … or …

## ... or an event published

Some might ask: But what is we could not execute our event handler? No exceptions? Then what?
The answer is: more domain events ;)
The domain event is just a message. If you use queues, you might know how to deal with messages that could not be processed. There are several patterns: retry it, skip it, … and finally if you really could not do anything you will send that message to dead letter queue.
Similar actions could be applied here, retry later if the previous message has not been processed yet, skip it if it has been already processed or publish a compensation message if your domain model should take some actions.
