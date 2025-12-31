---
created_at: 2025-12-30 12:00:00 +0100
publish: true
author: Andrzej Krzywda
tags: [ 'ddd', 'rails', 'multitenancy' ]
---

# Adding multi-tenancy to a DDD Rails app

Many businesses when they set out to create some software they need, don't know that one day, they might need multi-tenancy.

This is one of the features, that is not easy for programmers to add later easily. It might take months or even years. 

Let me describe how I approached this in an ecommerce app. Essentially, the idea is to allow to create multiple stores, where previously it was one (or actually lack of any, all resources were global).

<!-- more -->

## The ecommerce project

The project I am talking about is called [ecommerce](https://github.com/RailsEventStore/ecommerce) and it is part of the RailsEventStore (RES) organization on github. It started as a sample application for RES but over the last 10 years it grew to some kind of utopian Rails/DDD/CQRS/Events project.

This project does run on [production](https://ecommerce.arkademy.dev), but it's not really a production project. It's more of a visionary/educational project to show a Rails codebase that can be highly modular in a DDD fashion.

In this project, there was no concept of a Store. All the main resources were global, as in `Order.all` etc.

Similarly, the events didn't have any data or metadata that would point to a specific store.

```ruby
class OrderConfirmed < Infra::Event
  attribute :order_id, Infra::Types::UUID
end
```

Another idea related to this whole project is that those events (and wider - domains/bounded contexts) are generic in their nature. As such they can be used in other apps without changes. 

Just to prove this point that the domains can be reused, another rails app ([pricing_catalog_rails_app](https://github.com/RailsEventStore/ecommerce/tree/master/apps/pricing_catalog_rails_app)) exists which requires (as gems) the existing bounded contexts.

## The obvious solution - add store_id to all commands/events

When I talked to people, how they would approach adding multi-tenancy here this idea repeated. You need to extend existing events and commands with store_id.

I don't like such invasive approaches by default. 

Also, the domains reusability aspect - while still working, would be less elegant. Some event data would exist but never used in other apps (which don't need multi-tenancy).

It's definitely a concept that would work - so if you don't have such abstract needs as reusability, this may be the way to go.

## The different schema approach

Another obvious solution is to use some database concepts. Create a new schema per tenant or a new db. 

I also excluded this from my choices - I didn't want to solve this at the infra level. It also wasn't clear to me, how would I operate on some cross-store reports which are often required for such Shopify-like platforms.

## What exactly is multi-tenancy?

For some time, I didn't have an alternative solution either. I was contemplating what it means to be multi-tenant, tried to split into smaller concepts.

### Filtering data

We need to filter data. When a specific store is shown, we are displaying only the products of this store. In my architecture, that's a read model job. Definitely, my read models would need to be extended by store_id concept. I was OK with that, even though it was an invasive change. In my book, read models are application specific and if such a big application requirement comes, the read models need to adjust.

### Authorization

We need to authorize access to data.

This is where good old Rails controllers come handy. We need some concept of current_store and then pass the store_id to the read models.

### Admin panel

We need some admin panel, where stores can be created, deleted  and listed.
In my case that's a new read model but also a new "namespace/route" in the Rails app. 

### CQRS - write

So far, we have discussed the reads parts. 
In our CQRS split between reads and writes - how do we handle writes?

We have commands like this:

```ruby
module ProductCatalog
  class RegisterProduct < Infra::Command
    attribute :product_id, Infra::Types::UUID
  end
end
```

Similarly as with events, the commands are part of the BCs and shouldn't need to change.

Still, we need some way of saying that this Product is registered within a store. There's no way around it.

How can we do it, without changing the existing command definitions?

What I wanted was a solution that:
- doesn’t change existing BC APIs
- keeps domains reusable
- keeps multi-tenancy domain and app level, not infra

With these constraints in mind, the solution I arrived at looks almost obvious in hindsight.

## My solution

I'm still polishing the edges here, but overall my attempt seems to work.

The main idea is to create a new Bounded Context - `Stores`. This is the home for a new kind of events. The events are tiny (I like them this way) and they are just registering the main resources within the Store.

So, they look like this:

```ruby

  class ProductRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class CustomerRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :customer_id, Infra::Types::UUID
  end

  class OfferRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :offer_id, Infra::Types::UUID
  end
```

There's not really much logic around it, though. I did solve the problem of making this change non-invasive, but I do admit, the concept of such repetitive events is not super convincing either. 

So, yeah, that's the drawback.

But there are more things that I like here.

First of all, None of other BCs had to change in any way. Maybe one of the existing process managers had to change to include Store registration.

Plenty of read models had to change, but that was expected. They all need to subscribe to the one new event. They persist the store_id and they know how to filter.

```ruby
def call(event_store)
  event_store.subscribe(DraftOrder.new, to: [Pricing::OfferDrafted])
  event_store.subscribe(AssignStoreToOrder.new, to: [Stores::OfferRegistered])
```

```ruby
module Orders
  class AssignStoreToOrder
    def call(event)
      Order.
        find_by!(uid: event.data.fetch(:order_id)).
        update!(store_id: event.data.fetch(:store_id))
    end
  end
end
```

In the controllers, we now need to filter and authorize data:

```ruby
class InvoicesController < ApplicationController
  def show
    @invoice = Invoices.find_invoice_in_store(params[:id], current_store_id)
    not_found unless @invoice
  end
```

Also, in the controller, when we "create" new resources, we issue two commands, one for the original BC, the other one for Stores BC:

```ruby
class CouponsController < ApplicationController
  def create
    coupon_id = params[:coupon_id]

    ActiveRecord::Base.transaction do
      create_coupon(coupon_id)
    end
  rescue Pricing::Coupon::AlreadyRegistered
    flash[:notice] = "Coupon is already registered"
    render "new"
  else
    redirect_to coupons_path, notice: "Coupon was successfully created"
  end

  private

  def create_coupon(coupon_id)
    command_bus.(
      Pricing::RegisterCoupon.new(
        coupon_id: coupon_id,
        name: params[:name],
        code: params[:code],
        discount: params[:discount]
      )
    )
    command_bus.(
      Stores::RegisterCoupon.new(
        coupon_id: coupon_id,
        store_id: current_store_id
      )
    )
  end

end
```

This coupling is intentional and happens only at the application boundary, not inside BCs.

It was also a nice opportunity to revise all the 16 existing read models and make some long-needed cleanups too.

## How Claude Code helped me here

Hard to admit, but I wrote maybe 10% of the code changes in this whole implementation of multi-tenancy.

I assisted Claude in the original read model change - `Orders`. Then, I was shocked how well Claude worked with all other places. It knew the patterns and just repeated them. 

It wouldn't work, though, if not for the mutation test coverage.

Honestly, in all cases, when I followed the reasoning and the steps made by the AI, there were tiny hallucinations or tiny weird solutions, or tiny commenting out code.

Which all was caught by [mutant](https://github.com/mbj/mutant), the main quality guard I have here against AI.

If not for mutant, I'd have to be more in control and the constant code reviews would drive me crazy. With mutant in place I was much more confident - and faster!

I'm gonna write more about this AI experience in other blogposts. This story is already a bit weird - starting from DDD, via events, to multi-tenancy, to read models, to Claude Code. Thanks for bearing with me here. 

AI was crucial here, though. If not for AI, I'd hate myself by the 3rd of the 16 read models with the boring repetitive work.

If not for mutant, I'd hate myself for verifying AI in all 16 modules.

**To be honest, I don't know how people work with agents without mutation testing coverage.**

Without mutant it would be like working with juniors with short attention span. Actually, agents are now senior level sometimes, but it's seniors with dementia.

Here is an example mutant output, when AI worked on the `Shipments` read model. It ran mutant by itself, as it knows (CLAUDE.md) that it is required.

```
progress: 440/447 alive: 0 runtime: 34.21s killtime: 123.81s mutations/s: 12.86
Mutant environment:
Usage:           opensource
Matcher:         #<Mutant::Matcher::Config ignore: [] subjects: [Shipments*]>
Integration:     minitest
Jobs:            4
Includes:        ["test"]
Requires:        ["./config/environment"]
Operators:       light
MutationTimeout: 10
Subjects:        11
All-Tests:       359
Available-Tests: 359
Selected-Tests:  19
Tests/Subject:   1.73 avg
Mutations:       447
Results:         447
Kills:           447
Alive:           0
Timeouts:        0
Runtime:         34.73s
Killtime:        126.85s
Efficiency:      365.22%
Mutations/s:     12.87
Coverage:        100.00%
```

This was a successful run, but often it would catch its own hallucinations and thanks to mutant it fixed itself.

## Summary

To summarize - it's still too early to evaluate the solution, I still need to finish some reviews. But it does seem promising to me and I'm happy with the outcome, despite the drawbacks.

The key lesson for me wasn’t multi-tenancy itself, but that strong architectural foundation + mutation testing make large-scale AI-assisted refactors possible.


