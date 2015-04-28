---
title: "Why I want to introduce mutation testing to the rails_event_store gem"
created_at: 2015-04-28 12:08:56 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :arkency_form
---

We have recently released the [RailsEventStore](https://travis-ci.org/arkency/rails_event_store) project. Its goal is to make it easier for Rails developers to introduce events into their applications.

During the development we try to do TDD and have a good test coverage. The traditional test coverage tools have some limitations, though. Mutation testing is a different approach. In this post I’d like to highlight why using mutation testing may be a good choice.

<!-- more -->

Let me start with one example. In this example, mutant discovers  uncovered code. Other tools think this code is well-covered.

In the RailsEventStore (RES) implementation, we use the concept of a Broker. The broker allows subscribing to certain kinds of events. As part of the subscription we pass the subscriber object. In the current implementation, we expect that such a subscriber has a `handle_event` method.

```
#!ruby
module RailsEventStore
  module PubSub
    class Broker

      def initialize
        @subscribers = {}
      end

      def add_subscriber(subscriber, event_types)
        raise SubscriberNotExist  if subscriber.nil?
        raise MethodNotDefined    unless subscriber.methods.include? :handle_event
        subscribe(subscriber, [*event_types])
      end
    end
  end
end
```

When the `raise MethodNotDefined    unless subscriber.methods.include? :handle_event` line was introduced it didn’t come with any test. Despite this fact, the coverage tools assume it does have a coverage. That’s because the previous tests do go through this line and consider it covered.

Let’s turn this line into this:

```
#!ruby
if !subscriber.methods.include? :handle_event
	raise MethodNotDefined
end
```

With this code, the simple coverage tools are able to detect that the `if` block is never executed.

As you see, the coverage metric is now depending on the fact how you format the code. That’s not good.

If we run the first piece of code with mutant, it does detect that there is a lacking coverage.

**What’s wrong with the lack of coverage?**

The problem with lacking test/mutation coverage is that it’s easy to break things when you do any code transformations. The RailsEventStore is at the moment changing very often. We try to apply it to different Rails applications. This way we see, what can be improved. The code changes to reflect that. If we have features without some tests, then we may break them without knowing it.

My goal here is to have every important feature to be well-covered. This way, the users of RES can rely on our code.
