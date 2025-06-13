---
title: How to build a read model with Rails Event Store Projection
created_at: 2021-05-01 00:58:27 +0200
author: Szymon Fiedler
tags: ["res", "projection", "read model", "ddd", "rails event store"]
publish: true
---

Recently I faced interesting challenge in one of our customer's application. Imagine that you take a test after which
you get a personalised reports about your _skills_ level. Existing mechanism for that was time and resource consuming.
People had to wait for e-mail delivery with PDF-generated report several hours due to several constraints, which I would
prefer not to dive into.

<!-- more -->

The solution was obvious — let's progressively build read model every time someone answers the question. After the test
is done, the report will be available instantly in a web ui.

## Let's start with a domain event

```ruby
module TestExecution
  class AnswerRegistered < ::Event
    attribute :participant_id, Types::Integer
    attribute :test_id, Types::Integer
    attribute :question_id, Types::Integer
    attribute :answer_id, Types::Integer
    attribute :skill_id, Types::Integer
    attribute :score, Types::Float
    attribute :time_elapsed, Types::Integer
  end
end
```

Nothing fancy, a typical domain event powered by [Rails Event Store](https://railseventstore.org), with a schema
defined, keeping identifiers of involved entities and score calculated by the domain service which publishes the event
above when its job is done.

## Build the read model

Next building block is the asynchronous handler. Why asynchronous? Not to waste time on participant's request—response
cycle and lower their satisfaction from using our application:

```ruby
module Reporting
  class CalculateparticipantReport < ApplicationJob
    prepend RailsEventStore::AsyncHandler

    def perform(event)
      participant_id = event.data.fetch(:participant_id)
      test_id        = event.data.fetch(:test_id)

      link_to_stream(event, test_id, participant_id)

      scores = calculate_scores(test_id, participant_id)

      ParticipantReport.write(
        *prepare_data_for_read_model(scores, test_id, participant_id)
      )
    end

    private

    def prepare_data_for_read_model(scores, test_id, participant_id)
      # magic happens, querying additional info, formatting data
      [scores, participant, test]
    end

    def calculate_scores(test_id, participant_id)
      RailsEventStore::Projection
        .from_stream(stream_name(test_id, participant_id))
        .init(-> { Hash.new { |scores, skill_id| scores[skill_id] = { score: 0, number_of_scores: 0 } })
        .when(
            SurveyExecution::AnswerRegistered,
            ->(state, event) do
              skill_id = event.data.fetch(:skill_id)
              state[skill_id][:score] += event.data.fetch(:score)
              state[skill_id][:number_of_scores] += 1
            end
          )
            .run(Rails.configuration.event_store)
            .reduce({}) do |scores, (skill_id, values)|
            scores[skill_id] = values[:score] / values[:n]
            scores
          end
    end

    def link_to_stream(event, test_id, participant_id)
      begin
        Rails.configuration.event_store.link(
          event.event_id,
          stream_name: stream_name(test_id, participant_id)
        )
      rescue RubyEventStore::EventDuplicatedInStream
      end
    end

    def stream_name(test_id, participant_id)
      "ParticipantReport$#{test_id}-#{participant_id}"
    end
  end
end
```

What happens here:

1. `AnswerRegistered` event is linked to a dedicated report stream `participantReport$123-456`. By doing that, we can
   scope events in a way we desired, in our case, the stream contains id of a test and participant.
   `RubyEventStore::EventDuplicatedInStream` is being rescued to support _deliver at least once_ strategy.
2. Then, with the use of [Projection](https://railseventstore.org/docs/v2/projection/) reading from our dedicated
   stream `ParticipantReport$123-456` all the scores are grouped by the `skill_id`, accumulated with additional info (
   number of elements, specifically). After the projection is done, `reduce` is being used to do the math, resulting in
   average scores for each _skill_.
3. When the _scores_ are ready, further calculations come and additional info for read model (like _skill_ names, etc.)
   is gathered and formatted. There's no need to use any other query to present it to the participant.

## How the read model looks like?

| id  | report_slug  | participant_name | test_name                     | skills                                                      |
| --- | ------------ | ---------------- | ----------------------------- | ----------------------------------------------------------- |
| 997 | cf827527c552 | Jane Doe         | Important skillz test         | `[{name: 'Sleeping', average: '2.5', global: '2.2'}, #...]` |
| 998 | 6adb1fc1d201 | Ugly Joe         | Programming skills assessment | `[{name: 'Ruby', average: '4.0', global: '2.0'}, #...]`     |
| 999 | 4cece2d44ae0 | Mr Kobayashi     | Smartness test                | `[{name: 'Whatever', average: '5.0', global: '1.0'}, #...]` |

[Vaughn Vernon](https://twitter.com/VaughnVernon) in his „Implementing Domain-Driven Design” book describes _read model_
this way:

<blockquote>
The query model is a denormalized data model. It is not meant to deliver domain behavior, only data for display (and possibly reporting). If this data model is a SQL database, each table would hold the data for a single kind of client view (display). The table can have many columns, even a superset of those needed by any given user interface display view. Table views can be created from tables, each of which is used as a logical subset of the whole.
</blockquote>

Denormalization is not a popular technique in the Rails world. What it gives? Complex, often many queries replaced with
simple lookup for a single record which contains all the data to be displayed in a pre—formatted manner.

## How to deal with concurrency issues

Please, have a look at the read model implementation:

```ruby
module Reporting
  class ParticipantReport < ApplicationRecord
    def self.write(scores, participant, test)
      ApplicationRecord.transaction do
        advisory_lock(participant.id, test.id)

        report = find_or_initialize_by(participant_id: participant.id, test_id: test.id)

        report.slug = SecureRandom.hex(6)
        report.participant_name = participant.name
        report.scores = scores
        report.save!
      end
    end

    private_class_method def self.advisory_lock(participant_id, test_id)
      args = [participant_id, test_id].join
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(hash_64('#{args}'))")
    end
  end
end
```

It's _mostly obvious_. One might think that, there's already `with_lock` or simply `lock!` method in `ActiveRecord`. Yes,
it is. However, it won't work for the not–yet–existing records because it uses `lock for update` and on first write there's
no update operation, but create. So, in many cases `ActiveRecord::RecordNotUnique` errors would appear if two or more
concurrent threads would try to insert the row for the first time. Thanks to `pg_advisory_xact_lock ( key bigint ) → void`
we can _obtain an exclusive transaction-level advisory lock, waiting if necessary_. Yet another reason to use `PostgreSQL`.

### We were wrong on computing lock key

Previous implementation of `advisory_lock` method in this blogpost didn't provide identical hash across different MRI processes and code was prone to `ActiveRecord::RecordNotUnique` errors.

It required two different processes using two different connections to prove that previous `advisory_lock` didn't work as expected and allowed share of the same resource:

```ruby
private_class_method def self.advisory_lock(participant_id, test_id)
  bigint = [participant_id, test_id].join.hash
  ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(#{bigint})")
end
```

Why this happens is explained in [Ruby's `Object#hash` docs](https://ruby-doc.org/core-3.1.2/Object.html#method-i-hash):

> The hash value for an object may not be identical across invocations
> or implementations of Ruby. If you need a stable identifier across Ruby
> invocations and implementations you will need to generate one with
> a custom method.

We fixed it by creating custom `hash_64()` function in our PostgreSQL database:

```sql
create function hash_64(_identifier character varying) returns bigint
    language plpgsql
as
$$
DECLARE
hash bigint;
BEGIN
  select left('x' || md5(_identifier), 16)::bit(64)::bigint into hash;
  return hash;
  END;
  $$;

alter function hash_64(varchar) owner to dbuser;
```

which then was used to fix the implementation of `advisory_lock`:

```ruby
private_class_method def self.advisory_lock(participant_id, test_id)
  args = [participant_id, test_id].join
  ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(hash_64('#{args}'))")
end
```

The `hash_64()` implementation was taken from [Eventide](https://github.com/eventide-project/message-store-postgres/commit/272a848e0f19851e255a28d8c7dee2ba66e98997) codebase.

## How to use the read model

```ruby
# app/controllers/test_results_controller.rb
class TestResultsController < ApplicationController
  def show
    render locals: { report: ParticipantReport.find_by!(report_slug: params[:slug]) }
  end
end
```

```haml
\# app/views/test_results/show.html.haml
%h1
  = "Personalised report for #{report.participant_name}"
%h2= report.test_name
- report.skills.each do |skill|
  %div
    = "Your performance in #{skill[:name]} is"
    = "#{skill[:average]} comparing to"
    = "#{skill[:global]} earned by others"
```

## But...

What if another field is required or there was a bug in the calculations? Not a problem, read models can be thrown out
and rebuild with ease, because all the history behind them is known — thanks to domain events.

Btw. You might be also interested in other posts on [read models](https://blog.arkency.com/tags/read-model/) on our
blog.
