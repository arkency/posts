---
title: "Testing aggregates with commands and events"
created_at: 2016-02-19 07:26:59 +0100
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

Once you start switching to using aggregates in your system (as opposed to say, ActiveRecord objects), you will need to find good ways of testing those aggregate objects. This blogpost is an attempt to explore one of the possible ways.

<!-- more -->


The code I'm going to show is part of a project that I was recently working on. The app is called Fuckups (yes, I consider changing that name) and it helps us track and learn from all kinds of mistakes we make. 

Yes, we make mistakes. 

The important part is to **really** learn from those mistakes. This is our company habit that we have for years now. During the week we collect all the fuckups that we see. It doesn't matter who did them, the story and the lesson matters. We used to track them in a Hackpad called "Fakapy jak startupy" which means "Fuckups as Startups" (don't ask). That's why this name persisted until today. Our hackpad has all the archives now.
Every Friday we have a weekly sync. [As a remote/async company](http://blog.arkency.com/developers-oriented-project-management/) we avoid all kinds of "sync" meetings. Fridays are the exception, when we disuss all kinds of interesting things as the whole team. We call it "weeklys".

One part is usually the most interesting is the Fuckups part. We iterate through them, one person says what happened and we try to discuss and find the root problems. Once a fuckup is discussed we mark it as "discussed".

The app is a replacement for the hackpad. In its core, it's a simple list, where we append new things. 

I tried to follow the "Start from the middle" approach here and it mostly worked. It's far from perfect, but we're able to use it now. One nice thing is that we can add a new fuckup to the list by a simple Slack command. 

```
/fuckup SSL Certificates has not been updated before expiration date
```

No need to leave Slack anymore.

Although the app is already "in production", new organizations can't start using it yet. The main reason was that I started from the middle with authentication by implementing the Github OAuth. This implementation requires Github permissions to read people organizations (because not all memberships are public). 

Before releasing it to public, I wanted to implement the concept of a typical authentication - you know - logins/passwords, etc.

This is where I got sidetracked a bit. 

It's our internal project and not a client project, so there's a bit more freedom to experiment. As you may know, we talk a lot about [going from legacy to DDD](http://blog.arkency.com/2016/01/from-legacy-to-ddd-start-with-publishing-events/). That's what we usually do. It's not that often that we do DDD from scratch. So, the fuckups app core is a legacy Rails Way approach. But, authentication is another bounded context. I can have the excitement of starting a new "subproject" here.

Long story, short, I started implementing what I call `access` library/gem. A separated codebase responsible for authentication, not coupled to fuckups in any way.

There will be a concept of organizations, but for now I just have the concept of Host (a container for organizations). We can think of it as the host for other tenants (organizations).

I implemented the host object as the aggregate. At the moment it should know how to:

* register a user
* chossing a login for the user
* providing the password
* authenticate

Looking at different kinds of aggregates implementations, I decided to go with the way where the aggregate accepts a command as the input. It makes the aggregate closer to an actor. It's not an actor in the meaning of concurrent computation, but an actor in the conceptual meaning.

This means, the host takes 4 kinds of messages/commands as the input. The expected output for each command is an event or a set of events.

For example, if we have a RegisterUser command, then if it's successfully handled, we expect an UserRegistered event.

In this case, I also went with Event Sourcing the aggregate. It means that an aggregate can be composed from events. 

BTW, here we get a bit closer to the Functional Programming way of thinking. I didn't go with full FP yet, but I'm considering it. With "full" FP the objects here wouldn't mutate state, but they would return new objects every time a new event is applied.



```
#!ruby
  class Host
    include RailsEventStore::AggregateRoot

    def initialize
      @users = {}
    end

    def handle(command)
      case command
        when RegisterUser
          register_user(command.user_id)
        when Authenticate
          authenticate(command.credentials)
        when ChooseLogin
          choose_login(command.user_id, command.login)
        when ProvidePassword
          provide_password(command.user_id, command.password)
      end
    end

		private

    def register_user(user_id)
      apply(UserRegistered.new(data: {user_id: user_id}))
    end


    def apply_user_registered(event)
      @users[event.data[:user_id]] = RegisteredUser.new
    end

    # ...
  end
```

If you're interested what's the AggregateRoot part, here is the current implementation (it's part of our [aggregate_root](https://github.com/arkency/aggregate_root) gem):

```
#!ruby
module RailsEventStore
  module AggregateRoot
    def apply(event)
      apply_event(event)
      unpublished_events << event
    end

    def apply_old_event(event)
      apply_event(event)
    end

    def unpublished_events
      @unpublished_events ||= []
    end

    private

    def apply_event(event)
      send("apply_#{event.event_type.underscore.gsub('/', '_')}", event)
    end

  end
end
```

What's worth noticing is that the output of each aggregate command handling is an event (or a set of events). We collect them in the `@unpublished_events` and expose publicly.

Exposing such thing publicly is not the perfect thing, but it works and solves the problem of a potential dependency on some kind of event store.

# Testing

How can we test it?

In the beginning, I started testing the aggregate by preparing state with events. Then I applied a command and asserted the `unpublished_events`.
It works, but the downside is [similar to using FactoryGirl for ActiveRecord testing](http://blog.arkency.com/2014/06/setup-your-tests-with-). There's the risk of using events for the state, which are not possible to happen in the real world usage.

```
#!ruby
    def test_happy_path
      input_events = [
          UserRegistered.new(data: {user_id: "123"}),
          UserLoginChosen.new(data: {user_id: "123", login: "andrzej"}),
          UserPasswordProvided.new(data: {user_id: "123", password: "12345678"})
      ]
      command = Authenticate.new(Login.new("andrzej"), Password.new("12345678"))

      expected_events = [
          UserAuthenticated.new(data: {user_id: "123"})
      ]

      verify_scenario(input_events, command, expected_events)
    end
```

If you like this approach, we show it also as [a way to test the read models](http://blog.arkency.com/2015/09/testing-event-sourced-application-the-read-side/) and separately [for the write side](http://blog.arkency.com/2015/07/testing-event-sourced-application/).

Another approach that I'm aware of is by treating the aggregate as a whole and test with whole scenarios, by applying a list of commands.

This is the command-driven testing in practice:

```
#!ruby
module Access
  class AuthenticateTest < Minitest::Test

    def test_happy_path
      commands = [
          RegisterUser.new("123"),
          ChooseLogin.new("123", Login.new("andrzej")),
          ProvidePassword.new("123", Password.new("12345678")),
          Authenticate.new(Login.new("andrzej"), Password.new("12345678"))
      ]
      expected_events = [
          UserRegistered.new(data: {user_id: "123"}),
          UserLoginChosen.new(data: {user_id: "123", login: "andrzej"}),
          UserPasswordProvided.new(data: {user_id: "123", password: "12345678"}),
          UserAuthenticated.new(data: {user_id: "123"})
      ]

      host = Host.new
      commands.each { |cmd| host.handle(cmd) }
      assert_events_equal(expected_events, host.unpublished_events)
    end
  end
end
```

I like this approach. The only downside is that I need to assert the whole list of events here. This is no longer just testing handling one command, though. It's testing the whole unit (aggregate with commands, events and value objects) with scenarios. In this case, testing all events kind of makes sense. What's your opinion here?

If you're stuck with a more Rails Way code but you like the command-driven approach, then form objects may be a good step for you. Form objects are like the Command for the whole app, not just the aggregate, but their overall idea is similar. We wrote more about form objects in our ["Fearless Refactoring: Rails Controllers" book](http://rails-refactoring.com).