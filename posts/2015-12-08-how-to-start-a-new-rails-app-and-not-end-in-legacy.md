---
title: "How to start a new Rails app and not end in legacy"
created_at: 2015-12-08 12:25:37 +0100
publish: false
author: Andrzej Krzywda
---

You've been there before. Starting a new Rails app, everything goes fast at the beginning. This time it's going to be a super clean code base. Some weeks/months later, the progress slows down. The client's trust is much worse. Hard to test and more bugs.

You did it again, didn't you?

Is it Rails fault?

<!-- more -->

One of my techniques to get the most out of the Rails benefits, but not end in the usual mess:

1. Start with the most typical Rails-way approach
2. After some time (2-3 weeks?) start escaping from Rails into Clean Code / DDD

Rails is fantastic at the beginning. The productivity, the joy, the happiness, it's all here. Rails is optimized for the first hours/days/weeks of development. At that time, you often add new tables, new columns, new forms, etc. Everyone loves the speed at the beginning, me as the developer, the clients/users who see the app growing up very quickly.


However, after some time, things start to slow down, if you keep following the Rails Way approach. First bugs appear, hard to add new features, hard to test. It's hard to implement complex business logic - workflows, state machines. The client is no longer loving you as much as in the beginning.

**Where's the secret**?

Start reducing the Rails Way before it happens.
I know, we don't travel in time, so we need to base it on our intuition and experience.

What exactly can we do to reduce The Rails Way?

Start to write more tests and see the pain points:

* It's hard to test controllers, so simplify them by extracting **service objects**
* The tests are fragile because JavaScript snippets rely on backend-generated html - move more logic to the **frontend** and generate more html with JavaScript (maybe React.js?)
* The ActiveRecord patterns feels invasive to the application? - consider extracting **repository** objects
* It's hard to test the application with 3rd party API? consider extracting **adapter** objects.

Some links which may be helpful, if this technique sounds interesting:

service objects

[http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/](http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/)
 
[http://blog.arkency.com/2015/05/extract-a-service-object-using-simpledelegator/](http://blog.arkency.com/2015/05/extract-a-service-object-using-simpledelegator/)

[adapter objects with Rails](http://blog.arkency.com/2014/08/ruby-rails-adapters/)

[Rails repository objects](http://blog.arkency.com/2015/06/thanks-to-repositories/)

[React.js](http://blog.arkency.com/2015/11/arkency-react-dot-js-resources/)

