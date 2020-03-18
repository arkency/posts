---
title: "How to find records where column is not null or empty in Rails 4 or 5"
created_at: 2017-09-04 16:11:04 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'active_record' ]
newsletter: arkency_form
---

We all know that especially in legacy applications sometimes our database columns are not that well maintained. So we need to query for, or exclude rows containing `nil`/`NULL` and empty strings (`""`) as well. How can we do it in ActiveRecord?

<!-- more -->

Let's say your Active Record model is called `User` and the DB column we are going to be searching by is `category`.

## find records where column is null or empty

That's simple.

```ruby
User.where(category: [nil, ""])
```

## find records where column is not null or empty

Still easy.

```ruby
User.where.not(category: [nil, ""])
```

This `not()` clause is going to only apply to one `where`. You are not going to negate all previous conditions. In other words you can safely use it like this:

```ruby
User.
  where(state: "active").
  where.not(category: [nil, ""]).
  where("created_at > ?", 5.days.ago)
```

to get SQL statement like this:

```sql
SELECT "users".* FROM "users"
WHERE
  "users"."state" = "active" AND
  (NOT (("users"."category" = '' OR "users"."category" IS NULL))) AND
  (created_at > '2017-09-01 14:27:11')
```

## Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your
everyday Rails programmer job.

Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring big, complex Rails applications.
