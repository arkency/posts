---
created_at: 2025-03-04 13:00:00 +0100
author: Mirosław Pragłowski
tags: (actor-model ractor ruby)
publish: false
---

# Ractor - Getting Started

These are just my notes from learning. Just remember:

> Warning: Ractor is experimental, and the behavior may change in future versions of Ruby! Also, there are many implementation issues.

You have been warned. Let’s start:

## Creating an Actor

A simple actor is created as:

```ruby
simple = Ractor.new do
  # do something
end
```

You can pass some arguments to the created actor using the actor’s initializer. You can also set a name for an actor here. Passed arguments to `Ractor.new()` become block parameters for the given block. However, the interpreter does not pass the parameter object references but sends them as messages.

```ruby
obj = Object.new
val = “I’m a value”

simple = Ractor.new(obj, val, name: “Simple actor”) do |obj, val|
  “#{name} has: obj: #{obj.object_id}, val: #{val.object_id}”
end

puts “Created here: obj: #{obj.object_id}, val: #{val.object_id}”
puts simple.take
```

If you check the results:

```
Created here: obj: 167328, val: 167336
Simple actor has: obj: 167344, val: 167352
```

You can see that the instances of passed arguments are not the same as when they were created. [See more...](https://docs.ruby-lang.org/en/3.4/ractor_md.html#label-Send+a+message+by+copying)

Another thing worth noticing is:

```
> simple
=> #<Ractor:#5 Simple actor (irb):57 terminated>
```

This simple actor has yielded the result and is now terminated. It won’t accept new messages, resulting in an error:

```
> simple.send “anything”
<internal:ractor>:600:in ‘Ractor#send’: The incoming port is already closed (Ractor::ClosedError)
```

It also won’t allow fetching the result again as it has already been taken from the output mailbox:

```
> simple.take
<internal:ractor>:711:in ‘Ractor#take’: The outgoing port is already closed (Ractor::ClosedError)
```

You can define an actor that yields messages multiple times. Each `take` will “consume” a single yield.

```ruby
up_to_3_times = Ractor.new do
  Ractor.yield 3
  Ractor.yield 2
  Ractor.yield 1
end
```

An interesting thing is that the `up_to_3_times` actor yields 4 values.

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
<internal:ractor>:711:in ‘Ractor#take’: The outgoing port is already closed (Ractor::ClosedError)
```

The first three work as expected. But there is a fourth one that yields a `nil` value. That’s because the block return value is also yielded by the actor. Updating the actor:

```ruby
up_to_3_times = Ractor.new do
  Ractor.yield 3
  Ractor.yield 2
  Ractor.yield 1
  “finished here”
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

To avoid that, you can use the `close_outgoing` method.

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

The examples above have already used the actor’s communication mechanism. But let’s dive into it and intentionally send and receive messages.

## Sending & Receiving Messages

Actors communicate with other parts by incoming and outgoing messages. Here is a simple example of an actor that receives an incoming string and yields it in uppercase:

```ruby
upcase = Ractor.new do
  msg = Ractor.receive
  Ractor.yield msg.upcase
end
```

Now, the actor is waiting until it receives a message. To send a message, use:

```
> upcase.send “abc”
=> #<Ractor:#14 (irb):123 running>
```

The actor has now received a message, processed it, and yielded the result to the outbox. To check the result, you need to take it from the actor’s outbox.

```
> upcase.take
=> “ABC”
```

Just remember, this is a short-lived actor. So let’s make it last longer.

## Long-Running Actors

If you want your actor to stay alive for a while and process more than a single message, the implementation could be similar to:

```ruby
upcase = Ractor.new do
  loop do
    Ractor.yield Ractor.receive.upcase
  end
end
```

Now, we can make some texts uppercase multiple times:

```
upcase.send “aaa”
upcase.send “bbb”
upcase.send “ccc”
```

Each time we send a message to an actor, it will be placed in the actor’s inbox. The `receive` method will fetch it from the inbox, the actor will process it, and finally, the processed message will be placed in the actor’s outbox. Then we can get the results:

```
> loop { puts upcase.take }
AAA
BBB
CCC
```

But wait. The `loop` is not finished. We’ve entered an infinite loop. The `upcase` actor is waiting for the next message to process—`receive` waits for any message in the actor’s inbox. Meanwhile, the main thread is in an infinite loop waiting for a new message in the actor’s outbox—`take` blocks execution until any message is available. That’s a result of the type of actor communication we have implemented in this example.

## Types of Actor Communication

There are two types of communication between actors:

- **Push type**
  - Uses the `send` & `receive` method pair
  - The sender knows the destination of the message
  - The receiver does not know the sender and accepts all messages
  - `send` places a message in the receiver’s infinite inbox queue; it does not block execution
  - `send` is non-blocking; `receive` waits for any message to be available in the actor’s inbox
  - Used by most actor-based languages
- **Pull type**
  - Uses the `yield` & `take` method pair
  - The sender yields the message but does not know its destination
  - The receiver knows the sender and takes messages from its outbox
  - The receiver will block when there is no message
  - Both `yield` & `take` block execution; the outbox can only have a single message, and `yield` waits until the previous message is taken from the actor’s outbox

## Summary

> One actor is no actor; they come in systems.

That’s just the beginning...
More reading:

* [Actor model - wikipedia](https://en.wikipedia.org/wiki/Actor_model)
* [Hewitt, Meijer and Szyperski: The Actor Model (everything you wanted to know...)](https://www.youtube.com/watch?v=7erJ1DV_Tlo)
* [The actor model in 10 minutes](https://www.brianstorti.com/the-actor-model)
* [RActor class documentation](https://docs.ruby-lang.org/en/3.4/Ractor.html)
* [Ractor - Ruby’s Actor-like concurrent abstraction](https://docs.ruby-lang.org/en/3.4/ractor_md.html)
* [Introduction to Software Architecture with Actors](https://github.com/denyspoltorak/publications/blob/main/IntroductionToSoftwareArchitectureWithActors)
