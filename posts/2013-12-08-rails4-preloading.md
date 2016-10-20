---
title: "3 ways to do eager loading (preloading) in Rails&nbsp;3&nbsp;&&nbsp;4"
created_at: 2013-12-08 12:05:29 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :skip
newsletter_inside: :react_books
img: "preloading/header.png"
tags: [ 'rails', 'active record', 'preloading', 'eager_loading' ]
---

<%= img_fit("preloading/header.png") %>

You are probably already familiar with the method `#includes` for eager loading
data from database if you are using Rails and ActiveRecord.
But do you know why you someties get few small and nice SQL queries and sometimes
one giant query with every table and column renamed? And do you know
about `#preload` and `#eager_load` which can help you achieve the same goal?
Are you aware of what changed in Rails 4 in that matter? If not, sit down and
listen. This lesson won't take long and will help you clarify some aspects
of eager loading that you might not be yet familiar with.

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
Keep reading to find out.

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
for you which way it is going to be. You let Rails handle that decision.
What is the decision based on, you might ask. It is based on query conditions.
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

In the last example Rails detected that the condition in `where` clause
is using columns from preloaded (included) table names. So `#includes` delegates
the job to `#eager_load`. You can always achieve the same result by using the
`#eager_load` method directly.


What happens if you instead try to use `#preload` explicitly?

```
#!ruby
User.preload(:addresses).where("addresses.country = ?", "Poland")
#  SELECT "users".* FROM "users" WHERE (addresses.country = 'Poland')
#
#  SQLite3::SQLException: no such column: addresses.country
```

We get an exception because we haven't joined `users` table with
`addresses` table in any way.

## Is this intention revealing?

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

We know that we need only users with polish addresses. That itself is easy:
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
We are missing the user's second address that expected to have this time.
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
# SELECT "users".* FROM "users"
# INNER JOIN "addresses" ON "addresses"."user_id" = "users"."id"
# WHERE (addresses.country = 'Poland')

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

I prefer to add the condition to the association itself:

```
#!ruby
class User < ActiveRecord::Base
  has_many :addresses
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
that we would like to apply? I honestly don't know. Please tell me in the
comments if you found it out.

## The ultimate question

You might ask: _What is this stuff so hard?_ I am not sure but I think most ORMs
are build to help you construct single query and load data from one table. With
eager loading the situation gest more complicated and we want load multiple data
from multiple tables with multiple conditions. In Rails we are using chainable API
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

I hope you get the idea :) But this is just a dream. Let's get back to reality...

<%= show_product(item[:newsletter_inside]) %>

## Rails 4 changes

... and talk about what changed in Rails 4.

```
#!ruby
class User < ActiveRecord::Base
  has_many :addresses
  has_many :polish_addresses, -> {where(country: "Poland")}, class_name: "Address"
end
```

Rails now encourages you to use the new lambda syntax for defining association
conditions. This is very good because I have seen many times errors in that
area where the condition were interpreted only once when the class was loaded.

It is the same way you are encouraged to use lambda syntax or method syntax to
express scope conditions.

```
#!ruby
# Bad, Time.now would be always the time when the class was loaded
# You might not even spot the bug in development because classes are
# automatically reloaded for you after changes.
scope :from_the_past, where("happens_at <= ?", Time.now)

# OK
scope :from_the_past, -> { where("happens_at <= ?", Time.now) }

# OK
def self.from_the_past
  where("happens_at <= ?", Time.now)
end
```

In our case the condition `where(country: "Poland")` is always the same, no matter wheter interpreted
dynamically or once at the beginning. But it is good that rails is trying to
make the syntax coherent in both cases (association and scope conditions)
and protect us from the such kind of bugs.

Now that we have the syntax changes in place, we can check for any differences
in the behavior.

```
#!ruby
User.includes(:addresses)
#  SELECT "users".* FROM "users"
#  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)

User.preload(:addresses)
#  SELECT "users".* FROM "users"
#  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)

User.eager_load(:addresses)
#  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4,
#         "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7
#  FROM "users"
#  LEFT OUTER JOIN "addresses"
#  ON "addresses"."user_id" = "users"."id"
```

Well, this looks pretty much the same. No surprise here.
Let's add the condition that caused us so much trouble before:

```
#!ruby
User.includes(:addresses).where("addresses.country = ?", "Poland")

#DEPRECATION WARNING: It looks like you are eager loading table(s)
# (one of: users, addresses) that are referenced in a string SQL
# snippet. For example:
#
#    Post.includes(:comments).where("comments.title = 'foo'")
#
# Currently, Active Record recognizes the table in the string, and knows
# to JOIN the comments table to the query, rather than loading comments
# in a separate query. However, doing this without writing a full-blown
# SQL parser is inherently flawed. Since we don't want to write an SQL
# parser, we are removing this functionality. From now on, you must explicitly
# tell Active Record when you are referencing a table from a string:
#
#   Post.includes(:comments).where("comments.title = 'foo'").references(:comments)
#
# If you don't rely on implicit join references you can disable the
# feature entirely by setting `config.active_record.disable_implicit_join_references = true`. (

# SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4,
#        "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7
# FROM "users"
# LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id"
# WHERE (addresses.country = 'Poland')
```

Wow, now that is quite a verbose deprection :) I recommend that you read
it all because it explains the situation quite accuratelly.

In other words, because Rails does not want to be super smart anymore and
spy on our `where` conditions to detect which algorithm to use, it expects
our help. We must tell it that there is condition for one of the tables.
Like that:

```
#!ruby
User.includes(:addresses).where("addresses.country = ?", "Poland").references(:addresses)
```

I was wondering what would happen if we try to preload more tables but
reference only one of them:

```
#!ruby
User.includes(:addresses, :places).where("addresses.country = ?", "Poland").references(:addresses)

#  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4,
#         "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7,
#         "places"."id" AS t2_r0, "places"."user_id" AS t2_r1, "places"."name" AS t2_r2, "places"."created_at" AS t2_r3, "places"."updated_at" AS t2_r4
#  FROM "users"
#  LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id"
#  LEFT OUTER JOIN "places" ON "places"."user_id" = "users"."id"
#  WHERE (addresses.country = 'Poland')
```

I imagined that `addresses` would be loaded using the `#eager_load`
algorithm (by doing `LEFT JOIN`) and `places` would be loaded using
the `#preload` algorithm (by doing separate query to get them) but
as you can see that's not the case. Maybe they will change the
behavior in the future.

Rails 4 does not warn you to use the `#references` method if you
explicitely use `#eager_load` to get the data and the executed
query is identical:

```
#!ruby
User.eager_load(:addresses).where("addresses.country = ?", "Poland")
```

In other words, these two are the same:

```
#!ruby
User.includes(:addresses).where("addresses.country = ?", "Poland").references(:addresses)
User.eager_load(:addresses).where("addresses.country = ?", "Poland")
```

And if you try to use `#preload`, you still get the same exception:

```
#!ruby
User.preload(:addresses).where("addresses.country = ?", "Poland")
#  SELECT "users".* FROM "users" WHERE (addresses.country = 'Poland')
#
#  SQLite3::SQLException: no such column: addresses.country: SELECT "users".* FROM "users"  WHERE (addresses.country = 'Poland')
```

If you try to use the other queries that I showed you, they still work
the same way in Rails 4:

```
#!ruby
# Give me users with polish addresses and preload all of their addresses
User.joins(:addresses).where("addresses.country = ?", "Poland").preload(:addresses)

#Give me all users and their polish addresses.
User.preload(:polish_addresses)
```

Finally in Rails 4 there is at least some documentation for the methods,
which Rails 3 has been missing for years:

* [`#includes`](http://api.rubyonrails.org/v4.0.1/classes/ActiveRecord/QueryMethods.html#method-i-includes)
* [`#preload`](http://api.rubyonrails.org/v4.0.1/classes/ActiveRecord/QueryMethods.html#method-i-preload)
* [`#eager_load`](http://api.rubyonrails.org/v4.0.1/classes/ActiveRecord/QueryMethods.html#method-i-eager_load)

## Summary

There are 3 ways to do eager loading in Rails:

* `#includes`
* `#preload`
* `#eager_load`

`#includes` delegates the job to `#preload` or `#eager_load` depending on the
presence or absence of condition related to one of the preloaded table.

`#preload` is using separate DB queries to get the data.

`#eager_load` is using one big query with `LEFT JOIN` for each eager loaded
table.

In Rails 4 you should use `#references` combined with `#includes` if you
have the additional condition for one of the eager loaded table.

## Follow the author on Snapchat

<svg xmlns="http://www.w3.org/2000/svg" height="320" version="1.1" viewBox="0 0 320 320" width="320">
  <path d="M162.23,56.5c8.45,0,17.01,1.84,24.71,5.29c12.76,5.72,23.18,16.52,28.34,29.56c2.95,7.47,3.04,16.06,2.97,23.97c-0.04,4.56-0.25,9.13-0.52,13.68c-0.13,2.29-0.28,4.58-0.42,6.87c-0.08,1.26-0.16,2.51-0.23,3.77c-0.05,0.81-0.33,1.9-0.15,2.7c0.39,1.75,3.17,2.92,4.71,3.41c4.05,1.28,8.29,0.35,12.19-1.03c2.33-0.83,4.42-2.21,6.97-1.98c1.85,0.17,3.99,0.99,5.3,2.33c1.38,1.41,1.09,2.79-0.1,4.14c-2.26,2.56-5.98,4.02-9.13,5.05c-3.45,1.14-6.95,2.14-10.17,3.87c-3.17,1.7-6.09,4.15-7.34,7.63c-1.45,4.04-0.24,8.16,1.47,11.9c2.9,6.36,6.68,12.32,11.08,17.74c8.24,10.14,19.02,18.37,31.66,22.13c1.86,0.55,3.74,1.01,5.64,1.36c0.81,0.15,1.33-0.03,1.04,0.82c-0.04,0.11-0.11,0.21-0.17,0.31c-0.42,0.71-1.11,1.27-1.77,1.75c-3.72,2.72-8.63,3.98-13.03,5.06c-2.08,0.51-4.18,0.95-6.29,1.35c-2.09,0.39-4.64,0.4-6.6,1.25c-3.27,1.42-3.75,6.29-4.42,9.29c-0.26,1.17-0.53,2.35-0.84,3.51c-0.28,1.03-0.19,1.56-1.29,1.58c-1.89,0.03-3.79-0.47-5.63-0.81c-4.34-0.8-8.74-1.23-13.16-1.12c-4.82,0.12-9.75,0.67-14.24,2.54c-4.29,1.79-8.13,4.48-11.91,7.15c-6.6,4.66-13.31,9.28-21.33,11.06c-4.02,0.89-8.18,0.98-12.28,0.85c-4.37-0.14-8.68-1.05-12.74-2.68c-7.74-3.11-14.04-8.6-21.02-13c-3.97-2.5-8.19-4.48-12.85-5.21c-4.95-0.78-9.98-0.93-14.96-0.4c-1.93,0.21-3.85,0.51-5.76,0.87c-1.87,0.35-3.9,1.01-5.81,0.94c-0.9-0.04-0.91-0.31-1.15-1.16c-0.35-1.26-0.64-2.53-0.93-3.81c-0.43-1.95-0.8-3.95-1.5-5.83c-0.55-1.47-1.36-2.96-2.83-3.67c-1.88-0.91-4.46-0.89-6.5-1.27c-3.81-0.71-7.6-1.56-11.3-2.72c-3.18-1-7-2.22-9.39-4.7c-0.23-0.24-0.45-0.48-0.62-0.77c-0.06-0.09-0.13-0.19-0.17-0.29c-0.26-0.8,0.05-0.69,0.83-0.83c3.68-0.67,7.28-1.72,10.75-3.11c6.35-2.55,12.19-6.25,17.37-10.71c7.59-6.55,13.87-14.7,18.55-23.55c1.6-3.02,3.32-6.33,3.86-9.71c1.36-8.48-5.62-13.28-12.66-15.84c-3.74-1.36-7.59-2.29-11.08-4.27c-1.59-0.9-4.68-2.71-4.44-4.96c0.18-1.71,2.3-2.87,3.72-3.4c0.96-0.36,2.01-0.59,3.04-0.54c1.24,0.07,2.3,0.72,3.43,1.19c4.11,1.68,8.71,2.89,13.17,2.19c2.23-0.35,4.54-1.19,6.15-2.84c0.39-0.4,0.53-0.56,0.62-1.04c0.16-0.89-0.11-2.07-0.17-2.96c-0.14-2.37-0.29-4.74-0.44-7.11c-0.56-9.03-1.1-18.14-0.43-27.18c0.29-3.88,0.79-7.79,1.93-11.52c1.12-3.71,3.01-7.22,5.03-10.51c3.72-6.06,8.56-11.41,14.31-15.6c8.44-6.14,18.63-9.66,28.99-10.65C155.59,56.49,158.92,56.5,162.23,56.5M0,268.8C0,297.07,22.93,320,51.2,320L268.8,320C297.07,320,320,297.07,320,268.8L320,51.2C320,22.93,297.07,0,268.8,0L51.2,0C22.93,0,0,22.93,0,51.2L0,268.8" fill="#000000"></path>
  <path d="M6,51.2C6,26.24,26.24,6,51.2,6L268.8,6C293.76,6,314,26.24,314,51.2L314,268.8C314,293.76,293.76,314,268.8,314L51.2,314C26.24,314,6,293.76,6,268.8L6,51.2M162.23,51.72c-7.65,0.03-15.07,0.5-22.48,2.6c-11.81,3.35-22.46,10.08-30.2,19.66c-4.8,5.93-8.97,12.99-10.76,20.45c-2,8.32-1.98,17.09-1.72,25.59c0.14,4.49,0.4,8.98,0.68,13.46c0.07,1.08,0.14,2.16,0.21,3.25c0.05,0.73,0.58,3.49,0.14,3.98c-0.91,1.03-3.79,0.96-4.96,0.91c-2.1-0.08-4.18-0.58-6.16-1.25c-2.17-0.74-4.21-2.05-6.52-2.27c-3.62-0.35-7.62,1.15-10.12,3.79c-4.24,4.49-1.55,9.79,2.83,12.83c3.54,2.46,7.58,3.74,11.63,5.07c3.35,1.1,7.03,2.37,9.59,4.91c3.73,3.7,1.64,8.58-0.33,12.62c-1.53,3.15-3.33,6.18-5.28,9.09c-6.65,9.9-15.53,18.6-26.4,23.73c-3.27,1.54-6.71,2.75-10.23,3.58c-1.73,0.41-3.84,0.43-5.32,1.48c-1.62,1.14-2.29,3.12-1.9,5.03c0.97,4.87,6.81,7.41,10.93,8.94c3.64,1.35,7.41,2.31,11.2,3.11c2.31,0.49,4.63,0.91,6.96,1.29c1.14,0.19,1.66,0.11,2.07,1.21c0.32,0.85,0.53,1.74,0.74,2.63c0.52,2.17,0.93,4.36,1.53,6.52c0.39,1.41,0.9,2.76,2.09,3.69c3.08,2.42,7.96,0.55,11.38-0.06c9.15-1.62,19.11-1.57,27.34,3.17c7.15,4.11,13.33,9.69,20.81,13.26c7.96,3.81,16.76,4.9,25.5,4.09c8.19-0.76,15.6-4.12,22.39-8.61c7.42-4.9,14.25-11.11,23.37-12.35c4.97-0.67,10-0.63,14.96,0.06c3.44,0.48,7.01,1.68,10.51,1.37c4.74-0.41,5.24-5.58,6.06-9.31c0.33-1.5,0.48-3.75,1.38-5.04c0.53-0.76,2.02-0.68,2.92-0.83c1.27-0.22,2.54-0.45,3.81-0.69c6.64-1.3,14-2.82,19.71-6.68c1.65-1.11,3.23-2.54,4.05-4.39c0.77-1.74,0.8-3.77-0.37-5.35c-1.22-1.65-2.99-1.84-4.86-2.21c-6.96-1.4-13.55-4.29-19.4-8.28c-8.98-6.12-16.26-14.63-21.68-24c-1.13-1.95-2.16-3.95-3.1-6c-1.45-3.16-2.76-6.9-0.5-10.03c2.08-2.88,5.83-4.33,9.06-5.46c3.97-1.4,7.98-2.48,11.64-4.64c2.67-1.58,5.47-3.81,6.23-6.97c2-8.31-9.87-12.52-16.05-9.86c-3.81,1.64-8.44,3.74-12.65,2.35c-0.27-0.09-0.75-0.18-0.95-0.38c-0.34-0.35-0.16-0.9-0.13-1.44c0.07-1.22,0.15-2.43,0.22-3.65c0.12-1.88,0.24-3.76,0.35-5.64c0.53-8.89,0.95-17.87,0.14-26.76c-0.36-3.95-0.96-7.92-2.17-11.7c-1.18-3.69-3.03-7.21-5.02-10.52c-3.71-6.18-8.46-11.71-14.13-16.17c-8.53-6.71-18.89-10.83-29.59-12.43C168.56,51.98,165.39,51.72,162.23,51.72M69.03,14.27A5.13,5.13,0,0,0,69.03,24.53A5.13,5.13,0,0,0,69.03,14.27M102.11,14.27A5.13,5.13,0,0,0,102.11,24.53A5.13,5.13,0,0,0,102.11,14.27M217.89,14.27A5.13,5.13,0,0,0,217.89,24.53A5.13,5.13,0,0,0,217.89,14.27M118.65,30.81A5.13,5.13,0,0,0,118.65,41.07A5.13,5.13,0,0,0,118.65,30.81M135.19,30.81A5.13,5.13,0,0,0,135.19,41.07A5.13,5.13,0,0,0,135.19,30.81M151.73,30.81A5.13,5.13,0,0,0,151.73,41.07A5.13,5.13,0,0,0,151.73,30.81M234.43,30.81A5.13,5.13,0,0,0,234.43,41.07A5.13,5.13,0,0,0,234.43,30.81M250.97,30.81A5.13,5.13,0,0,0,250.97,41.07A5.13,5.13,0,0,0,250.97,30.81M267.51,30.81A5.13,5.13,0,0,0,267.51,41.07A5.13,5.13,0,0,0,267.51,30.81M52.49,47.36A5.13,5.13,0,0,0,52.49,57.62A5.13,5.13,0,0,0,52.49,47.36M69.03,47.36A5.13,5.13,0,0,0,69.03,57.62A5.13,5.13,0,0,0,69.03,47.36M217.89,47.36A5.13,5.13,0,0,0,217.89,57.62A5.13,5.13,0,0,0,217.89,47.36M250.97,47.36A5.13,5.13,0,0,0,250.97,57.62A5.13,5.13,0,0,0,250.97,47.36M267.51,47.36A5.13,5.13,0,0,0,267.51,57.62A5.13,5.13,0,0,0,267.51,47.36M19.4,63.9A5.13,5.13,0,0,0,19.4,74.16A5.13,5.13,0,0,0,19.4,63.9M35.94,63.9A5.13,5.13,0,0,0,35.94,74.16A5.13,5.13,0,0,0,35.94,63.9M85.57,63.9A5.13,5.13,0,0,0,85.57,74.16A5.13,5.13,0,0,0,85.57,63.9M234.43,63.9A5.13,5.13,0,0,0,234.43,74.16A5.13,5.13,0,0,0,234.43,63.9M267.51,63.9A5.13,5.13,0,0,0,267.51,74.16A5.13,5.13,0,0,0,267.51,63.9M300.6,63.9A5.13,5.13,0,0,0,300.6,74.16A5.13,5.13,0,0,0,300.6,63.9M52.49,80.44A5.13,5.13,0,0,0,52.49,90.7A5.13,5.13,0,0,0,52.49,80.44M300.6,80.44A5.13,5.13,0,0,0,300.6,90.7A5.13,5.13,0,0,0,300.6,80.44M19.4,96.98A5.13,5.13,0,0,0,19.4,107.24A5.13,5.13,0,0,0,19.4,96.98M85.57,96.98A5.13,5.13,0,0,0,85.57,107.24A5.13,5.13,0,0,0,85.57,96.98M234.43,96.98A5.13,5.13,0,0,0,234.43,107.24A5.13,5.13,0,0,0,234.43,96.98M300.6,96.98A5.13,5.13,0,0,0,300.6,107.24A5.13,5.13,0,0,0,300.6,96.98M19.4,113.52A5.13,5.13,0,0,0,19.4,123.78A5.13,5.13,0,0,0,19.4,113.52M69.03,113.52A5.13,5.13,0,0,0,69.03,123.78A5.13,5.13,0,0,0,69.03,113.52M250.97,113.52A5.13,5.13,0,0,0,250.97,123.78A5.13,5.13,0,0,0,250.97,113.52M300.6,113.52A5.13,5.13,0,0,0,300.6,123.78A5.13,5.13,0,0,0,300.6,113.52M284.06,130.06A5.13,5.13,0,0,0,284.06,140.32A5.13,5.13,0,0,0,284.06,130.06M300.6,130.06A5.13,5.13,0,0,0,300.6,140.32A5.13,5.13,0,0,0,300.6,130.06M52.49,146.6A5.13,5.13,0,0,0,52.49,156.86A5.13,5.13,0,0,0,52.49,146.6M284.06,146.6A5.13,5.13,0,0,0,284.06,156.86A5.13,5.13,0,0,0,284.06,146.6M19.4,163.14A5.13,5.13,0,0,0,19.4,173.4A5.13,5.13,0,0,0,19.4,163.14M69.03,163.14A5.13,5.13,0,0,0,69.03,173.4A5.13,5.13,0,0,0,69.03,163.14M250.97,163.14A5.13,5.13,0,0,0,250.97,173.4A5.13,5.13,0,0,0,250.97,163.14M267.51,163.14A5.13,5.13,0,0,0,267.51,173.4A5.13,5.13,0,0,0,267.51,163.14M19.4,179.68A5.13,5.13,0,0,0,19.4,189.94A5.13,5.13,0,0,0,19.4,179.68M35.94,179.68A5.13,5.13,0,0,0,35.94,189.94A5.13,5.13,0,0,0,35.94,179.68M52.49,179.68A5.13,5.13,0,0,0,52.49,189.94A5.13,5.13,0,0,0,52.49,179.68M69.03,179.68A5.13,5.13,0,0,0,69.03,189.94A5.13,5.13,0,0,0,69.03,179.68M19.4,196.22A5.13,5.13,0,0,0,19.4,206.48A5.13,5.13,0,0,0,19.4,196.22M52.49,196.22A5.13,5.13,0,0,0,52.49,206.48A5.13,5.13,0,0,0,52.49,196.22M267.51,196.22A5.13,5.13,0,0,0,267.51,206.48A5.13,5.13,0,0,0,267.51,196.22M284.06,196.22A5.13,5.13,0,0,0,284.06,206.48A5.13,5.13,0,0,0,284.06,196.22M19.4,212.76A5.13,5.13,0,0,0,19.4,223.02A5.13,5.13,0,0,0,19.4,212.76M284.06,212.76A5.13,5.13,0,0,0,284.06,223.02A5.13,5.13,0,0,0,284.06,212.76M19.4,229.3A5.13,5.13,0,0,0,19.4,239.56A5.13,5.13,0,0,0,19.4,229.3M52.49,245.84A5.13,5.13,0,0,0,52.49,256.1A5.13,5.13,0,0,0,52.49,245.84M69.03,245.84A5.13,5.13,0,0,0,69.03,256.1A5.13,5.13,0,0,0,69.03,245.84M300.6,245.84A5.13,5.13,0,0,0,300.6,256.1A5.13,5.13,0,0,0,300.6,245.84M35.94,262.38A5.13,5.13,0,0,0,35.94,272.64A5.13,5.13,0,0,0,35.94,262.38M52.49,262.38A5.13,5.13,0,0,0,52.49,272.64A5.13,5.13,0,0,0,52.49,262.38M201.35,262.38A5.13,5.13,0,0,0,201.35,272.64A5.13,5.13,0,0,0,201.35,262.38M234.43,262.38A5.13,5.13,0,0,0,234.43,272.64A5.13,5.13,0,0,0,234.43,262.38M250.97,262.38A5.13,5.13,0,0,0,250.97,272.64A5.13,5.13,0,0,0,250.97,262.38M267.51,262.38A5.13,5.13,0,0,0,267.51,272.64A5.13,5.13,0,0,0,267.51,262.38M284.06,262.38A5.13,5.13,0,0,0,284.06,272.64A5.13,5.13,0,0,0,284.06,262.38M35.94,278.93A5.13,5.13,0,0,0,35.94,289.19A5.13,5.13,0,0,0,35.94,278.93M52.49,278.93A5.13,5.13,0,0,0,52.49,289.19A5.13,5.13,0,0,0,52.49,278.93M85.57,278.93A5.13,5.13,0,0,0,85.57,289.19A5.13,5.13,0,0,0,85.57,278.93M102.11,278.93A5.13,5.13,0,0,0,102.11,289.19A5.13,5.13,0,0,0,102.11,278.93M118.65,278.93A5.13,5.13,0,0,0,118.65,289.19A5.13,5.13,0,0,0,118.65,278.93M217.89,278.93A5.13,5.13,0,0,0,217.89,289.19A5.13,5.13,0,0,0,217.89,278.93M234.43,278.93A5.13,5.13,0,0,0,234.43,289.19A5.13,5.13,0,0,0,234.43,278.93M102.11,295.47A5.13,5.13,0,0,0,102.11,305.73A5.13,5.13,0,0,0,102.11,295.47M135.19,295.47A5.13,5.13,0,0,0,135.19,305.73A5.13,5.13,0,0,0,135.19,295.47M168.27,295.47A5.13,5.13,0,0,0,168.27,305.73A5.13,5.13,0,0,0,168.27,295.47M201.35,295.47A5.13,5.13,0,0,0,201.35,305.73A5.13,5.13,0,0,0,201.35,295.47M234.43,295.47A5.13,5.13,0,0,0,234.43,305.73A5.13,5.13,0,0,0,234.43,295.47M250.97,295.47A5.13,5.13,0,0,0,250.97,305.73A5.13,5.13,0,0,0,250.97,295.47" fill="#FFFC00"></path>
  <path d="M162.23,56.5c8.45,0,17.01,1.84,24.71,5.29c12.76,5.72,23.18,16.52,28.34,29.56c2.95,7.47,3.04,16.06,2.97,23.97c-0.04,4.56-0.25,9.13-0.52,13.68c-0.13,2.29-0.28,4.58-0.42,6.87c-0.08,1.26-0.16,2.51-0.23,3.77c-0.05,0.81-0.33,1.9-0.15,2.7c0.39,1.75,3.17,2.92,4.71,3.41c4.05,1.28,8.29,0.35,12.19-1.03c2.33-0.83,4.42-2.21,6.97-1.98c1.85,0.17,3.99,0.99,5.3,2.33c1.38,1.41,1.09,2.79-0.1,4.14c-2.26,2.56-5.98,4.02-9.13,5.05c-3.45,1.14-6.95,2.14-10.17,3.87c-3.17,1.7-6.09,4.15-7.34,7.63c-1.45,4.04-0.24,8.16,1.47,11.9c2.9,6.36,6.68,12.32,11.08,17.74c8.24,10.14,19.02,18.37,31.66,22.13c1.86,0.55,3.74,1.01,5.64,1.36c0.81,0.15,1.33-0.03,1.04,0.82c-0.04,0.11-0.11,0.21-0.17,0.31c-0.42,0.71-1.11,1.27-1.77,1.75c-3.72,2.72-8.63,3.98-13.03,5.06c-2.08,0.51-4.18,0.95-6.29,1.35c-2.09,0.39-4.64,0.4-6.6,1.25c-3.27,1.42-3.75,6.29-4.42,9.29c-0.26,1.17-0.53,2.35-0.84,3.51c-0.28,1.03-0.19,1.56-1.29,1.58c-1.89,0.03-3.79-0.47-5.63-0.81c-4.34-0.8-8.74-1.23-13.16-1.12c-4.82,0.12-9.75,0.67-14.24,2.54c-4.29,1.79-8.13,4.48-11.91,7.15c-6.6,4.66-13.31,9.28-21.33,11.06c-4.02,0.89-8.18,0.98-12.28,0.85c-4.37-0.14-8.68-1.05-12.74-2.68c-7.74-3.11-14.04-8.6-21.02-13c-3.97-2.5-8.19-4.48-12.85-5.21c-4.95-0.78-9.98-0.93-14.96-0.4c-1.93,0.21-3.85,0.51-5.76,0.87c-1.87,0.35-3.9,1.01-5.81,0.94c-0.9-0.04-0.91-0.31-1.15-1.16c-0.35-1.26-0.64-2.53-0.93-3.81c-0.43-1.95-0.8-3.95-1.5-5.83c-0.55-1.47-1.36-2.96-2.83-3.67c-1.88-0.91-4.46-0.89-6.5-1.27c-3.81-0.71-7.6-1.56-11.3-2.72c-3.18-1-7-2.22-9.39-4.7c-0.23-0.24-0.45-0.48-0.62-0.77c-0.06-0.09-0.13-0.19-0.17-0.29c-0.26-0.8,0.05-0.69,0.83-0.83c3.68-0.67,7.28-1.72,10.75-3.11c6.35-2.55,12.19-6.25,17.37-10.71c7.59-6.55,13.87-14.7,18.55-23.55c1.6-3.02,3.32-6.33,3.86-9.71c1.36-8.48-5.62-13.28-12.66-15.84c-3.74-1.36-7.59-2.29-11.08-4.27c-1.59-0.9-4.68-2.71-4.44-4.96c0.18-1.71,2.3-2.87,3.72-3.4c0.96-0.36,2.01-0.59,3.04-0.54c1.24,0.07,2.3,0.72,3.43,1.19c4.11,1.68,8.71,2.89,13.17,2.19c2.23-0.35,4.54-1.19,6.15-2.84c0.39-0.4,0.53-0.56,0.62-1.04c0.16-0.89-0.11-2.07-0.17-2.96c-0.14-2.37-0.29-4.74-0.44-7.11c-0.56-9.03-1.1-18.14-0.43-27.18c0.29-3.88,0.79-7.79,1.93-11.52c1.12-3.71,3.01-7.22,5.03-10.51c3.72-6.06,8.56-11.41,14.31-15.6c8.44-6.14,18.63-9.66,28.99-10.65C155.59,56.49,158.92,56.5,162.23,56.5" fill="#FFFFFF"></path>
</svg>

## More

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
