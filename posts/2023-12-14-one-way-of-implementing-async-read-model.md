---
created_at: 2023-12-14 09:02:21 +0100
author: Łukasz Reszke
tags: ["read model", "res"]
publish: false
---

# A crucial detail in implementing an async read model builder

Let's start with claryfing few terms before we begin, just to make sure we're
on the same page.

Make sure you also look at the end of this blog post, where I describe one of
the most common mistakes.

## What is a read model 

* In an event sourced system (or part of the system that
is event sourced) the truth lays in the event store. However, event stores are
not optimized for reading the data. Therefore, it is more convenient to use
read models.
* A read model is a denormalized data model built using the data coming from the
events.
* You can think of it as a more convenient, handy data model that makes reading
the data for the UI easier and faster.

In this particular example, the read model will be implemented as an event
handler.

<!-- more -->

## Sync 
Although we'll focus on the async read model in this blog post, I think
you might also be interested in learning about the sync read model.

* Sync is the abbreviation that comes from the word synchronous. We use it quite
a bit, so I thought it might be useful to make it clear.
* When a read model is built synchronously, both the event and the read model are
stored in the database within the same process. However, not necessairly within
the same transaction. Usually that process is either a user request that causes
some object to publish an event, or a worker.
* The good thing about using synchronous read models is that we have instant
consistency. This is especially important when we think about a user making a
POST request that changes the state of the application. The state change is
immediately reflected in the read model, which means we can rely on that
information and get it back in the from the response. This makes it easy to
display in the UI. It is not so easy with asynchronous read models.
* The bad part is that if the read model update fails for some reason, the POST
request will also fail. This happens even if the write part is successful. As a
result, the user would see some error. Of course, you can take care of the the
error part by adding a few rescues here and there, but this would make your
read model inconsistent. Which is undesired. And you'd have to rebuild that
read model anyway.
* Also, you often have more than one event handler subscribing to an event. The
more sync event handlers that subscribe to an event, the higher the chance that
the request won't be processed successfully. Also, the more handlers, the more
IO operations, so the request will take longer. More often than not, the
approach of using only sync event handlers leads to an unacceptable amount of
time to process the request. Which in turn makes for bad UX.

## Async 
* Async is short for asynchronous.
* When a read model is built async, the event handlers are executed by the
background workers. This is great because we can scale the handling of events
independently of the web server.
* Also, if processing an event fails, then it is up to the queue mechanism to
deal with it. Most of the queues have an auto retry that you can rely on.
Sometimes the event will not be processed due to a transient error. In this
case, time will heal the wounds.  In other cases, the error will require code
fixes. With async handlers, there's the convenience of being able to fix the
error, deploy, and retry the job that handles the event. However, the user
experience would be poor in this  experience in this case because we're talking
about read models, which, as I said, is something that users like to browse.
* But nothing comes for free. Async requires us to deal with eventual
consistency.

## Implementing async read model builder 
This event handler that manages the reading model is quite simple. Its job is
to visualize the progress of a quiz to the supervisor. So what it does is it
subscribes to an event and builds the read model, which is an `ActiveRecord`
model. Questions are predefined as constants because there's only one quiz in
this demo app.

As mentioned above, we need some sort of background worker to set up an
asynchronous event handler. In this case, I'll show you how to set up an event
handler in application that uses `ActiveJob::Base` to take care of background
operations.

```ruby
class BuildOngoingQuiz < ActiveJob::Base
  prepend RailsEventStore::AsyncHandler

  def perform(event)
    ongoing_quiz = OngoingQuiz.new(quiz_id: quiz_id = event.data.fetch(:quiz_id))
    ongoing_quiz.answer_id = answer_id = Integer(event.data.fetch(:answer_id))
    ongoing_quiz.question_id = question_id = Integer(event.data.fetch(:question_id))
    question = Questions::DDD.fetch(:questions).select do |question|
      question.fetch(:question_id) == question_id
    end.first
    ongoing_quiz.question = question.fetch(:question)
    ongoing_quiz.answer = question.fetch(:answers).select { |answer| answer.fetch(:id) == answer_id }.first.fetch(:answer)
    ongoing_quiz.save!
  end
end
```

In this example I used the `ActiveJob::Base` to handle the background jobs. This
affects the way I have to set up the scheduler, we'll get to that in the next
paragraph.

The `RailsEventStore::AsyncHandler` module is included to deserialize the event
for the active job. I can access the event directly instead of going through
the payload. For an alternative approach, please see the doc.

Note that this is a simplified implementation. [There are other aspects to
consider when designing an async read
model](https://blog.arkency.com/read-model-patterns-in-case-of-lack-of-order-guarantee/)

In this case, I only subscribe to one event because that is all I need to build
the read model. Note that my first argument to the method is a class, not a
class instance.
```ruby
  Rails.configuration.event_store.tap do |store|
    # ... 
    store.subscribe(BuildOngoingQuiz, to: [QuestionAnswered])
  end
```

### The scheduler 
In this project I am using RailsEventStore's predefined `JSONClient`. [You can
read more about that
here.](https://blog.arkency.com/first-class-json-b-handling-in-rails-event-store/)

Although it is predefined, I want you to be aware of the part with the
scheduler as it is very important and often confused.

The scheduler is used to define how the subscriber of the event is handled. The
default implementation of the `JSONClient` uses `ActiveJobScheduler`. The
scheduler must define a call and verify methods. In the case of the async
scheduler, the verify method answers the question of whether the called
subscriber is properly defined as an is a correctly defined async class. The
call method knows how to call the Subscriber. In the most standard case of
`ActiveJobScheduler`, these methods are implemented as follows:

```ruby
    def verify(subscriber)
      if Class === subscriber
        !!(subscriber < ActiveJob::Base)
      else
        subscriber.instance_of?(ActiveJob::ConfiguredJob)
      end
    end

    def call(klass, record)
      klass.perform_later(record.serialize(serializer).to_h.transform_keys(&:to_s))
    end
```

[Full implementation available here.](https://github.com/RailsEventStore/rails_event_store/blob/48ac91ec4c481257740fb5c9d1ee72489dcf5731/rails_event_store/lib/rails_event_store/active_job_scheduler.rb#L4)

## Common mistake 
There's a common mistake with the async event handler subscription that we see
in the projects we consult. I want you to be aware of it.

`event_store.subscribe(BuildOngoingQuiz.new, to: [QuestionAnswered])`

At first glance, this code looks fine and raises no suspicions. But this is not
a proper subscription to the async event handler! Even if you inherit from the
`ActiveJob::Base`. This event handler is always executed synchronously.

Also, the same object will always be used to handle new events.

**Correct version below**
`event_store.subscribe(BuildOngoingQuiz, to: [QuestionAnswered])`

Sometimes the cause of this error is that people want to include dependencies
into the event handler/subscriber. 

It is not possible to do it that way and keep the event handler asynchronous.

Please keep this in mind. If you use RES in your project, it's a good moment to
check that you don't have event handlers that unintentionally subscribe to
events in this way ;).

But if you do, don't rush to remove the `.new` part. This change will affect
behavior of your application. You'll run into the potential consistency problem
that I described at the beginning of this article.

