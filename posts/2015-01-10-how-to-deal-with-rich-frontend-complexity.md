---
title: "How to deal with rich frontend complexity?"
created_at: 2015-01-04 15:28:14 +0100
kind: article
publish: false
author: Marcin Grzywaczewski 
tags: [ 'frontend', 'coffeescript', 'oop', 'architecture' ]
newsletter: arkency_form
---

Frontend part of many modern Rails' apps goes way beyond server-side served parts of HTML and CSS. Sophisticated UX solutions surround you even if you're a die-hard backend developer - I'm sure you've used or heard about tools like [GitHub](https://github.com), [Trello](https://trello.com) or [Discourse](http://www.discourse.org). Such tools makes your day-to-day work easier and it's often that your clients want the same level of experience. It's often hard to achieve though - **frontend development can be really different than traditional Rails development and it's easy to turn your code [into the big ball of mud](http://blog.arkency.com/2014/07/6-front-end-techniques-for-rails-developers-part-i-from-big-ball-of-mud-to-separated-concerns/)**. While you may find it very unpleasant, it's often the consequence of bad design - but how you can design in such different environment?

One of solutions is to include one of a big frontend frameworks to your project - like Angular or Ember.js. It brings kind of segregation to your frontend code. But there is a big cost - you must learn all terminology and so-called *way* of doing things in a particular frameworks which can be hard. You need to live with decisions that framework developers have under their control like two-way data binding - useful in general, pain to get rid of if you don't want it. And what makes JavaScript community so great and powerful - rapid change - is your enemy here. Frameworks come and go and even the most stable ones can introduce revolutional changes - **finding support for the niche framework you chose can be hard and escaping from any framework is a serious commitment**.

But what if you can make your code structured without worrying about change? Can we have code where changing a tool is a small commitment? Is there a way to have this delightful *Ok, I know exactly where code responsible for this part is!* feeling without resorting to a frameworks? Sure we can!

**Relying on a good architecture rather than frameworks allows us to retain full control while working with code easier and faster**. What's more - **it's a real fun to come with ideas to improve and change code architectures**! In Arkency there are some well-established architectures and tools you can use to make your frontend code organized and fun to work with. We're still developing improvements for them - I want to show you a ready-to-use overview of our established practices in this field.

<!-- more -->
