---
title: "Rails: MVP vs prototype"
created_at: 2016-02-12 20:07:59 +0100
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :skip
---

[In the last blog post](http://blog.arkency.com/2016/02/where-and-why-im-still-using-rails/) I explained my approach to using Rails  to quickly start a new app. In short - I'm starting with Rails but I also learnt how to gradually escape from the framework and separate the frontend.

Janko Marohnic commented on that and I thought it would be nice to reply here, as the reply covers the distinction between an MVP and a prototype.

<!-- more -->

Here are his words:
 

*The problem that I have with always starting to Rails is that it's later difficult to change to another framework or design. That's why I think if you want to later start with frontend and backend separate, you should do so from the beginning. If we practice that like we've practiced with Rails, we would become equally familiar*.

*I see some people have arguments that you can quickly prototype with Rails. I think in a frontend framework like React.js it's much easier to prototype, since you don't need to write any backend. You just have to be familiar with it, of course*.

*If you want the ActiveRecord pattern in a non-Rails framework, I think that's a great opportunity to switch to Sequel, since it's better than ActiveRecord in every possible way. So there is no need to switch to Rails here, but see for yourself how non-Rails libraries can be so much better than Rails*.

*I don't find things in Rails to be just working. Sprockets so often didn't work properly in the past. Spring started working properly only like 1 year after it was released. ActiveRecord is still missing some crucial features, like LEFT JOINs, PostgreSQL-specific support (so that you can actually use your database instead of Ruby) and a low-level interface where you don't have to instantiate AR objects that is actually usable (ARel is terrible). Turbolinks also didn't work properly, was getting authenticity token errors (without any AJAX). I definitely didn't find it just working*.



Janko touched some important topics here. Let me reply here. Janko's words are made bold.

**The problem that I have with always starting to Rails is that it's later difficult to change to another framework or design**. 

I don't think it's always true. This is actually where most of my focus goes - [how to gradually change your app so that it doesn't rely on Rails](http://controllers.rails-refactoring.com). It's not easy, but in many projects we proved it's possible and worth the effort. The sooner you start the separation, the easier it goes. This doesn't mean going there from the beginning.

**That's why I think if you want to later start with frontend and backend separate, you should do so from the beginning. If we practice that like we've practiced with Rails, we would become equally familiar**.

This is a problematic advice. If you're so skilled to be able to build a nicely separated application from the scratch - then yes, that's the way to go. What I'm seeing, though, is that even experienced React developers (as in 2 years of React experience) who happen to also have Rails skills, are not equally fast with the React frontend vs Rails-based frontend. 

So, when time to market is important, I think going with Rails (with the intention of refactoring it later) is faster overall.

I do agree with the notion that if we're practicing working with frontends/backends separately then we'll come to the position where it's easier to separate from the beginning. It does take time, though.

This is also the same with DDD. I think it's easier (time-to-market-wise) to start with The Rails Way than starting with DDD. However, once you're so good with DDD that you can make it faster (I'm not there yet), they don't rely on Rails.

It's all based on the time-to-market metric here. If you have the luxury of doing "the right thing" from the beginning and shipping quickly is not the main prio, then let's go with the right thing. I'm involved in such DDD projects and they have the maintainable architecture/design/code from the beginning.

**I see some people have arguments that you can quickly prototype with Rails. I think in a frontend framework like React.js it's much easier to prototype, since you don't need to write any backend. You just have to be familiar with it, of course**.

It's this part of the comment that made me think the most here. In many places [I'm advocating the idea of going frontend-first](http://andrzejonsoftware.blogspot.com/2013/02/frontend-first.html). This technique allows focus on the frontend (as the more important) part first. We can get it right as the first task and then we know how to build the backend because we know what data we need.

I've worked on many such projects and it worked very well.

There's one important distinction here. It's the prototype vs MVP distinction.

My definition of a prototype is of something that I can click, feel, experience. However, it's usually not production-ready. If you start with the frontend, you don't have an easy way to make it production ready, if there's no backend.

What Rails allows us to do is MVPs - the Minimum Viable Products. It's more than a prototype. It's a prototype + the fact that it's production ready. Rails gives all the basic security rules - CSRF, SQL Injection protection which makes building the whole thing faster and actually release it.

Both approaches are worth considering - if you feel that your project benefits more from just the prototype and your frontend/JS skills are good enough to make you deliver it quickly - then perfect. Do it. Then build the backend. Enjoy the separation.

If it's important to ship to the actual market as quickly as possible (I'm thinking days/weeks here, not months), then I believe Rails can make it happen faster.

BTW, it's a similar discussion to whether to go microservices first or not.

**If you want the ActiveRecord pattern in a non-Rails framework, I think that's a great opportunity to switch to Sequel, since it's better than ActiveRecord in every possible way. So there is no need to switch to Rails here, but see for yourself how non-Rails libraries can be so much better than Rails**.

It never happened to me to want to have the active record pattern in a non-Rails framework. If I  want to go with active record, then Rails makes it perfect for me with the ActiveRecord library. 
It's not that I'm against Sequel. We used it in our projects and it felt to me like just a slightly different API as compared to ActiveRecord. It's definitely lighter.

I think the distinction here is whether I want to go with The Rails Way or not. To me, The Rails Way means using the active record object in all layers of the application. If we want to do it, then AR makes more sense to me. If we seperate our persistence nicely, then Sequel may be a good alternative. However, it's definitely possible to hide the ActiveRecord behind a repository layer and have the same gains, but with AR.

**I don't find things in Rails to be just working. Sprockets so often didn't work properly in the past. Spring started working properly only like 1 year after it was released. ActiveRecord is still missing some crucial features, like LEFT JOINs, PostgreSQL-specific support (so that you can actually use your database instead of Ruby) and a low-level interface where you don't have to instantiate AR objects that is actually usable (ARel is terrible). Turbolinks also didn't work properly, was getting authenticity token errors (without any AJAX). I definitely didn't find it just working**.

This is a perfect summary of what is the danger of using some Rails features. Very well put.

I did generalize and simplify in my last email, that Rails just works. This was a simplification.

Rails just works, unless you start using the new and shiny things too quickly.

I'm vey conservative in my approach, when it comes to new features. I'm excited about the ActionCable addition, but I'm not going to use it very soon (I love Pusher for that).

**Sprockets** - they are a pain, especially in bigger projects. In smaller projects they don't hurt as much. If you start with them, but then switch to more modern JS approaches like Webpack, you shouldn't be affected by the Sprockets problems.

**Spring** - I don't use it all.

**ActiveRecord** is missing some crucial features, but you can always go down and just use your own SQL, in those places. If your data layer is separated it shouldn't hurt as much. I'm not advocating for using SQL everywhere, it's just in those missing places.

**Turbolinks** - I use it only when actually forget to disable it in a new app - and thanks for the reminder, in my current project I forgot to disable it. 



So, what is worth remembering here?

The notion of the time-to-market metric is important. If time-to-market is crucial, Rails may be fastest.

It's worth to know the distinction between a prototype and an MVP.
A prototype is something you can click on, while MVP is a prototype that is production-ready and can be exposed to the real world.


PS. Janko, thanks for your valuable comment!

PS2. If you'd like to improve your React/JavaScript skills, then our [free React.js koans](https://github.com/arkency/reactjs_koans) are a perfect place to start!
