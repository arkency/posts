---
created_at: 2025-03-04 13:00:00 +0100
author: Mirosław Pragłowski
tags: [actor-model ractor ruby]
publish: false
---

# Ractor - getting started

This is just my notes from learning.
Just remember:

> warning: Ractor is experimental, and the behavior may change in future versions of Ruby! Also there are many implementation issues.

You have been warned. Let's start:

## Creating an actor

The simple actor is created as:

```ruby
simple = Ractor.new do
  # do something
end
```

<!-- more -->

You could pass some arguments to created actor using actor's initializer. You could also set a name for an actor here.
Passed arguments to `Ractor.new()` becomes block parameters for the given block. However, an interpreter does not pass the parameter object references, but send them as messages.

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

You could see that the instances of passed arguments are not the same as it has been created. (See more..)[https://docs.ruby-lang.org/en/3.4/ractor_md.html#label-Send+a+message+by+copying]

Another thing worth notice is:
```
> simple
=> #<Ractor:#5 Simple actor (irb):57 terminated>
```

This simple actor has yielded the result and it is now terminated. It won't accept next messages resulting in an error:

```
> simple.send "anything"
<internal:ractor>:600:in 'Ractor#send': The incoming-port is already closed (Ractor::ClosedError)
```

And also it won't allow to fetch the result again as it has been already taken from output mailbox:

```
> simple.take
<internal:ractor>:711:in 'Ractor#take': The outgoing-port is already closed (Ractor::ClosedError)
```

You could define actor that yields message multiple times. Each `take` will "consume" single yield.

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

The first 3 works as expected. But there is 4th one that yields `nil` value. That's because block return value is also yielded by an actor. Updated actor:

```ruby
up_to_3_times = Ractor.new do
  Ractor.yield 3
  Ractor.yield 2
  Ractor.yield 1
  "finished here"
end
```

produces:

```
> loop { puts up_to_3_times.take }
3
2
1
finished here
=> nil
```

To avoid that you could use `close_outgoing` method.

```ruby
up_to_3_times = Ractor.new do
  Ractor.yield 3
  Ractor.yield 2
  Ractor.yield 1
  close_outgoing
end
```

produces:

```
> loop { puts up_to_3_times.take }
3
2
1
=> nil
```

The samples above have already used actor's communication mechanism. But let's dive into it and intentionally send & receive messages.

## Sending & receiving messages

Actors communicate with other parts by incoming & outgoing messages. Here the simple example of an actor that receives incoming string and yields it in upper case:

```ruby
upcase = Ractor.new do
  msg = Ractor.receive
  Ractor.yield msg.upcase
end
```

Now the actor is waiting, until it will receive a message. To send a message use:

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

Now we could make some texts uppercase multiple times:

```
upcase.send "aaa"
upcase.send "bbb"
upcase.send "ccc"
```

Each time we send a message to an actor it will be placed in actor's inbox, the `receive` method will fetch it from the inbox, then actor could process it and finally a processed message is placed in the actor's outbox. Then we could get the results:

```
> loop { puts upcase.take }
AAA
BBB
CCC
```

But wait. The `loop` is not finished. We've got into an infinite loop. The `upcase` actor is waiting for next message to process - `receive` method waits for any message in actor's inbox. And the main thread is in infinite loop waiting for a new message in actor's outbox - `take` method block execution until any message is available. That's the result of type of actor's communication we have implemented in the example.

## Types of actor's communication

There are 2 types of communication between actors:

* push type
  * using `send` & `receive` method pair
  * sender knows the destination of the message
  * receiver does not know the sender, accepts all messages
  * `send` puts a message in the receiver infinite inbox queue, it does not block the execution
  * `send` is non-blocking, `receive` waits for any message to be available in actor's inbox
  * used by most actor's based languages
* pull type
  * using `yield` & `take` method pair
  * sender yields the message, but does not know its destination
  * receiver knows the sender and takes message from its outbox
  * receiver will block when there is no message
  * both `yield` & `take` are blocking execution, outbox could have only single message and `yield` waits until previous message is taken from the actor's outbox, `take` blocks execution and waits for a message to be available in actor's outbox

## Actor's lifecycle

Actor likes basically as long as its incoming port is open.
In this example:

```ruby
r = Ractor.new do
  loop do
    close_incoming if receive == 0
  end
  "I'm done"
end
```

We could observe the behaviour:
```
> r
=> #<Ractor:#18 (irb):93 running>
```
Actor is alive and waits for incoming messages.

```
> r.send 123
=> #<Ractor:#18 (irb):93 running>
```
When message is received it is processed and actor is still running.

```
> r.send 0
=> #<Ractor:#18 (irb):93 terminated>
```
When received termination message the incoming port is closed (actor does no longer accept incoming messages) and the actor state is `terminated`. Any next try to send a message to the actor will result in error:
```
> r.send 42
<internal:ractor>:600:in 'Ractor#send': The incoming-port is already closed (Ractor::ClosedError)
```

However we could still get the message placed in actor's outbox:
```
irb(main):102> r.take
=> "I'm done"
```
The message has been placed there as a result of actor's block. So we could see that `close_incoming` also breaks the actor's infinite loop.

Next try to take message from outbox results in an error:
```
> r.take
<internal:ractor>:711:in 'Ractor#take': The outgoing-port is already closed (Ractor::ClosedError)
```

If we reply the same tests with `close_outgoing` method (closing actor's outgoing port) we could see that:

```ruby
r = Ractor.new do
  loop do
    close_outgoing if receive == 0
  end
  "I'm done"
end
```

At the beginning actor's is alive & running:
``` 
> r
=> #<Ractor:#19 (irb):105 running>
```

It accepts messages:
```
> r.send 123
=> #<Ractor:#19 (irb):105 running>
```

Termination message does not change actor's state:
```
> r.send 0
=> #<Ractor:#19 (irb):105 running>
```

It still accepts messages:
```
> r.send 42
=> #<Ractor:#19 (irb):105 running>
```

But we could not fetch a message from actor's outbox:
```
> r.take
<internal:ractor>:711:in 'Ractor#take': The outgoing-port is already closed (Ractor::ClosedError)
```

However actor is still running:
```
irb(main):116> r
=> #<Ractor:#19 (irb):105 running>
```

When the error is thrown in the actor's execution block the situation is a little bit different

```ruby
r = Ractor.new do
  loop do
    raise "Error" if receive == 0
  end
  "I'm done"
end
```

At the beginning the actor is running and accepts incoming messages:
```
irb(main):123> r.send 123
=> #<Ractor:#20 (irb):117 running>
```

After termination message an error is thrown and the actor is terminated:
```
irb(main):124> r.send 0
#<Thread:0x000000011fd64000 run> terminated with exception (report_on_exception is true):
(irb):119:in 'block (2 levels) in <top (required)>': Error (RuntimeError)
```

The actor is terminated and does not accepts incoming messages anymore:
```
> r
=> #<Ractor:#20 (irb):117 terminated>
> r.send 42
<internal:ractor>:600:in 'Ractor#send': The incoming-port is already closed (Ractor::ClosedError)
```

It also does not allow to take messages from its outbox:
```
> r.take
<internal:ractor>:711:in 'Ractor#take': thrown by remote Ractor. (Ractor::RemoteError)
```

## Summary

> one actor is no actor, they come in systems

That's just the beginning...

More reading:

* [https://en.wikipedia.org/wiki/Actor_model]
* [https://www.youtube.com/watch?v=7erJ1DV_Tlo] - Hewitt, Meijer and Szyperski: The Actor Model (everything you wanted to know...)
* [https://www.brianstorti.com/the-actor-model]
* [https://docs.ruby-lang.org/en/3.4/Ractor.html]
* [https://docs.ruby-lang.org/en/3.4/ractor_md.html]
* [https://github.com/denyspoltorak/publications/blob/main/IntroductionToSoftwareArchitectureWithActors]
