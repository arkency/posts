---
title: "One event to rule them all"
created_at: 2016-01-26 23:04:06 +0100
kind: article
publish: true
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain event', 'event sourcing', 'TDD' ]
newsletter: skip
newsletter_inside: rails_event_store
img: "events/cars-traffic-street-new-york.jpg"
---

<img src="<%= src_fit("events/cars-traffic-street-new-york.jpg") %>" width="100%">

Today I was asked a question:

> How to ensure that domain event published by one of the aggregates is available in another aggregate?

The story is simple. The user, who is a member of some organization, is registering a new fuckup (maybe by using Slack command).
The fuckup is reported by just entering its title. It is reported in the context of the organization where the user belongs.
The rest is not important here but what we want to achieve is: modify a state of an `organization` aggregate and,
at the same time, create new `fuckup` aggregate.

<!-- more -->

This is quite simple to implement using [Rails Event Store](https://github.com/arkency/rails_event_store) gem.

First let's start with the definition of a command that is executed when fuckup is registered and a domain event that is published
when fuckup is reported.

```ruby
ReportFuckupCommand = Struct.new(:organization_id, :title)
FuckupReported      = Class.new(RailsEventStore::Event)
```

Now we need a handler for our command. It should load an `Organization` aggregate from event store, execute domain logic responsible for reporting
new fuckup and store all published domain events in the event store.

```ruby
module ApplicationServices
  class OrganizationService
    def repository
      event_store = RailsEventStore::Client.new.tap do |es|
        es.subscribe(
          ApplicationServices::OnFuckupReported.new,
          ['FuckupReported'])
      end
      @repository ||= RailsEventStore::Repositories::AggregateRepository.new(
        event_store)
    end

    def report_fuckup(command)
      org = Organization.new(command.organization_id).tap do |aggregate|
        repository.load(aggregate)
      end
      org.report_fuckup(command.title)
      repository.store(org)
    end
  end
end
```

Our command handler needs an `Organization` aggregate. It should have all logic needed by the organization, does not matter now what it could be.
One thing to notice is that `Organization` does not create new `Fuckup` aggregate. Instead it "just" publishes a FuckupReported domain event.

```ruby
module Domain
  class Organization
    include RailsEventStore::AggregateRoot

    def initialize(id = SecureRandom.uuid)
      @id = id
      @public_fuckups = false
    end

    def report_fuckup(fuckup_title)
      apply FuckupReported.new(data: {
        title: fuckup_title,
        organization_id: id,
        public: public_fuckups })
    end

    attr_reader :id
    private
    attr_reader :public_fuckups

    def apply_fuckup_reported(event)
      # change organization state here...
    end
  end
end
```

So, how is `Fuckup` created? The answer is: by handling a domain event. The event handler should create new `Fuckup` aggregate (because we don't have any to load it from event store) and just store it.

```ruby
module EventHandlers
  class OnFuckupReported
    def repository
      @repository ||= RailsEventStore::Repositories::AggregateRepository.new(
        RailsEventStore::Client.new)
    end

    def hanle_event(event)
      fuckup = Fuckup.create(event)
      repository.store(fuckup)
    end
  end
end

module Domain
  class Fuckup
    include RailsEventStore::AggregateRoot

    def initialize(id = SecureRandom.uuid)
      @id = id
    end

    def self.create(event)
      fuckup = Fuckup.new
      fuckup.apply event
    end

    attr_reader :id
    private
    attr_reader :title, :organization_id, :public

    def apply_fuckup_reported(event)
      @title = event.data[:title]
    end
  end
end
```

With that implementation, our action responsible for reporting a fuckup should only execute our command handler.
Both aggregates have the domain events stored in its own stream, however as you may notice by comparing event_id
this is still the same domain event.

```ruby
=> [#<RailsEventStore::Models::Event:0x007fc0c0191120
      id: 77,
      stream: "42d98fe4-6d50-4fda-8b7f-9575d9ffa5a1",
      event_type: "FuckupReported",
      event_id: "fc1703ef-ca43-4e20-ae0c-25969511e48a",
      metadata: {:published_at=>2016-01-26 23:33:48 UTC},
      data: {:title=>"test", :organization_id=>"42d98fe4-6d50-4fda-8b7f-9575d9ffa5a1", :public=>false},
      created_at: Tue, 26 Jan 2016 23:33:48 UTC +00:00,
      updated_at: Tue, 26 Jan 2016 23:33:48 UTC +00:00>,
    #<RailsEventStore::Models::Event:0x007fc0c0190db0
      id: 78,
      stream: "b45d8738-1113-4952-a057-acb5344973c0",
      event_type: "FuckupReported",
      event_id: "fc1703ef-ca43-4e20-ae0c-25969511e48a",
      metadata: {:published_at=>2016-01-26 23:33:48 UTC},
      data: {:title=>"test", :organization_id=>"42d98fe4-6d50-4fda-8b7f-9575d9ffa5a1", :public=>false},
      created_at: Tue, 26 Jan 2016 23:33:48 UTC +00:00,
      updated_at: Tue, 26 Jan 2016 23:33:48 UTC +00:00>]
```

<%= show_product_inline(item[:newsletter_inside]) %>
