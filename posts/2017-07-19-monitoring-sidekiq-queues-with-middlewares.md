---
title: "Monitoring Sidekiq queues with middlewares"
created_at: 2017-07-19 13:28:16 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'chillout', 'sidekiq', 'middleware' ]
newsletter: arkency_form
---

Sidekiq, similarly to Rack, has a concept of middlewares. A list of wrappers around its processing logic that you can use to include custom behavior.

<!-- more -->

In [chillout](http://chillout.io) we use it to collect and send a number of metrics:

* how long did it take to process a job

    Obviously it is nice to notice when a certain jobs starts to work much slower than usually.

* how long did it take between scheduling a job and starting a job

    This is useful to know if your Sidekiq workers are not saturated. Ideally the numbers should be around 1-2ms, which means you are processing everything as it comes and have no delay.

    Depending on what your application does a second or two of a delay might be good enough as well. But if the number is getting higher it means you are having problems and maybe you need more machines, threads or just investigate a temporary issue.

    If it is one job causing you problems, check out your options in [Handle sidekiq processing when one job saturates your workers and the rest queue up](/2017/07/sidekiq-slow-processing-one-job-saturates-workers-rest-queue-up/).

    I used to think that number of unprocessed jobs is a good metric, but I think this is better. I doesn't matter if you have 1 or 10_000 jobs waiting if you can start all of them very quickly because you have enough workers and the jobs are processed very quickly.

    The delay before processing is a better indicator than queue size. Because you don't know if you have 1000 jobs which take 10ms each, or 1 job which takes 10 minutes to finish. And all you care about is the effect on other jobs waiting in queues.

* did it finish successfully or with a failure

    So that one can monitor a failure rate

* queue and job names

    To have granular metrics per jobs and queues.


The code is very simple and nicely explained in [Sidekiq documentation](https://github.com/mperham/sidekiq/wiki/Middleware) so if you want to build your own logging or monitoring, it's not hard.

```ruby
class SidekiqMonitor
  def initialize(options)
    @client = options.fetch(:client)
  end

  def call(_worker, job, queue)
    started = Time.now.utc
    success = false
    yield
    success = true
  ensure
    enqueue(queue, job, started, success)
  end

  def enqueue(queue, job, started, success)
    finished = Time.now.utc
    @client.enqueue(SidekiqJobMeasurement.new(
      job,
      queue,
      started,
      finished,
      success
    ))
  end
end

class SidekiqJobMeasurement
  attr_reader :retriable, :queue, :started,
    :finished, :delay, :duration, :success

  def initialize(job, queue, started, finished, success)
    @class     = job["class"].to_s
    @retriable = job["retry"].to_s
    @queue     = queue
    @started   = started.utc
    @finished  = finished.utc
    enqueued_at = job["enqueued_at"]
    @delay = 1000.0 * (@started.to_f - enqueued_at)
    @duration = 1000.0 * (@finished.to_f - @started.to_f)
    @success = success.to_s
  end
end

Sidekiq.server_middleware.add SidekiqMonitor,
  client: client
```

Effect (click to enlarge):

<a href=<%= src_original("ruby-rails-sidekiq-monitoring-jobs-queues/sidekiq_job_speed.jpg") %>>
  <%= img_fit("ruby-rails-sidekiq-monitoring-jobs-queues/sidekiq_job_speed.jpg") %>
</a>

<a href=<%= src_original("ruby-rails-sidekiq-monitoring-jobs-queues/delay.jpg") %>>
  <%= img_fit("ruby-rails-sidekiq-monitoring-jobs-queues/delay.jpg") %>
</a>

Testing middlewares is also easy:

```ruby
  def setup
    @client = mock("Client")
    Sidekiq::Testing.server_middleware.add SidekiqMonitor,
      client: client
  end

  def teardown
    Sidekiq::Testing.server_middleware.clear
  end

  class EmptyJob
    include Sidekiq::Worker
    def perform; end
  end

  def test_enqueues_stats
    @client.expects(:enqueue).with do |measurement|
      SidekiqJobMeasurement === measurement
    end
    Sidekiq::Testing.inline! { EmptyJob.perform_async }
  end

  class ErrorJob
    Doh = Class.new(StandardError)
    include Sidekiq::Worker
    def perform
      raise Doh
    end
  end

  def test_enqueues_stats_even_on_failure
    @client.expects(:enqueue).with do |measurement|
      SidekiqJobMeasurement === measurement &&
        measurement.success == "false"
    end
    Sidekiq::Testing.inline! do
      assert_raises(ErrorJob::Doh) do
        ErrorJob.perform_async
      end
    end
  end
```
