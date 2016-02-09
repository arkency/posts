---
title: "From legacy to DDD: What are those events anyway?"
created_at: 2016-02-09 23:48:04 +0100
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

[In one of my previous posts](http://blog.arkency.com/2016/01/from-legacy-to-ddd-start-with-publishing-events/), I've suggested to start with publishing events. It sounds easy in theory, but in practice it's not always clear what is an event. 
The problem is even bigger, as the term event is used in different places with different meaning. In here, I'm focusing on explaining events and commands, with their DDD-related meaning.

<!-- more -->

**Events are facts**. 

They happened. There's no arguing about it. That's why we name them in past tense:

```
UserRegistered
OrganizationAllowedToUseTheApp
OrderConfirmed
```

If those are only facts, then what is the thing which is the request to make the fact happen?

Enter commands.

Commands are the objects which represent the intention of the outside world (usually users). A command is like a request:

```
RegisterUser
AllowOrganizationToUseTheApp
ConfirmOrder
```

It's like someone saying "Please do it" to our system.

Usually handling commands in the system, causes some new events to be published.

**Commands are the input**.
**Events are the output**.

Both commands and events are almost like only data structures. They contain some "params".

It's important to note, they're not responsible for "handling" any action. 

For now, just remember:

**commands are requests**
**events are facts**
