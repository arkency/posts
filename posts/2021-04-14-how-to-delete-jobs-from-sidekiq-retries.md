---
title: How to delete jobs from Sidekiq Retries
created_at: 2021-04-14T19:33:34.618Z
author: Tomasz Wróbel
tags: [ 'sidekiq', 'background job' ]
publish: true
---

Hi future-me! This is just a list of snippets I might be looking for next time I suddenly have to deal with a huge list of failing Sidekiq jobs being retried over and over.

### List job classes sitting in the retries list

```ruby
Sidekiq::RetrySet.new
  .map(&:display_class)
  .uniq
```

### Number of jobs being retried for a specific class

```ruby
Sidekiq::RetrySet.new
  .select { |j| j.display_class == "AJob" }
  .count
```

### Delete all jobs for a class from the retries list

```ruby
Sidekiq::RetrySet.new
  .select { |j| j.display_class == "AJob" }
  .map(&:delete)
```

(similarly, there's `&:kill`, `&:retry`)

(similarly, there's `Sidekiq::DeadSet`, `Sidekiq::ScheduledSet`)

### If the jobs are RES async handlers, list the events:

```ruby
Sidekiq::RetrySet.new
  .select  { |j| j.display_class == "MyAsyncHandler" }
  .collect { |j| j.args[0]["arguments"][0]["event_id"] }
  .collect { |id| Rails.configuration.event_store.read.event(id) }
```

(warning: the details depend on your [RES](https://railseventstore.org/docs/v2/install/) async scheduler implementation)

### Unique error messages for a class of jobs

```ruby
Sidekiq::RetrySet.new
  .select { _1.display_class == "AJob" }
  .map    { _1.item["error_message"] }
  .uniq
```

## More

* https://github.com/mperham/sidekiq/wiki/API#retries
* https://gist.github.com/wbotelhos/fb865fba2b4f3518c8e533c7487d5354
* https://www.mikeperham.com/2021/04/20/a-tour-of-the-sidekiq-api/ — Fun fact: Mike Perham (Sidekiq's author) wrote this post after [stumbling upon my piece and deeming it incomplete](https://twitter.com/getajobmike/status/1382482181725900801), quite understandably. I never intended this article to a comprehensive walk-through of Sidekiq's API, just a list of snippets I use most often. Now we have the author expanding on the topic. Everyone benefits :)  
