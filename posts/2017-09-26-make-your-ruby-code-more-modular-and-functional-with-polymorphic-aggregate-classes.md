---
title: "Make your Ruby code more modular and functional with polymorphic aggregate classes"
created_at: 2017-10-16 16:12:56 +0200
kind: article
publish: true
author: Andrzej Krzywda
tags: ['ddd', 'aggregate', 'ruby', 'event sourcing', 'domain event']
---

For the last year, I've been using Rails (as I do for the last 10 years), but last year it was almost exclusively Rails "Not the Rails Way". We have successfully combined Rails with Domain-Driven Design, CQRS and Event Sourcing. Over the last year, most of the business logic state in my apps was persisted using events, not the "let's just store the last state and forget the history" ;)

In short, I was using a lot of Event Sourcing.

<!-- more -->

Event Sourcing is not easy and it does take time to get used to it. We are event sourcing our aggregates. Aggregates are like the more important objects in our systems, like Order, Product, User, Project etc.

Aggregates are just normal objects, but if you combine them with event sourcing they take this specific shape. We have developed a library called AggregateRoot (part of our [RailsEventStore](http://railseventstore.org) ecosystem of tooling), which helps a lot with Event Sourcing.

Once you start modelling your domain (aka what objects we should have and how they communicate), you will arrive to the problem of finding ways of making your aggregates smaller.

Today, I'd like to share an experimental technique with you. For now it's just a proof of concept, but hopefully soon this will be something I will be able to use in my apps.

Usually, I'd have a class like `Order` and it would have several methods, like:

```ruby

class Order
  def place
  end

  def pay
  end

  def cancel
  end
end
```

Depending on the current state of the order, we'd disallow certain actions, either via exception or whichever else favourite technique for returning the result:

```ruby
class Order
  def place
  end
  
  def pay
    raise OrderNotPlacedYet if @state != :placed
  end
end
```

In a way, this is like a state machine and could be implemented with some help of the state_machine gems or similar.

I wanted to try out a different attempt. For each state of the order let's have a separate class and use polymorphism to call the methods.

The initial proof of concept looks like this:

```ruby
class OrderPlaced    < RailsEventStore::Event; end
class OrderPaid      < RailsEventStore::Event; end
class OrderCancelled < RailsEventStore::Event; end

class Order
  include AggregateRoot

  def place
    apply(OrderPlaced.new)
  end

  private

  def apply_order_placed(_)
    PlacedOrder.new
  end
end

class PlacedOrder
  include AggregateRoot

  def pay
    apply(OrderPaid.new)
  end

  private

  def apply_order_paid(_)
    PaidOrder.new
  end
end

class PaidOrder
  include AggregateRoot

  def cancel
    apply(OrderCancelled.new)
  end

  private

  def apply_order_cancelled(_)
    CancelledOrder.new
  end
end

class CancelledOrder
  include AggregateRoot
end
```

As you can see after every call to the public method, we call the `apply` method - this is provided by the AggregateRoot gem. Under the hood it makes sure the event is published and then it calls the appropriate private method. Those private methods usually just set the state. However, in my spike, they actually also return a new kind of object, depending on the state.

It's still not production-ready, but I find it a good start for more research. I like how the classes become small. 

Most importantly I like how all the if statements disappear and I don't even need to signal the result anymore. In pure OOP, calling other objects is sending messages to them. In Ruby it's actually exactly like that. Under the hood, we have the `send` mechanism for that. If no such method exists, then the message can't be delivered. In a way, this is relying on the message-driven approach in Ruby objects.

Another nice side-effect (pun intended) is the fact that the objects are now immutable. They don't change existing state, they return a new state instead. Which brings OOP and FP nicely together in a nice domain modelling example.

If you want to learn more about aggregates and event sourcing with Ruby/Rails consider buying our ["Domain-Driven Rails"](http://blog.arkency.com/domain-driven-rails/) book. 

If you wonder where such a OOP/FP merge can bring us, consider learning more about [Serverless](https://speakerdeck.com/andrzejkrzywda/serverless), which is like a DDD/Microservices/FP heaven.

Thanks for reading!

