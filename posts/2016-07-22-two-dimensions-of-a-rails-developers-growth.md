---
created_at: 2016-07-22 19:53:41 +0200
publish: true
tags: [ 'rails', 'architecture' ]
author: Andrzej Krzywda
---

# Two dimensions of a Rails developer's growth

Yesterday I was contacted by a developer through our [Post Rails Book Bundle](http://www.railsbookbundle.com) intercom. He wasn't sure about whether the bundle is right to him. I quickly jumped to a phone call (how old-school!) with him and it turned into a very interesting discussion!

One topic that was relevant here is **how to grow as a Rails developer**. 

<!-- more -->

In my opinion, there are two main "dimensions" of growth. Both need to be improved **continuously**. The first direction is the "technology" part - learning languages, learning frameworks, libraries, APIs. This is quite clear, as that's what expected from us in the daily jobs. We need to write new features to our Rails apps - we need to know Ruby, we need to know the standard libraries of Ruby. We also need to know Rails, not just the scaffolding, but also all the details of associations, validations, controllers, routes, view helpers. The better we know it, the faster we implement the features.

This is very helpful in debugging too. If you know the frameworks you're using it's easy for you to spot the problem. This is often what makes one programmer N times faster than other. Not in the "new features time", but the debugging time. 

However, there is a trap. **If you're focused too much on the technology dimension, you will follow too much The Framework Way**. You will focus on using the specific solutions for the technology. You may apply some tricks which are only known in this community. Heck, you may even add some "hacks" so that it's  in the spirit of that technology.

Rails Conditional validations anyone?
Controller filters with :except anyone?
ActiveRecord + Single Table Inheritance anyone?

There's another direction, often neglected by developers. It's the "generic" skills as a programmer:

- testing
- TDD
- refactoring
- design patterns
- DDD
- clean architecture
- DCI
- Ports&Adapters
- Aspects
- Databases/ACID/CAP
- Programming Paradigms
- Concurrency/Parallelism
- DevOps
- Communication and Soft Skills

Those are the things that make you be able to talk to **programmers from other technologies**.
 

Can you talk to a PHP/Symfony programmer?
Can you talk to a Java/Spring/Akka/Scala/Clojure developer?
Can you talk to a .NET programmer?
Can you talk to a JavaScript/React.js developer?

The problem with learning in this dimension of your growth is that it seems hard to apply in your current job. It's hard to apply in your current Rails project.

It's nice to talk about DDD, but then you come back to **your 1000-line controller with a complex filters algebra**! What a change!

On one hand, this direction of growing, helps you long-term. You no longer need to worry what happens if Rails is really dead. You'll use your generic skills to learn other languages and frameworks.

**The confidence you get by knowing that you can always switch and it's going to be easy is priceless!**

I like working with Rails, I like working with React.js. But I'm not worried too much what happens if they disappear. The programming patterns that I'm using are any-technology-friendly. I can do DDD in any language. I can build more layers in any framework (well, I'm not sure about Angular ;) ).

So, it's great to grow as a developer with patterns, architectures and stuff. But how can we apply it in the current projects? How can we use it with Rails?

This is where I believe the Post Rails Book Bundle shines! The books and videos are exactly this - a nice combination of growing within a technology but by applying timeless patterns.

From the 2 of Giles books, you can learn why **Rails is not so OOP** and why it matters.

From my "Fearless Refactoring" book you can learn how to extract new classes and new layers (forms, adapters, repos, services) **even this week in your project**! It's all verified techniques.

You can watch my Rails and TDD videos to see an almost like science-fiction approach to building a Rails app, with the **DDD-infected way of thinking**, while being **mutation covered**!

You can read and apply the **Trailblazer** techniques by Apotonick, as they come with libraries and gems, making it even easier to apply. They come with similar layers, as described in my book!

You can (and should!) apply the modularizing/namespacing techniques from the **"Growing Rails"** book. You can extract gems (yes!) from your code, thanks to the **"Modular Rails"** book.

It's all exactly the combination of the two worlds of growing. It's all the best from the two worlds!

Happy growing as a software developer :)

[Post Rails Book Bundle](http://railsbookbundle.com)

