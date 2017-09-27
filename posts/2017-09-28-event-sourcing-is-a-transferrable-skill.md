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

handle' Nothing _ = error "PEBKAC"


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
