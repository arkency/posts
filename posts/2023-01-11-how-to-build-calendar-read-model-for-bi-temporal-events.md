---
created_at: 2023-01-11 14:08:30 +0100
author: Tomasz Patrzek
tags: [event sourcing, bi-temporal event sourcing, read model, serialized db column]
publish: true
---

# How to build Read models with bi-temporal events

In our previous [blogpost](https://blog.arkency.com/fixing-the-past-and-dealing-with-the-future-using-bi-temporal-eventsourcing/), Łukasz described how to handle events that are expected in the future and how we use it in our [ecommerce](https://github.com/RailsEventStore/ecommerce/) example application to get correct current prices while handling prices that are set for the future.

### Prepare the read model for the pricing catalog

The next step would be to give the salesperson the ability to view/create future prices for the products.
Let's create a read model for future prices.

```ruby
class AddPricesCatalogToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :prices_catalog, :text
  end
end
```

I've used a serialized column for the pricing catalog. However separate table for price entries might be even easier to manage.

```ruby
module Products
  class Product < ApplicationRecord
    serialize :prices_catalog, Array

    def prices_catalog
      super || []
    end
  end
end
```
### Handle new price set

On the `Pricing::PriceSet` event, we run a handler to update our read model. This is described in the configuration section.

```ruby
module Products
  class Configuration
    def initialize(event_store)
      @event_store = event_store
    end

    def call
      @event_store.subscribe(AddNewPriceToCatalog, to: [Pricing::PriceSet])
    end
  end
end
```

The `AddNewPriceToCatalog` handler adds new pricing entries to the catalog and sorts them by date to keep them in order.

```ruby
module Products
  class AddNewPriceToCatalog < Infra::EventHandler
    def call(event)
      @event = event
      @product = Product.find(event.data.fetch(:product_id))
      @product.update!(prices_catalog: new_prices_catalog)
    end

    private

    def new_prices_catalog
      (@product.prices_catalog + new_catalog_entry)
        .sort_by { |entry| entry[:valid_since] }
    end

    def new_catalog_entry
      {
        price: @event.data.fetch(:price),
        valid_since: e.metadata.fetch(:valid_at)
      }
    end
  end
end
```

In this example, records are stored as hashes. We persist the price and `valid_since` obtained from the `valid_at' bi-temporal event metadata.


### Rebuild

We can always rebuild our read model by reading the events.

```ruby
def prices_catalog_by_product_id(product_id)
  @event_store
    .read
    .of_type(PriceSet)
    .as_of
    .to_a
    .filter { |e| e.data.fetch(:product_id).eql?(product_id) }
    .map(&method(:to_catalog_entry))
end

def to_catalog_entry(e)
  {
    price: e.data.fetch(:price),
    valid_since: e.metadata.fetch(:valid_at)
  }
end
```

The [Rails Event Store's](https://railseventstore.org/docs/v2/bi-temporal/#usage) `as_of` method loads events in the correct order using the `valid_at` metadata.

### Future prices

Now we can introduce the `future_prices` method into our read model, which is needed for our use case.

```ruby
module Products
  class Product
    #...
    def future_prices
      prices_catalog.find { |entry| entry[:valid_since] > Time.now }
    end
  end
end
```

### Price in any time in history

Next, I've removed the previously used `price` column from the product read model.

Now I can get the price using the pricing catalog at any given time.

```ruby
def price(time = Time.now)
  last_price_before(time)
end

private

def last_price_before(time)
  prices_entries_before(time).last[:price]
end

def prices_entries_before(time)
  prices_catalog.partition { |entry| entry[:valid_since] < time }.first
end
```

### Time zone

On the write side, I'm storing the `valid_since` time in the UTC Time zone.

```ruby
def set_future_product_price(product_id, price, valid_since)
  valid_since = Time.parse(future_price["start_time"]).utc.to_s
  command_bus.(set_product_future_price_cmd(product_id, price, valid_since))
end
```

On the read side, the time is displayed in the user's time zone.
The price is also parsed to BigDecimal.

```ruby
def prices_catalog
  return [] unless super
  super.map(&method(:parese_catalog_entry))
end

private

def parese_catalog_entry(entry)
  {
    valid_since:  Time.parse(time_of(entry)).in_time_zone(Time.now.zone),
    price: BigDecimal(entry[:price])
  }
end
```

That's it. The first step in managing future prices is complete. The next step is to implement the removal and updating of price catalogue entries.
