---
title: "One Ruby to rule them all"
created_at: 2014-07-01 09:49:36 +0200
kind: article
publish: false
author: Kamil Lelonek
newsletter: :arkency_form
tags: [ 'android', 'ios', 'rubymotion', 'mobile' ]
---

<p>
  <figure align="center">
    <img src="/assets/images/mobile/go-mobile.jpg" width="100%">
  </figure>
</p>

Have you noticed the tendency that **development is moving strongly towards mobile**? There are **more and more projects with mobile** companion, there are a lot of just-mobile software houses, and there are even only-mobile projects.
What if a company has only web developers specialized in Ruby, but want to be really full-stack? Doesn't matter, **with Ruby, it can still goes mobile**!

<!-- more -->

## What were the beginnings?

Yet some time ago, if Ruby developer wanted to experiment with Android or iOS, he have to dive into Java or Objective-C. That might have been cumbersome if he only want to play with it, because he had to learn a new language. For these more assiduous it worked - they learned it, used it, then went back do daily work and... forgot it. You know how is that - not used is being forgotten.

## Let's meet RubyMotion

We'd like to **introduce here and encourage** to use [RubyMotion](http://rubymotion.com/) - toolchain that lets you quickly develop native **[iOS](https://github.com/HipByte/RubyMotionSamples/tree/master/ios)** and **[Android](https://github.com/HipByte/RubyMotionSamples/tree/master/android)** applications using the Ruby programming language.

Our adventure with RM started recently, so we don't feel skilled enough to present here some advanced code yet. That will happen, for sure, in the next blog posts, so you won't miss anything. For now we'd like to focus on our research done so far in that area.

As **we are RoR developers**, we usually depend on gems. They help us not to reinvent the wheel and speed up our development process. Sometimes they are deceptive, but it's not the topic of this blogpost so let's say that there are generally helpful.
Before we started RM we made some research how does the 3rd party support looks like. What struck us the most is that RubyMotion has tremendous bunch of libraries, pods and gems to improve our productivity. So let's talk about them.

1. **Libraries** - have to be shipped with project, are distributed usually as a compressed packages that require to be extracted and included by developers manually.
2. **Pods** - dependencies prepared especially for Objective-C. They were created before RM and are used in many Objective-C projects. Thanks to [HipByte](https://github.com/HipByte/motion-cocoapods), they can be used from Ruby right now.
3. **Gems** - they are rubygems prepared for RM and provide nifty solutions for many common problems in native environments.

### Frameworks
I'm not sure if framework is the best word word for describing what I want do present now, but in RM world there are some tools that makes mobile platforms completely separate from their native languages end extremely easy to implement. They are essentially gems but this is analogy to Rails among other Ruby gems. Here's the list:

- **Vanilla [RubyMotion](http://www.rubymotion.com/features/)** - this is RubyMotion itself, that allows to write the same methods taken form native platforms in ruby with just a little tweaks. It's the closest implementation to Java or Objective-C.

- **[ProMotion](https://github.com/clearsightstudio/ProMotion)** - it makes verbose Objective-C syntax more rubish by hiding native methods behind ruby-convention ones. PM also offers a bunch of ready classes to manipulate views without struggling with sometime complex implementation.

- **[RMQ](http://infinitered.com/rmq/)** - this is the jQuery for Objective-C. It makes extremely easy to manipulate views, traverse between components, animate and style whatever we want and handle events and user gestures.

### Gether them all
From the many [videocasts](http://bigbinary.com/videos/learn-rubymotion), [sources](http://rubymotion-tutorial.com/) and [examples](http://confreaks.com/videos?search=rubymotion) we've extracted basic configurations used among the projects and here they are:

1. **Must-have-one**
 - [SugarCube](https://github.com/rubymotion/sugarcube) - even better syntax for RubyMotion
 - [BubbleWrap](https://github.com/rubymotion/BubbleWrap) - a lot of utilities for managing most common platform elements like persistency, global state, notifications and hardware
 - [AFMotion](https://github.com/usepropeller/afmotion) - best networking library with beautiful DSL and block callbacks
 - [MotionSupport](https://github.com/rubymotion/motion-support) - port of the parts of ActiveSupport that make sense for RubyMotion<p/>

2. **Styling** (with emphasize on SweetKit)
 - [SweetKit](https://github.com/motion-kit/sweet-kit) ([MotionKit](https://github.com/motion-kit/motion-kit) + SugarCube) - layout and styling gem
 - [SweetTea](https://github.com/colinta/sweettea) ([Teacup](https://github.com/colinta/teacup) + SugarCube) - CSS styling, it's seriously awesome, but not [officially maintained yet](https://github.com/motion-kit/motion-kit#goodbye-teacup)<p/>
 
3. **Models**
 - [Core Data Query](https://github.com/infinitered/cdq) -  manage your Core Data stack with data model file
 - [Motion Model](https://github.com/sxross/MotionModel) - DSL for Core Data with validation and mixins<p/>

4. ***Frameworks*** (with preference to simpler for the beginning RMQ)
 - [Promotion](https://github.com/clearsightstudio/ProMotion)
 - [RMQ](https://github.com/infinitered/rmq) (which can use it's own styling mechanism)<p/>

## Summary
We encourage every ruby developer to **try RubyMotion**. It's a great way to **go into mobile** even if you don't know (and like) Java or Objective-C. We are impressed the **RubyMotion great support**, tools and community despite it's a standard as befits the Ruby world.

For now, stay tuned for more mobile blogposts!