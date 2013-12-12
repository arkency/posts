---
title: "Rails 3 & 4 - what you need to know about preloading"
created_at: 2013-12-08 12:05:29 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'rails', 'active record', 'preloading', 'eager_loading' ]
---

You are probably already familiar with the method `#includes` for eager loading
data from database if you are using Rails and ActiveRecord. But do you know
about `#preload` and `#eager_load` which can help you achieve the same goal?
And you know what changed in Rails 4 in that matter? If not, sit down and
listen. This lesson won't take long.

<!-- more -->

Let's start with our Active Record class and associations definitions that we
are going to use throughout the whole post:

```
#!ruby
class User < ActiveRecord::Base
  has_many :addresses
end

class Address < ActiveRecord::Base
  belongs_to :user
end
```

And here is the seed data that will help us check the results of our queries:

```
#!ruby
rob = User.create!(name: "Robert Pankowecki", email: "robert@example.org")
bob = User.create!(name: "Bob Doe", email: "bob@example.org")

rob.addresses.create!(country: "Poland", city: "Wrocław", postal_code: "55-555", street: "Rynek")
rob.addresses.create!(country: "France", city: "Paris", postal_code: "75008", street: "8 rue Chambiges")
bob.addresses.create!(country: "Germany", city: "Berlin", postal_code: "10551", street: "Tiergarten")
```

## Rails 3

Typically, when you want to use the eager loading feature you would use the
`#includes` method, which Rails encouraged you to use since Rails2 or maybe even
Rails1 ;). And that works like a charm doing 2 queries:

```
#!ruby
User.includes(:addresses)
#  SELECT "users".* FROM "users" 
#  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)
```

So what are those two other methods for? First let's see them in action.

```
#!ruby
User.preload(:addresses)
#  SELECT "users".* FROM "users" 
#  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)
```

Apparently `#preload` behave just like `#includes`. Or is it the other way around?

And as for the `#eager_load`:

```
#!ruby
User.eager_load(:addresses)
#  SELECT
#  "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, 
#  "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 
#  FROM "users" 
#  LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id"
```

It is a completely different story, isn't it? The whole mystery is that Rails
has 2 ways of preloading data. One is using separate db queries to obtain the addtional
data. And one is using one query (with `left join`) to get them all.

If you use `#preload`, it means you always want separate queries. If you use
`#eager_load` you are doing one query. So what is `#includes` for? It decides
for you which one way it is going to be. You let Rails handle that decision.
What is the decision based on, you might ask? It is based on query conditions.
Let's see an example where `#includes` delegates to `#eager_load` so that there
is one big query only.

```
#!ruby
User.includes(:addresses).where("addresses.country = ?", "Poland")
User.eager_load(:addresses).where("addresses.country = ?", "Poland")

# SELECT 
# "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4,
# "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 
# FROM "users"
# LEFT OUTER JOIN "addresses" 
# ON "addresses"."user_id" = "users"."id" 
# WHERE (addresses.country = 'Poland')
```

In the previous example Rails detected that the condition in `where` clause
is using columns from preloaded (included) table names. So `#includes` delegates
the job to `#eager_load`. You can always achieve the same result by using the
`#eager_load` method directly.


What happens if you instead try to use `#preload` explicitely?

```
#!ruby
User.preload(:addresses).where("addresses.country = ?", "Poland")
#  SELECT "users".* FROM "users" WHERE (addresses.country = 'Poland')

#  SQLite3::SQLException: no such column: addresses.country
```

We get an exception because we haven't joined `users` table with
`addresses` table in any way.

### Is this intention revealing?

If you look at our example again

```
#!ruby
User.includes(:addresses).where("addresses.country = ?", "Poland")
```

you might wonder, what is the original intention of this code.
What did the author mean by that? What are we trying to achieve here
with our simple Rails code:

* Give me users with polish addresses and preload only polish addresses
* Give me users with polish addresses and preload all of their addresses
* Give me all users and their polish addresses.

Do you know which goal we achieved? The first one. Let's see if we can
achieve the second and the third ones.

## Is `#preload` any good?

Our current goal: _Give me users with polish addresses but preload all of their addresses. I need to know all addreeses of people whose at least one address is in Poland._

We know that we only users with polish addresses. That itself is easy:
`User.joins(:addresses).where("addresses.country = ?", "Poland")` and we know
that we want to eager load the addresses so we also need `includes(:addresses)`
part right?

```
#!ruby
r = User.joins(:addresses).where("addresses.country = ?", "Poland").includes(:addresses)

r[0]
#=> #<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24"> 

r[0].addresses
# [
#   #<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">
# ]
```

Well, that didn't work exactly like we wanted.
We are missing the second user address that wanted to have this time.
Rails still detected that we are using included table in where statement
and used `#eager_load` implementation under the hood. The only difference compared to
previous example is that is that Rails used `INNER JOIN` instead of `LEFT JOIN`,
but for that query it doesn't even make any difference.

```
#!sql
SELECT 
"users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4,
"addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 
FROM "users"
INNER JOIN "addresses" 
ON "addresses"."user_id" = "users"."id" 
WHERE (addresses.country = 'Poland')
```

This is that kind of situation where you can outsmart Rails and be explicit
about what you want to achieve by directly calling `#preload` instead of
`#includes`.

```
#!ruby
r = User.joins(:addresses).where("addresses.country = ?", "Poland").preload(:addresses)
# SELECT "users".* FROM "users" INNER JOIN "addresses" ON "addresses"."user_id" = "users"."id" WHERE (addresses.country = 'Poland')
# SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1)

r[0] 
# [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">] 

r[0].addresses
# [
#  <Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">,
#  <Address id: 3, user_id: 1, country: "France", street: "8 rue Chambiges", postal_code: "75008", city: "Paris", created_at: "2013-12-08 11:36:30", updated_at: "2013-12-08 11:36:30">] 
# ]
```

This is exactly what we wanted to achieve.
Thanks to using `#preload` we are no longer mixing which users we want to fetch
with what data we would like to preload for them. And the queries are plain
and simple again.

## Preloading subset of association

The goal of the next exercise is: _Give me all users and their polish addresses_.

To be honest, I never like preloading only a subset of association because some
parts of your application probably assume that it is fully loaded. It might only
make sense if you are getting the data to display it.

In such case, I would prefer to add the condition to the association itself:

```
#!ruby
class User < ActiveRecord::Base
  has_many :polish_addresses, conditions: {country: "Poland"}, class_name: "Address"
end
```

And just preload it explicitely using one way:

```
#!ruby
r = User.preload(:polish_addresses)

# SELECT "users".* FROM "users" 
# SELECT "addresses".* FROM "addresses" WHERE "addresses"."country" = 'Poland' AND "addresses"."user_id" IN (1, 2)

r

# [
#   <User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">
#   <User id: 2, name: "Bob Doe", email: "bob@example.org", created_at: "2013-12-08 11:26:25", updated_at: "2013-12-08 11:26:25">
# ] 

r[0].polish_addresses

# [
#   #<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">
# ] 

r[1].polish_addresses
# [] 
```

or another:

```
#!ruby
r = User.eager_load(:polish_addresses)

# SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, 
#        "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7
# FROM "users" 
# LEFT OUTER JOIN "addresses" 
# ON "addresses"."user_id" = "users"."id" AND "addresses"."country" = 'Poland'

r
# [
#   #<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">,
#   #<User id: 2, name: "Bob Doe", email: "bob@example.org", created_at: "2013-12-08 11:26:25", updated_at: "2013-12-08 11:26:25">
# ]

r[0].polish_addresses
# [
#   #<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">
# ]

r[1].polish_addresses
# []
```

What should we do when we only know at runtime about the association conditions
that we would like to apply? I honestly don't know.

## The ultimate question

You might ask: _What is this stuff so hard?_ I am not sure but I think most ORMs
are build to help you construct single query and load data from one table. With
eager loading the situation gest more complicated and we want load multiple data
from multiple tables with multiple conditions. Here we are using chainable API
to build 2 or more queries (in case of using `#preload`).

What kind of API would I love? I am thinking about something like:

```
#!ruby
User.joins(:addresses).where("addresses.country = ?", "Poland").preload do |users|
  users.preload(:addresses).where("addresses.country = ?", "Germany")
  users.preload(:lists) do |lists|
    lists.preload(:tasks).where("tasks.state = ?", "unfinished")
  end
end
```

I hope you get the idea :)

## Rails 4 changes

Now, let's about what changed in Rails 4.

```
class User < ActiveRecord::Base
  has_many :addresses
  has_many :polish_addresses, -> {where(country: "Poland")}, class_name: "Address"
end


.0.0-p247 :005 > User.includes(:addresses)
  User Load (1.0ms)  SELECT "users".* FROM "users"
  Address Load (0.2ms)  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)
 => #<ActiveRecord::Relation [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">, #<User id: 2, name: "Bob Doe", email: "bob@example.org", created_at: "2013-12-08 11:26:25", updated_at: "2013-12-08 11:26:25">]> 
2.0.0-p247 :006 > User.preload(:addresses)
  User Load (0.6ms)  SELECT "users".* FROM "users"
  Address Load (0.5ms)  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)
 => #<ActiveRecord::Relation [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">, #<User id: 2, name: "Bob Doe", email: "bob@example.org", created_at: "2013-12-08 11:26:25", updated_at: "2013-12-08 11:26:25">]> 
2.0.0-p247 :007 > User.eager_load(:addresses)
  SQL (0.4ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id"
 => #<ActiveRecord::Relation [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">, #<User id: 2, name: "Bob Doe", email: "bob@example.org", created_at: "2013-12-08 11:26:25", updated_at: "2013-12-08 11:26:25">]> 




#~~~

2.0.0-p247 :010 >   User.includes(:addresses).where("addresses.country = ?", "Poland")
DEPRECATION WARNING: It looks like you are eager loading table(s) (one of: users, addresses) that are referenced in a string SQL snippet. For example: 

    Post.includes(:comments).where("comments.title = 'foo'")

Currently, Active Record recognizes the table in the string, and knows to JOIN the comments table to the query, rather than loading comments in a separate query. However, doing this without writing a full-blown SQL parser is inherently flawed. Since we don't want to write an SQL parser, we are removing this functionality. From now on, you must explicitly tell Active Record when you are referencing a table from a string:

    Post.includes(:comments).where("comments.title = 'foo'").references(:comments)

If you don't rely on implicit join references you can disable the feature entirely by setting `config.active_record.disable_implicit_join_references = true`. (called from block in <module:IRB> at /home/paneq/.rvm/rubies/ruby-2.0.0-p247/lib/ruby/2.0.0/irb/inspector.rb:122)
  SQL (0.7ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id" WHERE (addresses.country = 'Poland')
 => #<ActiveRecord::Relation [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">]> 
2.0.0-p247 :011 > User.eager_load(:addresses).where("addresses.country = ?", "Poland")
  SQL (0.7ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id" WHERE (addresses.country = 'Poland')
 => #<ActiveRecord::Relation [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">]> 





2.0.0-p247 :016 >   User.includes(:addresses).where("addresses.country = ?", "Poland").references(:addresses)
  SQL (0.7ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id" WHERE (addresses.country = 'Poland')
 => #<ActiveRecord::Relation [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">]> 
2.0.0-p247 :017 > r = User.includes(:addresses).where("addresses.country = ?", "Poland").references(:addresses)
  SQL (0.8ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id" WHERE (addresses.country = 'Poland')
 => #<ActiveRecord::Relation [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">]> 
2.0.0-p247 :018 > r[0]
 => #<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24"> 
2.0.0-p247 :019 > r[0].addresses
 => #<ActiveRecord::Associations::CollectionProxy [#<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">]> 


#~~~

2.0.0-p247 :021 >   User.preload(:addresses).where("addresses.country = ?", "Poland")
  User Load (0.7ms)  SELECT "users".* FROM "users" WHERE (addresses.country = 'Poland')
SQLite3::SQLException: no such column: addresses.country: SELECT "users".* FROM "users"  WHERE (addresses.country = 'Poland')
ActiveRecord::StatementInvalid: SQLite3::SQLException: no such column: addresses.country: SELECT "users".* FROM "users"  WHERE (addresses.country = 'Poland')



what do you want to achieve?

* Give me all users and their polish addresses.
* Give me users with polish addresses and preload all of their addresses
* Give me users with polish addresses and preload only polish addresses (achieved before)


* Give me users with polish addresses and preload all of their addresses
r = User.joins(:addresses).where("addresses.country = ?", "Poland").preload(:addresses)

* Give me all users and their polish addresses.
r = User.preload(:polish_addresses)
```
