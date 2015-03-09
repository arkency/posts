---
title: "Configurable dependencies in Angular.js"
created_at: 2015-03-09 15:09:17 +0100
kind: article
publish: false
author: Marcin Grzywaczewski
tags: [ 'angularjs', 'frontend' ]
img: '/assets/images/angular-configurable-di/img-fit.jpg'
newsletter: :react_book
---

<p>
  <figure>
    <img src="/assets/images/angular-configurable-di/img-fit.jpg" width="100%">
    <details>
      <a href="https://www.flickr.com/photos/streetmatt/15495884581/in/photolist-8xScux-bFdBMV-7xvfZr-pBjsBP-oZUAFC-hpXk7C-pykxQT-qv8xjz-6kQqd1-noXoEQ-8Z2YXD-hwJ5i2-dQjT8A-qMaWhE-btg35P-4yMT82-8FCxXe-7GEZhp-9AaEKV-okZoM1-hhwHFX-imQdib-aj3xuo-5E6YDk-pt454q-h1ycPn-gUxM12-2Z9JJK-r7T7Jn-c7WFkS-aZmF5X-qN8b3D-4NGfes-AD4kM-r43EN5-3iYoUp-odsRTN-frEFs1-BVfvF-5V5iVF-h1rcth-6x8yTn-6xcCNo-4BCrGK-8vyReg-6EqDGC-6PEVDY-8cxqf4-eiSbHh-e5Pjb5">Photo</a> 
      available thanks to the courtesy of
      <a href="https://www.flickr.com/photos/streetmatt/">streetmatt</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

Angular.js is often a technology of choice when it comes to creating dynamic frontends for Rails applications. **As every framework, Angular has it's flaws - but one of the most interesting features it has is built-in powerful dependency injection mechanism.** Compared to Rails, it is a great advantage - to achieve similar results you would need to use external gems like [dependor](https://github.com/psyho/dependor). Here you have this mechanism out of the box.

In my recent work I needed to learn Angular from scratch. **After learning about providers mechanism, my first question was: *Can I have a dependency and configure which implementation I can choose?* Apparently, with a little knowledge about JavaScript and Angular it was possible to come with a very elegant solution of this problem.**

<!-- more -->

## Why?

*Why would I need this feature?* - you may ask. The most important advantage you'd have from this feature is that you don't need to touch the *code* of your application if you want to substitute your dependency - all you need to do to change implementation is to modify one config variable and you're done. With switchable implementations you can achieve:

* Easy [feature toggling](http://en.wikipedia.org/wiki/Feature_toggle)
* Ability to create in-memory implementations of your adapters - it is the extremely useful gain. You can work on the frontend without even touching your backend and/or external services like Facebook. Just create an implementation which returns "phony" data stored in the browser's memory and focus on getting the frontend right. On production, replace your implementations with a real ones.
* "Mock" implementations of your adapters for testing - of course, you can still use a `$httpProvider` or other built-in solutions to stub your dependencies on frontend. But when working with less popular integrations or just to remain in full control of this code you may provide your own solution and change it in test environment's config, using `ENV` vars or whatever other solution you like.
* Per-client implementations - this is often the case with apps living on production. You may provide new version of the API of a certain service for new users, but your super-important old client have a big coupling of the old version of an API - with configurable dependencies you can create an adapter for a new version of API without touching the old one and substitute adapters for whatever clients you like.

## How:

First of all, create your Angular module:

```
#!coffeescript

myApp = angular.module('myApp', [])
```

Let's say you want to show dummy data on frontend just for quick prototyping, and then switch to a real AJAX requests to fetch it. Let's create our implementations:

```
#!coffeescript

myApp.service('InMemoryProductsRepository', ['$q', ($q) ->
  @getAll = ->
    deferred = $q.defer()
    deferred.resolve([
      { id: 1, name: 'Product #1', price: 100 }
      { id: 2, name: 'Product #1', price: 200 }
      { id: 3, name: 'Product #1', price: 300 } 
    ])
    deferred.promise

  @
])

myApp.service('RealProductsRepository', ['$http', ($http) ->
  @getAll = -> $http.get('/products')

  @
])
```

`$q` is used here to create a consistent interface of a Promise to work with both implementations in the same way.

Next step is to create a configuration variable to switch implementations as needed. This is the simplest approach - you may have more sophisticated rules to switch implementations (like user-based):

```
#!coffeescript

myApp.constant('Config',
  productsRepository:
    inMemory: true
)
```

You are nearly done. Now, to the heart of this solution - a factory (you canread about it more [here](https://docs.angularjs.org/guide/providers)) will be used to encapsulate logic of implementation switch.

```
#!coffeescript

myApp.factory('ProductsRepository', [
  'InMemoryProductsRepository', 'RealProductsRepository', 'Config', 
  (inMemoryImplementation, realImplementation, config) ->
    dependencyConfig = config.productsRepository
    implementation = ({
      true: inMemoryImplementation
      false: realImplementation
    })[dependencyConfig.inMemory]
  
    implementation
])
```

Notice you need to pass all implementations as separate dependencies - you can easily omit this step if you implement your dependency implementations as plain JavaScript prototypes (use of `class` notation in CoffeeScript is something I'd recommend) and make this code reachable within a closure where the factory is defined - you can even inline those implementations inside the factory's body. I like approach with plain objects a lot - if I can decouple from a framework, I'd happily do so every time I have an occasion for it.

The full code looks like this:

```
#!coffeescript

myApp = angular.module('myApp', [])

myApp.service('InMemoryProductsRepository', ['$q', ($q) ->
  @getAll = ->
    deferred = $q.defer()
    deferred.resolve([
      { id: 1, name: 'Product #1', price: 100 }
      { id: 2, name: 'Product #1', price: 200 }
      { id: 3, name: 'Product #1', price: 300 } 
    ])
    deferred.promise

  @
])

myApp.service('RealProductsRepository', ['$http', ($http) ->
  @getAll = -> $http.get('/products')

  @
])

myApp.constant('Config',
  productsRepository:
    inMemory: true
)

myApp.factory('ProductsRepository', [
  'InMemoryProductsRepository', 'RealProductsRepository', 'Config', 
  (inMemoryImplementation, realImplementation, config) ->
    dependencyConfig = config.productsRepository
    implementation = ({
      true: inMemoryImplementation
      false: realImplementation
    })[dependencyConfig.inMemory]
  
    implementation
])
```

## Conclusion:

Dependency injection is a powerful technique to make working with your code much easier. I'm really happy that Angular supports this way of doing things out of the box - I can't wait to see more opportunities of wise usage of this framework features. **With such small amount of code you can achieve great gains now.**

I'm really curious if you tried similar techniques before. How your implementations look like? Is this implementation is a case of the [NIH](http://en.wikipedia.org/wiki/Not_invented_here) principle? If you'd like to discuss about it, leave a comment!
