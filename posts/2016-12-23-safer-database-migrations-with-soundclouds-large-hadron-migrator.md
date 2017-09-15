---
title: "Safer Rails database migrations with Soundcloud's Large Hadron Migrator"
created_at: 2016-12-23 10:21:22 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'migrations' ]
newsletter: :arkency_form
img: "rails-migrations-large-online-big-data/large-hadron-migrator.jpg"
---

When I first started using Rails years ago I fell in love with the concept of
database migrations. Perhaps because at the time I was working on commercial
projects in C# which lacked this and I could feel the difference. The fact
that for many years the concept remained almost the same with some minor
improvements speaks for itself. Ruby on Rails continues evolving all the time but
migrations remain simple.

However, there is **an elephant in the room**.

<!-- more -->

Some DDL operations on MySQL database (such as adding or removing columns)
are locking the whole affected table. It means that **no other process will be
able to add or update a record at that time** and will wait until lock is released
or timeout occurs. The list of operations that can be performed online (without lock)
constantly increases with every new MySQL release so make sure to check the
version of your database and consult its documentation. In particular, this
**has been very much improved in
[MySQL 5.6](https://dev.mysql.com/doc/refman/5.6/en/innodb-create-index-overview.html)**.

With lower number of records, offline DDL operations are not problematic. You can live with 1s
lock. Your application and background workers will not do anything in that
time, some customers might experience slower response times. But in general,
nothing harmful very much.

However, when the table has millions of records **changing it can lock the table
for many seconds or even minutes**. Soundcloud even says _an hour_, although
I personally haven't experienced it.

Anyway, there are tables in our system of utter importance such as _orders_ or
_payments_ and locking them for minutes would mean that customers can't buy,
merchants can't sell and we don't earn a dime during that time.

For some time our solution was to run the costly migrations around 1 am or 6 am when
there was not much traffic and a few minutes of downtime was not a problem.
But with the volume of purchases constantly increasing, with having more merchants from
around the whole world, **there is no longer a good hour to do
maintenance anymore**.

Not to mention that everyone loves to sleep and waking up earlier just to
run a migration is pointless. We needed better tools and better robots to
solve this problem.

We decided to use [Large Hadron Migrator](https://github.com/soundcloud/lhm)
created by Soundcloud.

How does it work?

1. It creates a new version of table
2. It installs triggers that make updates in old table to appear in a new table
3. It copies in batches data from old table to new table
4. It switches atomically old and new tables when the whole process is finished.

That's the idea behind it.

The syntax is not as easy as with standard Rails migrations because you will need
to restore to using SQL syntax a bit more often.

```ruby
require 'lhm'

class MigrateUsers < ActiveRecord::Migration
  def up
    Lhm.change_table :users do |m|
      m.add_column :arbitrary_id, "INT(12)"
      m.add_index  [:arbitrary_id, :created_at]
    end
  end

  def down
    Lhm.change_table :users do |m|
      m.remove_index  [:arbitrary_id, :created_at]
      m.remove_column :arbitrary
    end
  end
end
```

## Summary

If you need to migrate big tables without downtime in MySQL you can use LHM
or upgrade MySQL to 5.6 :)

If you are still worried how to safely do Continuous
Deployment and handle migrations please read our other blog posts as well:

* [The biggest obstacle to start with Continuous Deployment - database migrations](/2014/04/the-biggest-obstacle-to-start-with-continuous-deployment/)
* [Rolling back complex apps](/2015/10/rolling-back-complex-apps/)
