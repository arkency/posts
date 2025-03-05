---
created_at: 2025-03-04 13:00:00 +0100
author: Mirosław Pragłowski
tags: ['actor-model', 'ractor', 'ruby']
publish: true
---

# Ractor - getting started

This is just my notes from learning.
Just remember:

> warning: Ractor is experimental, and the behavior may change in future versions of Ruby! Also there are many implementation issues.

You have been warned. Let's start:

## Creating an actor

A simple actor is created as follows:

```ruby
simple = Ractor.new do
  # do something
end
```

<!-- more -->

You can pass arguments to a created actor using the actor's initializer. You can also set a name for an actor here.
Arguments that are passed to `Ractor.new()` become block parameters for the given block. However, an interpreter does not pass the parameter object references, but rather sends them as messages.

```ruby
obj = Object.new
val = "I'm a value"

simple = Ractor.new(obj, val, name: "Simple actor") do |obj, val|
  "#{name} has: obj: #{obj.object_id}, val: #{val.object_id}"
end

puts "Created here: obj: #{obj.object_id}, val: #{val.object_id}"
puts simple.take
```

If you check the results:

```
Created here: obj: 167328, val: 167336
Simple actor has: obj: 167344, val: 167352
```

It's clear that the number of arguments that have been passed is not the same as the number created. [See more...](https://docs.ruby-lang.org/en/3.4/ractor_md.html#label-Send+a+message+by+copying)

Another thing to keep in mind is:
```
> simple
=> #<Ractor:#5 Simple actor (irb):57 terminated>
```

This simple actor has yielded the result and it is now terminated.  It won't accept any more messages, which causes an error:

```
> simple.send "anything"
<internal:ractor>:600:in 'Ractor#send': The incoming-port is already closed (Ractor::ClosedError)
```

Also, you can't get the result again because it has already been taken from the output mailbox.

```
> simple.take
<internal:ractor>:711:in 'Ractor#take': The outgoing-port is already closed (Ractor::ClosedError)
```

You can define an actor as something that yields message repeatedly. Each `take` will "consume" single yield.

```ruby
up_to_3_times = Ractor.new do 
  Ractor.yield 3
  Ractor.yield 2
  Ractor.yield 1
end
```

Interesting thing is the `up_to_3_times` actor yields 4 values.

```
> up_to_3_times.take
=> 3
> up_to_3_times.take
=> 2
> up_to_3_times.take
=> 1
> up_to_3_times.take
=> nil
> up_to_3_times.take
<internal:ractor>:711:in 'Ractor#take': The outgoing-port is already closed (Ractor::ClosedError)
```

The first 3 works as expected. But there is 4th one that yields a `nil` value. That's because block return value is also yielded by an actor. Updated actor:

```ruby
up_to_3_times = Ractor.new do
  Ractor.yield 3
  Ractor.yield 2
  Ractor.yield 1
  "finished here"
end
```

It produces:

```
> loop { puts up_to_3_times.take }
3
2
1
finished here
=> nil
```

To avoid that you can use `close_outgoing` method.

```ruby
up_to_3_times = Ractor.new do
  Ractor.yield 3
  Ractor.yield 2
  Ractor.yield 1
  close_outgoing
end
```

It produces:

```
> loop { puts up_to_3_times.take }
3
2
1
=> nil
```

The samples above have already used the actor's communication mechanism. But let's dive into it and intentionally send & receive messages.

## Sending & receiving messages

Actors communicate with other parts by sending and receiving messages. Here is an example of an actor that receives a string of text and displays it in upper case:

```ruby
upcase = Ractor.new do
  msg = Ractor.receive
  Ractor.yield msg.upcase
end
```

The actor is waiting for a message. To send a message, use:

```
> upcase.send "abc"
=> #<Ractor:#14 (irb):123 running>
```

The actor now has received a message, processed it and yielded the result to the outbox. To check the result you need to take it from the actor's outbox.

```
> upcase.take
=> "ABC"
```

Just remember this is short-lived actor. So let's make it alive for some more time.

## Long running actors

If you want you actor to stay for a while and process more than single message the implementation could be similar to:

```ruby
upcase = Ractor.new do
  loop do
    Ractor.yield receive.upcase
  end
end
```

Now we could make some texts all capital letters multiple times:

```
upcase.send "aaa"
upcase.send "bbb"
upcase.send "ccc"
```

Whenever we send a message to an actor, it will go into their inbox. The `receive` method will get the message from the inbox. Then, the actor can process it. Finally a processed message will be placed in the actor's outbox. Then we can get the results:

```
> loop { puts upcase.take }
AAA
BBB
CCC
```

But wait. The `loop` isn't finished. We've entered an infinite loop. The `upcase` actor is waiting for the next message to process. The `receive` method waits for any message in the actor's inbox. The main thread is in an infinite loop, waiting for a new message in the actor's outbox. The `take` method blocks execution until any message is available. This is what happens when you use this type of actor communication in the example.

## Types of actor's communication

There are two ways actors can communicate:

* Push type
  * Using the `send` & `receive` method pair
  * The sender knows the destination of the message
  * The receiver does not know the sender, and it accepts all messages
  * The `send` puts a message in the receiver's infinite inbox queue, and it does not block the execution
  * The `send` is non-blocking, and the `receive` waits for any message to be available in the actor's inbox
  * Used by most actor-based languages
* Pull type
  * Using the `yield` & `take` method pair
  * The sender yields the message, but it does not know its destination
  * The receiver knows the sender and takes the message from its outbox
  * The receiver will block when there is no message
  * Both `yield` & `take` are blocking execution. The outbox could have only one message, and `yield` waits until the previous message is taken from the actor's outbox The `take` method blocks execution and waits for a message to be available in the actor's outbox

## Actor's lifecycle

Actor lives as long as its incoming port is open.
In this example:

```ruby
r = Ractor.new do
  loop do
    close_incoming if receive == 0
  end
  "I'm done"
end
```

We could see the behavior:
```
> r
=> #<Ractor:#18 (irb):93 running>
```
The actor is alive and waits for incoming messages.

```
> r.send 123
=> #<Ractor:#18 (irb):93 running>
```
When a message is received, it is processed, and the actor keeps running.

```
> r.send 0
=> #<Ractor:#18 (irb):93 terminated>
```
When the system receives a termination message, it closes the incoming port (meaning it stops accepting incoming messages) and marks the actor as "terminated." If you try to send another message to the actor after this, you'll get an error.
```
> r.send 42
<internal:ractor>:600:in 'Ractor#send': The incoming-port is already closed (Ractor::ClosedError)
```

However, we could still send the message to the actor's outbox.
```
irb(main):102> r.take
=> "I'm done"
```
The message was placed there because the actor was having difficulty thinking of new lines. We can see that `close_incoming` also breaks the actor's infinite loop.

Next, when you try to send a message from the outbox, you get an error.
```
> r.take
<internal:ractor>:711:in 'Ractor#take': The outgoing-port is already closed (Ractor::ClosedError)
```

If we run the same tests again using the `close_outgoing` method (which closes the actor's outgoing port) we'll see something interesting 

```ruby
r = Ractor.new do
  loop do
    close_outgoing if receive == 0
  end
  "I'm done"
end
```

At the beginning, the actor is alive and running.
``` 
> r
=> #<Ractor:#19 (irb):105 running>
```

It accepts messages:
```
> r.send 123
=> #<Ractor:#19 (irb):105 running>
```

The termination message does not change actor's state:
```
> r.send 0
=> #<Ractor:#19 (irb):105 running>
```

The actor still accepts messages:
```
> r.send 42
=> #<Ractor:#19 (irb):105 running>
```

But message cannot be fetched from the actor's outbox:
```
> r.take
<internal:ractor>:711:in 'Ractor#take': The outgoing-port is already closed (Ractor::ClosedError)
```

However, the actor is still running:
```
irb(main):116> r
=> #<Ractor:#19 (irb):105 running>
```

If there's an error in the actor's execution block, things are a bit different.

```ruby
r = Ractor.new do
  loop do
    raise "Error" if receive == 0
  end
  "I'm done"
end
```

At the start, the actor runs and reads incoming messages.
```
irb(main):123> r.send 123
=> #<Ractor:#20 (irb):117 running>
```

After the termination message an error is thrown and the actor is terminated:
```
irb(main):124> r.send 0
#<Thread:0x000000011fd64000 run> terminated with exception (report_on_exception is true):
(irb):119:in 'block (2 levels) in <top (required)>': Error (RuntimeError)
```

The actor is terminated and won't accept any more messages:
```
> r
=> #<Ractor:#20 (irb):117 terminated>
> r.send 42
<internal:ractor>:600:in 'Ractor#send': The incoming-port is already closed (Ractor::ClosedError)
```

It also does not allow to take messages from its outbox either:
```
> r.take
<internal:ractor>:711:in 'Ractor#take': thrown by remote Ractor. (Ractor::RemoteError)
```

## Summary

> one actor is no actor, they come in systems

That's just the beginning...

More reading:

* [Actor model - wikipedia](https://en.wikipedia.org/wiki/Actor_model)
* [Hewitt, Meijer and Szyperski: The Actor Model (everything you wanted to know...)](https://www.youtube.com/watch?v=7erJ1DV_Tlo)
* [The actor model in 10 minutes](https://www.brianstorti.com/the-actor-model)
* [RActor class documentation](https://docs.ruby-lang.org/en/3.4/Ractor.html)
* [Ractor - Ruby’s Actor-like concurrent abstraction](https://docs.ruby-lang.org/en/3.4/ractor_md.html)
* [Introduction to Software Architecture with Actors](https://github.com/denyspoltorak/publications/blob/main/IntroductionToSoftwareArchitectureWithActors)
