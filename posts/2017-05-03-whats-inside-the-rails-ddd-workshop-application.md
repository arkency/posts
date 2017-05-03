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

<%= img_fit("workshop_app/customers_crud") %>
<%= img_fit("workshop_app/products_crud") %>
<%= img_fit("workshop_app/orders_list") %>
<%= img_fit("workshop_app/new_order") %>
<%= img_fit("workshop_app/payment_screen") %>
<%= img_fit("workshop_app/order_history") %>

Routes

```
#!ruby
Person.new.show_secret
# => 1234vW74X&
```

