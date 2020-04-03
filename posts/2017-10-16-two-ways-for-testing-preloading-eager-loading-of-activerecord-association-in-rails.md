---
title: "Two ways for testing preloading/eager-loading of ActiveRecord associations in Rails"
created_at: 2017-10-16 12:42:18 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'active record', 'testing']
newsletter: arkency_form
img: testing-association-preloaded-eager-loaded-rails-active-record/association-tested-rspec-minitest.jpeg
---

As a developer who cares about performance you know to [avoid N+1 queries by using `#includes`, `#preload` or `#eager_load` methods](/2013/12/rails4-preloading/) . But is there a way of checking out that you are doing your job correctly and making sure that the associations you expect to be preloaded are indeed? How can you test it? There are two ways.

<!-- more -->

Imagine we have two of these classes in our Rails application. An `order` can have many `order_lines`.

```ruby
class Order < ActiveRecord::Base
  has_many :order_lines

  def self.last_ten
    limit(10).preload(:order_lines)
  end
end
```

```ruby
class OrderLine < ActiveRecord::Base
  belongs_to :order
end
```

We implemented `Order.last_ten` method which returns last 10 orders with one eager loaded association. Let's see how can make sure that the lines are preloaded after calling it.

## association(:name).loaded?

```ruby
require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  test "#last_ten eager loading" do
    o = Order.new()
    o.order_lines.build
    o.order_lines.build
    o.save!

    orders = Order.last_ten
    assert orders[0].association(:order_lines).loaded?
  end
end
```

Because we `preload(:order_lines)` we are interested whether `order_lines` is loaded. To check that we need to get one `Order` object such as `orders[0]` verify on it. There is nothing to check on `orders` collection that could tell us if the association is loaded or not.

The test in Rspec would look quite similar

```ruby
require 'rails_helper'

RSpec.describe Order, type: :model do
  specify "#last_ten eager loading" do
    o = Order.new()
    o.order_lines.build
    o.order_lines.build
    o.save!

    orders = Order.last_ten
    expect(orders[0].association(:order_lines).loaded?).to eq(true)
    # or alternatively
    expect(orders[0].association(:order_lines)).to be_loaded
  end
end
```

## count queries with ActiveSupport::Notifications

ActiveRecord library has a nice helper method called [`assert_queries`](https://github.com/rails/rails/blob/e986cb49c8a475c48819cee451c73dbd005904c4/activerecord/test/cases/test_case.rb#L49) which is part of `ActiveRecord::TestCase`. Unfortunately, `ActiveRecord::TestCase` is not shipped as part of ActiveRecord. It is only available in rails internal tests to verify its behavior. We can however quite easily emulate it for our needs.

Imagine a scenario in which you operate on a graph of Active Record objects but you don't return them. You just return a computed values. How can your verify it in such case that you don't have the N+1 problem? There are no observable side-effects, no returned records to check if they are `loaded?`. But... aren't they really?

```ruby
class Order < ActiveRecord::Base
  has_many :order_lines

  def self.average_line_gross_price_today
    lines = where("created_at > ?", Time.current.beginning_of_day).
      preload(:order_lines).
      flat_map do |order|
        order.order_lines.map(&:gross_price)
    end
    lines.sum / lines.size
  end
end

class OrderLine < ActiveRecord::Base
  belongs_to :order

  def gross_price
    # ...
  end
end
```

In this situation. How can you test that `Order.average_line_gross_price_today` does not suffer from N+1 queries? Is there a way to make sure `order.order_lines.map(&:gross_price)` is not triggering a SQL query when reading `order_lines`? It turns out there is.

We can use `ActiveSupport::Notifications` and get notified about every executed SQL statement.

```ruby
require 'rails_helper'

RSpec.describe Order, type: :model do
  specify "#average_line_gross_price_today eager loading" do
    o = Order.new()
    o.order_lines.build
    o.order_lines.build
    o.save!

    count = count_queries{ Order.average_line_gross_price_today }
    expect(count).to eq(2)
  end

  private

  def count_queries &block
    count = 0

    counter_f = ->(name, started, finished, unique_id, payload) {
      unless %w[ CACHE SCHEMA ].include?(payload[:name])
        count += 1
      end
    }

    ActiveSupport::Notifications.subscribed(
      counter_f,
      "sql.active_record",
      &block
    )

    count
  end
end
```

If you go that way make sure to create enough records to detect potential issues with eager loading. One order with one line is not enough because with and without the eager loading the number of queries would be the same. In this case only when you have 2 order lines you can see the difference in a number of queries with preloading (2, one for all orders and one for all lines) vs without preloading (3, one for all orders and one for every line separately). Always make sure your test is failing before fixing it :)

While using this approach is possible, it tells me that it could be nice to split the responsibilities into two smaller methods. One responsible for extracting the right records from a database (IO-related) and one for transforming the data and doing the computations (no IO, side-effect free).

You can check out [db-query-matchers gem](https://github.com/brigade/db-query-matchers) for RSpec matchers to help you with that kind of testing.

### Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your everyday Rails programmer job. Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring.

Also, make sure to check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.
