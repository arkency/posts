---
created_at: 2023-01-11 14:08:30 +0100
author: Tomasz Patrzek
tags: [event sourcing, bi-temporal event sourcing, read model, serialized db column]
publish: false
---

# Catalog of future events using bi-temporal EventSourcing

In our previous [blog-post](https://blog.arkency.com/fixing-the-past-and-dealing-with-the-future-using-bi-temporal-eventsourcing/) Łukasz described how to handle events that should occur in the future.
And how we use it in our example application [ecommerce](https://github.com/RailsEventStore/ecommerce/) on the back-end side.


### Prices catalog read model

The next step would be to get the salesman the possibility to view / update their future prices.
Let's create a read model for the prices set for the future.


```ruby
class AddPricesCatalogToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :prices_catalog, :text
  end
end
```

I've used a serialized column for the prices catalog. Separate table for price entries could be event easier to handle the entries.

```ruby
module Products
  class Product < ApplicationRecord
    serialize :prices_catalog, Array

    def prices_catalog
      super || []
    end
  end

  class Configuration
    def initialize(event_store)
      @event_store = event_store
    end

    def call
      @event_store.subscribe(AddPriceToCatalog, to: [Pricing::PriceSet])
    end
  end
end
```
### Handle new price set

In the configuration part we set the handler to update our read model with new price on the `PriceSet` event.


```ruby
module Products
  class AddNewPricingCalendarEntry < Infra::EventHandler
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

The `AddPriceToCatalog` handler adds new entry to the catalog and sorts the price entries by date, to keep the entries in order.
Entries are stored as hashes in this example. We store price and `:valid_since` obtained from the bi-temporal event attribute `:valid_at`


### Rebuild

We can always rebuild our read model by reading the events

```ruby
def prices_catalog_by_product_id(product_id)
  @event_store
    .read
    .of_type(PriceSet)
    .as_of
    .to_a
    .filter { |e| e.data.fetch(:product_id).eql?(product_id) }
    .select(&method(:future_prices))
    .map(&method(:to_catalog_entry))
end

def future_prices(e)
  e.metadata.fetch(:valid_at) > Time.now
end

def to_catalog_entry(e)
  {
    price: e.data.fetch(:price),
    valid_since: e.metadata.fetch(:valid_at)
  }
end
```

The `as_of` method of [Rails Event Store](https://railseventstore.org/docs/v2/bi-temporal/#usage) loads events in correct order using `valid_at` attribute.

### Future prices

Now we can introduce `future_prices` method in our read model needed for our use case.

```ruby
module Products
  class Product
    #...
    def future_prices
      prices_catalog.find { |entry| entry[:valid_since] > time }
    end
  end
end
```

### Price in any time in history

As next I've removed the previously used `price` column from the product read model.

Now I can get the price using the pricing catalog for any given time.

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

I'm storing the `valid_since` time in UTC Time zone.

```ruby
def set_future_product_price(product_id, price, valid_since)
  valid_since = Time.parse(future_price["start_time"]).utc.to_s
  command_bus.(set_product_future_price_cmd(product_id, price, valid_since))
end
```

And on the read side, time is displayed in in user time zone.
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

The first step to manage future prices is ready. As next we would need to add a update and delete methods.
