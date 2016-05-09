---
title: "The anatomy of Domain Event"
created_at: 2016-05-09 18:59:04 +0200
kind: article
publish: false
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain', 'event', 'event sourcing' ]
newsletter: :arkency_form
---

Almost 2 years and over 16 million domain events ago I’ve started a process of "switching the mindset". I had no production experience with Event Sourcing (BTW it still is used only in some parts of the application, but that’s a topic for another post), I had only a limited experience with Domain Driven Design (mainly knowing the tactical patterns). During that time, a lot has changed.

<!-- more -->

## Start from the middle
I’ve started introducing new concepts in our project’s code base from the middle. Not with Domain Driven Design, not with Event Sourcing or CQRS (Command Query Responsibility Segregation). It all has started by just publishing Domain Events.

## Trials & errors
The more Domain Events we have "published" the better understanding of our domain I’ve got. Also, I’ve started better understand the core concepts of Domain Driven Design, the terms like _bounded context_, _context map_ and other from strategic patterns of DDD started to have more sense and be more and more important.
Of course, I’ve made a few mistakes, some of them still bite us because of decisions made almost 2 years ago ;)

Our first ever published domain event is:


```
#!ruby
RailsEventStore::Client.new.read_all_streams_forward(:head, 1)
=> ProductItemEvents::ProductItemSold
     @event_id="74eb88c0-8b97-4f27-9234-ed390f72287c",
     @metadata={:timestamp=>2014-11-12 22:20:24 UTC},
     @data={:order_id=>1472818, :product_item_id=>2065172,
            :attributes=>{
               "id"=>2065172, "order_id"=>1472818, "product_type_id"=>85522,
               "serialized_ticket_type"=>nil, "vip_token"=>nil, "invitation_id"=>nil,
               "price_in_cents"=>5000, "fee_in_cents"=>200, "barcode"=>"20651721194",
               "fee_included"=>true, "state"=>"sold", "type"=>"Ticket", "organization_id"=>58,
               "reciever_user_id"=>nil, "reciever_added_at"=>nil, "scanned_at"=>nil,
               "terminal_name"=>nil, "order_line_id"=>1336662, "code_id"=>nil,
               "ticket_scanner_ticket_uuid"=>nil, "vat_rate"=>nil,
               "updated_at"=>2014-11-12 22:20:24 UTC, "created_at"=>2014-11-12 22:20:24 UTC}}
```

Here is a set of rules / things to consider when you will build your domain events. Each of them is based on a mistake I’ve made ;)

## Rule #1: the naming is hard, really hard

In my [old talk](http://praglowski.com/presentations/cqrses/#/14) I’ve presented at dev’s user group meetup I’ve defined domain event as:

* Something that has had already happened, and therefore…
* Should be named in past tense…
* … and in business language (Ubiquitous Language)
* Represents state change,
* Something that will never change

The name of a domain event is extremely important. It is the "definition" of an event for others. It brings a lot of value when defined right, but it might be misleading when it won’t capture the exact business change.

In the example event above the name of the domain event is `ProductItemSold`. And this name is not the best one. The application domain is not selling some products but selling tickets for events (actually that’s huge simplification but it does not matter here). We do not sell products. We sell tickets. This domain event should be named `TicketSold`. Yeah, sure we could also sell some other products but then it should be a different domain event.

## Rule #2: don’t be CRUDy

There are very few domains where something is really created. Every time I see a `UserCreated` domain event I feel that this is not the case. The user might be registered, the user might be imported, I don’t know the case when we really create a user (he or she exists already ;P). Don’t stop when your domain expert tells you that something is created (updated or deleted). It is usually something more, something that has real business meaning.

And one more thing: don’t talk CRUD to your domain expert / customer. When he will start to talk CRUD, you are in serious trouble.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltd">You know what&#39;s the biggest tragedy in software engineering?<br><br>The customers gave up and learnt to speak CRUD to developers.</p>&mdash; Andrzej Krzywda (@andrzejkrzywda) <a href="https://twitter.com/andrzejkrzywda/status/650272559733321728">October 3, 2015</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

Check the [blog post](http://udidahan.com/2009/06/29/dont-create-aggregate-roots/) of [Udi Dahan](https://twitter.com/udidahan) where he explains this in more details.

## Rule #3: your event is not your entity

You might have spotted the `attributes` in the data argument of our first domain event. This is something I dislike most in that domain event. Why? Because it creates a coupling between our domain event & our database schema. Every kind of coupling is bad. Especially when you try to build a loosely coupled, event driven architecture for your application. The attributes of a domain event are their contract. It is not something you could and should easily change. There could be parts of the
system that rely on that contract. Changing it is always a trouble. Avoid that by applying Rule #4.

## Rule #4: be explicit

The `serialized_ticket_type`? It this a business language? Really? Or does the business care about the `scanned_at` when a ticket has been just sold? I don’t. And all event handlers for this event do not care. That’s just pure garbage. It holds no meaningful information here. It just messing with your domain event contract making it less usable, more complicated.
Explicit definition of your domain event’s attributes will not only let you avoid those unintentional things in the domain event schema but will force you to think what really should be included in the event’s data.

```
#!ruby
=> TicketSold
     @event_id="74eb88c0-8b97-4f27-9234-ed390f72287c",
     @metadata={:timestamp=>2014-11-12 22:20:24 UTC},
     @data={:barcode=>"20651721194",
            :order_id=>1472818, :order_line_id=>1336662,
            :ticket_type_id=>85522,
            :price=>{Price value object here}}
```

The modified version of my first domain event. Much cleaner. All important data is explicit. Clearly defined contract what to expect. Maybe some more refactoring could be applied here (TicketType value object & OrderSummary value object that will encapsulate the ids of other aggregates).
Also, important attribute here was revealed. The ticket’s barcode.

## Rule #5: natural is better

With the explicit definition of domain event schema, it is easier to notice that we do not need to rely on database’s id of a ticket (`product_item_id`) because we already have a natural key to use - the `barcode`. Why is the natural better?
Natural keys are part of the ubiquitous language, are the identifications of the objects you & your domain expert will understand and will use when you will talk about it. It also will be used in most cases on your application UI (if not you should rethink your user experience). When you want to print the ticket you use barcode as identification. When you validate the ticket on the venue entrance you scan the barcode. When some guest has troubles with his ticket your support team asks for the
barcode (…or order number, or guest name if you doing it right ;) ). The barcode is the identification of the ticket. The database record’s id is not. Don’t let you database leak through your domain.

## Rule #6: time is a modelling factor
## Rule #7: when in doubt

# <center>TALK TO YOUR DOMAIN EXPERT / BUSINESS</center>
