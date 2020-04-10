---
title: "How to persist hashes in Rails applications with PostgreSQL"
created_at: 2014-10-13 10:27:16 +0200
publish: true
author: Kamil Lelonek
newsletter_inside: arkency_form
tags: [ 'Active Record', 'PostgreSQL', 'Hash' ]
---

<p>
  <figure>
    <img src="<%= src_fit("postgres/coffee.png") %>" width="100%">
  </figure>
</p>

Our recent blogpost [about using UUID in Rails projects with PostgreSQL](http://blog.arkency.com/2014/10/how-to-start-using-uuid-in-activerecord-with-postgresql/)
was appreciated so we decided to publish a tutorial about **storing hashes in our favorite database**. Let's see how it can be achieved.

<!-- more -->

Sometimes we may need to not only store plain attributes like `string`, `integer` or `boolean` but also more complex objects. For now **let's talk about hashes**.

## `hstore`

[`HStore`](http://www.postgresql.org/docs/9.4/static/hstore.html) is a key value store within Postgres database. You can use it similar to how you would use a hash in Ruby application, though it's specific to a table column in the database. Sometimes we might need to **combine relational databases' features with flexibility of No-SQL ones** at the same time without having two separate data stores.

If you need to think about possible use cases, please note that hashes in other languages are called *dictionaries*, so it's already a hint how to and why use them.

### SQL
Firstly, let's see how it looks like in plain `SQL`, everything according to official [PostgreSQL documentation](http://www.postgresql.org/docs/9.4/static/hstore.html).

```sql
➜  Dev  psql
psql (9.3.5)
Type "help" for help.

postgres=# CREATE DATABASE hstore_example;
CREATE DATABASE

postgres=# \c hstore_example
You are now connected to database "hstore_example" as user "postgres".

hstore_example=# CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION

hstore_example=# SELECT 'company => arkency, blogpost => hstore'::hstore;
                   hstore
--------------------------------------------
 "company"=>"arkency", "blogpost"=>"hstore"
(1 row)

hstore_example=#
```

Pretty simple. We created example DB, enabled extension and selected some key-value structure as a `hstore`.

### Setup

In [previous blogpost about UUIDs](http://blog.arkency.com/2014/10/how-to-start-using-uuid-in-activerecord-with-postgresql/) we already showed how to enable particular extension. That's what we gonna do again:

```bash
rails g migration enable_hstore_extension
```

```ruby
class EnableHstoreExtension < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
  end
end
```

Let's reuse an existing example:

```bash
rails g migration add_description_to_books
```

```ruby
class AddDescriptionToBooks < ActiveRecord::Migration
  def change
    add_column :books, :description, :hstore, default: {}, null: false
  end
end
```

And now we can play with that:

```ruby
b = Book.create
#   (0.2ms)  BEGIN
#  SQL (0.7ms)  INSERT INTO "books" ("created_at", "updated_at")
#   VALUES ($1, $2)
#   RETURNING "id"  [["created_at", "2014-10-10 10:42:49.968435"], ["updated_at", "2014-10-10 10:42:49.968435"]]
#   (0.9ms)  COMMIT
# => #<Book id: "75fd5620-7a09-4ae1-88b4-935385a4e970", title: nil, created_at: "2014-10-10 10:42:49", updated_at: "2014-10-10 10:42:49", description: {}>

b.description
# => {}

b.description.class
# => Hash

b.description['en'] = 'Eccentric duck'
# => "Eccentric duck"

b.save
#   (0.2ms)  BEGIN
#  SQL (0.4ms)  UPDATE "books" SET "description" = $1, "updated_at" = $2
#   WHERE "books"."id" = '75fd5620-7a09-4ae1-88b4-935385a4e970'
#   [["description", "\"en\"=>\"Eccentric duck\""], ["updated_at", "2014-10-10 10:43:35.869645"]]
#   (0.9ms)  COMMIT
# => true

b = Book.first
#  Book Load (0.8ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
# => #<Book id: "75fd5620-7a09-4ae1-88b4-935385a4e970", title: nil, created_at: "2014-10-10 10:42:49", updated_at: "2014-10-10 10:43:35", description: {"en"=>"Eccentric duck"}>

b.description
# => {"en"=>"Eccentric duck"}

b.description['en']
# => "Eccentric duck"
```

### Awesomeness

The hstore datatype can be indexed with one of two types: [GiST or GIN](http://www.postgresql.org/docs/9.4/static/textsearch-indexes.html).

In choosing which index type to use, GiST or GIN, consider these performance differences:

- GIN index lookups are about three times faster than GiST
- GIN indexes take about three times longer to build than GiST
- GIN indexes are moderately slower to update than GiST indexes, but about 10 times slower if fast-update support was disabled
- GIN indexes are two-to-three times larger than GiST indexes
- GIN indexes are not lossy for standard queries, but their performance depends logarithmically on the number of unique words
- GiST indexes are lossy because each document is represented in the index by a fixed-length signature and it is necessary to check the actual table row to eliminate such false matches.

As a rule of thumb, GIN indexes are best for static data because lookups are faster. For dynamic data, GiST indexes are faster to update. Specifically, GiST indexes are very good for dynamic data and fast if the number of unique words (lexemes) is under 100,000, while GIN indexes will handle 100,000+ lexemes better but are slower to update.

So let's create an another migration:

```bash
rails g migration add_index_for_description_in_books
```

```ruby
class AddIndexForDescriptionInBooks < ActiveRecord::Migration
  def change
    add_index :books, :description, name: 'books_description_idx', using: :gin
    # :gist is default
  end
end
```

I don't have to explain why we should use indexes and why they are important when it comes to querying performance. If you want to use `hstore` selectors, you should definitely create these indexes.

**Here they are:**

Return the value from column `description` for key `en`:

```
"description -> 'en'"
```

Does the specified column `description` contain a key `en`:

```
"description ? 'en'"
```

Does the specified column `description` contain a value of `Eccentric duck` for key `en`:

```
"description @> 'en -> Eccentric duck'"
```

**How to use them:**

Create example book:

```ruby
b = Book.create(description: { en: 'Eccentric duck', pl: 'Kaczka dziwaczka' })
#   (0.1ms)  BEGIN
#  SQL (0.2ms)  INSERT INTO "books" ("created_at", "description", "updated_at") VALUES ($1, $2, $3) RETURNING "id"  [["created_at", "2014-10-10 11:21:02.294080"], ["description", "\"en\"=>\"Eccentric duck\", \"pl\"=>\"Kaczka dziwaczka\""], ["updated_at", "2014-10-10 11:21:02.294080"]]
#   (0.9ms)  COMMIT
# => #<Book id: "3ba701d2-15b9-43c3-88b6-56410b176b36", title: nil, created_at: "2014-10-10 11:21:02", updated_at: "2014-10-10 11:21:02", description: {"en"=>"Eccentric duck", "pl"=>"Kaczka dziwaczka"}>
```

Find a book with particular polish description:

```ruby
Book.where("description -> 'pl' = 'Kaczka dziwaczka'")
#  Book Load (0.5ms)  SELECT "books".* FROM "books" WHERE (description -> 'pl' = 'Kaczka dziwaczka')
# => #<ActiveRecord::Relation [#<Book id: "3ba701d2-15b9-43c3-88b6-56410b176b36", title: nil, created_at: "2014-10-10 11:21:02", updated_at: "2014-10-10 11:21:02", description: {"en"=>"Eccentric duck", "pl"=>"Kaczka dziwaczka"}>]>
```

Find a book containing 'duck' in english description:

```ruby
Book.where("description @> 'en=>duck'")
#  Book Load (0.3ms)  SELECT "books".* FROM "books" WHERE (description @> 'en=>duck')
# => #<ActiveRecord::Relation [#<Book id: "c484009e-a8e1-4534-8127-2032a92f9bc1", title: nil, created_at: "2014-10-10 10:39:58", updated_at: "2014-10-10 10:40:27", description: {"en"=>"duck"}>]>
```

Find all books with english descriptions provided:

```ruby
Book.where("description ? 'en'")
#  Book Load (0.3ms)  SELECT "books".* FROM "books" WHERE (description ? 'en')
# => #<ActiveRecord::Relation [#<Book id: "c484009e-a8e1-4534-8127-2032a92f9bc1", title: nil, created_at: "2014-10-10 10:39:58", updated_at: "2014-10-10 10:40:27", description: {"en"=>"duck"}>, #<Book id: "75fd5620-7a09-4ae1-88b4-935385a4e970", title: nil, created_at: "2014-10-10 10:42:49", updated_at: "2014-10-10 10:54:06", description: {"en"=>"false", "pl"=>"1", "short"=>"{:en=>\"Duck\", :pl=>\"Kaczka\"}"}>, #<Book id: "3ba701d2-15b9-43c3-88b6-56410b176b36", title: nil, created_at: "2014-10-10 11:21:02", updated_at: "2014-10-10 11:21:02", description: {"en"=>"Eccentric duck", "pl"=>"Kaczka dziwaczka"}>]>
```

### Problematic issues

Note the *update* statement stringifies our hash:

```
(...) ["description", "\"en\"=>\"Eccentric duck\""] (...)
```

In that case we may expect:

```ruby
b.description['en'] = false
# => false

b.description['pl'] = 1
# => 1

b.save
#   (0.2ms)  BEGIN
#  SQL (0.3ms)  UPDATE "books" SET "description" = $1, "updated_at" = $2 WHERE "books"."id" = '75fd5620-7a09-4ae1-88b4-935385a4e970'  [["description", "\"en\"=>\"false\", \"pl\"=>\"1\""], ["updated_at", "2014-10-10 10:51:19.683650"]]
#   (0.8ms)  COMMIT
# => true

b = Book.first
#  Book Load (0.3ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
# => #<Book id: "75fd5620-7a09-4ae1-88b4-935385a4e970", title: nil, created_at: "2014-10-10 10:42:49", updated_at: "2014-10-10 10:51:19", description: {"en"=>"false", "pl"=>"1"}>

b.description['pl']
# => "1"

b.description['pl'].class
# => String

b.description['en']
# => "false"

b.description['en'].class
# => String
```

Although it may not be a common case to store other types than `string` in a **dictionary**, it is still worth to have in mind that `hstore` supports only string data.

The more possible case may be storing nested dictionaries:

```bash
b.description['short'] = { en: 'Duck', pl: 'Kaczka' }
# => {:en=>"Duck", :pl=>"Kaczka"}

b.save
#   (0.1ms)  BEGIN
#  SQL (0.2ms)  UPDATE "books" SET "description" = $1, "updated_at" = $2 WHERE "books"."id" = '75fd5620-7a09-4ae1-88b4-935385a4e970'  [["description", "\"en\"=>\"false\", \"pl\"=>\"1\", \"short\"=>\"{:en=>\\\"Duck\\\", :pl=>\\\"Kaczka\\\"}\""], ["updated_at", "2014-10-10 10:54:06.442615"]]
#   (0.9ms)  COMMIT
# => true

b = Book.first
#  Book Load (0.3ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
# => #<Book id: "75fd5620-7a09-4ae1-88b4-935385a4e970", title: nil, created_at: "2014-10-10 10:42:49", updated_at: "2014-10-10 10:54:06", description: {"en"=>"false", "pl"=>"1", "short"=>"{:en=>\"Duck\", :pl=>\"Kaczka\"}"}>

b.description['short']
# => "{:en=>\"Duck\", :pl=>\"Kaczka\"}"

b.description['short'].class
# => String
```

Ough! We have a problem, again. So is there any solution for more complex cases?

## `json`

In addition to `hstore`, `json` is a full document datatype. That means it supports nested objects and more datatypes. It also has more operators that are very well described in [documentation](http://www.postgresql.org/docs/devel/static/functions-json.html). If you are using JSON somewhere in your application already and want to store it directly in database, then the JSON datatype is perfect choice.

### Migration

```bash
rails g migration add_metadata_to_books
```

```ruby
class AddMetadataToBooks < ActiveRecord::Migration
  def change
    add_column :books, :metadata, :json, default: {}, null: false
  end
end
```

**Then do whatever you want:**

```ruby
metadata = { pages: 400, published: false, isbn: SecureRandom.uuid }
# => {:pages=>400, :published=>false, :isbn=>"35280581-7169-48ce-88fa-9e85de5df778"}

Book.create(metadata: metadata)
#   (0.1ms)  BEGIN
#  SQL (1.0ms)  INSERT INTO "books" ("created_at", "metadata", "updated_at") VALUES ($1, $2, $3) RETURNING "id"  [["created_at", "2014-10-10 12:56:42.473753"], ["metadata", "{\"pages\":400,\"published\":false,\"isbn\":\"35280581-7169-48ce-88fa-9e85de5df778\"}"], ["updated_at", "2014-10-10 12:56:42.473753"]]
#   (1.1ms)  COMMIT
# => #<Book id: "00449e9f-4b03-423d-a8a9-4bcce6a92df4", title: nil, created_at: "2014-10-10 12:56:42", updated_at: "2014-10-10 12:56:42", description: {}, metadata: {"pages"=>400, "published"=>false, "isbn"=>"35280581-7169-48ce-88fa-9e85de5df778"}>

b = Book.last;

b.metadata
#  Book Load (0.7ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" DESC LIMIT 1
# => {"pages"=>400, "published"=>false, "isbn"=>"e29d7a86-da0e-4f89-8dcd-f8321a5f9980"}

b.metadata.class
# => Hash

b.metadata['pages'].class
# => Fixnum

b.metadata['published'].class
# => FalseClass
```

**However you should know that when searching for some records, you should stringify search parameters:**

```ruby
Book.where("metadata->>'published' = ?", 'false')
#  Book Load (0.6ms)  SELECT "books".* FROM "books" WHERE (metadata->>'published' = 'false')
# => #<ActiveRecord::Relation [#<Book id: "00449e9f-4b03-423d-a8a9-4bcce6a92df4", title: nil, created_at: "2014-10-10 12:56:42", updated_at: "2014-10-10 12:56:42", description: {}, metadata: {"pages"=>400, "published"=>false, "isbn"=>"35280581-7169-48ce-88fa-9e85de5df778"}>]>
```

```ruby
Book.where("metadata->>'pages' = ?", '400')
```

## MongoDB

I believe you see the **power of using PostgreSQL with ActiveRecord in your Rails projects**. If you still wonder whether *MongoDB* will be better choice for you needs, you should definitely check [`JSONB`](http://www.postgresql.org/message-id/E1WRpmB-0002et-MT@gemulon.postgresql.org) support [introduced in `9.4` version of postgres](http://obartunov.livejournal.com/177247.html), which is real data type with binary storage and indexing, a structured format for storing json.

> With the new JSONB data type for PostgreSQL, users no longer have to choose between relational and non-relational data stores: they can have both at the same time. JSONB supports fast lookups and simple expression search queries using Generalized Inverted Indexes (GIN). Multiple new support functions enables users to extract and manipulate JSON data, with a performance which matches or surpasses the most popular document databases. With JSONB, table data can be easily integrated with document data for a fully integrated database environment.

You can also read [PostgreSQL Outperforms MongoDB in New Round of Tests](http://blogs.enterprisedb.com/2014/09/24/postgres-outperforms-mongodb-and-ushers-in-new-developer-reality/)

## Heroku

If you're heroku user sometimes you may encounter the following error during `rake db:migrate` task:

```bash
No such file or directory - pg_dump -i -s -x -O -f /app/db/structure.sql
```

`pg_dump` command is not present on Heroku's environment, which is not needed in production, but it's nice to have this dumped SQL structure in development. You can get around it by turning of this feature when not needed:

```ruby
Rake::Task['db:structure:dump'].clear unless Rails.env.development?
```

## Summary

I believe after that article you see the benefits of using `store` and `json` types in Rails projects. A lot of flexibility combined with relational database give us almost unlimited room for improving our storage patterns.

<%= show_product_inline(item[:newsletter_inside]) %>

## Resources

- http://www.postgresql.org/docs/9.4/static/hstore.html
- https://alybadawy.com/post/using-postgres-hstore-datatype-with-ruby-on-rails
- http://jes.al/2013/11/using-postgres-hstore-rails4/
- https://blog.engineyard.com/2013/using-postgresql-hstore-in-a-rails-application-on-engine-yard-cloud
- http://edgeguides.rubyonrails.org/active_record_postgresql.html#json

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="<%= src_fit("rbe/rbe-cover.png") %>" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
