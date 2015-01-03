---
title: "The categories of validations"
created_at: 2015-01-03 15:07:05 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :skip
tags: [ 'foo', 'bar', 'baz' ]
---

<p>
  <figure>
    <img src="/assets/images/validations-categories/157H-fit.jpg" width="100%">
  </figure>
</p>

There are many reasons why rails changed the landscape of web development when it was released.
I think one of the aspects was how easy it was to communicate mistakes (errors) to the user.
Validations is a very nice convention for CRUD applications. Over time however, many of our active
record objects tend to grow in terms of validations. I think they fit at least into a few
categories (probably more).

<!-- more -->

* **trivial validations**
    * _"is this field empty?"_
    * trivial doesn't mean not important (we still need them)
* **domain validations**
    * _"is this product available in inventory"_
    * _"does this coupon code apply in this situation"_
* **security validation**
   * _"is this user allowed to do it"_
   * _"is the data not crafted in wrong way"_
   * _"do all associated children belong to the same user as parent record"_
* **use-case based**
   * _"is this facebook user registering and does she/he have this attribute present"_
* **aggregate internal state**
    * _"is this Order without empty OrderLines"_
    * _"does the order transaction amount equal amount from sum of order lines"_

So it's not uncommon to have half a dozen unrelated validations in an active record class. And they **sometimes lack cohesion** when you look at them together. To achieve better clarity and modularity in the application it might be good to start moving them to separate places.

Maybe the trivial validations are better suited in form objects in your case? Maybe domain checks should be moved into Service objects because our `Order` class shouldn't know and access the `Inventory` related data? Maybe **security validations don't need to be validations at all**? If security constraint is violated raising an exception could be better. Polite users won't see this validation ever anyway. Why be nice to hackers and display them a nice validation message?

Use-case based verifications? Maybe they belong to that one usecase (service object) only and the rest of the app doesn't need to know about it. The point being...

Once you find yourself in a situation where your object is coupled with many validations, especially such that are **crossing multiple boundaries** and verifying things from completely other parts of the system, you might wanna decouple it a little bit. Make it lighter. Move the validations into other places where they fit better. **Validations are often big bag of things that we need to check before we let the user proceed further. It's worth to think from time to time how to organize this bag. Maybe into a nice rucksack?**

That's why [Fearless Refactoring: Rails Controllers](http://rails-refactoring.com/) 1.1 release includes 2 practical and 2 theoretical chapters that will help you get started.

* Extract conditional validation into Service Object
* Extract a form object
* Validations: Contexts
* Validations: Objectify

Happy refactoring

Robert Pankowecki & Andrzej Krzywda
