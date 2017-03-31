---
title: "Why your classes eventually reach 50 columns and hundreds of methods"
created_at: 2017-03-31 11:20:39 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ddd', 'bounded contexts' ]
newsletter: :arkency_form
---

There are dozens of small or bigger problems that we can have in our code. Like diseases, they affect our applications and make them harder to maintain, expand and enjoy. They give us a headache and they give bugs to our customers. As a result, we (programmers) read a lot to find out more about the symptoms (code smells) and treatment (refactoring techniques, other languages, other architectures).

One of the most common issues that I see is that classes tend to grow bigger and bigger. In terms of Rails Active Record models, they get new columns/attributes and methods around them. I usually see it in `User` class, but not only. It really depends on what your system is all about. If you work on an e-commerce application it can be `Shop` or `Product` class. If you work on HR application, it can be `Employee`. Think about the most important classes in your system and there is a big chance they keep growing and growing in columns and responsibilities.

<!-- more -->

Reading about "Bounded Contexts", on of the strategical DDD pattern, allowed me to be better understand one of the potential cause of the problem. We hear the same word from many people, used in different situations and we identify the word with the same class. After all, that's what we were often thought in school. You know, the noun/verb mapping into classes/methods.

Let me show you 2 slides from one of my favorite presentation. It was an eye-opener for me.

<%= img_fit("rails-active-record-class-big-attributes-columns/before.png") %>

So... This is what we often think we have. A class (or entity). Just `Product`. Possibly with dozens of attributes and methods.

<%= img_fit("rails-active-record-class-big-attributes-columns/after.png") %>

This is what we could have. `Sales::Product`, `Pricing::Product`, `Inventory::Product`. Separate classes stored in separate storage (just separate tables for start), with their own attributes. When doing such split there are multiple heuristics you can apply to determine how to split a class. Think which attributes change together in a response to certain actions. Check who changes those attributes. Quantities can change because of customer's purchases but pricing is only changed by Merchants.

If you are working on discounts or promotions which are bound to certain conditions, perhaps that itself is reaching a level of complexity when you realize _I have a Pricing context in my application_.

When you catch yourself working on tracking inventory status, writing business rules about which delivery services provider should be used for which products, how it depends on weight or other product attributes then... Maybe you just started implementing an `Inventory` module and it owns certain information about products, which help make all those computations. So perhaps it is time to have `Inventory::Product`.

I know that understanding and putting boundaries in your application can be hard. Especially when you are just starting to work on an application. There is a lot of changes, a lot of new knowledge coming every day. But over time we (developers) should become more careful, more attentive to what is happening to our system. Sometimes we just add one more attribute, just one more column because we don't see how it fits the whole system at that time. I understand it.

But before a class reached 50 columns, there were 40 occasions to review its design, its responsibilities. To see whether some of those attributes and methods now form a cohesive, meaningful object which could be extracted into a separate class. To wonder whether our systems is reaching a level of complexity when we should seriously think about its modularization.

It does not necessarily mean micro-services. You can start with namespaces in your monolith. You can start be splitting those obese classes into smaller ones.

I don't recommend doing it in early stages of the project. It is easy to get things wrong unless the business which came to you already have years of experience from developing previous versions of their software. My recommendation would be to stay vigilant, try to notice those patterns in your application. Introduce modularization when the business is a bit more mature, but perhaps before you have 50 columns problem :)
