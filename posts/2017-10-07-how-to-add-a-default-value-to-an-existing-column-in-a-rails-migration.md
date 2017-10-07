---
title: "How to add a default value to an existing column in a Rails migration"
created_at: 2017-08-03 13:16:47 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'active_record', 'migrations', 'default' ]
newsletter: :arkency_form
---

You probably know that you can easily set a **default** when adding a new column in an Active Record migration.

```ruby
add_column(:events, :state, :string, default: 'draft', null: false)
```

```sql
ALTER TABLE "events" ADD "state" varchar(255) DEFAULT 'draft' NOT NULL
```

<!-- more -->

But what about adding a default to an existing column? Fortunately in Rails 4 and 5 there is an easy way to achieve that. Use `change_column_default` method.

## Set default value for an existing column

The Api is:

```ruby
change_column_default(
  table_name,
  column_name,
  default
)
```

or

```ruby
change_column_default(
  table_name,
  column_name,
  from:,
  to:
)
```

Check out an example:

```ruby
change_column_default(
  :events,
  :state,
  'draft'
)
```

Providing `nil` results in dropping the default.

```ruby
change_column_default(
  :events,
  :state,
  nil,
)
```

However, it's better to use `:from` and `:to` named arguments. It will make the migration reversible which is sometimes useful.

```ruby
change_column_default(
  :events,
  :state,
  from: nil,
  to: "draft"
)
```

BTW. There is a similar method named `change_column_null` which (as you probably guessed right now) allows you to easily set or remove the `NOT NULL` constraint.

```ruby
change_column_null(
  :events,
  :state,
  false
)
```

means that `state` cannot be `NULL` (null -> false).

```ruby
change_column_null(
  :events,
  :state,
  true
)
```

means that `state` can be `NULL` (null -> true).

If you want, you can also set a new value for records who currently have `NULL`.

```ruby
change_column_null(
  :events,
  :state,
  false,
  "draft"
)
```

## Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your
everyday Rails programmer job.

Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring big, complex Rails applications.