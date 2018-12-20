---
title: "Modeling passing time with events"
created_at: 2018-12-20 12:43:22 +0100
kind: article
publish: false
author: Paweł Pacana
tags: [ 'ddd', 'process manager' ]
newsletter: :arkency_form
---

# Modeling passing time with events
 
Learning new ideas can be a real struggle. Getting familiar with new concepts, nomenclature and understanding the context in which this new skills can be applied takes time. When it finally clicks and you've connected all the dots — the joy is tremendous.
 
I remember a nice discussion we had over burgers during wroc_love.rb conference in 2015. Folks shared their experiences of getting through [The Blue](https://domainlanguage.com/ddd/) and [The Red](http://www.informit.com/store/implementing-domain-driven-design-9780321834577?ranMID=24808) books — what was the most difficult to grasp and what made a breakthrough for them.
For me the turning point was a chapter on Domain Events. This is when it all made sense. When I shared this experience, Alberto Brandolini who was sitting next to me silently nodded. 
 
Eventstorming is a technique for collaborative exploration of complex business domains. I was lucky to participate in a few of such workshops, including the one Alberto facilitated after his [wroc_love.rb talk](https://www.youtube.com/watch?v=veTVAN0oEkQ). Events, as the name suggests, play a key role in this discovery process. An event, in this context, represents a fact. Something that has had already happened in the domain. Thus we name it in past tense and in the language of the business (Ubiquitous Language).

The other day my coworker Robert shared a technique he picked from a [DDDx talk](https://skillsmatter.com/skillscasts/5437-answering-a-question#video). In this video (with a completely non-searchable title) Greg Young presents how to model time in CQRS/ES system by sending your future self messages. And it turns out events are great for that purpose.

The concept is a bit tricky at first. You schedule an event to be delivered to you at some time in the future. An event is described in past tense but it did not happen yet. 
When the time comes, a message in form of this event is received notifying you that something just happened. You cannot reject it, as it belongs to the past and represents a fact. Yet you sent it into the future. It can be mind boggling.

An application we worked on with Robert allowed requesting invoices. As a customer you were allowed to make a delayed payment in such scenario. When due date was missed and payment still wasn't there, a credit note was sent.

At the time we were implementing this, ActiveJob and Sidekiq were out of our sight. With Resque at hand that led us to:

```ruby
scheduled = Payments::CreditNoteScheduled.new(
  scheduled_at: invoice.credit_note,
  invoice_id: invoice.id,
  order_id: transaction.order_id,
)

Resque.enqueue_at(invoice.credit_note.utc, Payments::SendCreditNote, YAML.dump(scheduled))
event_store.append(scheduled)
```

A credit note is sent after given time has passed. In our business that was two weeks since invoice was requested (`invoice.credit_note.utc`).

We enqueue an event `Payments::CreditNoteScheduled` to be delivered at that time to the receiver, `Payments::SendCreditNote`. Finally that event is appended to the event store log as a confirmation of scheduling in Resque/Redis.

```ruby
class Payments::SendCreditNote  
  @queue = :payment

  def self.perform(payload, **)
    new.call(YAML.load(payload))
  end

  def call(event)
    invoice_id = event.data.fetch(:invoice_id)    Payments::InvoicesService.new.credit_note_scheduled(invoice_id)  end
end

class Payments::InvoicesService
  def credit_note_scheduled(invoice_id)
    ActiveRecord::Base.transaction do
      invoice = Payments::Invoice.find(invoice_id)
     OrderTransaction.lock.find(invoice.order_transaction_id).tap do |ot|
+        return if ot.successful?
+        invoice.credit_note_issued_at = Time.now
+        invoice.save!
+        event_store.publish(Payments::CreditNoteIssued.new(
+          invoice_id: invoice.id,
+          order_id: invoice.order_id,
+        ))
+      end
+    end
+  end
end
```

A true receiver and an event handler is `credit_note_scheduled` method of a `Payments::InvoicesService`. The glue of `Payments::SendCreditNote` background job is to make this idea possible in the given infrastructure.

The code above is no longer in that application. The feature of invoices in that shape has been completely removed. Yet when digging through git history and restoring it for the purpose of this post, it struck me again that something wasn't quite right.

It wasn't about the infrastructure, although it can be much improved and overall less distracting. Something wasn't compiling in my head when looking at the events and their relation to time:

- `Payments::CreditNoteIssued` is okay at the time we
we've issued the note
- I cannot object much to `Payments::CreditNoteScheduled` when interpreting it as fact stating we've planned issuing a note in future. Although it seems a bit irrelevant and too "technical" from the domain perspective.
- I have a trouble receiving and handling `Payments::CreditNoteScheduled` in the future. It screams that what I got happened not just now, but two weeks ago. 

It doesn't indicate passing time! Today I would name this event differently. `TimeToPayForInvoiceExpired` already conveys the message better for me. 

Naming is hard and all models are wrong. But some are useful and this technique comes useful in one more aspect.


- workshop example with testing
- RESCON had it presented twice in different flavours (Szymon, David)
- suggestion of RES feature https://github.com/RailsEventStore/rails_event_store/issues/116
