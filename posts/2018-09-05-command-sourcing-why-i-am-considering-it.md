---
title: "Command sourcing - why I am considering it"
created_at: 2018-09-05 09:03:27 +0200
publish: true
author: Andrzej Krzywda
tags: [ 'ddd' ]
---

If you've been following me over the last years, you know that recently I've been very interested in event sourcing. Command sourcing sounds very similar and indeed there are similarities. But on the other hand, it's something completely different. We have been trying to introduce command sourcing to one of our projects and it requires us to address so many different aspects of it. 

<!-- more -->

Therefore, I will try to gradually get you familiar with what it's about, why we use it and what kind of problems we're trying to solve. Today, I'll try to stay simple and maybe in the next blog posts I will delve deeper into the subject. 

The idea of command sourcing is about persisting commands. A command is a user's intent to change the system or other system's intent to change our system state. We persist commands in a command store. In our case we just reuse an event store to kind of fake a command store. We just store another message type there. 

The persisted commands allow us to replay the whole state of our system. And here is one difference as compared with event sourcing, at least as compared with our approach to command sourcing and event sourcing: with event sourcing you never replay or source the whole system from events. You only do it per one read-model, usually per aggregate or per process manager, or you have a projection and load some state into memory. Usually it's a small state and it's fast and there are no performance penalties overall, because it's usually a short stream of events. 

But with command sourcing, at least the way we approach it, it's different. We do assume that it causes a performance hit, so command sourcing is not something that we do very often, at least not in the first phases. It's something that we consider doing with our system from time to time. Even if it takes one hour or two, we can do it under the hood and then just replay the system state. This way, we replay the whole system and all the users' requests to it.

Obviously not all projects sound like a good fit for that. In our case we think it's a good fit because we do complicated batch processing and batch calculations involving many edge cases, which means that sometimes things can go wrong. And the idea of command sourcing is to have a second weapon to use in situations when we notice that our calculations went wrong. If that is the case, we want to replay the system from all the commands and get a new state that is different from the current state because, hopefully, it contains fixes to the calculations. 

In a way, we can imagine that we can rebuild our system from one year of commands and get a new state. Obviously it has big implications and I'm going to cover them in the next episodes. For example, if any part of our system is leaking to other systems, then things can get complicated.

Moreover, when we replay the commands, it's not really the same system that we're replaying, because we inject or connect different dependencies. So usually when we have some kind of communication with another system, we do it through an adapter object. It means that during replaying we don't want to contact the other system. That is why during the replaying phase we  use an in-memory adapter which doesn't really contact the third-party system. But then again, to be very specific, it's about our project which doesn't really contact third parties that much. And even if it does, it happens very sporadically and always under control. So this is not a big issue for us. 

There is also another problem that command sourcing solves as a side effect. If you already do event sourcing, then you probably know it's cool and awesome, but there is one challenging thing about it. And this thing is called event versioning. Over the time of development, when you want to have one event, but then you realize that this event should actually have different properties, sooner or later you end up with the idea of an event version. So you have two different events or two versions of one event, which mean the same but have different properties, and your system needs to know how to deal with both of them, because they already live in the history and you never reject the history.

Consequently, you end up with two different events. Obviously there are ways to deal with it, so it's not the end of the world. You can convert those events into new versions of the events during loading or some other techniques. There's a fantastic book by Greg Young called "Event Versioning." I think it's free when you read it online, so you can easily google it. 
When you end up with those different versions of events and you have command sourcing, you can always rebuild the system from the commands, and as a result, have the events in their newest version. Indeed this is a nice side effect, but it can actually have a significant impact on the time and ease of development. So that's one reason why we want to do it. But of course there are more and I will cover them later. For now, I hope I managed to explain to you what command sourcing is generally about. Thanks for reading!

# REScon

If you like this topic of adding events to legacy (Ruby) applications, then attending [REScon](https://mailchi.mp/arkency/rescon/) might be a good idea. We'll show more advanced techniques how to gradually get out of the existing Rails Way architecture and turn it inot loosely-coupled event-driven application. As part of REScon we have 3 events (each can be attended/bought separately):

- 1-day Rails/DDD workshop - $400
- 1-day conference (talks about using DDD/events with Rails and [RailsEventStore](http://railseventstore.org)) - $200
- 1-day hackathon - FREE

All in beatiful Wrocław, Poland.

<iframe width="560" height="315" src="https://www.youtube.com/embed/tCiLgbHGhnw" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

 

