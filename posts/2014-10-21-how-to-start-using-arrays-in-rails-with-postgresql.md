---
title: "How to start using Arrays in Rails with PostgreSQL"
created_at: 2014-10-21 21:05:52 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :skip
newsletter_inside: :arkency_form
tags: [ 'ActiveRecord', 'PostgreSQL', 'Postgres', 'AR', 'Array' ]
---

<p>
  <figure>
    <img src="/assets/images/postgres/chairs-fit.jpg" width="100%">
  </figure>
</p>

So far we covered a lot of PostgreSQL goodness. We've already talked about [using uuid](http://blog.arkency.com/2014/10/how-to-start-using-uuid-in-activerecord-with-postgresql/) or [storing hashes](http://blog.arkency.com/2014/10/how-to-persist-hashes-in-rails-applications-with-postgresql/) in our Rails applications with PostgreSQL database. Now is the time to do something in the middle of these topics (more complex than `uuid`, but easier than `hstore`) - we want to **store list of simple values under one attribute**. How can we do that? You may think *"arrays"* right now and you are correct. Let's see how we can achieve that.

<!-- more -->

# A little bit of theory

Arrays are ordered, integer-indexed collections of any object. They are great for storing collection of elements even with different types.

First normal form (*1NF*) is a relation's property in a relational database. It requires every attribute to have domain that can consist of only atomic values so value of each attribute is always single value from that domain.

For [some wise reasons](http://databases.about.com/od/specificproducts/a/Should-I-Normalize-My-Database.htm) we pursue to normalize our databases so that no duplicated data is stored there. So should we consider combining relational databases with arrays as something that breaks `1NF`? [It seems so](http://stackoverflow.com/questions/20720523/does-an-array-uuid-break-1nf).

However there are [cases](http://blog.codinghorror.com/maybe-normalizing-isnt-normal/) when we might want to have redundant data, that's the place where arrays suit the best.

# Postgres

We'll start with empty database and create there example table:

```
#!sql
➜  Arkency-Blog git:(master) ✗ psql -d postgres
psql (9.3.5, server 9.3.4)
Type "help" for help.

postgres=# \dt
No relations found.

postgres=# CREATE TABLE arrays_example(
               name   text,
               values integer[]
           );
CREATE TABLE
```

We can put some data now:

```
#!sql
postgres=# INSERT INTO arrays_example VALUES('numbers', '{1, 2, 3}');
INSERT 0 1

postgres=# SELECT * FROM arrays_example;
   name   | values
----------+---------
 one-type | {1,2,3}
(1 row)

postgres=# SELECT name FROM arrays_example WHERE values[1] = 1;
  name
---------
 numbers
(1 row)
```

[Official Postgres documentation](http://www.postgresql.org/docs/9.4/static/arrays.html) provides a lot of useful examples to start working on SQL level with database.

# Rails

In the last blogpost about `hstore` we showed how to enable particular extension. This time is different (maybe easier), because [`array` is Postgres' data type](http://www.postgresql.org/docs/9.4/static/arrays.html), not an extension so there's no need to enable that, because it's accessible out of the box!

## Migration

In two previous articles (mentioned in the introduction of this article) we created `Book` model and appropriate SQL schema. Let's stick to that and extend it a little bit:

```
#!bash
rails g migration add_subjects_to_book subjects:text
```

And the migration file:

```
#!ruby
class AddSubjectsToBook < ActiveRecord::Migration
  def change
    add_column :books, :subjects, :text, array:true, default: []
  end
end
```

We can check it now:


```
#!ruby
2.1.2 :001 > b = Book.create
   (0.2ms)  BEGIN
  SQL (2.0ms)  INSERT INTO "books" ("created_at", "updated_at") VALUES ($1, $2) RETURNING "id"  [["created_at", "2014-10-17 08:21:17.870437"], ["updated_at", "2014-10-17 08:21:17.870437"]]
   (0.5ms)  COMMIT
 => #<Book id: "39abef75-56af-4ad5-8065-6b4d58729ee0", title: nil, created_at: "2014-10-17 08:21:17", updated_at: "2014-10-17 08:21:17", description: {}, metadata: {}, subjects: []>

2.1.2 :002 > b.subjects.class
 => Array
```

## Model manipulation

Now is the time to add some subjects for books and then query them. Please keep in mind that all of the following examples are executed `Rails 4.2.0.beta1` environment.

```
#!ruby
2.1.2 :003 > b.subjects << 'education'
 => ["education"]

2.1.2 :004 > b.save!
   (0.2ms)  BEGIN
  SQL (0.5ms)  UPDATE "books" SET "subjects" = $1, "updated_at" = $2 WHERE "books"."id" = '39abef75-56af-4ad5-8065-6b4d58729ee0'  [["subjects", "{education}"], ["updated_at", "2014-10-17 08:23:35.657137"]]
   (1.0ms)  COMMIT
 => true
```

```
#!ruby
2.1.2 :005 > Book.first.subjects
  Book Load (0.9ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
 => ["education"]

2.1.2 :006 > b.subjects.push 'business'
 => ["education", "business"]

2.1.2 :007 > b.save!
   (0.1ms)  BEGIN
  SQL (0.4ms)  UPDATE "books" SET "subjects" = $1, "updated_at" = $2 WHERE "books"."id" = '39abef75-56af-4ad5-8065-6b4d58729ee0'  [["subjects", "{education,business}"], ["updated_at", "2014-10-17 08:24:25.883010"]]
   (0.9ms)  COMMIT
 => true
```

```
#!ruby
2.1.2 :008 > Book.first.subjects
  Book Load (0.5ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
 => ["education", "business"]

2.1.2 :009 > b.subjects += ['history']
 => ["education", "business", "history"]

2.1.2 :010 > b.save!
   (0.2ms)  BEGIN
  SQL (0.4ms)  UPDATE "books" SET "subjects" = $1, "updated_at" = $2 WHERE "books"."id" = '39abef75-56af-4ad5-8065-6b4d58729ee0'  [["subjects", "{education,business,history}"], ["updated_at", "2014-10-17 18:53:12.755711"]]
   (0.9ms)  COMMIT
 => true
```

```
#!ruby
2.1.2 :011 > Book.first.subjects
  Book Load (0.4ms)  SELECT  "books".* FROM "books"  ORDER BY "books"."id" ASC LIMIT 1
 => ["education", "business", "history"]
 ```

### Caveats

In previous versions of Rails we may encounter some weird behavior:

```
#!ruby
2.1.2 :012 > b.subjects << 'art'
 => ["education", "business", "history", "art"]

2.1.2 :013 > b.save!
   (0.2ms)  BEGIN
   (0.1ms)  COMMIT
 => true

2.1.2 :014 > Book.first.subjects
  Book Load (0.6ms)  SELECT "books".* FROM "books" ORDER BY "books"."id" ASC LIMIT 1
 => ["education", "business", "history"]
```

What happened here? Why subjects array wasn't updated?

### Dirty tracking

[`ActiveModel::Dirty` module](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html) provides a way to track changes in your objects. Sometimes our record does not know that underlying object properties have been changed and that's why we have to point this explicitly.

```
#!ruby
2.1.2 :015 > b.subjects_will_change!
 => ["education", "business", "history"]

2.1.2 :016 > b.subjects << 'art'
 => ["education", "business", "history", "art"]

2.1.2 :017 > b.save!
   (0.2ms)  BEGIN
  SQL (2.8ms)  UPDATE "books" SET "subjects" = $1, "updated_at" = $2 WHERE "books"."id" = '39abef75-56af-4ad5-8065-6b4d58729ee0'  [["subjects", ["education", "business", "history", "art"]], ["updated_at", Fri, 17 Oct 2014 19:14:52 UTC +00:00]]
   (1.0ms)  COMMIT
 => true
```

```
#!ruby
2.1.2 :018 > Book.first.subjects
  Book Load (0.6ms)  SELECT "books".* FROM "books" ORDER BY "books"."id" ASC LIMIT 1
 => ["education", "business", "history", "art"]
```

And everything went as we wanted. So if you have any problem with updating properties of some enclosed object you can indicate that this particular object will be changed by your operations and then safely save it with new properties that will be updated:

```
#!ruby
2.1.2 :019 > b.subjects << 'finances'
 => ["education", "business", "history", "finances"]

2.1.2 :020 > b.changed?
 => false

2.1.2 :021 > b.subjects_will_change!
 => ["education", "business", "history", "finances"]

2.1.2 :022 > b.changed?
 => true

2.1.2 :023 > b.subjects_changed?
 => true

2.1.2 :024 > b.changes
 => {"subjects"=>[["education", "business", "history"], ["education", "business", "history", "finances"]]}

2.1.2 :025 > b.save!
   (0.2ms)  BEGIN
  SQL (3.1ms)  UPDATE "books" SET "subjects" = $1, "updated_at" = $2 WHERE "books"."id" = '39abef75-56af-4ad5-8065-6b4d58729ee0'  [["subjects", ["education", "business", "history", "finances"]], ["updated_at", Fri, 17 Oct 2014 19:21:25 UTC +00:00]]
   (1.0ms)  COMMIT
 => true
```

### Querying

PostgreSQL have a bunch of useful [array methods](http://www.postgresql.org/docs/9.4/static/functions-array.html) that you can leverage in your Rails applications.

```
#!ruby
2.1.2 :026 > Book.where("'history' = ANY (subjects)")
  Book Load (0.5ms)  SELECT "books".* FROM "books" WHERE ('history' = ANY (subjects))
 => #<ActiveRecord::Relation [#<Book id: "39abef75-56af-4ad5-8065-6b4d58729ee0", title: nil, created_at: "2014-10-17 08:21:17", updated_at: "2014-10-17 19:21:25", description: {}, metadata: {}, subjects: ["education", "business", "history", "finances"]>]>
```

```
#!ruby
2.1.2 :027 > Book.where("subjects @> ?", '{finances}')
  Book Load (0.5ms)  SELECT "books".* FROM "books" WHERE (subjects @> '{finances}')
 => #<ActiveRecord::Relation [#<Book id: "39abef75-56af-4ad5-8065-6b4d58729ee0", title: nil, created_at: "2014-10-17 08:21:17", updated_at: "2014-10-17 19:21:25", description: {}, metadata: {}, subjects: ["education", "business", "history", "finances"]>]>
```

# Summary

After reading all of these three articles you should be PostgreSQL trouper. You can now have flexible and relational database at the same time. There are [a lot of topics](http://edgeguides.rubyonrails.org/active_record_postgresql.html) worth to read, but not covered in any of these blogposts. I hope you find our tutorials useful.

## Off-topic

While I was researching arrays in Postgres I found an interesting thing, that I wasn't aware of before:

### Character Types

| *Name*                               | *Descirption*              |
|--------------------------------------|----------------------------|
| `character varying(n)`, `varchar(n)` | variable-length with limit |
| `character(n)`, `char(n)`            | fixed-length, blank padded |
| `text`                               | variable unlimited length  |

> Tip: There is no performance difference among these three types, apart from increased storage space when using the blank-padded type, and a few extra CPU cycles to check the length when storing into a length-constrained column. While character(n) has performance advantages in some other database systems, there is no such advantage in PostgreSQL; in fact character(n) is usually the slowest of the three because of its additional storage costs. In most situations text or character varying should be used instead.

<%= inner_newsletter(item[:newsletter_inside]) %>

# Resources

- http://postgresguide.com/sexy/arrays.html

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="/assets/images/fearless-refactoring-fit.png" width="15%" /></a>
<a href="/rails-react"><img src="/assets/images/react-for-rails/cover-fit.png" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/developers-oriented-project-management/"><img src="/assets/images/dopm-fit.jpg" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="/assets/images/blogging-small-fit.png" width="15%" /></a>
<a href="/responsible-rails"><img src="/assets/images/responsible-rails/cover-fit.png" width="15%" /></a>
