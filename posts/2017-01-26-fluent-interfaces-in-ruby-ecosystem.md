---
title: "Fluent Interfaces in Ruby ecosystem"
created_at: 2017-01-26 10:27:38 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'oop', 'ruby' ]
newsletter: arkency_form
img: fluent-interface-api-ruby-rails/title.jpeg
---

<%= img_fit("fluent-interface-api-ruby-rails/title.jpeg") %>

You already used fluent interfaces multiple times as a Ruby
developer. Although you might not have done it consciously.
And maybe you haven't built yourself a class with such API
style yet. Let me present you a couple of examples from Ruby
and its ecosystem and how I designed such API in my use-case.

<!-- more -->

## What is a fluent interface anyway?

* API that aims to provide more readable code
* usually implemented with method chaining
* often used for configuring / building objects

## Examples

Probably most well-known example would be Active Record Query API
used for building SQL statements.

```ruby
User.preload(:avatar).where(name: "John").order("id DESC").limit(10)
```

Most of the time it will return `ActiveRecord::Relation` as a result.
But there are a couple of methods like `first!`, `to_a`, `to_sql` which break
the pattern, evaluate the statement and return a result.

But if you think about it, usually the fluent interface must give you
a set of methods that will allow to either return the built object or
pass an object to it for interacting.

Rspec Mocks is another well-known example of fluent API.

```ruby
expect(invitation).to receive(:accept).with("John").at_most(3).times.and_return(true)
```

On each own, the methods sound silly. What would `with("John")` mean?
But in the context they are readable and make perfect sense.

I wonder if could say that certain built-in Ruby classes adhere to a fluent interface?
For example `String` or `Enumerable` have plenty of methods that you can chain
and they return the same class. 

```ruby
"Robert Pankowecki".first(7).strip.gsub("b", "B").reverse
# => "treBoR" 
```

But Martin Fowler said:

> Certainly chaining is a common technique to use with fluent interfaces, but true fluency is much more than that.

I could not find a more elaborate statement of what he meant exactly. But my guess would be that
fluency comes with a combination of Domain Specific Language.

The line between convenient method chaining and fluent interface might be a bit blurry. 

## My case

Some time ago we built an _Insights Panel_ for a marketplace platform where Merchants could
see some stats about their customers. The data is based on the marketplace Google Analytics
data and fetched via API. But it limits the data only to the customers of certain merchant;
without leaking global stats.

<%= img_fit("fluent-interface-api-ruby-rails/google_analytics_merchant_panel.jpg") %>

Google Analytics API can be queried in thousands of possible ways. If you have at least
one domain with GA, I encourage you to give [Query Explorer a try](https://ga-dev-tools.appspot.com/query-explorer/).

<%= img_fit("fluent-interface-api-ruby-rails/query_explorer.jpg") %>

You can get a ton of useful knowledge from it. Which days of week people buy most, which hours,
where are they from, what devices do they use etc. Google Analytics allows you to do a lot
within its interface, but I find the query explorer sometimes to be much easier. Maybe
because you can easily map its concepts into SELECT/WHERE/GROUP BY 😊

Going back to the fluent interfaces... Here is the code that I used for building the query.
What we usually display in most cases is _product sold over time_. So that's the default
configuration we set up in the constructor.

```ruby
class QueryBuilder
  def initialize(campaign, merchant_id)
    ids("ga:99990000")
    start_date( campaign.created_at.to_date.to_s(:db) )
    end_date( campaign.ends_at.to_date.to_s(:db) )
    dimensions("ga:date")
    metrics("ga:itemQuantity")
    filters("ga:productSku==#{campaign.id}")
    sort("ga:date")
    quota_user(merchant_id)
  end

  def start_date(start_date)
    @start_date = start_date
    self
  end

  def end_date(end_date)
    @end_date = end_date
    self
  end

  def dimensions(dimensions)
    @dimensions = dimensions
    self
  end

  def metrics(metrics)
    @metrics = metrics
    self
  end

  def add_filter(filter)
    @filters << ";#{filter}"
    self
  end

  def sort(sort)
    @sort = sort
    self
  end

  def dsc_qty
    sort("-ga:itemQuantity")
  end

  def max_results(max_results)
    @max_results = max_results
    self
  end

  def quota_user(quota_user)
    @quota_user = quota_user
    self
  end

  def to_hash
    {
      'ids'        => @ids,
      'start-date' => @start_date,
      'end-date'   => @end_date,
      'dimensions' => @dimensions,
      'metrics'    => @metrics,
      'filters'    => @filters,
      'sort'       => @sort,
      'quotaUser'  => @quota_user,
    }.tap do |h|
      h['max-results'] = @max_results if @max_results
    end
  end

  private

  def filters(filters)
    @filters = filters
    self
  end
  
  def ids(ids)
    @ids = ids
    self
  end
end
```

Then we can use the fluent API to change the values easily.
 
```ruby
# For displaying cities from which those customers buy
builder.dimensions("ga:city,ga:countryIsoCode").dsc_qty

# For their age
builder.dimensions("ga:userAgeBracket").sort("ga:userAgeBracket")

# For referrals
builder.dimensions("ga:source,ga:medium").add_filter("ga:medium==referral").dsc_qty
```

The API could be even further refined into:

```ruby
builder.add_dimension("source").add_dimension("medium")
```

or

```ruby
builder.add_filter("medium").equals("referral")
```

But the current form was good enough for our needs and readable enough.

The other most common usage is to group customers and their purchase stats
in total, without a timeline. In that case, we often want to display from most
to least buying groups. That is a common use-case so we have a dedicated method
for it.

```ruby
def dsc_qty
  sort("-ga:itemQuantity")
end
```

I think that's how fluent interfaces evolve over time. They get better names,
better chains, more out of the box, good defaults, and dedicated names.

After all you could write in Rspec `receive(:method).exactly(1).times` but it is 
much easier to understand `receive(:method).once`.

## Read more

* If you enjoyed this article you will also enjoy our [Rails and/or React.js books](/products). Especially
  [Fearless Refactoring: Rails controllers](http://rails-refactoring.com/) which helps you maintain
  pretty, small and readable controllers.
* https://www.martinfowler.com/bliki/FluentInterface.html
* http://jeffkreeftmeijer.com/2011/method-chaining-and-lazy-evaluation-in-ruby/
