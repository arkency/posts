---
title: "Minimal decoupled subsystems in your rails app"
created_at: 2016-09-30 09:49:59 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'active job', 'ddd', 'eventual consistency', 'messaging' ]
newsletter: :arkency_form
---

There are multiple ways to implement communication between two separate
microservices in your application. Messaging is often the most recommended
way of doing this. However, you probably heard that
[_"You must be this tall to use microservices"_](http://martinfowler.com/bliki/MicroservicePrerequisites.html).
In other words your project must be certain size and your organization
must be mature (in terms of DevOps, monitoring, etc) to split your app
into separately running and deployed processes. **But that doesn't mean
you can't benefit from decoupling certain subsystems in your application
earlier.**

<!-- more -->

## Example

Those subsystems in your application are called [Bounded Contexts](http://martinfowler.com/bliki/BoundedContext.html).

Now, imagine that you have two bounded contexts in your application:

* **Season Passes [SP]** - which takes care of managing season passes for football clubs.
* **Identity & Access [I&A]** - which takes care of authentication, registrations and permissions.

And the usecase that we will be working with is described as:

_When Season Pass Holder is imported, create an account for her/him and send a welcome
e-mail with password setting instructions._.

The usual way to achieve it, would be to wrap everything in a transaction, create an user,
create a season pass and commit it. But we already decided to split our application
into two separate parts. And we don't want to operate on both of them directly. They
have their own responsibilities and we want to keep them decoupled.

## Evented way

So here is what we could do instead:

* [SP] create a season pass (without a reference to `user_id`)
* [SP] publish a domain event that season pass was imported
* [I&A] react to that domain event in Identity & Access part of our application and create the user account
* [I&A] in case of success, publish a domain event that User was imported (`UserImported`)
    * or if user is already present on our platform, it would publish `UserAlreadyRegistered` domain event.
* [SP] react to `UserImported` or `UserAlreadyRegistered` domain event and update the `user_id` of created `SeasonPass` 
to the ID of the user.

It certainly sounds (and is) more complicated compared to our default solution.
So we should only apply this tactic where it benefits us more than it costs.

But I assume that if you decided to separate some sub-systems of your applications
into separate, indepdent, decoupled units, you already weighted the pros and cons. So now,
we are talking only about the execution.

## About the cost

You might be thinking that there is big infrastructural cost in communicating via domain events.
That you need to set up some message bus and think about event serialization.
But big chances are things are easier than you expect them to be.

You can start small and simple and change to more complex solutions later, when
the need appears. And chances are you already have all the components needed
for it, but you never thought of them in such a way.

Do you use Rails 5 Active Job, or resque or sidekiq or delayed job or any similar tooling,
for scheduling background jobs? Good, you can use them as message bus for asynchronous
communication between two parts of your application.
With [`#retry_job`](http://api.rubyonrails.org/v5.0.0.0.1/classes/ActiveJob/Enqueuing.html#method-i-retry_job)
you can even think of it as _at least 1 delivery_ in case of failures.

So the parts of your application (sub-systems, bounded-contexts) don't need at the
beginning to be deployed as separate applications (microservices). They don't need
a separate message bus such as RabbitMQ or Apache Kafka. At the very beginning all
you need is a code which assumes asynchronous communication (and also embraces
eventuall consistency) and uses the tools that you have at your disposal.

Also, you don't any fancy serializer at the beginning such as message pack or protobuf.
YAML or JSON can be sufficient when you keep communicating asynchronously
within the same codebase (just different part of it).

## Show me the code

### Storing and publishing a domain event

We are going to use [`rails_event_store`](https://github.com/arkency/rails_event_store)
but you could achieve the same results using any other pub-sub (eg. whisper +
whisper-sidekiq extension). `rails_event_store` has the benefit that your
domain events will be saved in database.

<hr />

Domain event definition. This will be published when Season Pass is imported:

```
#!ruby
class Season::PassImported < Class.new(RubyEventStore::Event)
  SCHEMA = {
    id: Integer,
    barcode: String,
    first_name: String,
    last_name: String,
    email: String,
  }.freeze

  def self.strict(data:)
    ClassyHash.validate(data, SCHEMA)
    new(data: data)
  end
end
```

<hr />

Domain event handlers/callbacks. This is how we put messages on our background
queue, treating it as a simple message bus. We use Rails 5 API here.

```
#!ruby
Rails.application.config.event_store.tap do |es|
  es.subscribe(->(event) do
    IdentityAndAccess::RegisterSeasonPassHolder.perform_later(YAML.dump(event))
  end, [SeasonPassImported])

  es.subscribe(->(event) do
    Season::AssignUserIdToHolder.perform_later(YAML.dump(event))
  end, [IdentityAndAccess::UserImported, IdentityAndAccess::UserAlreadyRegistered])
end
```

<hr />

Imagine this part of code somewhere in a part of code responsible for
importing season passes. It saves the pass and publishes `PassImported` event.

```
#!ruby
ActiveRecord::Base.transaction do
  pass = Season::Pass.create!(...)
  event_store.publish_event(Season::PassImported.strict(data: {
    id: pass.id,
    barcode: pass.barcode,
    first_name: pass.holder.first_name,
    last_name: pass.holder.last_name,
    email: pass.holder.email,
  }), stream_name: "pass$#{pass.id}")
end
```

When event_store saves and publishes the `Season::PassImported` event, it will be also queued
to be processed by `IdentityAndAccess::RegisterSeasonPassHolder` background job
(handler equivalent in DDD world).

### Reacting to the PassImported event

These are the events that will be published by Identity and Access bounded context:

```
#!ruby
class IdentityAndAccess::UserImported < Class.new(RubyEventStore::Event)
  SCHEMA = {
    id: Integer,
    email: String,
  }.freeze

  def self.strict(data:)
    ClassyHash.validate(data, SCHEMA)
    new(data: data)
  end
end

class IdentityAndAccess::UserAlreadyRegistered < Class.new(RubyEventStore::Event)
  SCHEMA = {
    id: Integer,
    email: String,
  }.freeze

  def self.strict(data:)
    ClassyHash.validate(data, SCHEMA)
    new(data: data)
  end
end
```

<hr />

This is how Identity And Access reacts to the fact
that Season Pass was imported.

```
#!ruby
module IdentityAndAccess
  class RegisterSeasonPassHolder < ApplicationJob
    queue_as :default

    def perform(serialized_event)
      event = YAML.load(serialized_event)
      ActiveRecord::Base.transaction do
        user = User.create!(email: event.data.email)
        event_store.publish_event(UserImported.strict(data: {
          id: user.id,
          email: user.email,
        }), stream_name: "user$#{user.id}")
      end
    rescue User::EmailTaken => exception
      event_store.publish_event(UserAlreadyRegistered.strict(data: {
        id: exception.user_id,
        email: exception.email,
      }), stream_name: "user$#{exception.user_id}")
    end
  end
end
```

(ps. if you think that we should not use exceptions for control-flow,
or that exceptions are slow, keep it to yourself. This is not a debate about
such topic. I am pretty sure you can imagine exception-less solution)

### Reacting to the UserAlreadyRegistered/UserImported event

Reminder how when an event is published we schedule something to happen
in the other part of the app.

```
#!ruby
Rails.application.config.event_store.tap do |es|
  es.subscribe(->(event) do
    IdentityAndAccess::RegisterSeasonPassHolder.perform_later(YAML.dump(event))
  end, [SeasonPassImported])

  es.subscribe(->(event) do
    Season::AssignUserIdToHolder.perform_later(YAML.dump(event))
  end, [IdentityAndAccess::UserImported, IdentityAndAccess::UserAlreadyRegistered])
end
```

<hr />

Season Pass Bonuded context reacts to either `UserImported`
or `UserAlreadyRegistered` by saving the reference to
`user_id`. It does not have a direct access to `User`
class. It just holds a reference.

```
#!ruby
module Season
  class AssignUserIdToHolder < ApplicationJob
    queue_as :default

    def perform(serialized_event)
      event = YAML.load(serialized_event)
      ActiveRecord::Base.transaction do
        Pass.all_with_holder_email!(event.data.email).each do |pass|
          pass.set_holder_user_id(event.data.id)
          event_store.publish_event(Season::PassHolderUserAssigned.strict(data: {
            pass_id: pass.id,
            user_id: pass.holder.user_id,
          }), stream_name: "pass$#{pass.id}")
        end
      end
    end

  end
end
```

## When your needs grow

Now imagine that the needs of Identity And Access grow a lot. We would like to extract it
as a small application (microservice) and scale separately. Maybe deploy much more instances
than the rest of our app needs? Maybe ship it with JRuby instead of MRI.
Maybe expose it to other applications that will now use it for authentication and managing
users as well? Can it be done?

Yes. Switch to a serious message bus that can be used between separate apps, and use a proper
serialization format (not YAML, because YAML is connected to class names and you won't have
identical class names between two separate apps).

Your code already assumes asynchronous communication between Season Passes and Identity&Access
so you are safe to do so.

## Did you like it?

Make sure to check our [books](/products)
and upcoming [Smart Income For Developers Bundle](http://www.smartincomefordevelopers.com/) .

## Disclaimer

* This is an oversimiplified example to show you the idea :)

## Read more

* [Evented Rails: Decoupling domains in Rails with Wisper pub/sub events](http://www.g9labs.com/2016/06/23/rails-pub-slash-sub-with-wisper-and-sidekiq/)
* [Domain-Driven Design Distilled](https://www.amazon.com/Domain-Driven-Design-Distilled-Vaughn-Vernon-ebook/dp/B01JJSGE5S/ref=sr_1_sc_3?s=digital-text&ie=UTF8&qid=1475222799&sr=1-3-spell&keywords=destilled)
* [Implementing DDD book](https://www.amazon.com/Implementing-Domain-Driven-Design-Vaughn-Vernon-ebook/dp/B00BCLEBN8/ref=mt_kindle?_encoding=UTF8&me=)
* [Reactive Messaging Patterns with the Actor Model](https://www.amazon.com/Reactive-Messaging-Patterns-Actor-Model-ebook/dp/B011S8YC5G/ref=mt_kindle?_encoding=UTF8&me=)
* [Microservice Prerequisites](http://martinfowler.com/bliki/MicroservicePrerequisites.html)
* [Worried about rollbacks?](http://blog.arkency.com/2015/10/run-it-in-background-job-after-commit/)
