---
title: "The Beginners Guide to jQuery.Deferred and Promises for Ruby programmers"
created_at: 2015-02-24 19:30:23 +0100
kind: article
publish: true
newsletter: react_books
author: Marcin Grzywaczewski
tags: [ 'jquery', 'frontend', 'promise', 'case-study' ]
---

Working with asynchronous code is the bread and butter for frontend developers. You can find it hard when working with it at first - as a Rails developer, you live with code which is usually synchronous. Luckily, promises were something which allowed us to get a huge step forward to deal with callbacks in a sane way. While widely adopted by backend JavaScript developers, **Promises and their tooling is something often missed by Rails devs.**

**It can be different - and you have all important libraries bundled by default in our Rails app.** Let's see what jQuery can offer you here - and I'll discuss how I managed to solve typical async problem with features that jQuery provides.

<!-- more -->

## Problem (in the domain way)

I'm working on fairly big project which have frontend composed of microapps. Such microapp is providing services to build our frontend - it's often a package of React components to build a view, commands which you invoke to perform an action on backend, and the storage - a class which encapsulates our data and reacts if this data is changed (it is similar to Store in Flux terminology). The whole thing is 'glued' together in a dispatcher - you may think of it as a telephone central when we 'route' events from our pieces to another piece.

In our app we are making some kind of surveys (called assessments) to rate "assets" in a certain way. There are two roles in the process - an user which is the owner of a given asset (it's often a piece of hardware). Owner can go to a view and perform as many surveys as he want to provide rating of his owned assets. An analyst defines what assets are and who owns them - he also defines criteria of surveys.

Everything was working fine without much coordination before a request from my client came. Some surveys are way more important than the other - just because some assets are more 'critical' now than the others. He asked me to introduce feature of assigning things - it's basically just a reminder via an e-mail to do this particular survey, chosen by an analyst. To implement such thing I'd need a direct link to a survey which I can include in an e-mail. After selecting this link a modal with a survey should pop and the asset owner can start working on this survey without hassle. After closing this survey he also needs to have an overview of his owned assets, opened at exact place where rating change occurs.

## Problem (in the code)

This feature is dependent on three apps - `Assets` which provides an overview of assets available for the owner, `Surveys` which is responsible for surveys modal and `Rating` which is an app for storing rating we surveyed before. We can complete a survey exactly once - once a rating is set, it cannot be changed. That's why we need to ask whether we need to complete a survey or not - clicking on a link second time should present an user with a message that this rating is already set.

These apps works completely asynchronously - each starts, fetches its data, sets dispatcher and waits. When an asset owner roams through components of `Assets` app to find a survey he like to make, timing issues does not occur. But in this particular case we want to present survey modal as soon as possible - timing is critical to make user's experience fine. I decided to put the code of this new feature in the `Surveys` app - in our case it must wait for data from `Rating` (to ensure the survey is still valid), `Assets` (we need to open tabs in the view on the certain asset, so we need to have this data loaded first) and its own data (fetched from backend), and THEN open our modal. How it can be achieved? Apparently, jQuery comes with an elegant and concise solution.

## Solution, part #1: `Surveys` data

This is an easy one. Our storage objects have a `sync` method, which returns a **Promise**. What is a promise?

**Promise is an object which is returned when there is a process waiting for its completion**. For example, `$.ajax` method returns a Promise. Promises can be *rejected* or *resolved* - and you can register callbacks to each case using `success` and `fail` methods of each Promise object.

Here's an example:

```coffeescript

# ajaxResponse is a Promise
ajaxResponse = $.ajax(url: '/surveys.json', type: 'GET')

# Promise is resolved (we got data!)
ajaxResponse.success (returnedData) =>
  console.log("returned data: ", returnedData)

# Promise is rejected (HTTP error, wrong data format returned etc.)
ajaxResponse.fail =>
  console.log("ERROR!")

ajaxResponse.fail =>
  console.log("THIS CALLBACK WILL BE CALLED TOO! (as the second one)")

# as a bonus:
ajaxResponse.always =>
  console.log "I'll always be called, no matter promise is resolved or rejected!"
```

You can register as many callbacks to Promises as you want. What's more, even if you register a success callback *after* the Promise is resolved it'll be fired immediately. The same goes for rejecting and `fail` callbacks.

**We can't resolve and reject Promises by ourselves.** We can only register callbacks to it. It makes sense for a process like an AJAX request - jQuery handles this stuff for us and we're only interested in getting our hands on data (or not, if error occurs). There must be a way to control this process - but I'll write about it later.

So, our final solution looks like this:

```coffeescript

@storage.sync().success =>
  # proceed with code...
```

So far so good. Now we need to take care of the more complex thing - waiting for dependent microapps to be ready. 

## Solution, part II: `Assets` and `Rating` apps readiness

In architecture I have in my project applications communicate only through events - there is an `@eventBus` object which has `@publish(eventName, data...)` and `@on(eventName, callback)` methods to publish and listen to events. Since I started in `Surveys` app I had an direct access to storage object which is synced - so I had a nice Promise to register on - in this case I can only listen to an event. So I've introduced two new events - `assetsStarted` and `ratingStarted` which are published when those applications are ready for interactions.

That is not helpful, though. I could've made something like this:

```coffeescript

@assetsReady  = false
@ratingReady  = false
@surveysReady = false 

@storage.sync().success =>
  @surveysReady = true
  @checkIfCanProceed()

@eventBus.on('assetsStarted', => @assetsReady = true; @checkIfCanProceed())
@eventBus.on('ratingStarted', => @ratingReady = true; @checkIfCanProceed())

checkIfCanProceed: ->
  @proceed() if @assetsReady and @ratingReady and @surveysReady 
```

There is a lot of imperativeness here. And I repeat myself three times here - I consider this solution a hack. But what can I do to improve this code?

What's less known, jQuery provides us a way to turn any process into a Promise. There are also tools which allows us to work with many promises. I'll use this approach to implement this code in a cleaner way.

We can turn our waiting for start events to a promise, using `jQuery.Deferred`:

```coffeescript

assetsAppPromise = new jQuery.Deferred((deferred) =>
                     @eventBus.on('assetsStarted', deferred.resolve)
                     # Error handling: Timeout? Just call deferred.reject()
                   ).promise()

ratingAppPromise = new jQuery.Deferred((deferred) =>
                     @eventBus.on('ratingStarted', deferred.resolve)
                     # Same.
                   ).promise()
```

`jQuery.Deferred` is the side that jQuery have when managing our `$.ajax` calls - it's a Promise with `resolve` and `reject` methods available. This way we can manually reject or resolve our `Assets` and `Rating` promises. `promise` method returns a real Promise from this object - without an ability to resolve and reject Promise. This is what we pass to our listeners.

You can pass a function to `jQuery.Deferred` constructor - it will be applied to the deferred object itself. The same code could be written as:

```coffeescript

assetsAppDeferred = new jQuery.Deferred()
@eventBus.on('assetsStarted', assetsAppDeferred.resolve)
# Error handling: Timeout? Just call assetsAppDeferred.reject()
assetsAppPromise = assetsAppDeferred.promise()

ratingAppDeferred = new jQuery.Deferred()
@eventBus.on('ratingStarted', ratingAppDeferred.resolve)
# Same.
ratingAppPromise = ratingAppDeferred.promise()
```

Any arguments passed to `resolve` and `reject` methods of `Deferred` object will be passed to all `success` or `fail` callbacks, respectively.

```coffeescript
deferred = new jQuery.Deferred()
deferred.promise().success (a, b, c) =>
  console.log a, b, c

deferred.resolve(1, 2, 3)
# Console output: 1 2 3
```

**`Deferred` objects can be rejected or resolved only once** - there are methods for making more 'grained' notifications from Promises (registering callbacks using `progress` and triggering those callbacks using `Deferred`'s `notify`) but it's beyond scope of this post.

Ok, so we got promises for our apps already. What we can do now? There is set of tools from jQuery available to work with Promises - `pipe`, `then`, `when`... they are all returning another Promises, transformed in a way. The idea is like with `Enumerable` collections in Ruby - you transform collections using `Enumerable` methods to achieve different `Enumerable`s or the result.

**In our case we'll use `jQuery.when` method. It takes a set of Promises and returns a Promise which is resolved if and only if all passed Promises are resolved.** If any of promises passed rejects, the whole `when` rejects. It resolves with data collected from contained promises. 

```
deferred1 = new jQuery.Deferred()
deferred2 = new jQuery.Deferred()

deferred1.resolve('a', 'b')
jQuery.when(deferred1.promise(), deferred2.promise()).success (data1, data2) =>
  console.log("data1 = ", data1)
  console.log("data2 = ", data2)
deferred2.resolve('c', 'd')

# Console output:
# data1 = ['a', 'b']
# data2 = ['c', 'd']
```

Apparently it is exactly what we're looking for! 

```coffeescript
assetsAppPromise = new jQuery.Deferred((deferred) =>
                     @eventBus.on('assetsStarted', deferred.resolve)
                     # Error handling: Timeout? Just call deferred.reject()
                   ).promise()

ratingAppPromise = new jQuery.Deferred((deferred) =>
                     @eventBus.on('ratingStarted', deferred.resolve)
                     # Same.
                   ).promise()

jQuery.when(assetsAppPromise, ratingAppPromise, @storage.sync()).success => @proceed()
```

That's it!

## Conclusion

Promises are one of the most effective and elegant ways to deal with asynchronous code in JavaScript. They were introduced to deal with anti-pattern called "Callback hell" - 3-4+ levels of nested callbacks. jQuery already provides us quite powerful implementation of Promises out of the box. You can use it to greatly improve your frontend code! In Node.js promises is widely adopted tool to deal with 'async everything' approach in their backend code.

## Read more

* [CommonJS Promises/A](http://wiki.commonjs.org/wiki/Promises/A) - Promises specification introduced by CommonJS. Also links to many great tools which introduces or allows to work with Promises both on backend and frontend.
* [jQuery Deferred Documentation](http://api.jquery.com/category/deferred-object/)
* [RxJS](https://github.com/Reactive-Extensions/RxJS) - Reactive programming has much to do with Promises - it's a "step forward" to generalize this neat tool.
