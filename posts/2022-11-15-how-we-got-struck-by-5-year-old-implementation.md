---
created_at: 2022-11-15 14:59:22 +0100
author: Szymon Fiedler
tags: ["ruby", "rails", "postgresql"]
publish: false
---

# How we got struck by 5–year–old implementation

Recently we discovered that we were wrong on computing lock key for acquiring advisory locks. It was already covered as an update to [article about building read models](https://blog.arkency.com/how-to-build-a-read-model-with-rails-event-store-projection/#we_were_wrong_on_computing_lock_key), but we thought that telling the whole story behind the issue could be interesting for you.

<!-- more -->

## Why we needed advisory lock

Please, have a look at this asynchronous event handler. There are two bounded contexts involved:

- Banking — it takes care of bank account's technical information coming from 3rd party service
- Accounting — it is interested in bank accounts but in terms of doing bookkeeping job like putting initial balance and its further changes into specific [accounts](<https://en.wikipedia.org/wiki/Account_(bookkeeping)>)

When bank account is created in _Banking_ we need to reflect that in _Accounting_ and provide bookkeeping identifier for that account. It is done under certain rules, eg. all the bank accounts need to own parent code `512000` and code which follows previous one like `512101`, `512102`, `512103`, etc.

```ruby
# frozen_string_literal: true

module Accounting
  class CreateBankAccount < Infra::EventHandler
    def call(event)
      tenant = ::Account.find(event.data.fetch(:tenant_id))
      bank_account = ::BankAccount.find(event.data.fetch(:id))
      bookkeeping_account = BookkeepingAccount.for(bank_account)

      BankAccount.create!(
        tenant: tenant,
        name: "#{bookkeeping_account.code} – Bank",
        display_name: "Bank",
        code: bookkeeping_account.code, # eg. 512101
        parent_code: bookkeeping_account.parent_code, # eg. 512000
      )
    end
  end
end
```

The code above is prone to concurrency issues. The business logic won't allow creating two `Accounting::BankAccount` with the same `code` for the given tenant. `ActiveRecord::RecordNotUnique` would pop up soon, obviously.

## Advisory locks to the rescue

In 2017 while working on a different project, we came with idea of using [advisory locks](https://www.postgresql.org/docs/9.4/explicit-locking.html#ADVISORY-LOCKS) to implement pessimistic locking, [`pg_advisory_xact_lock(key bigint)`](https://www.postgresql.org/docs/9.4/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS) specifically:

> `pg_advisory_xact_lock` works the same as `pg_advisory_lock`, except the lock is automatically released at the end of the current transaction and cannot be released explicitly.
>
> `pg_advisory_lock` locks an application-defined resource, which can be identified either by a single 64-bit key value or two 32-bit key values (note that these two key spaces do not overlap).

We needed a way to generate big integer to be passed as argument to `pg_advisory_xact_lock`. Using [`Object#hash`](https://ruby-doc.org/core-3.1.2/Object.html#method-i-hash) for that purpose sounded natural since it _generates an Integer hash value for this object_.

Quick spike to verify our hypothesis:

```ruby
uuid = "a2e920fd-c51a-44a8-924d-5dc6aaba9884"
lock_nr = uuid.hash
ActiveRecord::Base.transaction do
  puts "trying to obtain lock - #{Time.now}"
  ActiveRecord::Base.connection.execute "SELECT pg_advisory_xact_lock(#{lock_nr})"
  puts "lock granted, sleeping - #{Time.now}"
  sleep(50)
end
puts "lock released - #{Time.now}"
```

Lock no. 1:

```
   (0.5ms)  BEGIN
trying to obtain lock - 2017-06-28 10:05:44 +0200
   (0.7ms)  SELECT pg_advisory_xact_lock(1924743033351481473)
lock granted, sleeping - 2017-06-28 10:05:44 +0200
```

Lock no. 2:

```
trying to obtain lock - 2017-06-28 10:05:46 +0200
   (48570.8ms)  SELECT pg_advisory_xact_lock(1924743033351481473)
lock granted, sleeping - 2017-06-28 10:06:34 +0200
```

Proof of concept worked. Let's implement it then:

```ruby
# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.with_advisory_lock(*args)
    transaction do
      bigint = args.join.hash
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(#{bigint})")
      yield
    end
  end
end

module Accounting
  class CreateBankAccount < Infra::EventHandler
    def call(event)
      tenant = ::Account.find(event.data.fetch(:tenant_id))
      bank_account = ::BankAccount.find(event.data.fetch(:id))

      ApplicationRecord.with_advisory_lock(tenant.id) do
        bookkeeping_account = BookkeepingAccount.for(bank_account)

        BankAccount.create!(
          tenant: tenant,
          name: "#{bookkeeping_account.code} – Bank",
          display_name: "Bank",
          code: bookkeeping_account.code,
          parent_code: bookkeeping_account.parent_code,
        )
      end
    end
  end
end
```

`tenant_id` was taken as the input value for calculating _big integer_ since we needed to guarantee the uniqueness in scope of the tenant.

## Testing for concurrency issues

In 2015 Robert wrote a post on [Testing race conditions in Rails apps](https://blog.arkency.com/2015/09/testing-race-conditions/). Since then, we know well how to test concurrent code, don't we?

```ruby
# frozen_string_literal: true

require_relative "test_helper"
require "database_cleaner/active_record"

module Accounting
  class OnBankAccountCreatedConcurrencyTest < TestCase
    self.use_transactional_tests = false

    setup { DatabaseCleaner.strategy = [:truncation] }

    def test_concurrency
      begin
        concurrency_level = ActiveRecord::Base.connection.pool.size - 1
        assert concurrency_level >= 4

        bank_accounts = concurrency_level.times.map { create_bank_account }

        fail_occurred = false
        wait_for_it = true

        Thread.abort_on_exception = true
        threads =
          concurrency_level.times.map do |i|
            Thread.new do
              true while wait_for_it
              begin
                Accounting::CreateBankAccount.new.call(
                  Banking::BankAccountCreated.new(data: { tenant_id: 2137, id: bank_accounts.fetch(i).id }),
                )
              rescue ActiveRecord::RecordNotUnique
                fail_occurred = true
              end
            end
          end
        wait_for_it = false
        threads.each(&:join)

        refute fail_occurred
        assert_equal 4, Accounting::BankAccount.of_tenant(2137).where(parent_code: 512_000).size
      ensure
        ActiveRecord::Base.connection_pool.disconnect!
      end
    end

    teardown { DatabaseCleaner.clean }

    private

    def create_bank_account
      BankAccount.create!(
        connector_id: 12_345,
        balance_currency: Money::Currency.new("EUR").iso_code,
        balance_value: 1_000_000.00,
        external_id: SecureRandom.uuid,
      )
    end
  end
end
```

The test was green, code was acting properly, so we shipped the code to production and slept well.

## Everything was fine until it wasn't

Few years later, `ActiveRecord::RecordNotUnique` strikes back. We were intrigued why this had happened, but had no clue. The issue was self healing, since the code was run asynchronously on sidekiq with retries on failure. Quick investigations didn't bring answer to the problem. The issue wasn't a trouble to the app, but it was rather popping up in Honeybadger making developers scratch their head again and again.

Then our teammate get those flashbacks from past project. He reminded himself that from time to time the similar issue occurred with advisory lock acquired in the same manner. You start discussing stack differences between those projects, what has changed in the past few months

_— Oh, we've added another sidekiq process_

You instantly run two separate `irb` processes to check whether this might be the case:

Process no. 1:

```ruby
irb(main):001:0> 123456.hash
=> -169614201293062129
```

Process no. 2:

```ruby
irb(main):001:0> 123456.hash
=> -4474522856021669622
```

_— Boom! Roasted..._

## Properly compute your lock key

Our initial implementation of `advisory_lock` method didn't provide identical hash across different MRI processes and code was prone to `ActiveRecord::RecordNotUnique` errors:

```ruby
# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.with_advisory_lock(*args)
    transaction do
      bigint = args.join.hash
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(#{bigint})")
      yield
    end
  end
end
```

It required two different processes using two separate database connections to prove that previous `advisory_lock` didn’t work as expected and allowed share of the same resource. Test setup didn't meet this criteria both in dev environment nor on CI.

There's important note on that in Ruby’s [Object#hash](https://ruby-doc.org/core-3.1.2/Object.html#method-i-hash) docs being the key to our issues:

> The hash value for an object may not be identical across invocations or implementations of Ruby. If you need a stable identifier across Ruby invocations and implementations you will need to generate one with a custom method.

We fixed it by creating custom `hash_64()` function in our PostgreSQL database:

```sql
create function hash_64(_identifier character varying) returns bigint
    language plpgsql
as
$$
DECLARE
hash bigint;
BEGIN
  select left('x' || md5(_identifier), 16)::bit(64)::bigint into hash;
  return hash;
  END;
  $$;

alter function hash_64(varchar) owner to dbuser;

```

It was then used to fix the implementation of `advisory_lock`:

```ruby
# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.with_advisory_lock(*args)
    transaction do
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(hash_64('#{args.join}'))")
      yield
    end
  end
```

The `hash_64()` implementation was taken from [Eventide](https://github.com/eventide-project/message-store-postgres/commit/272a848e0f19851e255a28d8c7dee2ba66e98997) codebase.

There are other alternative solutions, like use of [`Zlib#crc32`](https://ruby-doc.org/stdlib-2.5.3/libdoc/zlib/rdoc/Zlib.html#method-c-crc32) if you prefer to stick with Ruby to compute lock key:

```ruby
# frozen_string_literal: true
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.with_advisory_lock(*args)
    transaction do
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(#{Zlib.crc32(args.join)})")
      yield
    end
  end
```
