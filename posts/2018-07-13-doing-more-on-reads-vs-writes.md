---
title: "Doing more on reads vs writes"
created_at: 2018-07-13 15:55:44 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

What do you like more in your application? Handling complexity when reading the data or when updating it?

<!-- more -->

Imagine you have a model such as `Product` with three potential date attributes:

* `publication_on` - Nominal date of publication. This date is primarily used for planning, promotion and other business process purposes, and is not necessarily the first date for retail sales or fulfillment of pre-orders.
* `preorder_on` - Preorder embargo date. Earliest date a retail ‘preorder’ can be placed (in the market)
* `announce_on` - Public announcement date. Date when a new product may be announced to the general public.

Also, three additional business rules:

* When `preorder_on` is not explicitly provided, `publication_on` date should be used instead to determine if a product can be ordered.
* When `announce_on` is not explicitly provided, `preorder_on` date should be used instead to determine if a product can be viewed. If `preorder_on` is not provided as well, then `publication_on` should be used instead.
* `announce_on` <= `preorder_on` <= `publication_on`

What this means is that a product can be:

* announced and visible
* preordered and thus buyable
* published

Of course, our e-commerce publishing system would like to query for products that can be displayed or purchased. There are multiple ways to implement such a solution. I am going to present two of them.

## Typical

I would say the most common solution deals with these business rules when reading the data.

```ruby
class Product < ApplicationRecord
  def self.visible(at = Date.current)
    where("
        announce_on <= :at  
      OR (
        announce_on IS NULL AND
        preorder_on <= :at
      ) OR (
        announce_on IS NULL AND
        publication_on IS NULL AND
        release_on <= :at
      )
    ", at: at)
  end

  def self.buyable(at = Date.current)
    where("
        preorder_on <= :at
      ) OR (
        preorder_on IS NULL AND
        publication_on <= :at
      )
    ", at: at)
  end

  def visible?(at = Date.current)
    (announce_on && announce_on <= at) ||
    (preorder_on && preorder_on <= at) ||
    publication_on <= at
  end

  def buyable?(at = Date.current)
    (preorder_on && preorder_on <= at) ||
    publication_on <= at
  end
end
```

I would say this is a typical UI-driven development. The user can provide three different fields. Let's have three different fields for storing these values. Nothing happens here on writes. Value A is stored as A. That's it. The whole presented logic is verified when reading the data, when querying it. If you send your products to ElasticSearch or Algolia, you need to repeat similar logic in those queries as well. However, it is simple, and it works.

Let's try something different.

## More complex writes, easier reads

In this solution whenever we change one of our three main attributes which can be provided from the UI, we [immediately recompute their effective, derived values](https://blog.arkency.com/on-activerecord-callbacks-setters-and-derived-data/).

```ruby
class Product < ApplicationRecord
  def self.visible(at = Date.current)
    where("announce_on_computed <= ?", at)
  end

  def self.buyable(at = Date.current)
    where("preorder_on_computed <= ?", at)
  end

  def visible?(at = Date.current)
    announce_on_computed <= at
  end

  def buyable?(at = Date.current)
    preorder_on_computed <= at
  end

  def publication_on=(val)
    super.tap{ recompute_dependent_columns }
  end
  
  def preorder_on=(val)
    super.tap{ recompute_dependent_columns }
  end
  
  def announce_on=(val)
    super.tap{ recompute_dependent_columns }
  end

  private

  def recompute_dependent_columns
    self.preorder_on_computed = preorder_on || publication_on
    self.announce_on_computed = announce_on || preorder_on_computed
  end  
end
```

So instead of having more complex reads, we have more complex writes. The reads are now stupidly simple. Also, you could send those derived dates to Elastic Search and the queries to it would be equally simple. While `preorder_on` and `announce_on` might be `nil`, their computed counterparts should not be (assuming a validation on `publication_on`).

The downside of this solution is that in many places you might need to remember to use `preorder_on_computed` instead of `preorder_on`. It could be tempting to reverse the nomenclature and use `preorder_on_provided` or a similar, longer name for the value coming from the UI. And to reserve `preorder_on` for the precomputed, not-null value which should be used for queries. Whichever way you go, make sure to communicate the pattern that you use with your team.

## Explicit transition

There is potentially an even simpler solution lurking here. Instead of remembering `preorder_on_computed` and `announce_on_computed` we would add booleans such as `is_visible` and `is_buyable`. Once a day (think _cron job or a scheduler_) we would query for all products which should become `visible` or `buyable` today and we would switch their booleans from `true` to `false`. Similarly, we would need to do it when the user updates one of our three main attributes.

```ruby
class Product < ApplicationRecord
  # executed daily
  def self.recompute!
    where("
      announce_on    = :today OR
      preorder_on    = :today OR
      publication_on = :today
    ", today: Date.current).find_each do |p|
      p.recompute_dependent_columns
      p.save!
    end
  end

  def self.visible
    where(is_visible: true)
  end

  def self.buyable
    where(is_buyable: true)
  end

  def visible?
    is_visible?
  end

  def buyable?
    is_buyable?
  end

  def publication_on=(val)
    super.tap{ recompute_dependent_columns }
  end
  
  def preorder_on=(val)
    super.tap{ recompute_dependent_columns }
  end
  
  def announce_on=(val)
    super.tap{ recompute_dependent_columns }
  end

  def recompute_dependent_columns
    self.is_buyable = [
      preorder_on, 
      publication_on
    ].reject(&:nil).min <= Date.current
    self.is_visible = [
      announce_on, 
      preorder_on, 
      publication_on
    ].reject(&:nil).min <= Date.current
  end  
end
```

Depending on your preferences this might seem even easier than the previous solution. Or, it might look ugly or like an over-kill. 

There is, however, one potential benefit lurking here. With some slight modifications, we could detect if the product was just announced, hidden, pre-orders opened or closed. In such case, we could publish an appropriate [domain event](/2016/05/domain-events-over-active-record-callbacks/) on our message bus. Thus making it an explicit event in our system that something important happened; potentially notifying other bounded contexts about a significant fact from our domain.

It might be a critical reflection that there is something like a Calendar Bounded Context in your application. The fact that time passed, there is a new day, new business day, new week, new month, new year, etc. is a crucial event that triggers state changes in your system.

Going even further in that direction, we could split our Product into two classes/models:

* write model responsible for verifying business rules
* read model for querying

Our write model does not need `is_buyable` or `is_visible` at all. But, it's very beneficial for the read-model which can live as a separate table in the SQL DB, or it could be in the already mentioned Elastic Search.

However, usually when working with `ActiveRecord`, we mix those two models together. In more complex apps, it might be a good idea to separate them.

## 12-weeks Rails Events video class

[Subscribe to our mailing list](http://arkency.com/newsletter) to be notified about our upcoming 12-weeks Rails Events video class.

You might also enjoy reading:

* [Ruby Event Store - use without Rails](/ruby-event-store-use-without-rails/) - did you know you can use Rails Event Store without Rails by going with RubyEventStore :)
* [When DDD clicked for me](/when-ddd-clicked-for-me/) - It took me quite a time to grasp the concepts from DDD community and apply them in our Rails projects. This is a story of one of such “aha” moments.
* [Conditionality is filtering. Don't filter control flow, filter data.](/2017/04/conditionality-is-filtering-dont-filter-control-flow-filter-data/) - a short example for how to start getting rid of if-statements in your code.