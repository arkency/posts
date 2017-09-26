---
title: "Why Event Sourcing basically requires CQRS and Read Models"
created_at: 2017-09-26 10:02:17 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ddd', 'event_sourcing', 'cqrs', 'read models' ]
newsletter: :arkency_form
---

Event sourcing is a nice technique with certain benefits. But it has a big limitation. As there is no concept of easily available _current state_, you can't easily get an answer to a query such as _give me all products with available quantity lower than 10_.

<!-- more -->

You could read `Product-1` stream of events for `Product` with `ID=1`, use them to rebuild the current state of this one product and get an answer to whether it has less than 10 available quantity. But to find all such products, you would need to iterate over all `Product-*` streams, and process all domain events stored for all products. That would be costly and take a lot of time.

All that use-cases that you see in your daily job get a little harder:

* Show me last 10 registered users
* Find customers by emails or address
* What's the total amount of all transaction from this month
* What's the Life Time Value of a customer
* Search all products with the text _blue pillow_

and so on, and so on...

Why?

Because when an Entity/Aggregate is event-sourced, there is only one method you can ask the repository about the object. And that's `find_by_id`. That's it.

You know the `Id` from somewhere ie: other entity has a reference to it, or from UI, or from API, or from a request. And you can do:

```ruby
id = params[:id]
product = ProductRepository.find_by_id(id)
```

The repository will know what stream of events it should read (ie. `Product-1`), those events will be applied on a `Product` instance and we will re-build the current state of one product. That's it.

So what's the solution to all those before-mentioned use-cases? Read models.

If you want to display a list of products in your e-commerce app so that customers can browse them and call commands such as `AddToBasket`  and `Product` is event sourced, you are going to need to have a read-model of Products. This read model can be in Elastic Search or in SQL or in any DB you want. That's up to specific requirements.

How does the process of building a read model work in steps?

1. When you update the product, you do it by saving new domain events.
2. Event handlers are triggered
    * They can be triggered by a message queue that you pushed the event into, after they are stored
        * In simplest case that can be implemented using ActiveJob, in more complex scenarios it can be Kafka, Rabbit or Amazon SQS.
    * Or you have a separate process (a projection) constantly iterating over saved domain events and picking them up for processing.
        * This is very simple when you use [EventStore DB](https://eventstore.org/) for saving domain events.
3. The event handler updates the read model accordingly based on what happened, what domain event it is processing.


As an example.

`ProductRegistered` event can cause adding a new element to ActiveRecord-backed read model `ProductList`.

```ruby
ProductList.create!(
  id: event.data[:product_id],
  name: event.data[:name],
  price: BigDecimal.new(event.data[:price]),
)
```

`ProductPriceChanged` event can cause updating the price on the list.

```ruby
ProductList.
  find_by!(id: event.data[:product_id]).
  update_attributes!(
    price: BigDecimal.new(event.data[:price]),
  )
```

etc etc.

And then when you want to display _10 most expensive products_ you can do it based on the read side of your application, based on the `ProductList` read-model.

```ruby
ProductList.order("price DESC").limit(10)
```

The write side of your application, the event-sourced `Product` class is about making changes, keeping track of them, and protecting business rules.

## Find out more

Would like to learn more about Event Handlers, Read Models and Event Sourcing? Grab a copy of our [Domain-Driven Rails ebook](/domain-driven-rails/)

<a href="/domain-driven-rails"><img src="<%= src_fit("domain-driven-rails-design/cover7-100.png") %>" width="30%" /></a>