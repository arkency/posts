---
created_at: 2022-11-21 18:55:15 +0100
author: Szymon Fiedler
tags: [tests postgresql mysql rails]
publish: true
---

# Sometimes it's worth to test your framework features

Rails 6 introduced [`upsert_all`](https://api.rubyonrails.org/v6.0/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert_all) which was a great alternative to raw SQL for inserting or updating multiple records at once. There were gems providing this feature for earlier versions of Rails like `activerecord-import`, it did a great job in [Rails Event Store](https://github.com/RailsEventStore/rails_event_store).

<!-- more -->

## Inconvenience in Rails 6

There was one minor disadvantage, the timestamps columns: `created_at` and `updated_at` weren't updated automatically causing inserts to fail because of `NOT NULL` constraints in the database.

It had to be done manually:

```ruby
timestamp = Time.current

FancyModel.upsert_all([{ foo: :bar, created_at: timestamp, updated_at: timestamp }], unique_by: [:custom_unique_index])
```

It worked great for new objects, but not necessarily for the existing ones which were updated. We had found this out while investigating issue in the system. Those records which we knew that were updated had equal `created_at` and `updated_at`.

We wanted to fix this case, so we started with a test:

```ruby
class FancyModelTest < ActiveSupport::TestCase
  def test_timestampz
    FancyModel.create!(foo: :bar)

    timestamp = Time.current
    FancyModel.upsert_all(
      [{ foo: :baz, created_at: timestamp, updated_at: timestamp }],
      unique_by: [:custom_unique_index],
    )

    fancy = FancyModel.find_by!(foo: :baz)

    assert fancy.updated_at > fancy.created_at
  end
end
```

It failed, obviously.

## Rails 7 to the rescue

We had few ideas how to fix this. The easiest solution was on the table since we were on Rails 7 already. [They can handle timestamps](https://api.rubyonrails.org/v7.0/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert_all) on your behalf unless you disable it.

Bad code setting identical timestamp for both columns was removed and `ActiveRecord` took care of timestamps handling again. Unfortunately, the test was constantly red:

```ruby
class FancyModelTest < ActiveSupport::TestCase
  def test_timestampz
    FancyModel.create!(foo: :bar)

    FancyModel.upsert_all([{ foo: :baz }], unique_by: [:custom_unique_index])

    fancy = FancyModel.find_by!(foo: :baz)

    assert fancy.updated_at > fancy.created_at
  end
end
```

## Too fast for you?

What if it happens so fast, that assertion won't even notice — we thought.

Put a `sleep(1)` on it, make it pass:

```ruby
class FancyModelTest < ActiveSupport::TestCase
  def test_timestampz
    FancyModel.create!(foo: :bar)

    sleep(1)

    FancyModel.upsert_all([{ foo: :baz }], unique_by: [:custom_unique_index])

    fancy = FancyModel.find_by!(foo: :baz)

    assert fancy.updated_at > fancy.created_at
  end
end
```

Nope, not gonna happen.

## What about time travel, Marty?

Let's create a record in the past, for sure this will work:

```ruby
class FancyModelTest < ActiveSupport::TestCase
  def test_timestampz
    travel_to Time.zone.local(1985, 10, 26, 1, 24) do
      FancyModel.create!(foo: :bar)
    end

    FancyModel.upsert_all([{ foo: :baz }], unique_by: [:custom_unique_index])

    fancy = FancyModel.find_by!(foo: :baz)

    assert fancy.updated_at > fancy.created_at
  end
end
```

Red.

Scratching head, losing faith in own skills moment appears.

## Transactional tests

After digging throughout the Rails code, we had intuition that `updated_at` not being set to a different value might have something in common with the fact that tests are wrapped in a database transaction. [Transaction is rolled back at the end of the test case](https://guides.rubyonrails.org/testing.html#testing-parallel-transactions) to make every other test independent from each other

We created a separate example not using transactions to prove our hypothesis:

```ruby
class FancyModelTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def test_timestampz
    FancyModel.create!(foo: :bar)

    FancyModel.upsert_all([{ foo: :baz }], unique_by: [:custom_unique_index])

    fancy = FancyModel.find_by!(foo: :baz)

    assert fancy.updated_at > fancy.created_at
  end
```

Green.

## We know the answer

It turned out that _PostgreSQL_ `CURRENT_TIMESTAMP` returns time at the start of the transaction (in our case the test–wrapping one). There's no chance that `created_at` and `updated_at` will differ from each other after running `upsert_all` within the test. [As _PostgreSQL_ docs state](https://www.postgresql.org/docs/13/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT):

> Since these functions return the start time of the current transaction, their values do not change during the transaction. This is considered a feature: the intent is to allow a single transaction to have a consistent notion of the „current” time, so that multiple modifications within the same transaction bear the same time stamp.

[NOW()](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html#function_now) in MySQL does the same.

Have a look in a [Rails codebase](https://github.com/search?q=repo%3Arails%2Frails%20CURRENT_TIMESTAMP&type=code) if you're curious how `CURRENT_TIMESTAMP` is utilised.
