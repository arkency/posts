---
title: "Event Sourcing is a transferrable skill"
created_at: 2017-09-28 00:56:41 +0200
kind: article
publish: false
author: Paweł Pacana
tags: [ 'event sourcing', 'fp' ]
newsletter: :arkency_form
---

As developers we're constantly learning to keep our axes sharp. Getting to know new concepts, patterns or paradigms broadens our horizons. It may eventually result in having new perspective how to solve business problems we're facing.

Learning comes with a certain cost. It's an investment we're taking now to reap benefits from it in the future. In a longer or a shorter term. Can we always justify this cost? Will the thing we've learned be still useful in a year or two? Or after we're forced to change the hammer — being it the framework or language we specialize in?

Is this whole Event Sourcing a skill worth learning?

<!-- more -->

Below you'll find an example of Event Sourcing in Ruby. Give it a look.

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

This particular code uses [aggregate_root](https://github.com/RailsEventStore/rails_event_store/tree/master/aggregate_root) gem. It's really a detail — most of the implementations in imperative languages look alike. Compare to [this one in C#](https://github.com/gregoryyoung/m-r/blob/master/SimpleCQRS/Domain.cs#L63). 
Once you get the idea right and maybe implement it yourself, you should be able to take this technique with you to a different language. Cool.

How would Event Sourcing look like in a completely different world than Ruby? Let's say — Haskell:

```haskell
module Inventory where

type Sku = String
type StoreId = String
type Quantity = Integer
type OrderNumber = String

data Event = ProductRegistered Sku StoreId |
             ProductSupplied Sku StoreId Quantity |
             ProductReserved Sku StoreId OrderNumber Quantity

data Command = Register Sku StoreId |
               Supply Quantity |
               Reserve Quantity OrderNumber

data Product = Product { sku :: Sku
                       , storeId :: StoreId
                       , quantityAvailable :: Quantity
                       , quantityReserved :: Quantity
                       }


handle :: [Event] -> Command -> [Event]
handle events command =
  handle' product command
  where product = apply events

handle' :: Maybe Product -> Command -> [Event]
handle' product (Register sku storeId) =
  [ProductRegistered sku storeId]

handle' (Just product) (Supply quantity) =
  [ProductSupplied (sku product) (storeId product) quantity]

handle' (Just product) (Reserve quantity orderNumber)
  | notAvailable = error "quantity not available"
  | otherwise    = [ProductReserved (sku product) (storeId product) orderNumber quantity]
  where notAvailable = (quantityAvailable product) < quantity

handle' Nothing _ = error "Welp"


apply :: [Event] -> Maybe Product
apply events = foldl apply' Nothing events

apply' :: Maybe Product -> Event -> Maybe Product
apply' Nothing (ProductRegistered sku storeId) =
  Just (Product sku storeId 0 0)

apply' (Just product) (ProductSupplied _ _ quantity) =
  Just (product { quantityAvailable = (quantityAvailable product) + quantity })

apply' (Just product) (ProductReserved _ _ _ quantity) =
  Just (product { quantityAvailable = (quantityAvailable product) - quantity
                , quantityReserved  = (quantityReserved  product) + quantity
                })

```

Not bad, even given my so-so Haskell skills. There are different   building blocks — sure. It will look alien at first sight if you've been only programming Ruby. 

Still the idea is about taking action (described as Command), protected by the business rules (conditions).   

```haskell
handle' (Just product) (Reserve quantity orderNumber)
  | notAvailable = error "quantity not available"
  | otherwise    = [ProductReserved (sku product) (storeId product) orderNumber quantity]
  where notAvailable = (quantityAvailable product) < quantity
```

Rules operate on state (product).

```haskell
data Product = Product { sku :: Sku
                       , storeId :: StoreId
                       , quantityAvailable :: Quantity
                       , quantityReserved :: Quantity
                       }                       
```

State is constructed from facts in the past (described as Event).

```haskell
apply :: [Event] -> Maybe Product
apply events = foldl apply' Nothing events  
```

Finally, the outcome of an action is just another event.

```haskell  
handle :: [Event] -> Command -> [Event]
```

In my opinion functional programming makes even sweeter foundation to implement Event Sourcing — a bit differently expressed.

The key point is however that Event Sourcing is a transferrable skill. You can learn it once. The principles behind it still make sense after technology change. It's a technique in your toolbox much broader than — let's say ActiveRecord callbacks.
