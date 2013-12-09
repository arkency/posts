---
title: "Rails 3 & 4 - what you need to know about preloading"
created_at: 2013-12-08 12:05:29 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'rails', 'active record', 'preloading' ]
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

Here goes the content and explanation ...

```
#
User.includes(:addresses)

2.0.0-p247 :018 >   User.includes(:addresses)
  User Load (0.4ms)  SELECT "users".* FROM "users" 
  Address Load (0.5ms)  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)


User.preload(:addresses)

2.0.0-p247 :020 >   User.preload(:addresses)
  User Load (0.4ms)  SELECT "users".* FROM "users" 
  Address Load (0.5ms)  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1, 2)


2.0.0-p247 :021 > User.eager_load(:addresses)
  SQL (0.2ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id"


#~~~

User.includes(:addresses).where("addresses.country = ?", "Poland")
User.eager_load(:addresses).where("addresses.country = ?", "Poland")

2.0.0-p247 :023 >   User.includes(:addresses).where("addresses.country = ?", "Poland")
  SQL (0.6ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id" WHERE (addresses.country = 'Poland')


2.0.0-p247 :025 > User.preload(:addresses).where("addresses.country = ?", "Poland")
  User Load (0.5ms)  SELECT "users".* FROM "users" WHERE (addresses.country = 'Poland')
SQLite3::SQLException: no such column: addresses.country: SELECT "users".* FROM "users"  WHERE (addresses.country = 'Poland')
ActiveRecord::StatementInvalid: SQLite3::SQLException: no such column: addresses.country: SELECT "users".* FROM "users"  WHERE (addresses.country = 'Poland')



A funny thing:

what do you want to achieve?

* Give me all users and their polish addresses.
* Give me users with polish addresses and preload all of their addresses
* Give me users with polish addresses and preload only polish addresses (achieved)


#~~~

Give me users with polish addresses but preload all of their addresses. I need to know all addreeses of people whose at least one address is in Poland.

User.joins(:addresses).where("addresses.country = ?", "Poland").includes(:addresses)

2.0.0-p247 :041 > r[0]
 => #<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24"> 
2.0.0-p247 :042 > r[0].addresses
 => [#<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">] 

This won't work because rails automatically default to the old method.


2.0.0-p247 :047 > r = User.joins(:addresses).where("addresses.country = ?", "Poland").preload(:addresses)
  User Load (0.5ms)  SELECT "users".* FROM "users" INNER JOIN "addresses" ON "addresses"."user_id" = "users"."id" WHERE (addresses.country = 'Poland')
  Address Load (0.4ms)  SELECT "addresses".* FROM "addresses" WHERE "addresses"."user_id" IN (1)
 => [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">] 
2.0.0-p247 :048 > r[0].addresses
 => [#<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">, #<Address id: 3, user_id: 1, country: "France", street: "8 rue Chambiges", postal_code: "75008", city: "Paris", created_at: "2013-12-08 11:36:30", updated_at: "2013-12-08 11:36:30">] 


But this does.

#~~~

Give me all users and their polish addresses.


To be honest, I never like loading only a subset of association. If I need that, I would add the condition to the association itself and load it.

User.preload(:polish_addresses)

2.0.0-p247 :055 > r = User.preload(:polish_addresses)
  User Load (0.4ms)  SELECT "users".* FROM "users" 
  Address Load (0.5ms)  SELECT "addresses".* FROM "addresses" WHERE "addresses"."country" = 'Poland' AND "addresses"."user_id" IN (1, 2)
 => [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">, #<User id: 2, name: "Bob Doe", email: "bob@example.org", created_at: "2013-12-08 11:26:25", updated_at: "2013-12-08 11:26:25">] 
2.0.0-p247 :056 > r[0].polish_addresses
 => [#<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">] 
2.0.0-p247 :057 > r[1].polish_addresses
 => [] 


2.0.0-p247 :060 > r = User.eager_load(:polish_addresses)
  SQL (0.6ms)  SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "users"."email" AS t0_r2, "users"."created_at" AS t0_r3, "users"."updated_at" AS t0_r4, "addresses"."id" AS t1_r0, "addresses"."user_id" AS t1_r1, "addresses"."country" AS t1_r2, "addresses"."street" AS t1_r3, "addresses"."postal_code" AS t1_r4, "addresses"."city" AS t1_r5, "addresses"."created_at" AS t1_r6, "addresses"."updated_at" AS t1_r7 FROM "users" LEFT OUTER JOIN "addresses" ON "addresses"."user_id" = "users"."id" AND "addresses"."country" = 'Poland'
 => [#<User id: 1, name: "Robert Pankowecki", email: "robert@example.org", created_at: "2013-12-08 11:26:24", updated_at: "2013-12-08 11:26:24">, #<User id: 2, name: "Bob Doe", email: "bob@example.org", created_at: "2013-12-08 11:26:25", updated_at: "2013-12-08 11:26:25">] 
2.0.0-p247 :061 > r[0].polish_addresses
 => [#<Address id: 1, user_id: 1, country: "Poland", street: "Rynek", postal_code: "55-555", city: "Wrocław", created_at: "2013-12-08 11:26:50", updated_at: "2013-12-08 11:26:50">] 
2.0.0-p247 :062 > r[1].polish_addresses
 => [] 


#~~~




















Rails 4

class User < ActiveRecord::Base
  has_many :addresses
  has_many :polish_addresses, -> {where(country: "Poland")}, class_name: "Address"
  #attr_protected
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
