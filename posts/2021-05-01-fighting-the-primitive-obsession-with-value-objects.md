---
title: Fighting the primitive obsession with Value objects
created_at: 2021-05-01 13:41:14 +0200
author: Szymon Fiedler
tags: ['ddd', 'value object']
publish: true
---
My previous post on [read models](https://blog.arkency.com/how-to-build-a-read-model-with-rails-event-store-projection/)
intended to address something different, but I decided to focus on read model part and leave the other topic for a different 
one. There's one thing which I dislike in the implementation. Using primitives to calculate the scores.

<!-- more -->

## Projection

```ruby
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
```

It accumulates the score in scope of a given skill so we can count the average and so on. This example is simplified,
as you may suspect, the original is more complex.

## We can do better

How can it be done differently? By introducing _Value object_. Before diving into the code, we should establish the
correct definition of it. I like characteristics of _Value object_ which Eric Evans put in his 
„Domain-Driven Design: Tackling the Complexity in the Heart of Software” book:

  * It measures, quantifies, or describes a thing in the domain.
  * It can be maintained as immutable.
  * It models a conceptual whole by composing related attributes as an integral unit.
  * It is completely replaceable when the measurement or description changes.
  * It can be compared with others using Value equality.
  * It supplies its collaborators with Side-Effect-Free Behavior

Probably the most common example of Value object you'll meet is the `Price` or `MonetaryValue` which represents the
combo of `BigDecimal` and a `String` representing the currency. I'll do something different then.

```ruby
class AnswerScore
  def initialize(skill_id, score)
    @skill_id = skill_id
    @score = BigDecimal(score.to_s)
  end

  attr_reader :skill_id, :score

  def eql?(other)
    other.instance_of?(AnswerScore) && skill_id.eql?(other.skill_id) && score.eql?(other.score)
  end

  alias == eql?

  def hash
    AnswerScore.hash ^ [skill_id, score].hash
  end
end
```

What we got here, we are able to compare two different `AnswerScore` by their values thanks to `==`, `eql?` and `hash`
methods on our own:

```ruby
irb(main):069:0> AnswerScore.new(123, 0) == AnswerScore.new(123, 0)
=> true
irb(main):070:0> AnswerScore.new(123, 0) == AnswerScore.new(123, 1)
=> false
irb(main):071:0> AnswerScore.new(123, 0) == BigDecimal("0")
=> false
irb(main):072:0> AnswerScore.new(123, 0) == AnswerScore.new(456, 0)
=> false
```

Same results will give us the `.eql?` operator since `==` is alias of it.

## Adding two value objects

Ok, you can compare two objects, what now? And there's also an id, shouldn't this be an `Entity`? Nope, it shouldn't,
we treat this id to distinguish scores of different skills. Adding two scores of two different skills wouldn't make much
sense, right? Imagine adding money in dollars and pounds sterling without distinguishing the currency.

Let's implement `+` operator on the object then.
```ruby
class AnswerScore
  def initialize(skill_id, score)
    @skill_id = skill_id
    @score = BigDecimal(score.to_s)
  end

  attr_reader :skill_id, :score

  def +(other)
    raise ArgumentError unless self.class === other
    raise ArgumentError if self.skill_id != other.skill_id

    score + other.score
  end

  def eql?(other)
    other.instance_of?(AnswerScore) && skill_id.eql?(other.skill_id) && score.eql?(other.score)
  end

  alias == eql?

  def hash
    AnswerScore.hash ^ [skill_id, score].hash
  end
end
```

And there it is, we won't be able to add anything wrong to our score:

```ruby
# Same skills, different scores
irb(main):123:0> AnswerScore.new(123, 0) + AnswerScore.new(123, 1)
=> 0.1e1

# Different object
irb(main):124:0> AnswerScore.new(123, 0) + 5
Traceback (most recent call last):
        5: from /Users/fidel/.rbenv/versions/2.7.3/bin/irb:23:in `<main>'
        4: from /Users/fidel/.rbenv/versions/2.7.3/bin/irb:23:in `load'
        3: from /Users/fidel/.rbenv/versions/2.7.3/lib/ruby/gems/2.7.0/gems/irb-1.2.6/exe/irb:11:in `<top (required)>'
        2: from (irb):124
        1: from (irb):107:in `+'
ArgumentError (ArgumentError)

# Scores of different skills
irb(main):126:0> AnswerScore.new(123, 0) + AnswerScore.new(456, 1)
Traceback (most recent call last):
        5: from /Users/fidel/.rbenv/versions/2.7.3/bin/irb:23:in `<main>'
        4: from /Users/fidel/.rbenv/versions/2.7.3/bin/irb:23:in `load'
        3: from /Users/fidel/.rbenv/versions/2.7.3/lib/ruby/gems/2.7.0/gems/irb-1.2.6/exe/irb:11:in `<top (required)>'
        2: from (irb):124
        1: from (irb):107:in `+'
ArgumentError (ArgumentError)
```

Works great, but returns `BigDecimal` and we want to add more `AnswerScore` object to each other to cleanup and simplify
our projection:

```ruby
def calculate_scores(test_id, participant_id)
  RailsEventStore::Projection
    .from_stream(stream_name(test_id, participant_id))
    .init(-> { NullScore.new( })
    .when(
      SurveyExecution::AnswerRegistered,
      ->(state, event) do
        state += AnswerScore.new(
          skill_id: event.data.fetch(:skill_id),
          score: event.data.fetch(:score)
        )
      end
    )
    .run(Rails.configuration.event_store)
    .reduce(&:+)
    .average_score
end
```

This won't work, we don't have a `NullScore`, we should implement it:

```ruby
class NullScore
  def +(other)
    raise ArgumentError unless AnswerScore === other

    other
  end

  def eql?(other)
    other.instance_of?(NullScore)
  end

  alias == eql?

  def hash
    NullScore.hash
  end
end
```

It just returns first real _Value object_, after addition. Great starting point for our projection than hacking
internals of `AnswerScore` to provide that behaviour.

## Be immutable

Getting back to the `AnswerScore`. We need to return a _Value object_ from our `AnswerScore` rather than raw
`BigDecimal` value. Adding two scores is no longer a score, we should return `ScoreSum`, probably.

```ruby
class AnswerScore
  def initialize(skill_id, score)
    @skill_id = skill_id
    @score = BigDecimal(score.to_s)
  end

  attr_reader :skill_id, :score

  def +(other)
    raise ArgumentError unless self.class === other
    raise ArgumentError if self.skill_id != other.skill_id

    ScoreSum.new(skill_id: skill_id, sum: score + other.score, n: 2)
  end

  def average_score
    score.round(2)
  end

  def eql?(other)
    other.instance_of?(AnswerScore) && skill_id.eql?(other.skill_id) && score.eql?(other.score)
  end

  alias == eql?

  def hash
    AnswerScore.hash ^ [skill_id, score].hash
  end
end

class ScoreSum
  def initialize(skill_id:, sum:, n:)
    @skill_id = skill_id
    @sum = BigDecimal(sum.to_s)
    @n = Integer(n)
  end

  attr_reader :skill_id, :sum, :n

  def +(other)
    raise ArgumentError unless AnswerScore === other
    raise ArgumentError if self.skill_id != other.skill_id

    ScoreSum.new(sum: sum + other.score, skill_id: skill_id, n: n + 1)
  end

  def average_score
    (score / n).round(2)
  end

  def eql?(other)
    other.instance_of?(ScoreSum) && skill_id.eql?(other.skill_id) && sum.eql?(other.sum) && n.eql?(other.n)
  end

  alias == eql?

  def hash
    ScoreSum.hash ^ [skill_id, sum, n].hash
  end
end
```

How it rolls:

```ruby
irb(main):254:0> AnswerScore.new(123, 0) + AnswerScore.new(123, 1)
=> #<ScoreSum:0x00000001137b3770 @skill_id=123, @sum=0.1e1, @n=2>
irb(main):255:0> AnswerScore.new(123, 0) + AnswerScore.new(123, 1) + AnswerScor
e.new(123, 1)
=> #<ScoreSum:0x0000000112030a30 @skill_id=123, @sum=0.2e1, @n=3>
irb(main):256:0> [AnswerScore.new(123, 0), AnswerScore.new(123, 1), AnswerScore
.new(123, 1)].reduce(&:+)
=> #<ScoreSum:0x00000001137a8938 @skill_id=123, @sum=0.2e1, @n=3>
```

What this gives us:
* the objects are immutable, every time we do some operation, the new object is returned
* we clearly explain our concept
* we can incorporate specific behaviour for `AnswerScore` and `ScoreSum`, eg. `average_score` method which for score is
  simply a score, but for `ScoreSum` it's a sum divided by number of elements

## Bad news
Our projection won't work now. Because current implementation in [Rails Event Store](https://railseventstore.org)
framework doesn't allow that. Initial implementation worked because we used the `Hash` to maintain our state and we were
mutating on and on the same instance
of it😱

## But there is light

```ruby
WeDontDoThatHere = Class.new(StandardError)

def calculate_scores(test_id, participant_id)
  Rails
    .configuration
    .event_store
    .read
    .stream(stream_name(test_id, participant_id))
    .map do |event|
      case event.event_type
      when 'SurveyExecution::AnswerRegistered'
        AnswerScore.new(
          skill_id: event.data.fetch(:skill_id),
          score: event.data.fetch(:score)
        )
      else
        raise WeDontDoThatHere
      end
  end
  .reduce(&:+)
  .average_score
end
```

Does the same, and even looks less magical, at least to me. And the `NullScore` is obsolete now, we do `map`—`reduce`
and there it is.