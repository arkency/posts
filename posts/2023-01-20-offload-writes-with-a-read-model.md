---
created_at: 2023-01-20 12:56:50 +0100
author: Piotr Jurewicz
tags: []
publish: false
---

# Offload writes with a read model

Imagine following business requirement:

*All the products should be reserved for a customer on order submission.
Simply adding items to the cart does not guarantee products availability.
However, the customer should not be able to add to the cart a product which is already not available.*


Actually, it is not any fancy requirement. I used to work on ecommmerce project with such feature.
When I was diving deeper into DDD, I started to think how to meet this requirement in a proper way.

At first, the rule *"the customer should not be able to add to the cart a product which is already out of stock"* sound like an intuitive invariant to me.
I have even implemented a `Inventory::CheckAvailability` command which was invoked on `Inventory::InventoryEntry` aggregate.
In fact, It was doing nothing with aggregate's internal state. This method was just raising an error if the product was out of stock.
It was a really awful candidate for a command. It was obfuscating the aggregate's code which should be minimalistic and did no changes within a system.

When I realized that my command makes nothing but the read, I started looking for a solution in read model.
An efficient read model is eventually consistent. It is not a problem for our case.
In fact, checking availability on the aggregate neither was immediate consistent. Just 1 ms after check, it could change.
That's just because that command didn't change state!

<!-- more -->

FIXME: Place post body here.

```ruby
Person.new.show_secret
# => 1234vW74X&
```
