---
title: "What's inside the Rails DDD workshop application?"
created_at: 2017-05-03 14:18:37 +0200
kind: article
publish: true
author: Andrzej Krzywda
tags: ['ddd']
img: workshop_app/order_history.png
---

An integral part of our Rails DDD workshops is an application which we use during the teaching and exercises process.

Many people have asked what's inside the app, so I have prepared a small sneak-peek.

<!-- more -->

# The UI

Let's start with the UI to see the scope of the app.

There are typical Rails scaffold CRUD UIs for customers and products, respectively:

<%= img_fit("workshop_app/customers_crud.png") %>
<%= img_fit("workshop_app/products_crud.png") %>

In the above screens we can manage and prepare customers and products, which will be used in other parts of the system.

The order list screen lets us review the orders, which is the main part of the system:

<%= img_fit("workshop_app/orders_list.png") %>

As you can see, there are some features of what we can do with the order: pay, ship, cancel, history.

<%= img_fit("workshop_app/new_order.png") %>

Creating a new order screen displays the existing products and lets us choose a customer.

<%= img_fit("workshop_app/payment_screen.png") %>

This screen simulates the payment, to show how we can integrate with external API.

<%= img_fit("workshop_app/order_history.png") %>

The history view shows the events related to that order, which makes debugging easier, we can the whole history here.

# The routes/controllers

```ruby

Rails.application.routes.draw do
  root to: 'orders#index'
  resources :orders, only: [:index, :show, :new, :create, :destroy] do
    get  :pay
    post :ship
  end
  resources :payments, only: [:create]

  resources :customers, only: [:index, :show, :new, :edit, :create, :update]
  resources :products
end
```

# The domain

Given that this app helps learning DDD, you could expect some interesting domain layer, right?

In this case there are 2 domain-rich bounded contexts, each of them represented as a Ruby namespace:

- `Orders`
- `Payments`

and there are `Products` and `Customers` which we could probably also call like Catalog and CRM respectively, but here they are just CRUD contexts, without much logic.

We've used the Product and Customer ActiveRecord-driven CRUDs to represent how such things can cooperate with domain-rich bounded contexts.

We also have one saga (or process manager, depending on the definition), called `Discount`.

There's also a projection, called `PaymentsProjection`.

In the spirit of CQRS, we handle the "write" part with Commands.

```ruby

module Payments
  class AuthorizePaymentCommand
    include Command

    attr_accessor :order_number
    attr_accessor :total_amount
    attr_accessor :card_number

    validates_presence_of :order_number, :total_amount, :card_number
  end
end
```

Everything is based on events, through which the different contexts communicate with each other.

```ruby

  class PaymentReleased < RubyEventStore::Event
    SCHEMA = {
      transaction_identifier: String,
      order_number:  String,
    }.freeze

    def self.strict(data:)
      ClassyHash.validate(data, SCHEMA, true)
      new(data: data)
    end
  end
```

There are aggregates for `Payment` and for `Order`.

All the domain logic of the application is fully tested.

```ruby
module Orders
  RSpec.describe Order do
    it 'newly created order could be expired' do
      order = Order.new(number: '12345')
      expect{ order.expire }.not_to raise_error
      expect(order).to publish [
        OrderExpired.strict(data: { order_number: '12345' }),
      ]
    end
```

# The CQRS/EventSourcing infra code

The app is a nice example of a non-trivial code which is using the [RailsEventStore](https://github.com/arkency/rails_event_store) ecosystem of tools.

# The exercises

The code is hosted on GitLab. Once you get access there, you will also see a list of Issues. Each issue is actually an exercise to let you practice DDD, based on this app. Several of those exercises are what we expect you to do, during the workshops (with our support and help).

# Summary

I hope this blogpost answers some questions and can help you evaluate whether our [Rails DDD workshops](http://blog.arkency.com/ddd-training/) are of value to you.
