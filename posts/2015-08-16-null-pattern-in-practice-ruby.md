---
title: "Null Object pattern in practice"
created_at: 2015-08-16 15:02:24 +0200
publish: true
author: Robert Pankowecki
tags: [ 'null', 'object', 'pattern', 'ruby' ]
newsletter: fearless_refactoring_1
img: "null/null-object-ruby-pattern-fowler.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("null/null-object-ruby-pattern-fowler.jpg") %>" width="100%">
  </figure>
</p>

Wikipedia describes [Null Object](https://en.wikipedia.org/wiki/Null_Object_pattern) as _an object with defined neutral behavior_.

[Martin Fowler says](http://martinfowler.com/eaaCatalog/specialCase.html) _Instead of returning null, or some odd value,
return a Special Case that has the same interface as what the caller expects._

But null object pattern can also be seen as
a way to **simplify some parts of your code** by reducing _if_-statements
and introducing interface that is identical in both situations,
when something is missing and when something is present.

<!-- more -->

Also it gives you a chance to **properly name the situation
in which you want to do nothing** (_is it always nothing?_).
By just adding `Null` prefix instead of using a more precise word,
you are missing an opportunity.

There is [a great Sandi Metz talk "Nothing is something"](https://www.youtube.com/watch?v=OMPfEXIlTVE) when she talks
about it.

<iframe width="640" height="360" src="https://www.youtube.com/embed/OMPfEXIlTVE?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>

## Rails View example

I have a view that is displaying an event data, as well as
a collection of tickets available. It's
quite complicated view. It is **reused in one different place**. When the
event organizer is editing event and tickets properties we
display **preview of the same page**. So naturally we use the same
view template that is used for rendering an event page for a preview page.

There are slight differences however so one additional variable
(`is_preview`) is **passed down through number of partials that
the page is consisted of**.

We have a class called `EventPool` which is responsible
for gathering and keeping data to quickly answer the one question - whether
a given ticket type is available to buy or not. In other words, it checks
its inventory status. Naturally when organizers are in the process
of adding tickets and haven't saved them yet, they are still
interested in seeing preview of how they would be displayed on
event page. **There is no point of checking inventory status of
unexisting tickets (remember they are not saved yet). Also even
for existing tickets we want to pretend they are not sold out
when displaying the preview**.

The code responsible for the situation (greatly oversimplified)
looked like this:

```html+erb
# show.html.haml
= render 'events/tickets', {
    tickets: event.tickets,
    event_pool: event_pool,
    is_preview: is_preview
  }
```

```html+erb
# events/_tickets.html.haml
- tickets.each do |ticket|
  = render 'events/ticket', {
      ticket: ticket,
      ticket_pool: event_pool.pool_for_ticket_id(ticket.id),
      is_preview: is_preview
    }
```

```html+erb
# events/_ticket.html.haml
if !is_preview && ticket_pool.sold_out?
  = "Sold out"
```

But for the entire tree of partials to work correctly
we still need to pass down `event_pool` which needs to have `#pool_for_ticket_id`
method, even if at the end we decide not to check
the availability status of returned `ticket_pool`.

For me it looked like a great case for applying Null Object Pattern.

```ruby
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

```ruby
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

```html+erb
# show.html.haml
= render 'events/tickets', {
    tickets: event.tickets,
    event_pool: event_pool,
  }
```

```html+erb
# events/_tickets.html.haml
- tickets.each do |ticket|
  = render 'events/ticket', {
      ticket: ticket,
      ticket_pool: event_pool.pool_for_ticket_id(ticket.id),
    }
```

```html+erb
# events/_ticket.html.haml
if ticket_pool.sold_out?
  = "Sold out"
```

If all the places which care whether we are in a real mode
or preview mode adopted this approach, bunch of if-statements
could be removed in favor of using properly named classes
with identical interfaces. Some would be used only when a real
event is displayed, some only when the preview is shown.

**The code
using dedicated Null-* classes (in our case the view) wouldn't care and wouldn't know
if this is preview or not. The logic for preview behavior would
be localized in those classes.**

We could also completely eliminate the `is_preview` variable in the end. In this case
we only eliminated it for the related part of code.

Did you like the blogpost? Join our newsletter to receive more goodies.