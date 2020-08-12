---
created_at: 2020-06-17 14:55:29 +0200
author: Mirosław Pragłowski
tags: ['rails', 'rails event store']
publish: true
---

# Rails multiple databases support in Rails Event Store

Rails 6 released in August 2019 has brought us several new [features](https://edgeguides.rubyonrails.org/6_0_release_notes.html).
One of the notable changes is [support for multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html).

To make the story short, to use multiple databases you need to:

* define multiple database configurations in `config/database.yml` file (for each environment)
* define a new abstract class that uses `connects_to` to set the target databases
* define a separate folder for other database migration files (don't forget to set it in the database config)
* define new models that inherit from new abstract class - all of them will be read & written to the database defined in the base class

All details have been described in [Rails guides](https://guides.rubyonrails.org/active_record_multiple_databases.html) and I've already read several blog posts describing how to do it. But how to use this feature to allow Rails Event Store data to be stored in a separate database?

<!-- more -->

## Basic setup

I've started with a new Rails 6 application. I've generated this application using
[RES application template](https://railseventstore.org/docs/start/):

```bash
rails new -m https://railseventstore.org/new sample_app
```

The template generated all the files and setup needed to start using [Rails Event Store](https://railseventstore.org)
in the Rails application. All I needed to do was to define the database configuration:

```ruby
# file: ./config/database.yml

default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  primary:
    <<: *default
    database: db/development.sqlite3
  event_store:
    <<: *default
    database: db/event_store_development.sqlite3
    migrations_paths: db/event_store

# ... and similar for other environments
```

And the base class for Rails Event Store Active Record models:

```ruby
# file: ./app/models/event_store_base.rb

class EventStoreBase < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :event_store, reading: :event_store }
end
```

That should be enough... but...

## Hardcoded ActiveRecord::Base

The `rails_event_store_active_record` gem (a part of the whole package of gems installed when you require `rails_event_store`)
has defined models for its data model. In Rails Event Store 1.0 it is [defined like this](https://github.com/RailsEventStore/rails_event_store/blob/v1.0.0/rails_event_store_active_record/lib/rails_event_store_active_record/event.rb):

```ruby
# frozen_string_literal: true

require 'active_record'

module RailsEventStoreActiveRecord
  class Event < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events'
  end

  class EventInStream < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events_in_streams'
    belongs_to :event
  end
end
```

The hardcoded `ActiveRecord::Base` class prevented me from the use of a new base class with a defined database setup.

## Required changes

So I've started experimenting. The goals were:

* do not break anything
* keep backward compatibility (RES 1.0 still support Rails 4.2)
* keep code clean & [100% mutation testing coverage](https://github.com/RailsEventStore/rails_event_store#code-status)

The implementation is conceptually quite easy:

* `EventRepository` gets an initializer argument where a developer can set the base class for its data models
* By default this is `ActiveRecord::Base` - for backward compatibility
* Data models for event repository are built dynamically
* All the code in `EventRepository` & `EventRepositoryReader` use the dynamically-built models instead of previously
  used `Event` & `EventInStream` classes.

And here is the code:

```ruby
module RailsEventStoreActiveRecord
  class EventRepository
    def initialize(base_klass = ActiveRecord::Base)
      raise ArgumentError.new(
        "#{base_klass} must be an abstract class or ActiveRecord::Base"
      ) unless ActiveRecord::Base.equal?(base_klass) || base_klass.abstract_class?

      @base_klass = base_klass
      instance_uuid = SecureRandom.uuid.gsub('-','')
      @event_klass = build_event_klass(instance_uuid)
      @stream_klass = build_stream_klass(instance_uuid)
      @repo_reader = EventRepositoryReader.new(@event_klass, @stream_klass)
    end

    private
    def build_event_klass(instance_uuid)
      Object.const_set("Event_"+instance_uuid,
        Class.new(@base_klass) do
          self.table_name = 'event_store_events'
          self.primary_key = 'id'
        end
      )
    end

    def build_stream_klass(instance_uuid)
      Object.const_set("EventInStream_"+instance_uuid,
        Class.new(@base_klass) do
          self.table_name = 'event_store_events_in_streams'
          belongs_to :event, class_name: "Event_"+instance_uuid
        end
      )
    end

    # ... and later use @event_klass & @stream_klass instead of
    # RailsEventStoreActiveRecord's Event & EventInStream classes
  end
end
```

Please notice that I've used `Object.const_set` to build model classes.
That is required because `active_record_import` gem needs the model classes to
be constants.

And finally with all these changes I've made a small change in RES setup - pass the
new base class to event repository to allow the event store models to use the database setup
defined in it.

```ruby
# file: ./config/initializers/rails_event_store.rb

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RailsEventStoreActiveRecord::EventRepository.new(EventStoreBase))

  # ... the rest of the setup here
end
```

All this allowed me to separate event store data (domain events) from the rest of the
application data - other models that still inherit from the `ApplicationRecord` model.

## Ups... no more transactions

Having 2 databases leads of course to another issue. Your data are now distributed.
You cannot have a database transaction that will span across these 2 databases.
No more transactional changes in application data and the event store.

This forces you to use **only** asynchronous event handlers. Unfortunately RES 1.0
uses [ImmediateAsyncDispatcher](https://github.com/RailsEventStore/rails_event_store/blob/v1.0.0/rails_event_store/lib/rails_event_store/client.rb#L10-L12) (actually it is a `ComposedDispatcher` with 2 dispatchers, async & sync one).
Fortunately, this is easy to change - and with multiple databases, this should be your new default:

```ruby
# file: ./config/initializers/rails_event_store.rb

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RailsEventStoreActiveRecord::EventRepository.new(EventStoreBase),
    dispatcher: RailsEventStore::AfterCommitAsyncDispatcher.new(
      scheduler: RailsEventStore::ActiveJobScheduler.new
    )
  )

  # ... the rest of the setup here
end
```

## There is more...

You might have noticed the `instance_uuid` used to generate EventRepository's model class names.
Each instance of `EventRepository` will generate new constants with different names.
This allows for having several instances of `EventRepository` - each with a separate database.
I could now start experimenting with separate Rails Event Stores - 1 for application, and 1 for each Bounded Context
defined in the domain. And all of them could be separated. Only commands & domain events could be used to communicate between them.
... but that's a story for another blog post ;)

Another way to use this feature could be having separate write & read databases in Rails Event Store.
But this requires more changes in `EventRepository`.

Also with upcoming Rails release new features could be added, some like
[horizontal sharding](https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding)
could be interesting for my future experiments here :)


This code has not been released yet. You can join me in these experiments - just post your comments to my code on Github on [multiple databases repository branch](https://github.com/RailsEventStore/rails_event_store/tree/multiple-databases-repository) or talk to me on [twitter](https://twitter.com/mpraglowski).
