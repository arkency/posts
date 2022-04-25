---
created_at: 2022-04-17 17:50:42 +0200
author: Łukasz Reszke
tags: ['sidekiq', 'honeybadger', 'notifications', 'failures', 'transient errors']
publish: false
---

# Notify Honeybadger about errors after few occurances

In our systems, there are those special types of errors that are transient. For those kinds of errors more often than not the time heals the wounds. Especially when those events occur in Sidekiq job that can be easily retried. So basically, we shouldn't worry about them too much. But... What if there's an error reported in Honeybadger that prematurely disturbs the team? Additionally, causing a loss of focus, which is expensive to regain, and unnecessary stress.

<!-- more -->

## We don't want to distracted for no reason
You're guessing it right that something like this happened recently in the project that I work on. So we started thinking about how we could solve it to get notified, on our Slack channel, only about exceptions that need our attention.

Luckily in that period, we were together at Arkency microcamp and the and one only [Mirosław](https://blog.arkency.com/authors/miroslaw-praglowski/) (thanks again!) arrived on the white horse (or rather his Kawasaki) and told us about the solution they have implemented in their project.

## Sidekiq DeathHandler to the rescue
The IgnoredError class is a wrapper for an error that has the potential to be transient. And hence it may heal itself in the next couple of occurrences.
```ruby
  class IgnoredError < StandardError
    def initialize(root_error, message: nil)
      raise if !root_error.is_a?(Exception)
      @root_error = root_error
      super(message || root_error.inspect)
    end
    attr_reader :root_error
  end
```

Let's see how it would be used in production code
```ruby
  rescue Banking::BankAccountNotFound => exception
    raise Infra::ErrorNotifier::IgnoredError.new(exception)
  end
```
The error might occur for very different reasons. One of them is that the events (in the Event-Driven system) appeared in a different order than would be expected. And that's okay. We don't need to worry about that if we can simply retry the job and handle the transient error. Hence we can transform this exception to `IgnoredError`.

In the happy-path scenario, after a retry (or few) is performed in Sidekiq, the job is successfully finished and the error will disappear.

## But what if the error is not transient?
In that case, the job will be retried until it reaches a possible retries threshold and then it'll call the death handler.
Death handlers are called when all retries for a job have been exhausted and the job dies. Once it gets there, there's information for us that the error most probably won't resolve itself and that manual intervention is required. In our case, we also want to be notified.
```ruby
class IgnoredErrorReportingDeathHandler
  def call(job, exception)
    if exception.is_a?(Infra::ErrorNotifier::IgnoredError)
      Infra::ErrorNotifier.notify(
        exception.root_error,
        context: {
          context: {
            tags: "death_handler"
          },
          parameters: job,
          component: job["class"]
        }
      )
    end
  end
end
```
The last step is to simply register the `IgnoredErrorReportingDeathHandler` in Sidekiq config
```ruby
config.death_handlers << IgnoredErrorReportingDeathHandler.new
```

And you're good to go! Less distractions, better focus.