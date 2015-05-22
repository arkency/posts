---
title: "3 ways to do eager loading (preloading) in Rails&nbsp;3&nbsp;&&nbsp;4"
created_at: 2013-12-08 12:05:29 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :skip
newsletter_inside: :react_book
img: "/assets/images/preloading/header-fit.png"
tags: [ 'rails', 'active record', 'preloading', 'eager_loading' ]
---

<img src="/assets/images/preloading/header-fit.png" width="100%">

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

<%= inner_newsletter(item[:newsletter_inside]) %>

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

## Don't miss our next blog post

If you enjoyed the article, 
[follow us on Twitter](https://twitter.com/arkency)
[and Facebook](https://www.facebook.com/pages/Arkency/107636559305814), 
or subscribe to our [newsletter](http://arkency.us5.list-manage1.com/subscribe?u=1bb42b52984bfa86e2ce35215&amp;id=4cee302d8a&group[15297]=1)

Also you might wanna check out our
[_Fearless refactoring: Rails controllers_ book](http://rails-refactoring.com/).
