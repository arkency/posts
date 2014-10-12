---
title: "Concurrency patterns in RubyMotion"
created_at: 2014-08-19 08:23:34 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :skip
newsletter_inside: :mobile
tags: [ 'concurrency', 'parallelism', 'gdc', 'ruby', 'rubymotion', 'ios', 'mobile' ]
stories: ['rubymotion']
---

<p>
  <figure align="center">
    <img src="/assets/images/mobile/line-queue-fit.jpg" width="100%">
  </figure>
</p>

The more we dive into RubyMotion, the more advanced topics we face with. Currently, in one of our RubyMotion applications we are implementing QR code scanning feature. Although it may seem already as a good topic for blogpost, this time we will focus on **concurrency patterns in RubyMotion**, because they are a good start for any **advanced features in iOS** like this 2D code recognition.

<!-- more -->

## Caveats
From the very beginning, it's worth to quote [RM documentation](http://www.rubymotion.com/developer-center/guides/runtime/#_grand_central_dispatch):

> Unlike the mainstream Ruby implementation, [race conditions](http://en.wikipedia.org/wiki/Race_condition#Computing) are possible in RubyMotion, since there is no [Global Interpreter Lock](http://en.wikipedia.org/wiki/Global_Interpreter_Lock) (GIL) to prohibit threads from running concurrently. You must be careful to secure concurrent access to shared resources.

Although it's a quotation from official documentation, we experienced that despite of using GIL, we still can fall into race condition.

So before any work with concurrency in RubyMotion, beware of accessing shared resources without preventing them from race condition.

## GCD
RubyMotion wraps the [Grand Central Dispatch](https://developer.apple.com/Library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) (GCD) concurrency library under the Dispatch module. **It is possible to execute both synchronously and asynchronously blocks of code under concurrent or serial queues**.
Although it is more complicated than implementing regular threads, sometimes GCD offers a more **elegant way to run code concurrently**.

Here are some facts about GDC:

- GCD maintains for you a pool of threads and its APIs are architectured to **avoid the need to use mutexes**.
- GCD uses multiple cores effectively to better accommodate the needs of all running applications, matching them to the available system resources in a balanced fashion.
- GCD automatically creates three concurrent dispatch queues that are global to your application and are differentiated only by their priority level.

## Queue
A `Dispatch::Queue` is the fundamental mechanism for **scheduling blocks** for execution, either **synchronously or asychronously**.

Here is the basic matrix of `Dispatch::Queue` [methods](https://developer.apple.com/library/mac/DOCUMENTATION/Darwin/Reference/ManPages/man3/dispatch_async.3.html). Rows represent whether to run in blocking or non-blocking mode, columns represent where to execute the code - in UI or background thread.

|       | Main                       | Background                                 |
|-------|----------------------------|--------------------------------------------|
| **Async** | `.main.async` | `.new('arkency_queue').async` |
| **Sync**  | `.main.sync`  | `.new('arkency_queue').sync`  |

**`.main.sync`** - it's actually equivalent to regular execution. May be helpful to run from inside of background queue.

**`.main.async`** - schedule block to run as soon as possible in UI thread and go on immediately to the next lines.

When can this be helpful? All view changes have to be done in the main thread. In the other case you may receive something like:

```
#!bash
Tried to obtain the web lock from a thread other than the main thread or the web thread.
This may be a result of calling to UIKit from a secondary thread.
Crashing now..
```

To update UI from background thread:

```
#!ruby
Dispatch::Queue.new('arkency').async do
  # background task

  Dispatch::Queue.main.sync do
    # UI updates
  end

  # background tasks that wait for updating UI
end
```

**`.new('arkency_queue').async`** - operations in background thread ideal for processing lots of data or handling HTTP requests.

**`.new('arkency_queue').sync`** - may be use for synchronization critical sections when the result of the block is not needed locally. In addition to providing a more concise expression of synchronization, this approach is less error prone as the critical section cannot be accidentally left without restoring the queue to a reentrant state.

> Conceptually, `dispatch_sync()` is a convenient wrapper around `dispatch_async()` with the addition of a semaphore to wait for completion of the block, and a wrapper around the block to signal its completion.

These functions support efficient temporal synchronization, background concurrency and data-level concurrency. These same functions can also be used for efficient notification of the completion of asynchronous blocks (a.k.a. callbacks).

This time, some facts about queues:

- All blocks submitted to dispatch queues begin executing in the order they were received.
- The system-defined queues can execute multiple blocks in parallel, depending on the number of threads in the pool.
- The main and user queues wait for the prior block to complete before executing the next block.

Queues are not bound to any specific thread of execution and blocks submitted to independent queues may execute concurrently.

## Singletons
**Singleton?** `Dispatch` module has only one module method which is [`once`](http://www.rubymotion.com/developer-center/api/Dispatch.html#once-class_method). It executes a block object once and only once for the lifetime of an application. We can be sure that whatever we placed inside passed block, will be run exactly one time in the whole lifecycle. Sounds like **singleton** now?

This technique is recommended by Apple itself to create shared instance of some class. In native iOS it may look like:

```
#!c
+ (MyClass *)sharedInstance
{
    static MyClass *sharedInstance;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [MyClass new];
    });
    return sharedInstance;
}
```

which is actually the same thing as:

```
#!c
+ (MyClass *)sharedInstance {
    static MyClass *sharedInstance;
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [MyClass new];
        }
    }
    return sharedInstance;
}
```

As you can see, the `dispatch_once` function takes care of all the necessary locking and synchronization. Moreover it is not only cleaner, but also [faster](http://bjhomer.blogspot.com/2011/09/synchronized-vs-dispatchonce.html) (especially in future calls), which may be an issue in many cases.

In RubyMotion implementation may be as follows:

```
#!ruby
class MyClass
  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end
end
```

`{ @instance ||= new }` block is guaranteed to be yielded exactly once in a thread-safe manner to crate singleton object.

<%= inner_newsletter(item[:newsletter_inside]) %>

## Summary
Concurrency in native iOS, or rather C, is far more advanced than in RubyMotion. From the other side, `Dispatch` module offers a lot of features too, more complicated than we described here. It's worth to get familiar with these methods so that we can better manage code execution.

It's also worth to take a look at [BubbleWrap Deferable module](https://github.com/rubymotion/BubbleWrap/blob/master/motion/reactor.rb), which wraps some [Dispatch::Queue operations](https://github.com/rubymotion/BubbleWrap/blob/master/motion/reactor.rb#L88) in even more elegant way.

### Resources
- http://www.raywenderlich.com/4295/multithreading-and-grand-central-dispatch-on-ios-for-beginners-tutorial
- http://www.raywenderlich.com/60749/grand-central-dispatch-in-depth-part-1
- http://www.raywenderlich.com/63338/grand-central-dispatch-in-depth-part-2
- http://jeffreysambells.com/2013/03/01/asynchronous-operations-in-ios-with-grand-central-dispatch

#### Posts:
- http://jeffreysambells.com/2013/03/01/asynchronous-operations-in-ios-with-grand-central-dispatch

#### Official Guides:
- https://developer.apple.com/library/mac/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008091-CH1-SW1
- https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Multithreading/Introduction/Introduction.html#//apple_ref/doc/uid/10000057i

#### Libraries:
- https://github.com/seanlilmateus/futuristic
- https://github.com/rubymotion/BubbleWrap
- https://github.com/mattgreen/elevate
- https://github.com/macfanatic/motion-launchpad
- https://github.com/MohawkApps/motion-takeoff
- https://github.com/opyh/motion-state-machine
- http://jeffreysambells.com/2013/03/01/asynchronous-operations-in-ios-with-grand-central-dispatch
