---
title: "How to connect to and use ActiveRecord outside of Rails?"
created_at: 2017-08-19 19:42:19 +0200
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'rails', 'active record' ]
newsletter: arkency_form
---

Let's say you have a Ruby script and you would like to use `ActiveRecord` library inside it. Is it possible without Rails? Is it hard? It's possible and not hard at all.

<!-- more -->

## Using ActiveRecord

Make sure your pure Ruby script starts by requiring `active_record`:

```ruby
require 'active_record'
```

## Connecting to database

### Connection defaults

I like to use [connection strings](/database-url-examples-for-rails-db-connection-strings/) instead of YAML/Hash with separate key-values to describe the connection.

```ruby
ENV['DATABASE_URL'] ||= "postgres://localhost/my_db_name?pool=5"
```

I prefer to use environment variables to set them because if I want to run the script on a different database, I can change it easily by setting an environment variable outside of the script. So this works nicely for me.

### Connect to database using the connection string

```ruby
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
```

That's it. This one-liner does the job.

## Models

You can now normally use the models in your script.

```ruby
class Event < ActiveRecord::Base
end
```

There is no `ApplicationRecord` so you can't inherit from it (unless you define that as well, yourself).

## Migrations

If the database does not already have the tables you are planning on using, you can create them with Active Record migrations. If you always want to have a clean state when you run the script, pass `force: true` to drop a table before creating it.

```ruby
ActiveRecord::Schema.define do
  self.verbose = true # or false

  enable_extension "plpgsql"
  enable_extension "pgcrypto"

  create_table(:events, force: true) do |t|
    t.string      :title,       null: false
    t.text        :description, null: false
    t.datetime    :created_at,  null: false
  end
end
```

Set `verbose` to `false` if you don't want to see the output of SQL statements creating those tables.

## Logger

If you want to see the SQL queries and commands executed by your script, don't forget to set a logger.

```ruby
require 'logger'
ActiveRecord::Base.logger = Logger.new(STDOUT)
```

Use `STDOUT` instead of a file, to output directly on the screen.

## Running the script

```bash
ruby my_script.rb
```

If you want to use different DB than the default:

```bash
DATABASE_URL=mysql2://root:@127.0.0.1/db_name?pool=5 ruby my_script.rb
```

If you want to always use specific `activerecord` version you need to create the `Gemfile`

```ruby
source 'https://rubygems.org'
gemspec
gem 'activerecord', '~> 5.1.3'
```

and run `bundle install`.

Execute the script with bundler:

```bash
bundle exec ruby my_script.rb
```

## Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your
everyday Rails programmer job.

Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring big, complex Rails applications.
