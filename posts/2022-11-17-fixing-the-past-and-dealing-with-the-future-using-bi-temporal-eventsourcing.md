---
created_at: 2022-11-17 09:58:56 +0100
author: Łukasz Reszke
tags: [event sourcing, ddd, bi-temporal event sourcing]
publish: true
---

# Fixing the past and dealing with the future using bi-temporal EventSourcing

Working with EventSourcing is amazing. There's a history of events that happened in the system. This makes debugging so much easier.

However it doesn't protect us from our users making mistakes. How should we deal with that? Should we remove the event? Find it in the database and update it? Events are, by definition, immutable. So given solutions don't sound like legit plan...

What about bi-temporal EventSourcing?

<!-- more -->

## Bi-temporal EventSourcing

Bi-temporal EventSourcing is based on two-time dimensions.

One of them is the one that is already well known in EventSourcing. It's the time when the event was published. In [RailsEventStore](https://railseventstore.org) we use the `timestamp` metadata to record that fact.

The other time dimension describes when the event actually becomes valid. In [RailsEventStore](https://railseventstore.org) we use the `valid_at` metadata to record that fact.

## Fixing the history

In the RailsEventStore [documentation](https://railseventstore.org/docs/v2/bi-temporal/) we have a conceptual example of how we can use bi-temporal event sourcing to fix incorrectly raised salary. I'll reuse the example.

### The example

Think about a system that allows you to keep track of the salaries of employees in a given company.

You probably thought about an excel sheet, but let's imagine something more sophisticated and user-friendly :)

All you have to do is to modify the salary of the employee. Then the change is propagated to the payroll system and at the end of the day, it lands in the employee's bank account. Cool.

Currently, there's no way to deal with an error that can be introduced by the person responsible for salary management.

Let's use the bi-temporal EventSourcing approach to deal with it.

### The one without mistake

In the simplest case, we just raise the salary of an employee. And we're fine.

```ruby
def test_raise_salary
  employee_id = SecureRandom.uuid
  stream = "Salary$#{employee_id}"
  expected_events = [SalaryRaised.new(data: { salary: 10_000, employee_id: employee_id })]

  aggregate_root_repository.with_aggregate(Salary.new(employee_id), stream) { |salary| salary.raise(10_000) }

  assert_expected_events_in_stream(stream, expected_events)
end
```

### The one with one mistake

Things happen. Humans make errors. Look at the following example that could possibly happen in the system.

The salary of an employee is raised to 10K

`salary.raise(10000)`

After 2 months an employee investigates payslips and it turns out that they're not getting what they agreed upon. They were supposed to get 10.3K.

The test below shows how we can deal with that issue using i-temporal EventSourcing.

First, let's set the salary.

```ruby
Timecop.travel(Time.utc(2022, 1, 1)) do
  aggregate_root_repository.with_aggregate(Salary.new(employee_id), stream) { |salary| salary.raise(10_000) }
end
```

We're pretending to be in the past, hence the `Timecop`. We set the salary for Jan 1, 2022.

On March 1, 2022, we already know we made an error and we need to fix it. So we use the `valid_at` metadata to say that this event is valid from this specific date.

```ruby
Timecop.travel(Time.utc(2022, 3, 1)) do
  event_store.with_metadata({ valid_at: Time.utc(2022, 1, 1) }) do
    aggregate_root_repository.with_aggregate(Salary.new(employee_id), stream) { |salary| salary.raise(10_300) }
  end
end
```

How to check that salary is right? We cannot just use the `as_of` operator on `event_store.read` because it returns an array that is ordered by the `valid_at` date. But it doesn't answer the question of what was the correct salary on Jan 1, 2022.

Here's how we can read the data from RES.

```ruby
def salary_for_given_date(employee_id, valid_at)
  event_store
    .read
    .of_type(SalaryRaised)
    .as_of # ordered by valid_at
    .to_a
    .filter { |e| e.data.fetch(:employee_id).eql?(employee_id) }
    .filter { |e| e.metadata.fetch(:valid_at).to_date.eql?(valid_at.to_date) }
    .first
    .data
    .fetch(:salary)
end
```

Whole test below.

```ruby
def test_raise_salary_but_made_mistake_that_was_found_out_later
  employee_id = SecureRandom.uuid
  stream = "Salary$#{employee_id}"

  Timecop.travel(Time.utc(2022, 1, 1)) do
    aggregate_root_repository.with_aggregate(Salary.new(employee_id), stream) { |salary| salary.raise(10_000) }
  end

  Timecop.travel(Time.utc(2022, 3, 1)) do
    event_store.with_metadata({ valid_at: Time.utc(2022, 1, 1) }) do
      aggregate_root_repository.with_aggregate(Salary.new(employee_id), stream) { |salary| salary.raise(10_300) }
    end
  end

  assert_equal 10_300, salary_for_given_date(employee_id, Time.utc(2022, 1, 1))
end
```

### The one that makes mistakes more often

But... this won't work if you make mistake twice. We need a smarter function to find out the salary for Jan 1, 2022.

Say the person introducing the data made a typo. First, they introduced 10350, then 10300.

```ruby
Timecop.travel(Time.utc(2022, 3, 1)) do
  event_store.with_metadata({ valid_at: Time.utc(2022, 1, 1) }) do
    aggregate_root_repository.with_aggregate(Salary.new(employee_id), stream) do |salary|
      salary.raise(10_350)
      salary.raise(10_300)
    end
  end
end
```

What's the result gonna be with our current implementation of `salary_for_given_date`?

It'll be 10350. The result will be ordered by `valid_at`, and then the `event_id` which is monotonical. So we could use `last`, instead of `first`, in our previous function but... Whenever I order a collection I prefer to specify the order that I am expecting. Hence, I changed the code to the one below. It specifies that the latest modification should be always preferred.

```ruby
def salary_for_given_date(employee_id, valid_at)
  event_store
    .read
    .of_type(SalaryRaised)
    .as_of # ordered by valid_at
    .to_a
    .filter { |e| e.data.fetch(:employee_id).eql?(employee_id) }
    .filter { |e| e.metadata.fetch(:valid_at).to_date.eql?(valid_at.to_date) }
    .sort { |a, b| b.metadata.fetch(:timestamp) <=> a.metadata.fetch(:timestamp) }
    .first
    .data
    .fetch(:salary)
end
```

_et voilà_

This is how you can deal with the past. Time to plan for the future.

## Planning for the future

In the [ecommerce](https://github.com/RailsEventStore/ecommerce/), our demo application, there was an issue regarding [scheduling prices for the future](https://github.com/RailsEventStore/ecommerce/issues/190). It was good opportunity to use the bi-temporal EventSourcing feature that we have introduced some time ago.

I was eager to test it out in larger project than simple example above, so I just proceed. But at first the solution didn't feel ok in the beginning. You can see my concerns in the GitHub issue and in the [commit message](https://github.com/RailsEventStore/ecommerce/commit/b7c83959b30de1aaceb0082b96d57d8803def938) itself.

### The solution

Instead of changing the domain code, we used the bi-temporal EventSourcing feature. Because of that we needed a new command and it's handler.

```ruby
class SetFuturePriceHandler
    def initialize(event_store)
    @repository = Infra::AggregateRootRepository.new(event_store)
    @event_store = event_store
    end

    def call(cmd)
    @event_store.with_metadata({ valid_at: cmd.valid_since }) do
        @repository.with_aggregate(Product, cmd.product_id) do |product|
        product.set_price(cmd.price)
        end
    end
    end
end
```

The most important here are following lines

```ruby
@event_store.with_metadata({ valid_at: cmd.valid_since }) do
    @repository.with_aggregate(Product, cmd.product_id) do |product|
        product.set_price(cmd.price)
    end
end
```

We add the additional `valid_at` metadata to the `event_store`. As you remember from the beginning, it's the other time dimension that allows us to make decision _when_ the event became valid. Exactly at which point in time. This metadata is used when the _Product_ aggregate publishes the `PriceSet` event.

### The test

Test has to be included in order to prove that it works as expected.

```ruby
    def test_check_future_price
       product_1_id = SecureRandom.uuid
       set_price(product_1_id, 20)
       future_date_timestamp = Time.now.utc + plus_five_days
       set_future_price(product_1_id, 30, future_date_timestamp.to_s)

       Timecop.travel(future_date_timestamp + 2137) do
         order_id = SecureRandom.uuid
         add_item(order_id, product_1_id)
         stream = "Pricing::Order$#{order_id}"

         assert_events(
           stream,
           OrderTotalValueCalculated.new(
             data: {
               order_id: order_id,
               discounted_amount: 30,
               total_amount: 30
             }
           )
         ) { calculate_total_value(order_id) }
       end
     end
```

As you can see the newer price is used when we _time travel_ into the future.

But you don't have to trust me.

You can check it yourself by cloning [ecommerce](https://github.com/RailsEventStore/ecommerce) and experimenting with those tests on your own.

## The moment it clicked for me that Bi-temporal EventSourcing is good approach for the future pricing

As I mentioned, initially I wasn't convinced that this approach is good for setting future prices. I thought that having it in metadata is kind of... coupling to the infra. We had an discussion with the team and I missed very important point in my thought process.

Metadata is just part of an event. Event is part of the domain layer. Hence it makes total sense to deal with such problems using bi-temporal EventSourcing.
And as you can see, this solution is quite simple. It doesn't require us to make _any_ changes to the domain model. If you ask me, that's very valuable benefit.