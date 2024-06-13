---
created_at: 2024-06-13 13:16:29 +0200
author: Szymon Fiedler
tags: [rails, mysql, postgresql, performance]
publish: false
---

# How to add index to big table of your Rails app
When your application is successful, some of the tables can grow pretty big — I’m looking at you *users* table. If you’re curious enough, you periodically check how your database performs. If any slow query pops up in the metrics, there’s a great chance that some index is missing. 

<!-- more -->

## State of the DB engines
While most modern database engines create indexes in an asynchronous, non–blocking manner, it’s good to get familiar with all the exceptions from this rule. I highly recommend reading the documentation of [PostgreSQL](https://www.postgresql.org/docs/current/sql-createindex.html#SQL-CREATEINDEX-CONCURRENTLY), [MySQL](https://dev.mysql.com/doc/refman/8.4/en/innodb-online-ddl-operations.html#online-ddl-index-operations). I’m not sure about SQLite here as the documentation doesn’t clearly state that. However, my [quick chit–chat with LLM](https://chatgpt.com/share/248e939b-0fa4-49ad-a691-8535bab7dd08) may give you some insights.

## What’s the problem then?
As you already know `CREATE INDEX` statement will be handled asynchronously by the database if appropriate algorithm is used. This means that no reads, writes and update will be blocked. 

Typically, for the Rails application, you’ll run a migration via Ruby process during deployment, using all the goodies from `ActiveRecord::Migration` class and its surroundings. 

Let’s imagine the database schema like that:

```ruby
ActiveRecord::Schema[7.1].define(version: 2024_06_13_121701) do
  create_table "users", force: :cascade do |t|
    t.string "email"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
```

Imagine you want to quickly find all those users which didn’t activate the account:

```ruby
User.where(active: false)
```

If you have enough *users*, speaking of dozens or hundreds of millions, doing full table scan could simply kill the database performance. Full table scan happens when database has no index to use and need to check every row whether it meets the criteria.

## Obvious solution

Let’s add the index then:

```shell
➜  trololo git:(master) bin/rails g migration AddIndexOnActiveUsers
      invoke  active_record
      create    db/migrate/20240613121751_add_index_on_active_users.rb
```

Implementation:

```ruby
class AddIndexOnActiveUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :active
  end
end
```

Let’s run it:

```
➜  trololo git:(master) bin/rails db:migrate
== 20240613121751 AddIndexOnActiveUsers: migrating ============================
-- add_index(:users, :active)
   -> 0.0013s
== 20240613121751 AddIndexOnActiveUsers: migrated (0.0013s) ===================
```

Ok, it was quite fast, right? That’s correct for your dev machine, not necessarily for the production setup. Now magnify this time `0.0013s` by 6 or 7 orders of magnitude if your table is big enough:

```
➜  trololo git:(master) bin/rails db:migrate
== 20240613121751 AddIndexOnActiveUsers: migrating ============================
-- add_index(:users, :active)
   -> 13000.4928s
== 20240613121751 AddIndexOnActiveUsers: migrated (0.0013s) ===================
```

I’ll do the maths for you: *1300.4928s* means *21 minutes 40.49 seconds*. But it can be even longer — don’t ask me how I found about this.

While the process of migration will end up eventually, the  migration blocking any other deployments to your application during this time may be unacceptable for various reasons:
* you cannot release any other change to production until migration completes
* something other goes wrong and you need to rapidly deploy a hotfix, but you can’t since the deployment is blocked by *long running migration™*
* process manager on a deployment machine may expect output within, e.g. 5 minutes. Long running migration will get killed in such scenario.

## What to do then?
Simply skip the migration body for `RAILS_ENV=production`:

```ruby
class AddIndexOnActiveUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :active, if_not_exists: true unless Rails.env.production?
  end
end
```

The migration will be executed on production environment, but will have no effect on your database. `schema.rb` or `structure.sql` (depending on what you use) will be aligned. Sufficient entry will also appear in `schema_migrations` table. All the developers will have index added on their local databases, test environment will be aligned too.

But _Hey, where’s my index on production?!_ you might ask. And that’s a pretty valid question. What you’ll need is a way to run a rails runner or rake task on production. Depending on the capabilities you have, you might choose to:
* Run it within `bin/rails console`:

```ruby
ActiveRecord::Migration.add_index :users, :active, if_not_exists: true
```

* Do the same via `bin/rails runner`:

```shell
bin/rails r "ActiveRecord::Migration.add_index :users, :active, if_not_exists: true"
```

* Last, but not least, implement a `Rake` task. It has the advantage that it has to be committed to the repository so you don’t loose the history what’s happened:

```ruby
namespace :indexes do
  task add_index_on_active_users: :environment do
    ActiveRecord::Migration.add_index :users, :active, if_not_exists: true
  end
end
```

Execute it with `bin/rails indexes:add_index_on_active_users`.

For the last option it’s also easy to enhance it with logging to easily identify execution in *Grafana*, *Datadog* or any other tool you use for your logs.

```ruby
namespace :indexes do
  task add_index_on_active_users: :environment do
    Rails.logger.info("task indexes:add_index_on_active_users started")

    ActiveRecord::Migration.add_index :users, :active, if_not_exists: true

    Rails.logger.info("task indexes:add_index_on_active_users finished”)
  end
end
```

### Tiny detail
If you’re aware enough, you probably spotted `if_not_exists: true` flag. We like idempotence and that’s the reason. If anyone runs this task again, nothing will happen. If you prefer to see `ActiveRecord::StatementInvalid` instead, feel free to skip it.
