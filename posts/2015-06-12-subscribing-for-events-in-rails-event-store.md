---
title: "Subscribing for events in rails_event_store"
created_at: 2015-06-12 09:19:01 +0200
kind: article
publish: true
author: Mirosław Pragłowski
tags: [ 'rails_event_store', 'domain', 'event', 'event sourcing' ]
newsletter: :skip
newsletter_inside: :rails_event_store
img: "events/hitbythebus.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("events/hitbythebus.jpg") %>" width="100%">
  </figure>
</p>


## Sample CQRS / ES application gone wrong
In my post [Building an Event Sourced application](http://blog.arkency.com/2015/05/building-an-event-sourced-application-using-rails-event-store/) I've included sample code to setup denormalizers (event handlers) that will build a read model:

```
#!ruby
def event_store
  @event_store ||= RailsEventStore::Client.new.tap do |es|
    es.subscribe(Denormalizers::Router.new)
  end
end
```

<!-- more -->

## One router to rule them all
Because that is only a sample application showing how easy is to build an Event Sourced application using Ruby/Rails and Rails Event Store there were some shortcuts. Shortcuts that should have never been there. Shortcuts that have made some doubts for others who try to build their own solution.

The router was defined as:

```
#!ruby
module Denormalizers
  class Router
    def handle_event(event)
      case event.event_type
      when Events::OrderCreated.name      then Denormalizers::Order.new.order_created(event)
      when Events::OrderExpired.name      then Denormalizers::Order.new.order_created(event)
      when Events::ItemAddedToBasket      then Denormalizers::OrderLine.new.item_added_to_basket(event)
      when Events::ItemRemovedFromBasket  then Denormalizers::OrderLine.new.item_removed_from_basket(event)
      end
    end
  end
end
```

And denormalisers were implemented as:

```
#!ruby
module Denormalizers
  class Order
    def order_created(event)
      # ...
    end

    def order_expired(event)
      # ...
    end
  end
end
```

But we could remove it completely and we do not need that `case` at all!

All this code could be rewritten using [`rails_event_store`](https://github.com/arkency/rails_event_store) subscriptions as follows:

```
#!ruby
#command handler (or anywhere you want to initialise rails_event_store
def event_store
  @event_store ||= RailsEventStore::Client.new.tap do |es|
    es.subscribe(Denormalizers::OrderCreated.new, ['Events::OrderCreated'])
    es.subscribe(Denormalizers::OrderExpired.new, ['Events::OrderExpired'])
    es.subscribe(Denormalizers::ItemAddedToBasket.new, ['Events::ItemAddedToBasket'])
    es.subscribe(Denormalizers::ItemRemovedFromBasket.new, ['Events::ItemRemovedFromBasket'])
  end
end

#sample event handler (denormaliser)
module Denormalizers
  class OrderCreated
    def handle_event(event)
      # ... denormalisation code here
    end
  end
end
```

You see? No Router at all! It's event store who _"knows"_ where to send messages (events) based on subscriptions defined.

## Implicit assumptions a.k.a conventions
Sometimes when you have a simple application like this it is tempting to define _"convention"_ and avoid the tedious need to setup all subscriptions. It seems to be easy to implement and (at least at the beginning of the project) it seems to be elegant and simple solution that would do _"the magic"_ for us.

```
#!ruby
# WARNING: not recommended code ahead ;)
def event_store
  @event_store ||= RailsEventStore::Client.new.tap do |es|
    get_all_events_defined.each |event_class|
      handlers_for(event_class).each |handler|
        es.subscribe(handler, [event_class.to_s])
      end
    end
  end
end

def get_all_events_defined
  [ Events::OrderCreate, Events::OrderExpired, Events::ItemAddedToBasket, Events::ItemRemovedFromBasket ]
  # or implement some more sophisticated way of getting all event's classes ;)
end

def handlers_for(event_class)
  handler_class = "Denormalizers::#{event_class.name.demodulize}".constantize
  handler_class.new
end
```

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">I wonder what would happen if we called it &quot;Implicit Assumptions&quot; instead of &quot;Convention over Configuration&quot;.</p>&mdash; Andrzej Krzywda (@andrzejkrzywda) <a href="https://twitter.com/andrzejkrzywda/status/607519026944872448">June 7, 2015</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>


Naming is important! If we do not use _convention_ but instead _implicit assumption_ we will realise that it is not that simple and elegant at it looks like. Even worse, project tent to grow. When you will start using domain events you will want more and more of them. You could even want to have several handles for a single event ;) And maybe your handlers will need some dependencies? ... Here is the moment when your simple convention breaks!

## Make implicit explicit!
By coding the subscriptions one by one, maybe grouping them in some functional areas (bounded context) and clearly defining dependencies you could have more clear code, less _"magic"_ and it should be easier to reason how things work.

<%= inner_newsletter(item[:newsletter_inside]) %>

