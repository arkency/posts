---
title: "Rename stream in Rails Event Store with zero downtime"
created_at: 2020-04-27 10:06:09 +0200
author: Mirosław Pragłowski
tags: ['ddd', 'rails event store', 'domain event']
publish: false
---

A question has been posted on our Arkency's slack today:

> How to rename stream in event store?
> Is `link` & `delete_stream` enough to do it?
> Asking for a friend ;)

At first it looks quite easy. Sure, we can! Just link add events from source stream
to target stream, then change publisher to write to new stream and use `delete_stream`
method of Rails Event Store to remove old stream.

> Ahhh, and of course we must handle incoming domain events, with zero downtime.

And now where the fun begins :)

<!-- more -->

## Naive approach

The concept is still the same:

1. link all events from source stream to target stream
2. switch publisher to write to target stream
3. delete source stream


But having publisher constantly writing to source stream creates a few problems to handle.

Source stream could not be just switched to target stream when all source stream's events
are linked to target stream. There could be a race condition and after we link last event
and switch publisher to target stream new domain events could be published in source stream.
This of course will be bad as we could loose some domain events.


## Catchup subscription FTW

So let's use catchup subscription to ... you know... catch up with source stream and only then
switch to the target stream.

This time concept is:

1. publisher is constantly publishing new domain events to a stream, which is
  defined in some data store,
2. catchup subscription reads a chunk of events from source stream (never read too much,
  some streams might have a lot of events), and then:
  - if there are more events in source stream, link them to target stream and fetch next chunk of events
  - if the subscription is catched up with source stream (we have both streams with the same events)
    then do the switch of stream in publlisher's data store. Since now publisher will be writting to
    the target stream
3. delete source stream


## Race conditions again

But there is a catch. Race condition. Or I should say race conditions.
There are moments in code execution where we still miss some domain events.

- after we catchup with source stream and before we make the switch new events might be published
  in source stream,
- publisher might fetch current stream from data store and then catchup process can make the switch,
  this time publisher will still write to source stream, and we will miss some events again

## Get yourself a lock!

We need to have a lock on 2 critical operations here.
First while fetching source stream events and making a switch
of target stream on catchup process. And second while publisher fetches current stream from
data store and write new events to it.

## Code spike to demonstrate this concept

I've spent some time today to experiment how to implement this with the Rails Event Store.
Or actually with Ruby Event Store. I do not need Rails for that, just pure Ruby.

Let's setup some basic objects

```ruby
require 'ruby_event_store'

event_store = RubyEventStore::Client.new(
  repository: RubyEventStore::InMemoryRepository.new,
  mapper: RubyEventStore::Mappers::NullMapper.new
)

FooEvent = Class.new(RubyEventStore::Event)
```

This code will create a new instance of `RubyEventStore::Client` using in memory repository
and `NullMapper` just to skip some friction. Then it defines a sample domain event class.


So now our publisher (simulated):

```ruby
def publish(stream)
  index = 0
  while(true) do
    stream.publish(FooEvent.new(data: {index: index}))
    puts "#{index} published to stream: #{stream}"
    sleep(Random.rand(1.1) / TIME_UNIT)
    index += 1
  end
end
```

Is just a method that constantly publish a new domain event (with index) to some stream.
The `stream` here will be the most interesting part here.

Then the catchup process:

```ruby
def catchup(stream)
  processed = nil
  while(true)
    events = stream.catchup(processed)
    break if events.empty?
    events.each do |event|
      stream.link(event)
      puts "#{event.data[:index]} linked to stream: target"
    end
    processed = events.last.event_id
    sleep(Random.rand(1.0) / TIME_UNIT)
  end
end
```

As described it fetch some events from source stream and link them to target stream.
It stops when there is nothing more to read from source stream.


Please notice the difference in:

```ruby
# publish
    sleep(Random.rand(1.1) / TIME_UNIT)

# catchup
    sleep(Random.rand(1.0) / TIME_UNIT)
```

To give a catchup process a chance to finally catchup with source stream it must process
events a little faster then they are published by publisher.
A `TIME_UNIT` is just a constant to define how fast you want this experiment to process events.

```ruby
WAIT_TIME = 0.5
publish = Thread.new {publish(stream)}
sleep(WAIT_TIME)
puts "Starting catchup thread"
catchup = Thread.new {catchup(stream)}


catchup.join
puts "Catchup thread done"
sleep(WAIT_TIME)
publish.exit
puts "Publish thread done"

puts "Source stream:"
puts (source_events = event_store.read.stream("source").map{|x| x.data[:index]}).inspect
puts "Target stream:"
puts (target_events = event_store.read.stream("target").map{|x| x.data[:index]}).inspect

raise "FAIL"  unless target_events[0, source_events.size] == source_events
puts "DONE - now remove source stream"
```

To check if the me experimental code works I start 2 threads. First will be the publisher
(executing the `publish` method). Second will be the catchup process (executing the
`catchup` method). Before catchup process starts it will wait for some time - just
to let publisher write some events to source stream. Then after catchup thread is finished I will
wait again some time to let publisher publish a few more events - this time to target stream.

And finally some assertion to check if target stream starts with all events from source stream.

## The StreamSwitcher

```ruby
class StreamSwitch
  def initialize(event_store, source, target, lock: Mutex.new)
    @event_store = event_store
    @current = source
    @source = source
    @target = target
    @lock = lock
  end

  def publish(event)
    @lock.synchronize do
      @event_store.publish(event, stream_name: @current)
    end
  end

  def catchup(processed)
    @lock.synchronize do
      scope = @event_store.read.stream(@source).limit(5)
      scope = scope.from(processed) if processed
      events = scope.to_a
      change if events.empty?
      events
    end
  end

  def link(event)
    @event_store.link(event.event_id, stream_name: @target)
  end

  def to_s
    @current
  end

  private
  def change
    @current = @target
  end
end
```

Here is the logic. The `publish`, `catchup` & `link` methods are called by
publisher & catchup threads. The `publish` will always write domain event to
current stream. Notice that it uses the synchronized block to avoid race conditions.
The same lock is used by `catchup` method to avoid race condition where we read source stream
and - if there is no more events to link - do the change of current stream.

I've used a `Mutex` class here to synchronize critical operations - but this is only experimental code,
**not production ready**. In real life scenario the lock should depend on what kind of `EventRepository`
you are using in your system. If you store tour domain events in SQL database consider named locks to implement
a synchronization.


## The result

Here sample execution for `TIME_UNIT = 10.0`:

```bash
~/arkency$ ruby rename-stream.rb
0 published to stream: source
1 published to stream: source
2 published to stream: source
3 published to stream: source
4 published to stream: source
5 published to stream: source
6 published to stream: source
Starting catchup thread
0 linked to stream: target
1 linked to stream: target
2 linked to stream: target
3 linked to stream: target
4 linked to stream: target
5 linked to stream: target
6 linked to stream: target
Catchup thread done
7 published to stream: target
8 published to stream: target
9 published to stream: target
10 published to stream: target
11 published to stream: target
12 published to stream: target
13 published to stream: target
14 published to stream: target
15 published to stream: target
Publish thread done
Source stream:
[0, 1, 2, 3, 4, 5, 6]
Target stream:
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
DONE - now remove source stream
```

Looks very simple. But play a bit with it. It looks much more interesting when `TiME_UNIT = 100000.0`.

Now you could finally remove the source stream:

```ruby
event_store.delete_stream("source")
```

BTW Neither `link` nor `delete_stream` does not affect any domain event in any way.
Stream is just a grouping mechanism for domain events. Once you write domain event to event store
it could not be deleted (at least not without use of rails console :P).




## Make your own experiments

Code is fun! Go play with it! Here is the [source of code spike](https://github.com/RailsEventStore/rails_event_store/blob/master/contrib/scripts/rename-stream.rb) for this blog post.
