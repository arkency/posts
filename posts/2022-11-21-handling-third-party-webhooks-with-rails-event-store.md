---
created_at: 2022-11-21 11:44:08 +0100
author: Piotr Jurewicz
tags: ['rails event store']
publish: false
---

# Handling third-party webhooks with Rails Event Store

Lately, one of our clients asked us for reviewing his Rails Event Store based application. RES mentoring is one of the fields of our professional activity.
What caught our attention was the way of handling webhooks from third-party services.

<!-- more -->

## Two event types

The advice we gave was to distinguish between two types of webhooks and publish them 
###Technical event
This event is published when a webhook is received from a third-party service. It just contains the whole payload. `WebhookReceived`, `ConnectionSynced` are good examples of such events.

###Domain event
This event is published when a webhook payload is processed and a domain event is extracted from it. It captures the memory of something interesting which affects the domain.
`UserRegistered`, `OrderPlaced`, `InvoiceIssued` are common examples.

## Why?

###External system audit log
The main benefit of having technical events is an audit log of all the events received from the external system. This is useful for debugging and troubleshooting.
What is more, if your business rules ever change, you can still reuse the payload stored in a technical event. You just don't loose the valuable data.

###Improved performance
Your responses to the third-party are super fast because you don't need to wait for the domain event to be processed synchronously.
You just publish the technical event and respond immediately. Than you can process the queue asynchronously based on the processing units availability and the priority of the events.
Overall, you can scale the processing of the events independently from the web server.

###No need to rely on the third-party retry mechanism
Once you have a payload stored, you can process it as many times as you want. If there is a bug in your code, you can fix it and reprocess the event. Retrying on unhandled exception is a default mechanism of most ActiveJob queue adapters.
You can't relay on how the third-party will act on your internal error. It may retry the request, or not. It may retry it immediately, or after a few hours. It may retry it only once, or many times. You don't want to lose control over this.
