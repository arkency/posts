---
created_at: 2021-08-09 12:25:24 +0200
author: Andrzej Krzywda
tags: [event sourcing]
publish: false
---

# Audit log with event sourcing

Recently I've been fixing the way the "history" (essentially an audit log) feature works in the Arkency Ecommerce application. This story may be a good reminder of how audit logs work and how they can be implemented.

Here is the video story:

<iframe width="560" height="315" src="https://www.youtube.com/embed/0-80yi8DQiI" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

<%= img_fit("audit-log-with-event-sourcing/order_list.png") %>

The history link used to show an audit log for the whole Order object. However, after the Order aggregate was split into several bounded contexts, this feature became less useful.

### The evolution of bounded contexts

Why did it become less useful?

We've been using the [Rails Event Store Browser](https://railseventstore.org/docs/v2/browser/). It's an excellent tool for an audit log. It can serve you as a good starting point for having an audit log.

The main feature is to show a stream of events and single event details.

This is where I had to find some fix. Previously, an Order was just one aggregate in one bounded context. This means, under the hood it was 1 stream of events.

You see, previously all the events were published from the Ordering::Order aggregate, which means they were part of one stream. All we've had to do was just to link the "history" button with the RES Browser and point to the Ordering::Order stream.

After some recent changes and new features it's now different. The Order now exists in Ordering, Pricing and Payments bounded contexts (aka business departments).

They are no longer part of one stream.

But there is a trick.

### Read models and audit log

Read models are the views to the system. They react to events and they return a data structure. 

This is a visual representation of the `Orders` read model in this app.

<%= img_fit("audit-log-with-event-sourcing/order_view.png") %>

While read models react to events, they don't have to be grouped as a stream. They don't have to, but it's usually a good idea to link them to a stream.

### Making the read model stream-based.

```ruby
module Orders
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      subscribe(-> (event) { mark_as_submitted(event) }, [Ordering::OrderSubmitted])
      subscribe(-> (event) { change_order_state(event, "Expired") }, [Ordering::OrderExpired])
      subscribe(-> (event) { change_order_state(event, "Ready to ship (paid)") }, [Ordering::OrderPaid])
      subscribe(-> (event) { change_order_state(event, "Cancelled") }, [Ordering::OrderCancelled])
      subscribe(-> (event) { add_item_to_order(event)}, [Pricing::ItemAddedToBasket])
      subscribe(-> (event) { remove_item_from_order(event) }, [Pricing::ItemRemovedFromBasket])
      subscribe(-> (event) { update_discount(event) }, [Pricing::PercentageDiscountSet])
      subscribe(-> (event) { update_totals(event) }, [Pricing::OrderTotalValueCalculated])
    end

    private

    def subscribe(handler, events)
      link_and_handle =
        -> (event) {
          link_to_stream(event)
          handler.call(event)
        }
      @cqrs.subscribe(link_and_handle, events)
    end
  end
end    
```

That's what I did as part of this audit log fix. The last lines change was to combine linking with handling. Whenever we handle an event in this read model - we also link it to one stream.

Now that we have a stream which consists of most order related events, we can reuse it.

But a fair warning here - I do reuse this stream but we need to be aware it's a coupling. Whenever read models changes this may impact the audit log. 

All in all, it was a smooth fix and the audit log provides a nice visibility into the system.

Here is how the stream view shows us the audit of the Order object:


<%= img_fit("audit-log-with-event-sourcing/stream_view.png") %>

Each event is linked to an event view:

<%= img_fit("audit-log-with-event-sourcing/event_view.png") %>

You can see, as part of the RES Browser we have other features built-in here - grouping events in many different ways.

Obviously this was simple here - we use event-driven approach and we already have RailsEventStore together with its RailsEventStore Browser.

### Audit log in a CRUD app

What would I do if this was a CRUD app?

Actually, I would do the same.

You don't have to go all in with events. Event sourcing is a great technique but it's not required for audit logs. The same with bounded contexts - rarely seen in CRUD apps.

You can start with event-driven.

I'd introduce events in all the places where Order change. It might be in your service objects. I'd start publishing those events as part of one stream.

Then I'd use RailsEventStore Browser to display it. (assuming it's Rails)

BTW, [The browser is implemented in Elm](https://github.com/RailsEventStore/rails_event_store/blob/master/ruby_event_store-browser/elm/src/Page/ShowStream.elm) which compiles to JavaScript so even without Rails you can use it too.

```elm
browseEvents : Url.Url -> String -> Api.PaginatedList Api.Event -> Maybe (List String) -> Html Msg
browseEvents baseUrl title { links, events } relatedStreams =
    div [ class "py-8" ]
        [ h1 [ class "font-bold px-8 text-2xl" ] [ text title ]
        , div [ class "px-8" ] [ displayPagination links ]
        , div [ class "px-8" ] [ renderResults baseUrl events ]
        , div [] [ renderRelatedStreams baseUrl relatedStreams ]
        ]
``` 

I hope I was able to show you some ideas how to connect events with audit logs. It's super simple and so worth it - for the developers, but also for the admin/support users. 