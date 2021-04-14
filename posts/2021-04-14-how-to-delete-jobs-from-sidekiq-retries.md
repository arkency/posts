---
title: How to delete jobs from Sidekiq Retries
created_at: 2021-04-14T19:33:34.618Z
author: Tomasz Wróbel
tags: []
publish: false
---

This is just a list of snippets I might be looking for next time I suddenly have to deal with a huge list of failing Sidekiq jobs being retried over and over.

### What job classes are in retries?

```ruby
Sidekiq::RetrySet.new.map(&:display_class).uniq
```

### Number of jobs being retried for a specific class:

```ruby
Sidekiq::RetrySet.new.select { |j| j.display_class == "MyJob" }.count
```

### Delete all jobs for a class from the retries list:

```ruby
Sidekiq::RetrySet.new.select { |j| j.display_class == "MyJob" }.map(&:delete)
```

(similarly, there's `&:kill`, `&:retry`)

(similarly, there's `Sidekiq::DeadSet`, `Sidekiq::ScheduledSet`)

## More

* https://github.com/mperham/sidekiq/wiki/API#retries
* https://gist.github.com/wbotelhos/fb865fba2b4f3518c8e533c7487d5354
