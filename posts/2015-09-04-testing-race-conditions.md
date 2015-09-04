---
title: "Testing race conditions in your Rails app"
created_at: 2015-09-04 09:22:03 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'race conditions' ]
newsletter: :skip
img: "/assets/images/race-conditions-rails-active-record/race-rails2-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/race-conditions-rails-active-record/race-rails2-fit.jpg" width="100%" />
  </figure>
</p>

From time to time, there comes a requirement in your application
where you have to guarantee that something can be done at most X
number of times. For example, only 15 people can subscribe to a
course, only **limited number of people can buy this physical or
virtual product**, only 200 people can go to a concert, etc. How
do you test that this limitation actually work? And not only work
but that it works under **heavy load**, when there are multiple customers
trying to **buy the last item because it is a hot event or the
product is offered with a big discount**?

<!-- more -->

You might think that testing it is hard, and maybe not worthy? But I found
out that sometimes it is **not so hard at all**, and it might be simpler than
you imagine. Sometimes, all you need is **4 threads to reproduce and fix
the problem**.

```
#!ruby
specify do
  begin
    expect(ActiveRecord::Base.connection.pool.size).to eq(5)
    concurrency_level = 4

    merchant  = TestMerchant.new
    product   = merchant.create_product(quantity: concurrency_level - 1)

    customers    = concurrency_level.times.map{ TestCustomer.new }

    fail_occurred = false
    wait_for_it  = true

    threads = concurrency_level.times.map do |i|
      Thread.new do
        true while wait_for_it
        begin
          customers[i].buy_products([{quantity: 1, product: product}])
        rescue Orders::CreateOrderService::Invalid
          fail_occurred = true
        end
      end
    end
    wait_for_it = false
    threads.each(&:join)
    
    expect_fail_for_one_customer(fail_occurred)
    expect_success_for_rest_of_customers(customers, product)
    expect_product_not_oversold(product, concurrency_level)
  ensure
    ActiveRecord::Base.connection_pool.disconnect!
  end
end
```

Let's go step by step through this code.

```
expect(ActiveRecord::Base.connection.pool.size).to eq(5)
```

By default Active Record **connection pool** can keep up to 5 DB connections.
This can be changed in `database.yml` . This just checks if the
preconditions for the test are what I imagined. That no developer, and no
CI server has these values different.


```
#!ruby
concurrency_level = 4
```

**One DB connection is used by the main thread** (the one running the test itself).
This leaves us with 4 threads that can use the 4 remaining DB connections
to simulate customers buying in our shop.

```
#!ruby
merchant  = TestMerchant.new
product   = merchant.create_product(quantity: concurrency_level - 1)
```

We instantiate a new `TestMerchant` actor which creates a new product with a limited
quantity available. There are only **3 items in the inventory** so when 4 customers
try to buy at the same time, it should fail for one of them. Actors are
implemented with plain Ruby classes. They just call the same
[Service Objects](http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/)
that our Controllers do. This code is specific to your application.

```
#!ruby
customers = concurrency_level.times.map{ TestCustomer.new }
```

We create 4 customers in the main thread. Depending on what being a customer
means in your system, and how many Service Objects it involves, you might
want to do this in your main thread, instead of in the _per-customer_ threads.
Because, we strive to achieve **the highest contention possible** around buying
the product. If you create your customer in the _per-customer_ threads it might
mean that one customer is already buying while another is still registering.

```
#!ruby
fail_occurred = false
```

In one of the threads, we want to catch an exception that placing an Order is
impossible because it is no longer in stock and remember that it occurred. We need to define the
variable outside of the `Thread.new do end` block, **otherwise it would not be
accessible in the main scope**.

```
#!ruby
wait_for_it  = true
```

I couldn't find a way in Ruby to create a thread with a block, without starting it
immediately. **So I am using this boolean flag instead**. All the threads are
executing a nop-loop while waiting for this variable to be switched to false, which
happens after initializing all threads.

```
#!ruby
threads = concurrency_level.times.map do |i|
  Thread.new do
    true while wait_for_it
    begin
      customers[i].buy_products([{quantity: 1, product: product}])
    rescue Orders::CreateOrderService::Invalid
      fail_occured = true
    end
  end
end

wait_for_it = false
```

We create 4 threads in which **4 customers try to buy the product which can
be purchased max 3 times**. One of the customers should fail in which case
we will set `fail_occured` to true. The first thread is created faster than the rest
of them and remember that we want high contention. So we use `true while wait_for_it`
to wait until all threads are created. Then main thread sets `wait_for_it` to `false`.
That starts the buying process for those customers.

```
#!ruby
threads.each(&:join)
```

We don't know how long it will take for the threads to finish so we **gladly wait
for all of them**.

```
#!ruby
expect_fail_for_one_customer(fail_occured)
expect_success_for_rest_of_customers(customers, product)
expect_product_not_oversold(product, concurrency_level)
```

Then we can check all our expectations. One failure, three
successes, and product not _over-sold_. These, of course, are very specific
to your domain as well.

When building such test case it is very important to start with _red_ phase when you
go through _red, green, refactor_ cycle. Without the race condition preventing method
that you choose to implement the test should fail. **If it doesn't fail it means the
contention you created is not big enough**.

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="/assets/images/fearless-refactoring-fit.png" width="18%" /></a>
<a href="/rails-react"><img src="/assets/images/react-for-rails/cover-fit.png" width="18%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="18%" /></a>
<a href="/developers-oriented-project-management/"><img src="/assets/images/dopm-fit.jpg" width="18%" /></a>
<a href="https://arkency.dpdcart.com"><img src="/assets/images/blogging-small-fit.png" width="18%" /></a>
