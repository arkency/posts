---
title: "Event scout rule"
created_at: 2018-09-04 13:54:21 +0200
kind: article
publish: true
author: Andrzej Krzywda
tags: [ 'ddd' ]
newsletter: :skip
---

Recently I came up with a new name for an existing technique that I have been suggesting over the last few years. It is connected with applying domain-driven design, event sourcing or event-driven architecture to various existing applications. 

<!-- more -->

The idea is that when you start a new application and you already know how to do events, event-driven architecture or event sourcing, then from a technical perspective, it’s all quite easy. You simply add a new feature and all is event-driven from the beginning. 

# Legacy apps

In the case of existing applications, however, it's a bit more complicated, because there are no events. Building a new feature in an existing application is hard, because when you get down to it, you realize you are missing many events that could prove useful once you decide to build this feature in the event-driven way right from the start. The feature can be, for example, a read model or improving performance of a read model or improving performance of reading a report. Another example is a feature changing the business logic. Still, the problem is that you have no events.

The technique I'm talking about is unintuitive and that's why I think it's more a discipline than something you do by intuition. It's probably similar to TDD, which is also a discipline. 

# The event scout rule

The idea is that, when working on an existing system, at some point you decide to go event-driven. Then, in the course of work on a feature, you may realize that you know how to build it quickly and easily without being event-driven, and so you do it like that, not in the event-driven way. But you also add publishing events to the existing code, even though you are not going to use them just yet. So in a way, it's an unused code or a dead code. It serves the logging purpose in the application rather than anything else at that time. You publish an event, for example, you've just changed the registration procedure and you can find the key moment in time, let's say it's a service object, application service or aggregate, when you can clearly say the user was registered. You publish a "UserRegistered" event and you add some attributes to it: maybe a user ID is enough. 

You're not using the UserRegistered event yet, but if you do it regularly, like every day, every feature, every week, then after a year you will probably have a hundred of events in your application. And one year from now you will thank yourself for doing it, after you realize that you can use these events to build new features. It means that you have been systematically building **the event coverage**.

I call this technique **the event scout rule**, because it's similar to the scout rule that I hope many programmers are familiar with. 

# The scout rule

The scout rule says: leave the code which you touched, or even just read or looked at, a little bit better. Namely, improve the naming, the structure or maybe just make some small refactorings, extract some new methods or a small class. Don't do huge changes, but make the life of the next person dealing with the code slightly easier. Maybe it will be you one month from now.

# Always leave the place with more events

And it's the same with events: always leave the place with more events, so that one day you can benefit from that. You or some other colleagues. It’s not an easy technique, in fact it's a discipline. It may not make sense at the beginning, because you don't see the benefits right away, but to my knowledge, it's the only technique that allows you to say one day: "Oh, I actually have all or almost all the events ready! So I'll just add the three missing events as part of the feature.” 

This will be the first feature built fully in the event-driven way. And that's the goal. But we have to remember that events will not add themselves, right? You have to add them, even though people will not see the benefits right away. Maybe it will also make the life of code reviewers a little bit harder. 

# It's just a few lines

But still, it's just adding a few lines of code in certain places, maybe passing the dependency to the event store or event bus. Sometimes, you will have to add human factor to the process, as it may turn out necessary to discuss why you are doing this. But once you start doing it and people start to see its value, all doubts will disappear and you can continue doing it every day, every week, every month.

I said before that you will see the benefits of the technique after about a year, but actually it can be much faster. If you are working on one area for most of the time, perhaps you will be able to see the benefits in one month’s time, which means the technique can bring short-term benefits as well.

```ruby
class CancelOrdersService
  def call(order_id, user_id)
    order = Order.find_by!(
      customer_id: user_id,
      order_id: order_id,
    )
    order.cancel!
    publish_event(order)
  end

  private

  def publish_event(order)
    event_store.publish(
      OrderCancelled.new(data: {
        order_id: order.id,
        customer_id: order.customer_id,
      }),
      stream_name: "Order-#{order.id}"
    )
  end
  
  def event_store
    Rails.configuration.event_store
  end
end
```

# REScon

If you like this topic of adding events to legacy (Ruby) applications, then attending [REScon](https://mailchi.mp/arkency/rescon/) might be a good idea. We'll show more advanced techniques how to gradually get out of the existing Rails Way architecture and turn it inot loosely-coupled event-driven application. As part of REScon we have 3 events (each can be attended/bought separately):

- 1-day Rails/DDD workshop - $400
- 1-day conference (talks about using DDD/events with Rails and [RailsEventStore](http://railseventstore.org)) - $200
- 1-day hackathon - FREE

All in beatiful Wrocław, Poland.

<iframe width="560" height="315" src="https://www.youtube.com/embed/tCiLgbHGhnw" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

Happy event publishing! 
