---
title: "How to start using UUID in ActiveRecord with PostgreSQL"
created_at: 2014-10-02 23:58:11 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :skip
newsletter_inside: :arkency_form
tags: [ 'ActiveRecord', 'PostgreSQL', 'Postgres', 'AR', 'UUID' ]
---

<p>
  <figure>
    <img src="<%= src_fit("postgres/elephant.jpg") %>" width="100%">
    <details>
        Author of photo: <a href="https://www.flickr.com/photos/christianhaugen/">Christian Haugen</a>.
    </details>
  </figure>
</p>

Although it may be obvious for many developers, there are still some that are not aware of **great features that PostgreSQL allows to use with ActiveRecord**. This tutorial is intended to reveal UUID type, which we can use **in our Rails applications, especially as models' attributes**.

<!-- more -->

Special Postgre's data types are available in our databases by enabling so called *extensions*. According to the [documentation](http://www.postgresql.org/docs/9.4/static/extend-how.html):

- PostgreSQL is extensible because its operation is catalog-driven.
- The catalogs appear to the user as tables like any other.
- PostgreSQL stores much more information in its catalogs like data types, functions and access methods.
- These tables can be extended by the user.
- Traditional database systems can only be extended by changing source code or by loading modules written by the DBMS vendor.

So not only we get a possibility to create our own extensions, but we get a bunch of useful features out of the box as well. Let's see one of them in action right now.

## Setup

You can follow all of presented steps with your brand new Rails application. To create one, for the purpose of this tutorial, you can run:

```
#!bash
rails new -T -J -V -S postgres-extensions --database postgresql
```

We skipped some tests, javascripts, views and sprockets and set our database to PostgreSQL.

## `UUID`
Personally I think that [UUID](http://www.postgresql.org/docs/9.4/static/uuid-ossp.html) is extremely interesting topic to discuss and [Andrzej](https://twitter.com/andrzejkrzywda) has already written [an excellent article](http://andrzejonsoftware.blogspot.com/2013/12/decentralise-id-generation.html) about using this feature.

This is 16-octet / 128 bit type compatible with most common GUID and UUID generators, supporting distributed application design, defined by [RFC 4122, ISO/IEC 9834-8:2005](http://tools.ietf.org/html/rfc4122). It is represented by 32 lowercase hexadecimal digits, displayed in five groups separated by hyphens, in the form 8-4-4-4-12 for a total of 36 characters (32 alphanumeric characters and four hyphens).

### Versions

Although UUID might appear in different versions (MAC address, DCE security, MD5 or SHA-1 hash), [the most generators](http://en.wikipedia.org/wiki/Universally_unique_identifier#Implementations) relies on random numbers and produces UUID version 4.

> Version 4 UUIDs have the form xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx where x is any hexadecimal digit and y is one of 8, 9, A, or B.

So the validation regexp may be as follows:

```
#!ruby
/[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
```

### Ruby stdlib

How can we produce it in Ruby?

```
#!ruby
[1] (pry) main: 0> require 'securerandom'
true

[2] (pry) main: 0> SecureRandom.uuid
"624f6dd0-91f2-4026-a684-01924da4be84"
```

It's available since `Ruby 1.9` and provides UUID version 4 described above, which is derived entirely from random numbers.

### Psql

How to use it in SQL code?

```
#!bash
postgres=# CREATE EXTENSION "uuid-ossp";

CREATE EXTENSION
postgres=# SELECT uuid_generate_v4();
           uuid_generate_v4
--------------------------------------
 f8c9ffd6-a234-4729-bd2a-68379df315fb
(1 row)
```

The uuid-ossp module provides functions to generate universally unique identifiers (UUIDs) using one of several standard algorithms. There are also functions to produce certain special UUID constants.

### Rails finally

Let's see how can we use it in our applications. To enable this extension in our database through rails, we can use [convenient helper method](https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L338-L342) for `PostgreSQLAdapter`:

```
#!bash
rails g migration enable_uuid_extension
```

```
#!ruby
class EnableUuidExtension < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'
  end
end

```

We can create our model now:

```
#!bash
rails g model book
```

```
#!ruby
class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books, id: :uuid  do |t|
      t.string :title
      t.timestamps
    end
  end
end

# app/models/book.rb
class Book < ActiveRecord::Base; end
```

And then we can play with them a little bit:

```
#!ruby
2.1.2 :001 > Book.create
   (0.1ms)  BEGIN
  SQL (0.9ms)  INSERT INTO "books" ("created_at", "updated_at") VALUES ($1, $2) RETURNING "id"  [["created_at", "2014-10-01 10:30:12.152568"], ["updated_at", "2014-10-01 10:30:12.152568"]]
   (0.4ms)  COMMIT
 => #<Book id: "adf5efad-7c72-4e3f-9b1a-922fdbf6ebdf", title: nil, created_at: "2014-10-01 10:30:12", updated_at: "2014-10-01 10:30:12">

 2.1.2 :002 > _.id
 => "adf5efad-7c72-4e3f-9b1a-922fdbf6ebdf"
```

So we created our book with auto-generated `id` as a UUID, great!

But what if I need just another field  of `uuid` type? We can do it too.

```
#!bash
rails g migration add_uuid_to_books uuid:uuid
```

```
#!ruby
class AddUuidToBooks < ActiveRecord::Migration
  def change
    add_column :books, :uuid, :uuid, default: 'uuid_generate_v4()'
  end
end
```

After migration we have:

```
#!ruby
2.1.2 :001 > Book.create
   (0.1ms)  BEGIN
  SQL (0.2ms)  INSERT INTO "books" ("created_at", "updated_at") VALUES ($1, $2) RETURNING "id"  [["created_at", "2014-10-01 10:39:19.646211"], ["updated_at", "2014-10-01 10:39:19.646211"]]
   (0.9ms)  COMMIT
 => #<Book id: "e15b0c03-3ff0-46c2-99b2-76406da80b3a", title: nil, created_at: "2014-10-01 10:39:19", updated_at: "2014-10-01 10:39:19", uuid: nil>

2.1.2 :002 > Book.first
  Book Load (0.4ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
 => #<Book id: "e15b0c03-3ff0-46c2-99b2-76406da80b3a", title: nil, created_at: "2014-10-01 10:39:19", updated_at: "2014-10-01 10:39:19", uuid: "0699c100-4c6e-4dc3-b72f-91bac8847304">
```

And we're done. Note that UUID is accessible only after retrieving a record from the database (or reloading it in place), not immediately in brand new created object, because we get UUID generated from Postgres and not Rails itself.

### Threats and inconveniences

To be honest I should mention about some drawbacks right now. Maybe they are not crucial, but it's worth to be aware that they exists.

Some inconvenience may be referencing with a foreign key to associated model. We can't just add reference column like:

```
#!bash
rails g migration AddAuthorRefToBook
```

because it produces:

```
#!ruby
class AddAuthorRefToBook < ActiveRecord::Migration
  def change
    add_reference :books, :author, index: true
  end
end
```

Which may seems OK at the first sight, but it's actually a little bit tricky. We have the following models:

```
#!ruby
class Book < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :books
end
```

and we are trying to create an association:

```
#!bash
2.1.2 :001 > Author.create.books.create
   (0.1ms)  BEGIN
  SQL (0.8ms)  INSERT INTO "authors" DEFAULT VALUES RETURNING "id"
   (1.0ms)  COMMIT
   (0.1ms)  BEGIN
  SQL (0.3ms)  INSERT INTO "books" ("author_id") VALUES ($1) RETURNING "id"  [["author_id", 49624675]]
   (0.3ms)  COMMIT
 => #<Book id: "38c66078-9e03-45dc-8b78-408a1a41b55c", title: nil, uuid: nil, author_id: 49624675>

2.1.2 :002 > Book.first
  Book Load (0.8ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
 => #<Book id: "38c66078-9e03-45dc-8b78-408a1a41b55c", title: nil, uuid: "3caa9344-c7e3-4a9e-abb4-e44d1b857d25", author_id: 49624675>

2.1.2 :003 > Author.first
  Author Load (0.4ms)  SELECT  "authors".* FROM "authors"  ORDER BY "authors"."id" ASC LIMIT 1
 => #<Author id: "49624675-3386-4423-8cb6-70916972fe34", name: nil>
```

See what happened? If not, take a look:

```
#!bash
2.1.2 :004 > Book.first.author
  Book Load (0.3ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
  Author Load (1.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 49624675]]
PG::InvalidTextRepresentation: ERROR:  invalid input syntax for uuid: "49624675"
: SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1
ActiveRecord::StatementInvalid: PG::InvalidTextRepresentation: ERROR:  invalid input syntax for uuid: "49624675"
: SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1
```

What is wrong? `add_reference` associates model by default integer ID, which is not present in our database. Here's created schema:

```
#!ruby
create_table "books", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
  t.string  "title"
  t.uuid    "uuid",      default: "uuid_generate_v4()"
  t.integer "author_id"
end
```


Instead we should have a string field for referencing UUID, so any time we connect two tables, we can make a proper association. Fortunately it's a small change:

```
#!ruby
class AddAuthorRefToBook < ActiveRecord::Migration
  def change
    add_column :books, :author_id, :uuid
  end
end
```

which creates:

```
#!ruby
create_table "books", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
  t.string "title"
  t.uuid   "uuid",      default: "uuid_generate_v4()"
  t.uuid   "author_id"
end
```

and that is what we're talking about.

```
#!bash
2.1.2 :001 > Author.create.books.create.author
   (0.1ms)  BEGIN
  SQL (1.0ms)  INSERT INTO "authors" DEFAULT VALUES RETURNING "id"
   (0.4ms)  COMMIT
   (0.1ms)  BEGIN
  SQL (0.5ms)  INSERT INTO "books" ("author_id") VALUES ($1) RETURNING "id"  [["author_id", "e6ebe66f-3c6e-4a1f-ae67-2c5ddfce46f7"]]
   (0.2ms)  COMMIT
 => #<Author id: "e6ebe66f-3c6e-4a1f-ae67-2c5ddfce46f7", name: nil>
```

### How unique is universally unique identifier?
While the UUIDs **are not guaranteed to be unique**, the probability of a duplicate is *extremely low*. The UUID is generated using a cryptographically strong pseudo random number generator. There's very slight chance to get the same result twice. [Wikipedia provides](http://en.wikipedia.org/wiki/Universally_unique_identifier#Random%5FUUID%5Fprobability%5Fof%5Fduplicates) some nice explanation of possible duplicates.


## Conclusion

PostgreSQL offers many more extensions and types out of the box, that [are compatible with Rails](http://edgeguides.rubyonrails.org/active_record_postgresql.html) in easy way. What might be worth to check out are:

- [Binary](http://www.postgresql.org/docs/9.4/static/datatype-binary.html)
- [Range](http://www.postgresql.org/docs/9.4/static/rangetypes.html)
- [Network](http://www.postgresql.org/docs/9.4/static/datatype-net-types.html)

<%= inner_newsletter(item[:newsletter_inside]) %>

The rest will be covered in further blogposts very soon.

## References

- http://www.postgresql.org/docs/9.4/static/extend.html
- http://www.postgresql.org/docs/9.4/static/extend-extensions.html
- http://www.postgresql.org/docs/9.4/static/sql-createextension.html
- http://decomplecting.org/rails4-postgres/

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
