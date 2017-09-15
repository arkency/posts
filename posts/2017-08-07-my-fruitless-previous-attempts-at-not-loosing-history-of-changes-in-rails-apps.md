---
title: "My fruitless, previous attempts at not losing history of changes in Rails apps"
created_at: 2017-08-07 15:56:21 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ddd', 'rails' ]
newsletter: :arkency_form
---

Some time ago I was implementing a simple Inventory with products that could be available, reserved and sold in certain quantities.

There were certain requirements that I tried to maintain:

* having a history of operations so that we know where the numbers came from and so that we can do many kinds of reports
* having an agreement between current state and the state computed based on history
* making decisions based on current state instead of re-computing everything based on all historical operations (we don't want to query thousands of historical DB records)

<!-- more -->

I was also experimenting with keeping the main business logic decoupled from DB and Active Record as well as a few more coupled approaches. Let me show you some parts of a solution that I came up with about 30 months ago. It's not a whole solution but just a few snippets around the reservation logic. Good enough to get a feeling of the whole solution.

#### Product

```ruby
class Inventory::Product
  attr_reader :store_quantity,
    :available_quantity,
    :reserved_quantity,
    :sold_quantity,
    :identifier

  def initialize(available_quantity:,
    reserved_quantity:,
    sold_quantity:,
    store_quantity:,
    identifier:
  )
    @available_quantity     = available_quantity
    @reserved_quantity      = reserved_quantity
    @sold_quantity          = sold_quantity
    @store_quantity         = store_quantity
    @identifier             = identifier
  end

  def reserve(qty)
    raise QuantityTooBig if qty > available_quantity
    self.available_quantity -= qty
    self.reserved_quantity  += qty

    ProductHistoryChange.new(
      identifier,
      available_quantity,
      reserved_quantity,
      sold_quantity,
      -qty,
      +qty,
      0
    )
  end
end
```

I imagined that the `Product` protects some rules such as that you can't reserve more of given product than you already have. Quite simple, quite logical. The product keeps track of all the quantities and implements the business logic. In the case of reservation that's just:

```ruby
  def reserve(qty)
    raise QuantityTooBig if qty > available_quantity
    self.available_quantity -= qty
    self.reserved_quantity  += qty
  end
```

#### ProductHistoryChange

However, because I wanted to keep history what happened I came up with what I called `ProductHistoryChange`. It was a structure where I kept note about the changes made to a Product.

It looked like this:

```ruby
class ProductHistoryChange < Struct.new(
  :identifier,

  :available_quantity,
  :reserved_quantity,
  :sold_quantity,

  :available_quantity_change,
  :reserved_quantity_change,
  :sold_quantity_change
)
end
```

Nothing fancy. 3 fields for what changed in the quantities and 3 fields about current values of the quantities after applying the changes.

#### Facade

Here is how I imagined using those classes together:

```ruby
class Inventory
  Error          = Class.new(StandardError)
  QuantityTooBig = Class.new(Error)

  def initialize(repository)
    @repository = repository
  end

  def reserve_product(identifier, qty)
    product = @repository.get_product(identifier)
    change = product.reserve(qty)
    @repository.save_change(change)
    @repository.save_product(product)
  end

  private

  def store_quantity(identifier)
    @repository.store_quantity(identifier)
  end
end
```

The solution was not that bad, it had good and bad points. There were however certain points that I didn't like about it:

* Artificial `ProductHistoryChange` class.
* There was no easy way to make sure that what I say happened in `ProductHistoryChange` was indeed what changed in `Product so I could not be sure the history reflected actual changes
* I could easily forget about saving the returned `ProductHistoryChange` since that was 2 separate operations.
* `ProductHistoryChange` was not actually used by `Product` in any way.

## Many books and months later

Here is something that I understood over time...

I was trying to implement:

* Aggregates - a term from DDD community for objects modeling the domain and protecting business rules. Such as the `Product` which makes sure we cannot over-book too much of it.
* Domain Events - `ProductHistoryChange` was my poor attempt at stating what changed in the `Product` and why. But I could only imagine doing it via a separate DB table which is often not necessary.
* Read models - for building reports which do not affect the domain logic, but rely on knowing what changed
* (optionally) Event Sourcing - a technique which gives us the ability to use stored domain events to reconstruct past states

However, my implementation was... not the best.

It took me quite some time, a lot of reading and experimenting to find out better ways to achieve it.

Now, this kata is the base for for many exercises from our [Domain-Driven Rails book](/domain-driven-rails/) and [Rails/DDD workshops](/ddd-training/) and you can see several different approaches to the problem. They progressively go from more Rails-way spectrum to more DDD-way of solving the before-mentioned problems so you can see for yourself how the solution changes but the logic remains the same.

Here is part of one of the solutions from Event Sourcing spectrum.

```ruby
class Product
  include AggregateRoot

  def reserve(quantity:,)
    raise QuantityTooBig unless @quantity_available >= quantity

    apply(ProductReserved.strict(data: {
      identifier: @identifier,
      quantity: quantity,
      order_number: order_number,
    }))
  end

  private

  def apply_strategy
    -> (event) {
      {
        ProductReserved   => method(:reserved),
        # other domain events ...
      }.fetch(event.class).call(event)
    }
  end

  def reserved(event)
    quantity = event.data.fetch(:quantity)
    @quantity_available -= quantity
    @quantity_reserved  += quantity
  end
end
```

## Learn More

On Wednesday we are going to release our newest book "Domain-Driven Rails".

<div style="margin:auto; width: 480px;">
  <a href="/domain-driven-rails/">
    <img src="//blog-arkency.imgix.net/domain-driven-rails-design/cover7-100.png?w=480&h=480&fit=max">
  </a>
</div>

It already has 140 pages and contains 10 building blocks you can use in your Rails app to achieve better architecture.

Subscribe to our [newsletter](http://arkency.com/newsletter) to always receive best discounts and free Ruby and Rails lessons every week.