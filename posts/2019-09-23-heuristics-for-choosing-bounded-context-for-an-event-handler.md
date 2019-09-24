---
title: "Heuristics for choosing bounded context for an event handler"
created_at: 2019-09-23 10:55:30 +0200
kind: article
publish: true
author: Rafał Łasocha
newsletter: :skip
---

Some time ago I was implementing a feature. As part of this I was, of course, writing a bunch of event handlers.
At some point, I've realized I didn't put much thought when choosing the bounded context to which the event handlers should belong. It was mostly driven by intuition or some mechanical routine that upfront design.

<!-- more -->

## The code

Let's consider the popular example, of "Order with shipping" and few different approaches.

Of course, one solution is:

```ruby
module Shipping
  # handler reacting to Ordering::OrderCompleted
  class ShipOrderHandler
    def call(fact)
      service = Shipping::Service.new
      service.call(
        Shipping::PrepareShipment.new(
          order_id: fact.data.fetch(:order_id),
          # ...
        )
      )
    end
  end
end
```

The other however is

```ruby
module Ordering
  # handler reacting to Ordering::OrderCompleted
  class ShipOrderHandler
    def call(fact)
      service = Shipping::Service.new
      service.call(
        Shipping::PrepareShipment.new(
          order_id: fact.data.fetch(:order_id),
          # ...
        )
      )
    end
  end
end
```

Which one to choose?
Both fact and commands are something we usually consider a "public API" (by a public, I mean public for bounded contexts within an organization, not public to the whole world. Or published language, how some would probably call it).

## Context maps

The first suggestion of my colleagues was: do what your context map tells you.
In that popular case of some eCommerce, there's a high chance that `Ordering` and `Shipping` are in upstream-downstream relation, `Ordering` being upstream one.
Therefore, the Shipping should "adjust" to Ordering, so it makes sense that the handler is in the `Shipping` bounded context.

On the other hand, we can imagine that we want refund the order when we receive information from the shipping company that the package was destroyed, so we make a handler:

```ruby
module Shipping
  # handler reacting to Shipping::PackageDestroyed
  class RefundOrderAfterPackageBeingDestroyedHandler
    def call(fact)
      service = Ordering::Service.new
      service.call(
        Ordering::RefundOrder.new(
          order_id: fact.data.fetch(:order_id),
          # ...
        )
      )
    end
  end
end
```

In this case, we have an event handler in the same BC as published domain event, because again, we want `Ordering` to know as little as possible (preferably nothing) about `Shipping`.

## Process managers

The other suggestion given by Andrzej was: none of them.
Instead of scheduling `PrepareShipment` command in either one of these bounded contexts, we can extract a process manager which manages the whole "order flow".

Why would we like to do that?

Firstly, you end up with no coupling between `Ordering` and `Shipping` (at least when it comes to that particular flow). The whole coupling is in the `OrderFlow` process manager, and this is a place you want to go when you want to understand how the whole flow is working.

Secondly, as told nicely [in a talk by Bernd Rucker about process managers](https://skillsmatter.com/skillscasts/9853-long-running-processes-in-ddd), it allows you to achieve less coupled code in more complex scenarios.

Imagine that you want to add pretty packaging if the buyer had a "VIP status".
In that case, you either need to have information about which buyers are VIP in the `Shipping` BC (which sounds like a lot of work to do and adding complexity only to make one conditional work) or you add a conditional in the handler, like so:

```ruby
module Shipping
  class ShipOrderHandler #reacting to Ordering::OrderCompleted
    def call(fact)
      service = Shipping::Service.new
      if fact.data.fetch(:vip_status)
        service.call(
          Shipping::PreparePrettyShipment.new(
            order_id: fact.data.fetch(:order_id),
            # ...
          )
        )
      else 
        service.call(
          Shipping::PrepareRegularShipment.new(
            order_id: fact.data.fetch(:order_id),
            # ...
          )
        )
      end
    end
  end
end
```

As a result, you end up with domain logic in the event handler (which is sometimes fine, but it's always best to have as little of it as possible in the handlers).

By having a process manager for the order flow, process manager have to know about the VIP status of the buyer, but it sounds far more reasonable than forcing `Shipping` to know it (especially that there can be some additional actions in the other BCs done only if the buyer is a VIP).

## Other ...?

Having said that, these were two heuristics, there are possibly more.
What are your heuristics when deciding about a place where a given event handler resides?
Do you use the ones mentioned above?
Share your opinion :)


_Thanks to [@pawelpacana](https://twitter.com/pawelpacana/), [@szymonfiedler](https://twitter.com/szymonfiedler/), and [@andrzejkrzywda](https://twitter.com/andrzejkrzywda/) for the discussion_

