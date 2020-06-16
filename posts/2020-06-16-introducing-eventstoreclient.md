---
title: "Introducing EventStoreClient - a ruby implementation for Greg's EventStore"
created_at: 2020-06-16 15:25:22 +0200
author: Sebastian Wilgosz
tags: ["event sourcing", "ruby", "ddd"]
publish: true
---

Not so long ago, I've been challenged by one of my clients to split a big, monolithic 10-year old rails application into a Domain-Driven Designed, microservice-based, event-sourced ecosystem of distributed applications.

Not on my own of course, but still - **it was quite a challenge.**

<!-- more -->

# Event Store Client

One of the key components was to design a communication channel for our services and after a lot of options checks, we've decided to go with events as our *Source Of Truth* and eventual consistency for the whole ecosystem.

To make a long story short, we've created an [EventStoreClient gem for Ruby](https://github.com/yousty/event_store_client/). It's a ruby client for HTTP communication with [Greg's Event Store](https://eventstore.org).

And here is our why.

## From Rails Event Store...

When we checked options for implementing Event Sourcing with Ruby, we've obviously met the [Arkency's RailsEventStore](https://github.com/RailsEventStore/rails_event_store) which is amazing and I use it a lot in my other projects. However, it's designed for monolithic applications - not distributed systems with servers scattered around the world.

There was an option to use **distributed version of Rails Event Store**, but it was in the very early stage at the moment and we weren't sure how a rails-based event store will behave when we scale up too much.

This forced us to look for other solutions out there on the web and surprisingly there were not too many of them.

## ... to Greg's Event Store

This is how we've ended up using **EventStore from Greg Young**, a project that proved to be used in production by applications of all sizes and all kinds of traffic involved. There was a problem, though. There was no Ruby client for their API.

> Actually, there was - an [Http Event Store from Arkency team](https://github.com/arkency/http_event_store). It was not maintained, however, as Arkency focused on supporting RailsEventStore leaving this project a bit forgotten.

Without proper support from maintainers, we could grab this project and continue from there, but under time pressure, we could not think too much about supporting backward compatibility or guides to upgrade for old projects - also, at the very beginning, my client was not sure if we want to have it open-sourced.

That's how we've ended up with implementing the [EventStoreClient](https://github.com/yousty/event_store_client) - from scratch - to support 5.x version of Greg's EventStore.

### The concept.

We've been heavily inspired by the work Arkency did on both of their projects - *http_event_store* AND *rails_event_store*. If something is great, there is no need to invent the wheel again. As I've already got used to the RailsEventStore gem, I wanted to keep the interface as similar as possible to make it easy to switch if needed (we've already started to use RailsEventStore in the project for testing purposes).

At the end of the day, the usage of this gem is quite similar:

**Defining an event**

```ruby
require 'securerandom'

class SomethingHappened < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:title).value(:string)
    end
  end
end

event = SomethingHappened.new(
  data: { user_id: SecureRandom.uuid, title: "Something happened" },
)
```

**Defining a handler**

```ruby
class DummyHandler
  def self.call(event)
    puts "Handled #{event.class.name}"
  end
end
```

**Subscribing to the events**

```ruby
# initialize the client
client = EventStoreClient::Client.new

client.subscribe(DummyHandler, to: [SomethingHappened])

# now try to publish several events
events = (1..10).map { event }
client.publish(stream: 'newstream', events: events)

# .... wait a little bit ... Your handler should be called for every single event you publish
```

If you've got used to the RailsEventStore, this code will look very similar to you and that's intentional. We use [dry-rb](https://dry-rb.org) to define events and we also have different mappers to support

- InMemory testing,
- Encryption of events,
- The default - non-encrypted mapper.

### Publishing the events

We mostly publish events via the [transactional endpoints](https://driggl.com/blog/a/cars-api-endpoints-in-rails-applications) I've described in the separate article not so far ago. For that, we inject the proper `command_bus` dependency into the transaction and then we call commands using an aggregate to control the business logic behind the scenes. It looks more or less like this:

```ruby
# frozen_string_literal: true

module Endpoints
  module PublishArticle
    class Transaction < FastCqrs::Transaction
      # inject dependencies
      import Blogging::Import[
        'command_bus',
        'endpoints/publish_article/authorizer',
        'endpoints/publish_articlevalidator',
        'endpoints/publish_articlerequest',
        repository: 'repositories/articles_repository'
      ]

      # call all steps
      def call(params:, auth:)
        model = yield request.call(params)
        resource = yield repository.find(id: model[:id])
        yield authorizer.call(caller: auth, resource: resource)
        yield validator.call(model)

        # This is what we're interested with right now
        yield publish(model)

        Success(http_status: 204)
      end

      private

      def publish(attrs)
        command_bus.call(
          ::Blogging::PublishArticle.new(article_id: attrs[:id])
        )
        Success()
      rescue Blogging::BaseCommandHandler::CommandNotAllowedError
        Failure(:action_forbidden)
      end
    end
  end
end
```

So again - this stuff is pretty much what you'd probably do when you've ever worked with RailsEventStore.

## Implementation details

Under the hood, you connect with the EventStore database via the HTTP connection. I've tried to keep the interface agnostic of which kind of client it uses, so there is a bit of code duplication, where you have similar sets of methods in the `EventStoreClient::StoreAdapter::Api::Client` class and the `EventStoreClient::Client` class.

### Entry point

The most important class being an interface to everything inside is the base `EventStoreClient::Client` class. It implements all methods to communicate with the EventStore API to allow using subscriptions, publishing events, reading from a stream, and so on.

Most of it is just a delegation to the given adapter, like here:

```ruby
...

def publish(stream:, events:, expected_version: nil)
  connection.publish(
    stream: stream,
    events: events,
    expected_version: expected_version
  )
rescue StoreAdapter::Api::Client::WrongExpectedEventVersion => e
  raise WrongExpectedEventVersion.new(e.message)
end

def read(stream, direction: 'forward', start: 0, all: false)
  connection.read(stream, direction: direction, start: start, all: all)
end

...
```

However, there are some additional tricks, like implementing the `poll` method which sends a request to the Event Store to get new events for all subscriptions we have in the service.

### Configuration

The EventStoreClient is easily configurable by using the `EventStore::Configuration.instance` - an instance of the configuration class defined using the *singleton* pattern.

```ruby
EventStoreClient.configure do |config|
  config.service_name = 'my_service'
  config.error_handler = ErrorHandler.new(logger: Rails.logger)
end
```

Easy stuff and simple in use. We've tried to keep everything framework-agnostic, however, we use it in Rails applications only so far, so it'd not been proved yet that we'd succeeded in that field.

### Encryption Key repository

As we've been concerned about the security and all the GDPR requirements, we've also developed a way to encrypt/decrypt events by injecting the encryption key repository. You can configure it easily by just replacing the default mapper:

```ruby
EventStoreClient.configure do |config|
  config.mapper = EventStoreClient::Mapper::Encrypted.new(key_repository)
end
```

It also had been inspired by the EncryptedMapper implemented in RailsEventStore, but here we've been forced to improve the performance of it - which I can proudly say that we've succeeded in it.

I'll write more about that soon, as It's an extremely interesting topic.

## Obstacles and possible improvements

When we've implemented this thing, we're in the process of intense learning. We needed to learn how the EventStore works in details, but also understand all the Event Sourcing and Microservice weirdos - all stuff that is completely different than in monolithic applications.

At the same time, the clock was ticking - as usual when we talk about applications that should generate income.

At the end of the day, we've prepared a Minimal Viable Product - a gem that allowed us to go out and deliver a feature to production. However, we've made some mistakes that are already on our schedule to be improved and some of the functionalities were just not implemented due to the lack of urgent need.

Here is a list of topics that can be improved to make this gem much more useful than it is right now.

- Moving ACK to after processing the events - in the first version we've made a mistake by notifying event store about consuming events too early and this causes several further issues.
- Not 100% test coverage - as Event Store is a completely separate service, running in another container, it's a bit tricky to test it. It's not like in Postgres adapter, you can clear the database easily, and the whole communication is done via HTTP - which should be stubbed in tests... So honestly, we struggle with it at the moment. We've implemented the InMemory adapter, but the reality already shows, that adapter that is only used in testing easily goes out of sync with the real one.
- Not all endpoints covered - Greg's EventStore allows for a crazy amount of amazing stuff to be done with events and streams by communicating via the API. Obviously, we've focused on what'd been important to our projects but there is a way more to be implemented if there are a will and need for it.

### Summary

Microservice architecture is a really, really interesting topic and I'm very happy having a chance to work with it. It puts challenges in front of our team every day and I love it as well. However, to go into the microservices, you should really know your WHY.

Do you know your WHY? Why do you work on microservices OR the monolith? Why not the other one?

I'll leave it for you to think about.

**By the way, [CONTRIBUTIONS WELCOME](https://github.com/yousty/event_store_client/graphs/contributors)!**
