---
title: "What's inside the Rails DDD workshop application?"
created_at: 2017-05-03 14:18:37 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
img: workshop_app/order_history.png
---

An integral part of our Rails DDD workshops is an application which we use during the teaching and exercises process.

Many people have asked what's inside the app, so I have prepared a small sneak-peek.

<!-- more -->

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



```
#!ruby
Person.new.show_secret
# => 1234vW74X&
```

