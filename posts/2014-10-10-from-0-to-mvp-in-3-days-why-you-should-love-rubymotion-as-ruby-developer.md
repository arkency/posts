---
title: "From 0 to MVP in 3 days - why you should love RubyMotion as Ruby developer"
created_at: 2014-10-10 03:13:30 +0200
kind: article
publish: false
author: Marcin Grzywaczewski
newsletter: :skip
newsletter_inside: :mobile
tags: [ 'ruby', 'ios', 'rubymotion', 'mobile' ]
stories: ['rubymotion']
---

<p>
  <figure align="center">
    <img src="/assets/images/from-0-to-mvp-rubymotion/header-image-fit.jpg" alt="" />
  </figure>
</p>

Recently in Arkency we've decided to cope with the mobile market to expand offer to our customers. **Since our team are mostly rubyists, we have decided to try RubyMotion**. Some days ago I finished my project and it was a great occasion to create a simple app to easily share our content with Ruby community. We are blogging heavily and we want to provide nice solution for all who want to read our blogposts and follow our communication channels.

The experiment went very well. **There is no reason for Ruby developer to choose another technology if you want to develop an iOS app**. Prototyping with this technology is fast, materials for learning are easily accessible and you can make your workflow pretty similar to Rails development if you want.

**I have started with nearly zero knowledge about iOS development. After 3 days I've developed fully working MVP**. In this blogpost I'd like to talk about what makes RubyMotion friendly for Ruby developers and why we have chosen it after all.

<!-- more -->

## Fast start

RubyMotion projects creation is similar to Rails. **There is only one command to bootstrap your application and one command to compile it**. This skeleton is really small and you can compile it straight away. 

All project-specific commands (compilation, cleaning) are incorporated into a `rake` command - so it's quite similar to what we have in Rails. RubyMotion is integrated with Bundler by default so adding new gems are straightforward and there are no surprises here.

The manifest file of your application is `Rakefile`. Here you set all information like icon paths, app name, allowed devices and screen orientations and so on. These informations are translated during compilation to the `Info.plist` file which is a typical iOS app manifest file.

All these small similarities allows you to work with RubyMotion projects easily. **You shouldn't have any problems to operate on RM project if you come from Rails**.

## You can easily incorporate iOS developers workflow

Your friends can work on iOS applications in a traditional way. They use XCode to include assets, use [Core Data](http://en.wikipedia.org/wiki/Core_Data) within it to define data structures, lay out their UI using [Interface Builder and Storyboards](https://developer.apple.com/xcode/interface-builder/). You could think they have an easier life due to a great IDE. But it is not true. **You can use all benefits which XCode provides to you**. [Motion-IB](https://github.com/rubymotion/ib) gem allows you to integrate with Storyboards. You can use old-fashioned XIB solutions out of the box. You can integrate further with XCode using [xcodeproj](https://github.com/CocoaPods/Xcodeproj). All tools you'd probably use to create a simple app are there, ready to use. **That makes your learning even easier since you can use the same tools that iOS developers use.**

## RubyMotion is a really thin wrapper to iOS API...

You may think about it as a bad thing. But it makes one thing very easy - **you can easily use both RM developers and Obj-C/Swift developers knowledge during your learning process**.

Most functions that Obj-C developers use work in RubyMotion. You can use iOS documentation of the standard lib - and it works. There are LOTS of articles (both official and made by community) you can rely on. And you can even easily try an Objective-C code snippets since they can be easily incorporated to your project. During my learning process I relied often on blogposts and StackOverflow threads made by iOS developers - and I had no problems with translation of code snippets to the Ruby code. Thanks to this, even if RubyMotion is not as popular as Rails, **there will be no problem to find help if you get stuck or you have no idea how to achieve your goal.**

## ... but you can change it easily if you want

Ruby community is known and famous for great libraries and DSLs to make code easier to work with and more readable. Objective-C is much lower level language than Ruby - and it may hurt you as a Ruby developer. Fortunately, **RubyMotion community created gems to make interaction with iOS API more Ruby-like**. 

Most of them are inspired by solutions all Rails developers already know - for example, a [motion-support](https://github.com/rubymotion/motion-support) gem which provides most of ActiveSupport core extensions we love. We got great DSLs to create UI in code ([TeaCup](https://github.com/colinta/teacup), [MotionKit](https://github.com/motion-kit/motion-kit), [RMQ](https://github.com/infinitered/rmq)...) and other APIs like binding to events ([BubbleWrap](https://github.com/rubymotion/BubbleWrap), [SugarCube](https://github.com/rubymotion/sugarcube)) or networking ([AFMotion](https://github.com/clayallsopp/afmotion)) and a lot more. You can often use gems you like if they are pure Ruby (like [dotenv](https://github.com/bkeepers/dotenv)). **There are a lot of ways to make working with iOS APIs almost 100% Ruby-like.** Damn, we're a really great community!

## There is a pod for that (or two)!

With RubyMotion, **you can easily use a variety of libraries that are in common use of iOS developers**. [Motion-CocoaPods](https://github.com/HipByte/motion-cocoapods) allows you to use a CocoaPods library which is RubyGems equivalent for Objective-C developers. That opens door for providing much more sophisticated features to your app (like [image processing](https://github.com/under-os/under-os-image)) without a hassle. Ruby ease of use with power of libraries which powers the most advanced iPhone and iPad apps in the world? Sounds like a great thing!

## Not only a mobile solution

With RubyMotion you can also develop OSX apps. We have not tried it yet, but it's also an interesting market. It makes this **solution complete to provide full-stack experience to users of your start-up or your client businesses.**

## Android support built-in

RubyMotion is actively developed library. **Android support is officially announced and it is included in recent versions**. Investing in this technology can be really cost-effective since you can develop mobile solutions for both major platforms on the market.

<%= inner_newsletter(item[:newsletter_inside]) %>

## Summary

As a passionate developer I always love to try new programming tools and libraries. I got an opportunity to try RubyMotion and now I'm totally convinced that it'll remain as my technology of choice when it comes to create mobile solutions. I'd really recommend to give it a try if you have an occasion.

If you want to see it in action, Arkency application is available as an open source. **We want to share with you what it can be achieved in RubyMotion (made by a RubyMotion newcomer) in one week.** It is also a great occasion for us to prepare a good content about RubyMotion for you. Stay tuned!

