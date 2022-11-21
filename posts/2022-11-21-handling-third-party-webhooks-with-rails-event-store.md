---
created_at: 2022-11-21 11:44:08 +0100
author: Piotr Jurewicz
tags: ['rails event store']
publish: true
---

# Handling third-party webhooks with Rails Event Store

Lately, one of our clients asked us to review his Rails Event Store-based application.
We helped him, as [RES mentoring](https://railseventstore.org/support/) is one of the key fields of our professional activity.

What caught our attention was the way of handling incoming webhooks from third-party services.

<!-- more -->

In a given project, incoming requests payloads were mapped to the domain commands on the fly, resulting in publishing domain events afterward.

In fact, incoming webhooks usually inform us about things that have already happened in the past. So we should rather treat them as events, not commands.

But simply mapping them to the domain events is risky. We can not reject them, as they are facts, but we can check if they do not contradict our invariants.
If they do it can mean that we have incorrect expectations, or external service is not operating correctly.

## Two event types

The advice we gave was to distinguish between two types of events:

###Technical event
This event is published when a webhook is received from a third-party service. It just contains the whole payload. `WebhookReceived`, `ConnectionSynced` are good examples of such events.
This is an example of how publishing such an event can look like:
```ruby
module Api
  module Webhooks
    class FooController < Api::BaseController
      before_action :authenticate_foo_token!

      protect_from_forgery with: :null_session

      def connection_synced
        publish_event_uniquely(
          Foo::ConnectionSynced.new(data: { payload: webhook_payload }),
          webhook_payload[:id_webhook_data]
        )
        head :no_content
      end

      private

      def publish_event_uniquely(event, *fields)
        uniqueness_key = [event.event_type, *fields].join("_")
        event_store.publish(event, stream_name: "$unique_by_#{uniqueness_key}", expected_version: :none)
      rescue RubyEventStore::WrongExpectedEventVersion
      end

      def webhook_payload
        params[:foo].permit!.to_h
      end

      def authenticate_budgea_token!
        credentials = FooCredential.find_by(permanent_access_token: token_from_header)
        head :unauthorized unless credentials
      end
    end
  end
end
```

###Domain event
This event is published when a webhook payload is processed and a domain event is extracted from it. It captures the memory of something interesting which affects the domain.
`UserRegistered`, `OrderPlaced`, and `InvoiceIssued` are common examples. You can extract more than one domain event from a single technical event. It's also ok to have a technical event that doesn't result in any domain event.

## Why?

###External system audit log
The main benefit of having technical events is an audit log of all the events received from the external system. This is useful for debugging and troubleshooting.

What is more, if your business rules ever change, you can still reuse the payload stored in a technical event. You just don't lose valuable data.

###Improved performance
Your responses to the third-party are super fast because you don't need to wait for the domain event to be processed synchronously.
You just publish the technical event and respond immediately. Then you can process the queue asynchronously based on the processing unit's availability and the priority of the events.

Overall, you can scale the processing of the events independently from the web server.

###No need to rely on the third-party retry mechanism
Once you have a payload stored, you can process it as many times as you want. If there is a bug in your code, you can fix it and reprocess the event. Retrying on unhandled exceptions is a default mechanism of most ActiveJob queue adapters.

You can't rely on how the third-party will act on your internal error. It may retry the request, or not. It may retry it immediately, or after a few hours. It may retry it only once, or many times. You don't want to lose control over this.
