---
title: "correlation id and causation id in evented systems"
created_at: 2018-05-09 18:28:57 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

Debugging can be one of the challenges when building asynchronous, evented systems. _Why did this happen, what caused all of that?_. But there are patterns which might make your life easier. We just need to keep track of what is happening as a result of what.  

<!-- more -->

For that you can use 2 metadata attributes associated with the even you are going to publish.

Let's hear what Greg Young says about `correlation_id` and `causation_id`:

> Let's say every message has 3 ids. 1 is its id. Another is correlation the last it causation. 
> If you are responding to a message, you copy its correlation id as your correlation id, its message id is your causation id. 
> This allows you to see an entire conversation (correlation id) or to see what causes what (causation id).

Now, the message that you are responding to can be either a command or an event which triggered some event handlers and probably caused even more events.

<%= img_fit("correlation_id_causation_id_rails_ruby_event/CorrelationAndCausationEventsCommands.png") %>

In [Rails/Ruby Event Store](https://railseventstore.org/) this is also possible. Recently we've released [version 0.29.0](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.29.0) which adds [#with_metadata method](http://railseventstore.org/docs/request_metadata/#passing-your-own-metadata-using-with_metadata-method) that makes it even easier. BTW, that was our [52nd release](https://github.com/RailsEventStore/rails_event_store/releases).

```ruby
class MyEventHandler
  def call(occured_event)
    event_store.with_metadata(
      correlation_id: occured_event.metadata[:correlation_id] || occured_event.event_id,
      causation_id:   occured_event.event_id
    ) do
    
      # do something which triggers another event
      event_store.publish_event(MyEvent.new(data: {foo: 'bar'}))   
    end
  end
  
  private
  
  def event_store
    Rails.configuration.event_store
  end
end
```

of course if you don't publish many events, it might be easier to apply it manually, once.

```ruby
class MyEventHandler
  def call(occured_event)
    # do something which triggers another event
    event_store.publish_event(MyEvent.new(
      data: {foo: 'bar'},
      metadata: {
        correlation_id: occured_event.metadata[:correlation_id] || occured_event.event_id,
        causation_id:   occured_event.event_id
      }
    ))   
  end
end
```

Now, keeping that correlation and causation IDs in events' metadata is one thing. That's beneficial and if you want to check why event `X` happened you can just easily do it, but it's not where the story ends.

Imagine that you have a global handler registered which reacts to every event occuring in your system and building two projections by linking the events to certain streams:

```ruby
class BuildCorrelationCausationStreams
  def call(event)
    if causation_id = event.metadata[:causation_id]
      event_store.link_event(
        event.event_id,
        stream_name: "causation-#{causation_id}"
      )
    end
    if correlation_id = event.metadata[:correlation_id]
      event_store.link_event(
        event.event_id, 
        stream_name: "correlation-#{correlation_id}"
      )
    end
  end
end
```

What would that give you?

Given an event with id `54b2` you can now check:

* in stream `causation-54b2` all the events which were triggered directly as a result of it
* and in stream `correlation-54b2` all the events which were triggered directly or indirectly as a result of it (if that message started the whole conversation)

That makes it possible to verify _what happened because of X_?

I hope that in the future we can automate all of it when some of the upcoming Ruby Event Store features are finished:

* [Correlation ID as 1st class citizen](https://github.com/RailsEventStore/rails_event_store/issues/346)
* [Metadata-driven streams](https://github.com/RailsEventStore/rails_event_store/issues/221)
* [Storing Commands](https://github.com/RailsEventStore/rails_event_store/issues/340)

