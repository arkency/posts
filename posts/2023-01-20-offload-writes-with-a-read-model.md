
---
created_at: 2023-02-06 12:56:50 +0100
author: Piotr Jurewicz
tags: ['read model', 'cqrs', 'commands']
publish: false
---

# Offloading write side with a read model

Imagine the following business requirement:

*All the products should be reserved for a customer on order submission.
Simply adding items to the cart does not guarantee product availability.
However, the customer should not be able to add a product that is already unavailable.*

<!-- more -->

Actually, it is not any fancy requirement. I used to work on e-commmerce project with such a feature.
When diving deeper into DDD, I started thinking about how to properly meet this requirement.

At first, the rule *"the customer should not be able to add to the cart a product which is already out of stock"* sounded like an intuitive invariant to me.
I have even implemented a `Inventory::CheckAvailability` command which was invoked on `Inventory::InventoryEntry` aggregate.
```ruby
def check_availability!(desired_quantity)
  return unless stock_level_defined?
  raise InventoryNotAvailable if desired_quantity > availability
end
```
In fact, It was doing nothing with the aggregate's internal state. This method was just raising an error if the product was out of stock.
**It was a terrible candidate for a command**. It was obfuscated the aggregate's code, which should stay minimalistic, and did no changes within the system.

When I realized that my command made nothing but the read, I started looking for a solution in the read model.
An efficient read model is eventually consistent. It is not a problem in our case.
In fact, placing an order after checking availability directly on the aggregate neither guaranteed consistency. Just 1 ms after checking, it could change.
That's just because that command did not affect the aggregate's state!

So, I prepared `ProductsAvailability` read model, which was driven by `Inventory::AvailabilityChanged` events.
I use it as a kind of validation if invoking `Ordering::AddItemToBasket` command makes any sense.

<img src="<%= src_original("offload-writes-with-a-read-model/exploring_inventory.png") %>" width="100%">

```ruby
def add_item
  if Availability::Product.exists?(["uid = ? and available < ?", params[:product_id], params[:quantity]])
    redirect_to edit_order_path(params[:id]),
                alert: "Product not available in requested quantity!" and return
  end
  command_bus.(Ordering::AddItemToBasket.new(order_id: params[:id], product_id: params[:product_id]))
  head :ok
end
```

Lessons that I learned:
- Started to distinguish hard business rules which go together with some state change within the aggregate.
Requirements of this kind are, in fact, good candidates for invariants.
- Noticed that some requirements improve user experience but are not so critical to affecting aggregate design.
Checking those, we do not care for 100% consistency with a write side.
- It is OK to have some read models that are not strict for viewing purposes.