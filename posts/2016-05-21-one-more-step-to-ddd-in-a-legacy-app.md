---
title: "One more step to DDD in a legacy app"
created_at: 2016-05-21 13:50:09 +0200
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---
<p>
    <figure>
        <img src="<%= src_fit('one-more-step-to-ddd-in-a-legacy-app/head.jpg') %>" width="100%">
    </figure>
</p>

Recently I picked up a ticket from support team for one of our clients. Few months ago VAT rates have changed in Norway - 5% became 10% and 12% became 15%. It has some implications to platform users — event organizers, since they can choose which VAT rate applies to products which they offer to the ticket buyers. You'll learn why I haven't just updated db column

<!-- more -->

## Current state of the app
This app is a great example of legacy software. It's successful, earns a lot of money, but have some areas of code which haven't been cleaned yet. There's a concept of an _organization_ in codebase, which represents the given country market. The organization has an attribute called `available_vat_rates` which is simply a serialized attribute, keeping `VatRate` value objects. I won't focus on this object here, since its implementation is not a point of this post. It works in a really simple manner:

```
#!ruby
irb(main):001:0> vat_rate = VatRate.new(15)
=> #<VatRate:0x007fdb8ed50db0 @value=15.0, @code="15">
irb(main):002:0> vat_rate.code
=> "15"
irb(main):003:0> vat_rate.to_d
=> #<BigDecimal:7fdb8ed716c8,'0.15E2',9(27)>
```

`VatRate` objects are `Comparable` so you can easily sort them; pretty neat solution.

Event organizer, who creates eg. a ticket, can choose a valid VAT rate applying to his product. Then, after purchase is made, ticket buyer receives the e-mail with a receipt. This has also side-effects in the financial reporting, obviously.

## So what's the problem?
I could simply write a migration and add new VAT rates, remove old ones and update events' products which use old rates. However, no domain knowledge would left about when change was done and what kind of change happened. You simply can't get that information from `updated_at` column in your database. We have nice domain facts "coverage" around _event_ concept in the application, so we're well informed here. We don't have such knowledge in regard to the _Organization_.

## Start with a plan
I simply started with making a plan of this upgrade.

1. I've checked if the change made to `available_vat_rates` will be represented properly in the financial reports.
2. I've checked how many products were having old VAT rates set.
3. I've introduced new domain events called `OrganizationFacts::VatRatedAdded` and `OrganizationFacts::VatRateRemoved` which are published to the `Organization$organization_id` stream.
4. I've run a migration, which was adding new VAT rates (10% & 15%) and publishing sufficient domain facts — let's call it **step 1**.
5. I've performed an upgrade of the VAT rates on the products which required it - **step 2**.
6. I've run a migration, which has removed old VAT rates (5% & 12%) and published domain facts - **step 3**.

## Step 1 - adding new VAT rates
```
#!ruby
require 'event_store'

class AddNewVatRatesToNoOrgazation < ActiveRecord::Migration
  #… minimum viable implementations of used classes

  def up
      event_store   = Rails.application.config.event_store

      organization  = Organization.find_by(domain: 'example.no')
      originator_id = User.find_by(email: 'me@example.com').id

      organization.available_vat_rates = [
          VatRate.new('NoVat'),
          VatRate.new(5),  # deprecated one
          VatRate.new(10), # new one
          VatRate.new(12), # deprecated one
          VatRate.new(15), # new one
          VatRate.new(25),
      ]

      if organization.save
        event_store.publish(OrganizationFacts::VatRateAdded.new({ organization: organization.id, vat_rate_code: 10, originator_id: originator_id})
        event_store.publish(OrganizationFacts::VatRateAdded.new({ organization: organization.id, vat_rate_code: 15, originator_id: originator_id})
      end
  end
end
```

Two things worth notice happen here. Event data contain `originator_id`, I simply passed there my `user_id`. Just to leave other team members information about person who performed the change in the codebase — audit log purpose. The second thing is that I leave old VAT rates still available. Just in case if any event organizer performing changes on his products, to prevent errors and partially migrated state.

## Step 2 - migrating affected product data
The amount of products which required change of the VAT rates was so small that I simply used web interface to update them. Normally I would just go with  baking `EventService` with `UpdateTicketTypeCommand` containing all the necessary data.

## Step 3 - remove deprecated VAT rates
```
#!ruby
require 'event_store'

class RemoveOldVatRatesFromNoOrgazation < ActiveRecord::Migration
  #… minimum viable implementations of used classes

  def up
      event_store   = Rails.application.config.event_store

      organization  = Organization.find_by(domain: 'example.no')
      originator_id = User.find_by(email: 'me@example.com').id

      organization.available_vat_rates = [
          VatRate.new('NoVat'),
          VatRate.new(10),
          VatRate.new(15),
          VatRate.new(25),
      ]

      if organization.save
        event_store.publish(OrganizationFacts::VatRateRemoved.new({ organization: organization.id, vat_rate_code: 5, originator_id: originator_id})
        event_store.publish(OrganizationFacts::VatRateRemoved.new({ organization: organization.id, vat_rate_code: 12, originator_id: originator_id})
      end
  end
end
```

## Summary
All the products on the platform have proper VAT rates set, _organization_ has proper list of available VAT rates. And least, but not least, we know what and when exactly happened, we have better domain understanding, we started publishing events for another bounded context of our app.
If you're still not convinced to publishing domain events, please read Andrzej [post on that topic](http://blog.arkency.com/2016/01/from-legacy-to-ddd-start-with-publishing-events/) or even better, by watching his keynote _From Rails legacy to DDD_ performed on [wroc_love.rb](wrocloverb.com).

<iframe width="560" height="315" src="https://www.youtube.com/embed/LrSBrHgCLm8" frameborder="0" allowfullscreen></iframe>
