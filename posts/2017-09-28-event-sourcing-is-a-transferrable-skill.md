---
title: "Event Sourcing is a transferrable skill"
created_at: 2017-09-28 00:56:41 +0200
kind: article
publish: false
author: Paweł Pacana
tags: [ 'event sourcing', 'fp' ]
newsletter: :arkency_form
---

Roadmap:

* code sample of AggregateRoot
* same code in Haskell
* event sourcing is a transferrable technique
* http://verraes.net/2014/05/functional-foundation-for-cqrs-event-sourcing/
* http://tojans.me/blog/2014/02/26/cqrs-and-functional-programming/
* https://gist.github.com/pawelpacana/e3f06aa709dd4dcc7e564e3fa555dfe8

<!-- more -->

```ruby
class Product
  include AggregateRoot

  def register(store_id:, sku:)
    apply(ProductRegistered.new(data: {
      store_id: store_id,
      sku: sku,
    }))
  end

  def supply(quantity)
    apply(ProductSupplied.new(data: {
      store_id: @store_id,
      sku: @sku,
      quantity: quantity,
    }))
  end

  def reserve(quantity:, order_number:)
    unless @quantity_available >= quantity
      raise QuantityNotAvailable
    end
    apply(ProductReserved.new(data: {
      store_id: @store_id,
      sku: @sku,
      quantity: quantity,
      order_number: order_number,
    }))
  end

  private

  def apply_strategy
    ->(_me, event) {
      {
        ProductRegistered => method(:registered),
        ProductSupplied   => method(:supplied),
        ProductReserved   => method(:reserved),
      }.fetch(event.class).call(event)
    }
  end

  def registered(event)
    @store_id = event.data.fetch(:store_id)
    @sku = event.data.fetch(:sku)
    @quantity_available = 0
    @quantity_reserved  = 0
    @quantity_shipped   = 0
  end

  def supplied(event)
    @quantity_available += event.data.fetch(:quantity)
  end

  def reserved(event)
    quantity = event.data.fetch(:quantity)
    @quantity_available -= quantity
    @quantity_reserved  += quantity
  end
end
```

