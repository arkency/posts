---
title: "DATABASE_URL examples for Rails DB connection strings"
created_at: 2017-08-31 10:04:49 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'travis', 'rails', 'database_url', 'connection string' ]
newsletter: :arkency_form
---

Recently I've been configuring [RailsEventStore](https://github.com/RailsEventStore/rails_event_store) to run tests on many
databases on the Travis CI. We do it using `DATABASE_URL` environment variable
but I couldn't find good examples easily. So here they are.

<!-- more -->

## PostgreSQL

```
DATABASE_URL=postgres://localhost/rails_event_store_active_record?pool=5
```

## MySQL

```
DATABASE_URL=mysql2://root:@127.0.0.1/rails_event_store_active_record?pool=5
```

## Sqlite in memory

```
DATABASE_URL=sqlite3::memory:
```

## Code

```
ENV['DATABASE_URL'] ||= "postgres://localhost/rails_event_store_active_record?pool=5"

RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end
end
```
