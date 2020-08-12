---
created_at: 2017-06-07 23:05:46 +0200
publish: true
author: Szymon Fiedler
tags: [ 'rails', 'rspec', 'testing']
newsletter: arkency_form
---

# Test critical paths in your app with ease thanks to Dependency Injection

Dependency Injection is one of my favorite programming patterns. In this short blogpost, I’ll present you how it helps testing potentially untestable code.

<!-- more -->

Imagine that your customer wants to easily identify orders in the e-commerce system which you are maintaining. They requested simple numeric identifier in a very specific 9-digit format which will make their life easier, especially when it comes to discussing order details with their client via the phone call. They want identifier starting with 100 and six random digits, e.g. 100123456.

Easy peasy you think, but you probably also know that the subset is limited to 999999 combinations and collisions may happen. You probably create a unique index on the database column, let’s call it `order_number` to prevent duplicates. However, instead of raising an error if the same number occurs again you want to make a retry.

Let’s start with a test for the best case scenario

```ruby

RSpec.describe OrderNumberGenerator do
  specify do
    order = Order.create!

    OrderNumberGenerator.new.call(order.id)

    expect(order.reload.order_number).to be_between(100_000_001, 100_999_999)
  end
end
```

And the simple implementation:

```ruby

class OrderNumberGenerator
  MAX_ATTEMPTS = 3

  def initialize
    @attempts = 0
  end

  def call(order_id)
    order = Order.find(order_id)
    order.order_number ||= random_number_generator.call
    order.save!
  rescue ActiveRecord::RecordNotUnique => doh
     @attemps += 1
     retry if @attemps < MAX_ATTEMPTS
     raise doh
  end

  private

  def random_number_generator
    rand(100_000_001..100_999_999)
  end
end
```

The code looks fine, but we’re not able to easily verify whether `retry` scenario works as intended. We could stub Ruby’s `Kernel#rand` but we want cleaner & more flexible solution, so let’s do a tiny refactoring.

```ruby

class RandomNumberGenerator
  def call
    rand(100_000_001..100_999_999)
  end
end

class OrderNumberGenerator
  MAX_ATTEMPTS = 3

  def initialize(random_number_generator: RandomNumberGenerator.new)
    @attempts = 0
    @random_number_generator = random_number_generator
  end

  def call(order_id)
    order = Order.find(order_id)
    order.order_number ||= @random_number_generator.call
    order.save!
  rescue ActiveRecord::RecordNotUnique => doh
     @attemps += 1
     retry if @attemps < MAX_ATTEMPTS
     raise doh
  end
 end
```

Random number generator is no longer a private method, but a separate class `RandomNumberGenerator`. It’s injected to `OrderNumberGenerator` and the code still works as before. Instead of a default `RandomNumberGenerator`, for the testing purposes we pass simple lambda. Lambda pops elements from crafted array to cause intended unique index violation.

```ruby

RSpec.describe OrderNumberGenerator do
  specify do
    order_1 = Order.create!
    order_2 = Order.create!

    numbers = [100_000_999, 100_000_001, 100_000_001, 100_000_001]
    order_number_generator = OrderNumberGenerator.new(random_number_generator: -> { numbers.pop })

    order_number_generator.call(order_1.id)

    expect { order_number_generator.call(order_2.id) }.not_to raise_error
  end

  specify do
    order_1 = Order.create!
    order_2 = Order.create!

    numbers = Array.new(4, 100_000_001)
    order_number_generator = OrderNumberGenerator.new(random_number_generator: -> { numbers.pop })

    order_number_generator.call(order_1.id)

    expect { order_number_generator.call(order_2.id) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
```

## Wrap up

As you can see, apart from being more confident about the critical code in our application due to having more test scenarios, we gained a lot of flexibility. Requirements related to `order_number` may change in the future. Injecting a different `random_number_generator` will do the job and core implementation of `OrderNumberGenerator` will remain untouched.

