---
title: "Why I want to introduce mutation testing to the rails_event_store gem"
created_at: 2015-04-28 12:08:56 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :arkency_form
---

We have recently released the [RailsEventStore](https://github.com/arkency/rails_event_store) project. Its goal is to make it easier for Rails developers to introduce events into their applications.

During the development we try to do TDD and have a good test coverage. The traditional test coverage tools have some limitations, though. Mutation testing is a different approach. In this post I’d like to highlight why using mutation testing may be a good choice.

<!-- more -->

Let me start with one example. In this example, [mutant](https://github.com/mbj/mutant) discovers  uncovered code. Other tools think this code is well-covered.

In the RailsEventStore (RES) implementation, we use the concept of a Broker. The broker allows subscribing to certain kinds of events. As part of the subscription we pass the subscriber object. In the current implementation, we expect that such a subscriber has a `handle_event` method.

```ruby
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

```ruby
if !subscriber.methods.include? :handle_event
	raise MethodNotDefined
end
```

With this code, the simple coverage tools are able to detect that the `if` block is never executed.

As you see, the coverage metric is now depending on the fact how you format the code. That’s not good.

If we run the first piece of code with mutant, it does detect that there is a lacking coverage.

**Mutant output**

When I run mutant on RES, I use the following:

```
bundle exec mutant —include lib —require rails_event_store —use rspec “RailsEventStore*”
```

which results in the following summary:

```
Mutant configuration:
Matcher:         #<Mutant::Matcher::Config match_expressions=[<Mutant::Expression: RailsEventStore*>] subject_ignores=[] subject_selects=[]>
Integration:     rspec
Expect Coverage: 100.00%
Jobs:            4
Includes:        [“lib”]
Requires:        [“rails_event_store”]
Subjects:        47
Mutations:       1238
Kills:           888
Alive:           350
Runtime:         108.15s
Killtime:        159.60s
Overhead:        -32.24%
Coverage:        71.73%
Expected:        100.00%
```

It’s worth noting that mutation testing is very time-consuming. In our case, the time spent was the following:

```
real	1m52.906s
user	3m56.833s
sys	2m34.144s
```

My goal is to setup Travis to run the mutation tests on every push. Also, I’d like to set up a 100% expected mutation coverage in the future.

This is an [example output](https://travis-ci.org/arkency/rails_event_store/builds/60342041) of the mutant run on a Travis machine. It’s worth looking at, as you can see the full output. Mutant shows us every alive mutation - the ones that don’t break tests. One example:

```ruby
 def version_incorrect?(stream_name, expected_version)
   unless expected_version.nil?
-    find_last_event_version(stream_name) != expected_version
+    find_last_event_version(stream_name) != nil
   end
 end
```

This output means, that our coverage here was not perfect. Simply replacing the `expected_version` with `nil` is still passing all tests. That’s not good. We can’t really rely on our tests if we want to refactor this code. 

**What’s wrong with the lack of coverage?**

The problem with lacking test/mutation coverage is that it’s easy to break things when you do any code transformations. The RailsEventStore is at the moment changing very often. We try to apply it to different Rails applications. This way we see, what can be improved. The code changes to reflect that. If we have features without some tests, then we may break them without knowing it.

My goal here is to have every important feature to be well-covered. This way, the users of RES can rely on our code.

Feel free to start using RailsEventStore in your Rails apps. We already plugged it into several of our applications and it works correctly. In case of any question, please jump to our [gitter channel](https://gitter.im/arkency/rails_event_store), we’ll be happy to help.