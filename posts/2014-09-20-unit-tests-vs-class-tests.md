---
title: "Unit tests vs class tests"
created_at: 2014-10-12 19:06:17 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: skip
newsletter_inside: fearless_refactoring_course_instantiating
tags: ['testing']
img: "unit_tests_vs_class_tests/GULLIVERS-TRAVELS.JPG"
---
<p>
  <figure>
		<img src="<%= src_fit("unit_tests_vs_class_tests/GULLIVERS-TRAVELS.JPG") %>" width="100%">
  </figure>
</p>

There's a popular way of thinking that unit tests are basically tests for classes.

I'd like to challenge this understanding.

<!-- more -->

When I work on a codebase that is heavily class-tested, I find it harder to do refactoring. If all I want is to move some methods from one class to another, while preserving how the whole thing works, then I need to change at least two tests, for both classes.

## Class tests slow me down

Class tests are good if you don't do refactoring or if most of your refactorings are within 1 class. This may mean, that once you come up with a new class, you know the shape of it.

I like a more light-weight approach. Feel free to create new classes, feel free to move the code between them as easily as possible. It doesn't mean I'm a fan of breaking the functionalities. Totally the opposite. I feel paralysed, when I have to work on untested code. My first step in an unknown codebase is to check how good is the test coverage.

How to combine such light-weight refactoring style with testing?

## Test units, not classes

I was in the "let's have a test file per a class" camp for a long time. If I created a OrderItem class, it would probably have an equivalent OrderItemTest class. If I had a FriendPresenter, it would have a FriendPresenterTest.

With this approach, changing any line of code, would result in failing tests.

Is that really a safety net?

It sounds more like **cementing the existing design**. It's like building a wall in front of the code. If you want to change the code, you need to rebuild the wall.

In a team, where collective ownership is an accepted technique, this may mean that whoever first works on the module, is also the one who decides on the structure of it. It’s not really a conscious decision. It’s just a result of following the class-tests approach. Those modules are hard to change. They often stay in the same shape, even when the requirement change. Why? Because it’s so hard to change the tests (often full of mocks). Sounds familiar?

**What's the alternative?**

The alternative is to think in units, more than in classes. What's a unit? I already touched on this subject in [TDD and Rails - what makes a good unit?](http://andrzejonsoftware.blogspot.com/2014/04/tdd-and-rails-what-makes-good-unit.html). Let me quote the most important example:

You've got an Order, which can have many OrderLines, a ShippingAddress and a Customer.

Do we have 4 units here, representing each class? It depends, but most likely it may be easier to treat the whole thing as a Unit. You can write a test which test the whole thing through the Order object. The test is never aware of the existence of the ShippingAddress. It's an internal implementation detail of the Order unit.

**A class doesn't usually make a good Unit, it's usually a collection of classes that is interesting.**

## The Billing example

In one of our projects, which is a SaaS service, we need to handle billing, paying, licenses. We've put it in one module. (BTW, the 'module' term is quite vague nowadays, as well). It has the following classes:

* Billing (the facade)
* Subscription
* License
* Purchase
* Pricing
* PurchasingNotEnoughLicenses
* BillingDB
* BillingInMemoryDB
* BillingNotificationAdapter
* ProductSerializer

It's not a perfect piece code (is there any in the world?), but it's a good example for this topic. We've got about 10 classes. How many of them have their own test? Just the Billing (the facade). 
What's more, in the tests we don't reference and use any of those remaining classes. We test the whole module through the Billing class. The only other class, that we directly reference is a class, that doesn't belong to this module, which is more of a dependency (shared kernel). Obviously, we also use some stdlib classes, like Time.

BTW, did you notice, how nicely isolated is this module? It uses the payment/billing domain language and you can’t really tell for what kind of application it’s designed for. In fact, it’s not unlikely that it could be reused in another SaaS project. To be honest, **I’ve never been closer to reusing certain modules between Rails apps, than with this approach**. The reusability wasn’t the goal here, it’s a result of following good modularisation.

Some requirements here include:

* licences for multiple products
* changing licences within a certain date
* terminating licenses
* license counter

It's nothing really complicated - just an example.

What do I gain, by having the tests for the whole unit, instead of per-class?

**I have the freedom of refactoring** - I can move some methods around and as long as it's correct, the tests pass. I tend to separate my coding activities - when I'm adding a new feature, I'm test-driven. I try to pass the test in the simplest way. Then I'm switching to refactoring-mode. I'm no longer adding anything new, I'm just trying to find the best structure, for the current needs. It's about seconds/minutes, not hours. When I have a good shape of the code, I can go to implement the next requirement. 

**I can think about the whole module as a black-box.** When we talk about Billing in this project, we all know what we mean. We don't need to go deeper into the details, like licenses or purchases. Those are implementation details.

When I add a new requirement to this module, I can add it as a test at the higher-level scope. When specifying the new test, I don't need to know how it's going to be implemented. It's a huge win, as I'm not blocked with the implementation structure yet. Writing the test is decoupled from the implementation details.

Other people can enter the module and clearly see the requirements at the higher level.

Now, would I see value in having a test for the Pricing class directly? Having more tests is good, right?
Well, no - tests are code. The more code you have the more you need to maintain. It makes a bigger cost. It also builds a more complex mental model. 
Low-level tests are often causing more troubles than profit. 

Let me repeat and rephrase - **by writing low-level tests, you may be damaging the project**. 

As Damian Hickey puts it in [an excellent way](http://dhickey.ie/post/2014/03/03/gulliver-s-travels-tests.aspx):

_Like writing lots and lots of fine-grained "unit" tests, mocking out every teeny-weeny interaction between every single object?
This is your application:_

<img src="/assets/images/unit_tests_vs_class_tests/GULLIVERS-TRAVELS.JPG">


_Now try to change something._


<%= show_product_inline(item[:newsletter_inside]) %>
