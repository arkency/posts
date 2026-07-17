---
created_at: 2026-07-16 11:03:31 +0200
author: Andrzej Krzywda
tags: ['rails', 'process manager', 'ddd']
publish: true
---

# 3 example process managers in Rails

I am writing this blogpost from this beautiful place in the Polish mountains. Our RailsEventStore camp takes place this week. 

<img src="<%= src_fit("3-example-process-managers/IMG_9894.jpeg") %>" width="70%">

Process managers are meant to map business process into code. The more readable and declarative it is, the better the chance domain experts will understand it.

Over the last years, we have experimented with several approaches on how to implement process managers in Ruby.

The foundation here is [RailsEventStore](https://railseventstore.org) and the architecture where events are published and commands are used to tell what to do next.

Most business processes can be mapped into some sort of a checklist of requirements and when certain conditions are met we decide (a command) what to do next.

During the RESCamp I have released a small library - [ruby_event_store-process_manager](https://github.com/RailsEventStore/rails_event_store/tree/master/contrib/ruby_event_store-process_manager) - which was extracted from the ecommerce project.

## 1. ReleasePaymentOnOrderExpiration

I will start with a process which defines what to do when a payment was authorized but the offer has expired. You can imagine that different businesses have different rules for such situations. BTW, that's why I like to put process managers at the application layer and keep them under app/processes.

```ruby
module Processes
  class ReleasePaymentOnOrderExpiration
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Payments::PaymentAuthorized,
      Payments::PaymentReleased,
      Fulfillment::OrderRegistered,
      Pricing::OfferExpired,
      Fulfillment::OrderConfirmed
    )

    private

    def act
      release_payment if state.release?
    end

    def apply(event)
      case event
      when Payments::PaymentAuthorized
        state.with(payment_authorized: true)
      when Payments::PaymentReleased
        state.with(payment_authorized: false)
      when Pricing::OfferExpired
        state.with(order_expired: true)
      else
        state
      end
    end

    def release_payment
      command_bus.call(Payments::ReleasePayment.new(order_id: id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:payment_authorized, :order_expired) do
      def initialize(payment_authorized: false, order_expired: false) = super

      def release?
        payment_authorized && order_expired
      end
    end
  end
end
```

Thanks to the ProcessManager certain things are taken care of for free. One of them is the concept of streams and event sourcing. All events which are relevant to this process are grouped into one stream. This stream by convention will be called `ReleasePaymentOnOrderExpiration$uuid` but it's easy to override. All the events will be linked to this stream automatically. Thanks to this, the process will be rebuilt by replaying the stream on every new event.
Additionally, if two events for the same process race and hit a version conflict, the state-building is retried once.

That's what is hidden. 

What we have here is typical sections:

- events
- state building
- decision (`act`)

## 2. Reservation

Reservation is a common problem to solve in order-related apps. However, every business defines their reservation process differently. 
Imagine a business which sells equipment around a specific topic, let's say photography. You want to buy a camera, a lens and a tripod. All of this is important and if any of them is not available the whole order doesn't make sense -  a camera the customer can't yet use isn't worth shipping

This business process is implemented here:

```ruby
module Processes
  class ReservationProcess
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Pricing::OfferAccepted,
      Fulfillment::OrderCancelled,
      Fulfillment::OrderConfirmed
    )

    private

    def act
      case state
      in order: :accepted
        unavailable = reserve_stock
        if unavailable.any?
          reject_order(unavailable)
        else
          accept_order
        end
      in order: :cancelled
        release_stock(state.reserved_product_ids)
      in order: :confirmed
        dispatch_stock
      end
    end

    def apply(event)
      case event
      when Pricing::OfferAccepted
        order_lines_hash = event.data.fetch(:order_lines).map { |ol| [ol.fetch(:product_id), ol.fetch(:quantity)] }.to_h
        state.with(
          order: :accepted,
          order_lines: order_lines_hash
        )
      when Fulfillment::OrderCancelled
        state.with(order: :cancelled)
      when Fulfillment::OrderConfirmed
        state.with(order: :confirmed)
      end
    end

    def reserve_stock
      unavailable_products = []
      reserved_products = []
      state.order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Reserve.new(product_id: product_id, quantity: quantity))
        reserved_products << product_id
      rescue Inventory::InventoryEntry::InventoryNotAvailable
        unavailable_products << product_id
      end

      if unavailable_products.any?
        release_stock(reserved_products)
      end
      unavailable_products
    end

    def release_stock(product_ids)
      state.order_lines.slice(*product_ids).each do |product_id, quantity|
        command_bus.(Inventory::Release.new(product_id: product_id, quantity: quantity))
      end
    end

    def dispatch_stock
      state.order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Dispatch.new(product_id: product_id, quantity: quantity))
      end
    end

    def accept_order
      command_bus.(Fulfillment::RegisterOrder.new(order_id: id))
    end

    def reject_order(unavailable_product_ids)
      command_bus.(Pricing::RejectOffer.new(
        order_id: id, reason: "Some products were unavailable", unavailable_product_ids:)
      )
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:order, :order_lines) do
      def initialize(order: nil, order_lines: [])
        super(order:, order_lines: order_lines.freeze)
      end

      def reserved_product_ids = order_lines.keys
    end

  end
end
```

What is worth noting here is that this business process can result in 5 different commands for 3 different contexts:

- `Pricing::RejectOffer`
- `Fulfillment::RegisterOrder`
- `Inventory::Dispatch`
- `Inventory::Reserve`
- `Inventory::Release`

This is very typical case in complex businesses. A context can be seen as a department in a company - that's one of the DDD metaphors which I enjoy using.

## 3. Publishing a post on Twitter-like app

This process comes from a different app. Imagine a social media app, where people see their timeline consisting of posts from the people they follow. The process here is simple - make a delivery (posting to a timeline) per each follower, but also include the author timeline.
In the future, we can imagine other rules. For example, we may want to decide to deliver to the online people first. Or maybe we want to push some ads to the timeline when a post seems related. It's nice to have such business rules in one place.

```ruby
class TimelineDeliveryProcess
  include RubyEventStore::ProcessManager.with_state { ProcessState }

  subscribes_to(
    Social::UserFollowed,
    Social::UserUnfollowed,
    Social::PostPublished
  )

  private

  def act
    recipients.each { |recipient_id| deliver_post_to(recipient_id) } if state.post
  end

  def recipients
    state.followers + [state.post.data.fetch(:author_id)]
  end

  def apply(event)
    case event
    when Social::UserFollowed
      state.with(followers: state.followers | [event.data.fetch(:follower_id)], post: nil)
    when Social::UserUnfollowed
      state.with(followers: state.followers - [event.data.fetch(:follower_id)], post: nil)
    when Social::PostPublished
      state.with(post: event)
    end
  end

  def fetch_id(event)
    case event
    when Social::UserFollowed, Social::UserUnfollowed
      event.data.fetch(:followee_id)
    when Social::PostPublished
      event.data.fetch(:author_id)
    end
  end

  def deliver_post_to(recipient_id)
    command_bus.call(
      Social::DeliverPostToTimeline.new(
        post_id: state.post.data.fetch(:post_id),
        recipient_id: recipient_id,
        author: state.post.data.fetch(:author),
        body: state.post.data.fetch(:body)
      )
    )
  end

  ProcessState = Data.define(:followers, :post) do
    def initialize(followers: [], post: nil)
      super(followers: followers.freeze, post: post)
    end
  end
end

```

## The ruby_event_store-process_manager gem

As you see, [RailsEventStore](https://railseventstore.org) together with the [ruby_event_store-process_manager](https://github.com/RailsEventStore/rails_event_store/tree/master/contrib/ruby_event_store-process_manager) gem, allows to map complex business processes into modules, which encapsulates the logic, but hides the infrastructure.

In a typical non-event-driven Rails app such processes are usually scattered across models, service objects and callbacks. The alternative approach requires publishing events (which provides event log for free) but the benefits might be worth it.