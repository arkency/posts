---
created_at: 2026-05-31 15:42:04 +0200
author: Łukasz Reszke
tags: ['event sourcing']
publish: false
---

# Storing data as a sequence of events - RubyConfA lightning talk supplement

This post originated from the lightning talk and the discussions I had afterward at [RubyConfAt](http://rubyconf.at). 

It was a great conference. Especially the music part was amazing. Big kudos and applause to the organizers, once again! 

## The Lightning Talk
During my lightning talk I discussed an alternative way of storing data in Ruby applications. The alternative way is to store data as a sequence of events. 

It all starts with admitting the fact that an **update of data causes information loss**. We do know **what** it is now - we see the current state in a database column. But we don’t know **how** we got there. Context is lost.

Event sourcing solves that problem by storing each change as an event in our database. 

## What is an event?
An event represents a fact, something that happened in our system. It’s **immutable** - once persisted, it cannot be changed.

An event consists of a name, event_id, data, and metadata.

An example of an event is `ShipmentPacked`. This event tells us, well, that a shipment has been packed. No surprise. And that’s also an important aspect. We want event names to be self-explanatory and follow the language that business speaks. Having an event named `ShipmentUpdated` is not a good event sourcing event name. It’s too vague. It doesn't tell us what happened in the system.

### Common misconception #1 - Immutable is problem

The first common misconception that has to be addressed is this:
The fact that the event is immutable doesn’t mean you cannot change data!

Event sourcing draws from the accounting domain in that case. 
If you make a mistake with the data, you make a correction. 

The cool part also comes when you analyze different kinds of mistakes and their consequences. 

Consider the following: a developer made a mistake in the code. 

Ok, so then they write migration script to address it. 

Unfortunately they make another mistake. 

*Oshit.jpg what now?*

It’s up to you. You can either start from the beginning (before the first attempt) or continue from the second mistake. All the data is already in place. You do what’s easier. There are patterns to deal with that so you don’t need to reinvent the wheel. 

## Event Sourcing


I highlighted that during my lightning talk and I’ll do it again here. Better twice than sorry :)

**Event sourcing is just another persistence technique.**

Instead of storing current state, events are stored. 
Those events are used to rebuild the state when needed. 
A decision is made based on the state. 
Just like with the CRUD approach we’re used to. 
The difference is state rebuilding. 

### Common misconception #2 - rebuilding starts from the beginning of the universe


There’s a common misconception that I need to address, though. To rebuild the state **you don’t need to load all events since the beginning of the universe.** You just read the exact events that you need to make a decision. No more. And this is where streams kick in. 


## Streams 


A stream is a logical representation of a business concept. 
It gathers all events belonging to that concept.


In the packing example, it's all about packing a specific shipment, with id 1234. 
Then the `ShipmentPacked` event would belong to the `Shipment$1234` stream. 

*Side note: the dollar sign is just stream naming convention. It’s not necessary.*


You can think about a stream similarly to an entity represented by an `ActiveRecord` model. It’s just built differently using so-called projections. 

Projections read all events from a specific stream to build the state of an object and make a specific decision. 

### Another case for streams

Representing a specific business concept is not the only use case for a stream.

In [RailsEventStore](railseventstore.…) an event can be linked to multiple streams. 
You can use this technique to answer interesting business questions.

Let’s look at a specific example. 

Imagine you're organizing a conference in Vienna. 
You could be interested in the number of tickets sold on a specific day. 
To achieve that you should link all `TicketPurchased` events to `Ticket_sold_at_${Date.current}` stream.

We can go even further. If we had other events representing speaker, talk, agenda, or fun activities announcement, you could link all those events together, build a timeline (or feed an agent), and figure out what has the biggest impact on sales. 

Cool, isn’t it? 

## Common misconception #3 - it's slow

It must be slow to display data, isn’t it? 


No, it is not. And more often it will be even faster than a regular approach. 
That’s actually what Andrzej mentioned in his talk. 

Use events to build read models. 

The way we often do it is that we move the pressure from reads to writes. This means that instead of having a long-running query, we’ll prepare the read model that the user displays upfront, based on specific events. 

## Summary

There are many more aspects of event sourcing that I’d love to discuss in more detail. However, this is a good start. In general, I am very happy that we are starting to talk more about events in the Ruby community and that we allow ourselves to think outside of the Rails Way. Which is awesome, btw, up to a certain point. I hope that I’ll have a chance to discuss more interesting aspects like anti-patterns, case studies with happy endings that had some stress involved (aka fuckup stories) in upcoming conferences! 

But before this happens, I must write one more thing. Event sourcing is a tool that you should have in your toolbox. But it’s not a silver bullet. In my experience, it makes the important parts of an application better in many different ways. However, I do not apply it everywhere, nor do I recommend doing that. 

### Benefits recap

To recap the benefits I’ve talked about during the lightning talk: 
- No information is lost. Moreover, the data is richer because there’s additional metadata describing it
- It’s auditable 
- Debugging gets easier. You can see exactly how bits of your data changed, when they changed, by whom, and what caused each change. Super useful when you have business processes that involve multiple steps 
