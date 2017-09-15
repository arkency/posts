---
title: Mutation testing and continuous integration
created_at: 2015-05-01 11:56:02 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :arkency_form
---

Mutation testing is another form of checking the test coverage. As such it makes sense to put it as part of our Continuous Delivery process. In this blog post I’ll show you how we started using mutant together with TravisCI in the [RailsEventStore](https://github.com/arkency/rails_event_store) project.

<!-- more -->

In the last blogpost I explained [why I want to introduce mutant to the RailsEventStore project](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/). It comes down to the fact, that RailsEventStore, despite being a simple tool, may become a very important part of a Rails application. 

RailsEventStore is meant to store events, publish them and help building the state from events (Event Sourcing). As such, it must be super-reliable. We can’t afford introducing breaking changes. Regressions are out of question here. It’s a difficult challenge and there’s no silver bullet to achieve this.

We’re experimenting with mutant to help us with ensuring the test coverage. There are other tools, like simplecov or rcov but they work on much worse level of precision. 

Another way of ensuring that we don’t do mistakes is to rely on automation. Whatever can be done automatically, should be done automatically. A continuous integration server is a part of the automation process. We use TravisCI here.

Previously, TravisCI just run `bundle exec rspec`. The goal was to extend it with running the coverage tool as well.

When I was experimenting with mutant and run it for the first time, I saw about 70% of coverage. That was far from perfect. However, it was a good beginning. My idea was to introduce mutant as part of the CI immediately - with the first goal being that we don’t get worse over time.

Mutant supports the `—score` option:

```
$ mutant -h
usage: mutant [options] MATCH_EXPRESSION …
Environment:
        —zombie                     Run mutant zombified
    -I, —include DIRECTORY          Add DIRECTORY to $LOAD_PATH
    -r, —require NAME               Require file with NAME
    -j, —jobs NUMBER                Number of kill jobs. Defaults to number of processors.

Options:
        —score COVERAGE             Fail unless COVERAGE is not reached exactly
        —use STRATEGY               Use STRATEGY for killing mutations
        —ignore-subject PATTERN     Ignore subjects that match PATTERN
        —code CODE                  Scope execution to subjects with CODE
        —fail-fast                  Fail fast
        —version                    Print mutants version
    -d, —debug                      Enable debugging output
    -h, —help                       Show this message
```

I didn’t read this output carefully, at first. I assumed that the score option is there to check if my coverage is equal or higher than the expected coverage. When I run the tests and checked the exit code (`echo $?`) afterwards I saw the result being 1 (a failure).

I assumed that something was broken and went to the mutant sources to find this [here](https://github.com/mbj/mutant/blob/7529b724c4409fdeb73c9a0fe6390ec7b5e4946c/lib/mutant/result.rb#L95):

```ruby

      # Test if run is successful
      #
      # @return [Boolean]
      #
      # @api private
      #
      def success?
        coverage.eql?(env.config.expected_coverage)
      end
```

BTW, if you want see a pretty Ruby codebase - you should look at the [mutant code](https://github.com/mbj/mutant).

**Raising the coverage bar**

This must have been a mistake, I thought. Why would you ever want to assume that the coverage is equal to expected coverage. Being higher than the expected coverage is a good thing, right? Actually, it’s not a good thing. As I learnt from Markus (the author of mutant), this setting is intentional. The reason for that is that you want to fail in both cases - when the current coverage is lower than expected - that’s clear. You also want the build to fail, when it’s higher. Why? Because otherwise you may miss the point of time when you improved the coverage. Later on, you may have reduced again. You never noticed that the expected coverage should be raised. If I got it correctly, this technique is called “raising the bar”. After this explanation it made a perfect sense to me.

Unfortunately, at the moment, there’s a small problem with using this technique. Due to the [rounding precision problems](https://github.com/mbj/mutant/issues/323), we can’t pass the “right” number to mutant. Very often your coverage is like `74.333333333%` and you can’t pass such precision easily. This is not a big problem, though. There's a better way of using mutant - whitelisting/blacklisting.

**Whitelisting/blacklisting uncovered classes**

Another technique that I learned from Markus was to whitelist or blacklist certain classes which don’t pass the 100% coverage. The idea is to never break the coverage of the perfectly covered units. 
This motivated us to get all the “almost” covered units to the 100% mark, which we did.

BTW, it’s worth mentioning that we only test our code through the public API. In our case, it’s the `Client` facade and the `Event` class. We avoid grabbing an internal class and testing it directly. [I wrote more about this topic in the past](http://blog.arkency.com/2014/09/unit-tests-vs-class-tests/).

We were only left with 2 (private) classes that were left uncovered: MigrateGenerator and the EventRepository. Both of them are Rails-related. The MigrateGenerator looks like this:

```ruby

require 'rails/generators'

module RailsEventStore
  class MigrateGenerator < Rails::Generators::Base
    source_root File.expand_path(File.join(File.dirname(__FILE__), '../generators/templates'))

    def create_migration
      template 'migration_template.rb', 'db/migrate/#{timestamp}_create_events_table.rb'
    end

    private

    def timestamp
      Time.now.strftime("%Y%m%d%H%M%S")
    end

  end
end
```

This is just a helper for the Rails developers who use our tool to generate a migration for them. It creates a table, where events will be stored.

At the moment this class is blacklisted from the mutant coverage. How would you put it under a test coverage?

**The repository pattern and the ways of testing it**

The second case is `EventRepository`:

```ruby

module RailsEventStore
  module Repositories
    class EventRepository

      def initialize
        @adapter = EventEntity
      end
      attr_reader :adapter

      def find(condition)
        adapter.where(condition).first
      end

      def create(data)
        model = adapter.new(data)
        raise EventCannotBeSaved unless model.valid?
        model.save
      end

      def delete(condition)
        adapter.destroy_all condition
      end

      def get_all_events
        adapter.find(:all, order: 'stream').map &method(:map_record)
      end

      def last_stream_event(stream_name)
        adapter.where(stream: stream_name).last.map &method(:map_record)
      end

      def load_all_events_forward(stream_name)
        adapter.where(stream: stream_name).order('id ASC').map &method(:map_record)
      end

      def load_events_batch(stream_name, start_point, count)
        adapter.where('id >= ? AND stream = ?', start_point, stream_name).limit(count).map &method(:map_record)
      end

      private

      def map_record(record)
        event_data = {
            stream:     record.stream,
            event_type: record.event_type,
            event_id:   record.event_id,
            metadata:   record.metadata,
            data:       record.data
        }
        OpenStruct.new(event_data)
      end
    end
  end
end

```

We use the repository pattern to encapsulate and hide the storage part of our tool. If you want to read more about the repository pattern, [I wrote a book](http://controllers.rails-refactoring.com) which explains why it’s worth using and how to introduce this pattern to the existing Rails application.

In tests, we use an InMemoryRepository:

```ruby

require 'ostruct'

module RailsEventStore
  class EventInMemoryRepository

    def initialize
      @db = []
    end
    attr_reader :db

    def find(condition)
      db.select { |event| event.event_id == condition[:event_id].to_s }.first
    end

    def create(model)
      model.merge!({id: db.length})
      db.push(OpenStruct.new(model))
    end

    def delete(condition)
      db.reject! { |event| event.stream == condition[:stream] }
    end

    def last_stream_event(stream_name)
      db.select { |event| event.stream == stream_name }.last
    end

    def load_all_events_forward(stream_name)
      db.select { |event| event.stream == stream_name }
    end

    def get_all_events
      db
    end

    def load_events_batch(stream_name, start_point, count)
      response = []
      db.each do |event|
        if event.stream == stream_name && event.id >= start_point && response.length < count
          response.push(event)
        end
      end
      response
    end

    def reset!
      db = []
    end

  end
end

```

Replacing the repository with an in memory equivalent (with the same API) is a nice technique. It lets us run the tests super fast.

There’s one drawback, though - we don’t test the real repository. This was rightly pointed out by mutant.

I don’t want any place in the code to remain untested. I want us to have the confidence that whenever tests pass we can ship a new release of the gem (ideally automatically).

So, how to test the ActiveRecord-related code? How to make it fast (mutant runs those tests several times)? If you have any idea, please share it with us here. I’ve got some ideas but that’s a topic for another blogpost probably :)

**Mutant and TravisCI**

Now - the main point. To summarise - we now have 100% mutant coverage in all but 2 classes. We can make it part of the CI process just by putting the following into our .travis.yml file:

```
language: ruby
rvm:
- 2.1.5
before_install: gem install bundler
gemfile: Gemfile
script: bundle exec mutant —include lib —require rails_event_store —use rspec "RailsEventStore*" —ignore-subject "RailsEventStore::MigrateGenerator*" —ignore-subject "RailsEventStore::Repositories::EventRepository*"
```

Thanks to that, the CI will check the coverage every time the code is pushed. It may influence the way we work in some interesting ways - we need to ensure that the coverage is always the same. That’s an interesting challenge!