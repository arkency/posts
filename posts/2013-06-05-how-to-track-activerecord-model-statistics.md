---
title: "How to track ActiveRecord model statistics"
created_at: 2013-06-05 11:56:43 +0200
kind: article
publish: true
author: Jan Filipowski
newsletter: :chillout
tags: ['rails', 'active record', 'metrics']
---

If you're really serious about your application you have to collect and analyze its statistics. You can use Google Analytics or any other tool [to track visits and basic events](http://blog.arkency.com/2012/12/google-analytics-for-developers/), or you can send specific events on demand. There's also a way to automatically track ActiveRecord model creations and in this post I'll show you how easy it is.

<!-- more -->

## The solution

Let's digg into the most important source code:

```
#!ruby
# config/initializers/creation_listener.rake
module CreationListener
  def inherited(subclass)
    super
    class_name = subclass.name
    subclass.after_commit :on => :create do
      Rails.logger.info "[#{Time.now.to_s}] Model created: '#{class_name}'"
    end
  end
end

ActiveRecord::Base.extend(CreationListener)
```

I think you already know what it does - it binds to ActiveRecord::Base's callback and puts appropriate message with time of creation and class name of created model. Then log messages are parsed with the following rake task:

```
#!ruby
# lib/tasks/creations.rake
task creations: :environment do
  creation_entry_regexp = /\[([\w\W]+)\] Model created: '([\w\W]+)'/
  log_path = File.join(Rails.root, "log", "development.log")
  date_to_calculate = Date.today

  result = Hash.new{|hash, key| hash[key] = 0}

  File.open(log_path, "r") do |f|
    f.each_line do |line|
      if line =~ creation_entry_regexp
        creation_time = Date.parse($1)
        model_name = $2.strip
        if creation_time == date_to_calculate
          result[model_name] += 1
        end
      end
    end
  end

  puts "Statistics for: #{date_to_calculate}"
  result.each_pair do |key, value|
    puts "  #{key}: #{value}"
  end
end

```

I just define how to look for and parse creation messages, which log file I want to check and for which date. Then both parsing and calculating result happens - if line matches to regexp and given date is one we are looking for it increments result for given model. So as a result you get the list of all model classes which instances were created on given day.

You can check how it works using [this sample project](https://github.com/chilloutio/creations_counting_rails_example).

## Logger? Seriously?!

In this example I assume, that the only method to persist information about created model is to use log messages. Of course it's just a simplification. In real world you don't want to gather all statistics in log: it can be time consuming to calculate the results, logs can be really big or rotated.

For alternative persistence method you have to be aware of 2 things:

1. It shouldn't slow down response time too much.
2. It should be threadsafe.

If you dig into [chillout](https://github.com/chilloutio/chillout) gem you'll see how you can achieve that - you can use ```Thread.current``` to pass information about created models and middleware to get this information and send it to the storage - in our case to API endpoint. There are a few simple optimizations that will help you not to kill app's performance when dealing with API, but that's subject for another post.
