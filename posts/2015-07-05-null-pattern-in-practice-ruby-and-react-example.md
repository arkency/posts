---
title: "Null pattern in practice - ruby and react example"
created_at: 2015-07-05 20:02:24 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

Wikipedia/Fowler describes Null Object Pattern as ...


<!-- more -->

But null object pattern can also be seen as
a way to simplify some parts of your code by reducing _if_-statements
and introducing interface that is identical in both situations,
when something is missing and when something is present.

Also it gives you a chance to properly name the situation
in which you want to do nothing (_is it always nothing?_).
By just adding `Null` prefix instead of using a more precise word,
you are missing an opportunity.

There is a great Sandi Metz speech when she talks
about it.

## Ruby

I have a view that is displaying an event data, as well as
a collection of tickets available to display those events. It's
quite complicated. It is reused in one different place. When the
event organizer is editing event and tickets properties we
display preview of the same page. So naturally we use the same
view that is used for rendering event page for preview page.

There are slight differences however so one additional variable
(`is_preview`) is passed down through number of partials that
the page is consisted of.
 
We have a class called `EventPool` that is responsible
for data responsible to quickly anwers one question. Whether
given ticke type is available or not. In other words, it checks
its inventory status. Naturally when organizers are in the process
of adding tickets and haven't saved them yet, they are still
interested in seeing preview of how they would be displayed on
event page. There is no point of checking inventory status of
unexisting tickets (remember they are not saved yet). Also even
for existing tickets we want to pretend they are not sold out
when displaying the preview.

The code responsible for the situation (greatly oversimplified)
looked like this:

```
# show.html.haml
= render 'events/tickets', {
    tickets: event.tickets,
    event_pool: event_pool,
    is_preview: is_preview
  }
```

```
# events/_tickets.html.haml
- tickets.each do |ticket|
  = render 'events/ticket', { 
      ticket: ticket,
      ticket_pool: event_pool.pool_for_ticket_id(ticket.id),
      is_preview: is_preview
    }
```

```
# events/_ticket.html.haml
if !is_preview && ticket_pool.sold_out?
  = "Sold out"
```

But for the entire tree of partials to work correctly
we still need to pass down `event_pool` which needs to have `#pool_for_ticket_id`
method, even if at the end we decide not check
the availability status of returned `ticket_pool`.
  
For me it looked like a great case for applying Null Object Pattern.

```
class PreviewEventPool
  class PreviewTicketPool
    def sold_out?
      false
    end
  end
  def pool_for_ticket_id(*)
    PreviewTicketPool.new
  end
end
```

```
class Controller
  def preview
    event = current_user.events.find( params[:id] )

    respond_to do |format|
      format.html do
        render 'events/show', locals: {
          event: event,
          event_pool: PreviewEventPool.new,
          is_preview: true
        }
      end
    end
  end
```

```
# show.html.haml
= render 'events/tickets', {
    tickets: event.tickets,
    event_pool: event_pool,
  }
```

```
# events/_tickets.html.haml
- tickets.each do |ticket|
  = render 'events/ticket', { 
      ticket: ticket,
      ticket_pool: event_pool.pool_for_ticket_id(ticket.id),
    }
```

```
# events/_ticket.html.haml
if ticket_pool.sold_out?
  = "Sold out"
```

If all the places that care whether we are in real mode
or preview mode adopted this approach, bunch of if-statements
could be removed in favor of using properly named classes
with identical interfaces. Some would be used only when real
event is displayed, some only when preview is shown. The code
using them wouldn't care and wouldn't know if this is preview
or not. The logic for preview behavior would be localized in those
classes.

## React.js

 