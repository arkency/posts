---
title: "Testing deprecations warnings with RSpec"
created_at: 2017-08-27 14:04:06 +0200
publish: true
author: Andrzej Krzywda
tags: ['testing']
---

Recently at Arkency we've been doing quite a lot of work around the [RailsEventStore](https://railseventstore.org) ecosystem. We see RailsEventStore as the way to help Rails teams start doing DDD without needing to build the infrastructure for CQRS/ES. 

The growing number of teams which use RES + a growing number of contributors made us do some cleaning.

One of the small changes which was introduced was a very simple refactoring. It would be simple if not the fact, that this was changing the public API, so it requires a proper handling with a deprecation warning.

<!-- more -->

In the RailsEventStore you can pass a handler to any event. We expect that this handler responds to `call`. If it doesn't respond to that, we used to raise MethodNotDefined exception. However, this can be a confusing name, so we decided to rename that to InvalidHandler to be more explicit about the problem.

It's very unlikely that someone was relying on this exception in their project using RES. Still, it's a good practice to not crash the client code, after an upgrade. We want to keep it working, but give a warning message. Also, we don't want any new code to depend on this old class.

What we did:

- remove the old exception class
- introduce a new class
- implement `RubyEventStore.const_missing` which replaces the old class with the new one and gives a warning to std error.

This is the whole implementation:

```ruby
 module RubyEventStore
  def self.const_missing(const_name)
    super unless const_name.equal?(:MethodNotDefined)
    warn "RubyEventStore::MethodNotDefined has been deprecated. Use RubyEventStore::InvalidHandler instead."
    InvalidHandler
  end
end
```

This works and is fine. However, how can we ensure that this works? By writing tests of course!

We have 3 requirements here:

- makes sure we use InvalidHandler instead of MethodNotDefined
- still crashes for other missing consts
- warns the developer about the deprecation

which nicely turns into this RSpec code:

```ruby

RSpec.describe "RubyEventStore.const_missing" do
  it "makes sure we use InvalidHandler instead of MethodNotDefined" do
  end
  
  it "still crashes for other missing consts" do
  end
  
  it "warns the developer about the deprecation" do
  end
end
```

The first spec goes like that:

```ruby

  it "makes sure we use InvalidHandler instead of MethodNotDefined" do
    expect(RubyEventStore::MethodNotDefined).to(eq(RubyEventStore::InvalidHandler))
  end
```

The second spec:

```ruby

  it "still crashes for other missing consts" do
    expect(-> {RubyEventStore::FooBarNotExisting}).to(raise_error(NameError))
  end
```

The third one was a bit more complex. We rely on `.warn` method which is built-in in Ruby. Its result is to output a message to $stderr. There are several ways to approach this. We can either mock the `.warn` method, or we can wrap the whole thing with some kind of `UIAdapter` which just happens to have `.warn` as the implementation detail (but we still need to test the new class). The last solution is to make sure the effect is valid - we see some output on $stderr, which can be done by introducing a FakeStdErr class.

```ruby

class FakeStdErr
  attr_accessor :messages

  def initialize
    @messages = []
  end

  def write(msg)
    @messages << msg
  end
end
```

Then the spec looks like this:

```ruby

it "warns the developer about the deprecation" do
    begin
      original_stderr = $stderr
      fake_std_err    = FakeStdErr.new
      $stderr         = fake_std_err
      RubyEventStore::MethodNotDefined
      warn_message = "`RubyEventStore::MethodNotDefined` has been deprecated. Use `RubyEventStore::InvalidHandler` instead."
      expect(fake_std_err.messages[0]).to(eq(warn_message))
    ensure
      $std_err = original_stderr
    end
  end
```

It's also worth noting, that most developers will rely on the RailsEventStore gem, which is the umbrella gem for all the ecosystem here. However, RailsEventStore is only a simple wrapper over the RubyEventStore gem. In particular it means we wrap the public exceptions with a code like this:

```ruby

module RailsEventStore
  Event                     = RubyEventStore::Event
  InMemoryRepository        = RubyEventStore::InMemoryRepository
  EventBroker               = RubyEventStore::PubSub::Broker
  Projection                = RubyEventStore::Projection
  WrongExpectedEventVersion = RubyEventStore::WrongExpectedEventVersion
  InvalidExpectedVersion    = RubyEventStore::InvalidExpectedVersion
  IncorrectStreamData       = RubyEventStore::IncorrectStreamData
  EventNotFound             = RubyEventStore::EventNotFound
  SubscriberNotExist        = RubyEventStore::SubscriberNotExist
  InvalidHandler            = RubyEventStore::InvalidHandler
  InvalidPageStart          = RubyEventStore::InvalidPageStart
  InvalidPageSize           = RubyEventStore::InvalidPageSize
  GLOBAL_STREAM             = RubyEventStore::GLOBAL_STREAM
  PAGE_SIZE                 = RubyEventStore::PAGE_SIZE
```

This gives us the control that from a RailsEventStore perspective the RubyEventStore can be an implementation detail. People who are using it with their Rails apps don't need to be aware of the details. However, RubyEventStore is something that can be used in any project, not only Rails (think Hanami, Sinatra, etc).

This way the feature is covered fully with tests. Mutant is happy (100% coverage) and we can feel secure that other changes don't break this simple functionality.

Obviously, we could debate whether this kind of a feature (deprecations) deserves the tests. It's a hard question and not easy to answer. We should probably decide whether the new tests make our further work harder. 

One thing which we follow from the beginning of the project is [to have 100% mutation coverage](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/) to ensure the quality and to encourage the contributors to follow the TDD techniques. RailsEventStore is a tool on which serious projects rely on and we want to ensure that it works the best possible way.
