---
title: "Implementing worker threads in Rails"
created_at: 2013-06-17 10:47:05 +0200
kind: article
publish: true
newsletter: :arkency_form
author: Paweł Pacana
tags: [ 'ruby', 'thread', 'fork', 'chillout', 'unicorn', 'puma', 'passenger' ]
---

If you care about your application performance you have to schedule extra tasks into background when handling requests. One of such tasks may be collecting performance or business metrics. In this post I'll show you how to avoid potential problems with threaded background workers.

<!-- more -->

## Problem

I was working on [chillout](http://chillout.io) client to collect metrics from ActiveRecord creations. Initially the code was sending collected metrics during the request. It was simpler but slowed down the application response to the customer. The response time was also fragile with regard to metrics endpoint availability. So I had the idea to start a worker thread in background responsible for that. Since everything worked like a charm in development, a deployment was inevitable. Then things started to get hairy.

## Forking servers

My production application was running on Unicorn and it was configured to preload application code. In that settings Unicorn master process will boot an application and next when code is loaded it will fork into several application workers.

The problem with fork call is that only main thread survives it:
> Inside the child process, only one thread exists. It is made from a copy of the thread that called fork in the parent.

This means that under any forking server (e.g Unicorn, Phusion Passenger) our background thread will die, provided it was started before process forked. You may think:
> I know, I'll use after_fork hook.

And this might be solution for you and your specific web server. It definitely isn't a solution when you don't want to be tied to particular deployment option or explicitly support all webserver specific solutions.

The other possibility is to start our worker thread lazily when it's actually needed for the first time. A naive implementation may look like this:

```ruby
class MetricClient
  def initialize
    @queue = Queue.new
  end

  def enqueue(metric)
    start_worker unless worker_running?
    @queue << metric
  end

  def worker_running?
    @worker_thread && @worker_thread.alive?
  end

  def start_worker
    @worker_thread = Thread.new do
      worker = Worker.new(@queue)
      worker.run
    end
  end
end
```

An attentive reader may notice that lazy starting solution applies to any kind of background worker threads - it will solve similar problems in [girl_friday](https://github.com/mperham/girl_friday/issues/47) or [sucker_punch](https://github.com/brandonhilkert/sucker_punch/issues/6).

##  Threading servers

Now that we have lazy loading mechanism we're good to deploy anywhere, right? Wrong! As soon as we deploy to threaded server (e.g. Puma) we'll encounter another problem.

Since changing webserver model to threaded we will service several requests in one process concurrently. Each of these threads servicing request will be racing to start the worker in background but we want only one instance of the worker to be present. Thus we have to make worker starting code thread-safe:

```ruby
class MetricClient
  def initialize
    @queue = Queue.new
    @worker_mutex = Mutex.new
  end

  def enqueue(metric)
    ensure_worker_running
    @queue << metric
  end

  def ensure_worker_running
    return if worker_running?
    @worker_mutex.synchronize do
      return if worker_running?
      start_worker
    end
  end

  def worker_running?
    @worker_thread && @worker_thread.alive?
  end

  def start_worker
    @worker_thread = Thread.new do
      worker = Worker.new(@queue)
      worker.run
    end
  end
end
```

Now we're good to go on any forking or threading web server. We're covered even in such a rare case of webserver forking to threaded workers (does it actually exist?). Life is good.

## The case of BufferedLogger

There's one peculiar thing left. If you happen to use logger in your worker thread and it is [BufferedLogger](http://api.rubyonrails.org/classes/ActiveSupport/BufferedLogger.html) from Rails you'll be surprised to find out some of your messages don't get logged. It's a [known](http://log.kares.org/2011/04/railslogger-is-not-threadsafe.html) and apparently [solved](https://github.com/rails/rails/commit/b838570bd69ff13d677fb43e79f10d6f3168c696) issue. If you have to support apps which didn't get the fix just remember to explicitly call [flush](http://stackoverflow.com/questions/1598494/logging-inside-threads-in-a-rails-application) on logger.


You can see all the solutions from above applied in [chillout](https://github.com/chilloutio/chillout) gem. If you're interested how we're collecting metrics have look on [How to track ActiveRecord model statistics](http://blog.arkency.com/2013/06/how-to-track-activerecord-model-statistics/). Happy hacking!
