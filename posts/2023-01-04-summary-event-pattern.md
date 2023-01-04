---
created_at: 2023-01-04 11:19:39 +0100
author: Piotr Jurewicz
tags: []
publish: false
---

# Reduce the communication between bounded contexts with a Summary Event pattern

## Granularity or redundancy?

I can see no point for Invoicing Bounded Context to know about an order that is not submitted yet.
However, when the order is finally submitted, Invoicing needs to know all its details.
All the operations of adding and removing items from the order are not relevant for Invoicing.
It is only the final state of the order that matters.
In this case, we will gain by reducing the communication between the bounded contexts. Code will be simpler and more maintainable.
Dumping all the order details into OrderSubmitted event looks pretty tempting.


On the other hand, if your business is for example a fast food restaurant, you might have some bounded contexts that want to know about order item being added to the cart even it is not submitted yet.
In this kind of business, fast fulfillment may be more important than some loses when the order is altered or abandoned before it is submitted.
In this case, you would rather to stick to granular events.


## Why not both?

This is where the Summary Event pattern comes in.


<!-- more -->

FIXME: Place post body here.

```ruby
Person.new.show_secret
# => 1234vW74X&
```
