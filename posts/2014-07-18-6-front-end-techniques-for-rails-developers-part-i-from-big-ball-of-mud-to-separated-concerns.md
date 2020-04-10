---
title: "6 front-end techniques for Rails developers. Part I: From big ball of mud to separated concerns"
created_at: 2014-07-18 19:58:54 +0200
publish: true
author: Marcin Grzywaczewski
tags: [ 'front end', 'javascript', 'refactoring' ]
newsletter: frontend_course 
---

<p>
  <figure>
    <img src="<%= src_fit("big-ball-of-mud/cupcakes.jpg") %>" width="100%">
    <details>
      <a href="https://www.flickr.com/photos/clevercupcakes/4402962654/in/photolist-7H5kpd-7H1pMg">Photo</a>
      remix available thanks to the courtesy of
      <a href="https://www.flickr.com/photos/clevercupcakes/">Clever Cupcakes</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

Current trends in web development forces us to write more and more front-end code in our applications. Single Page Applications, content changes without refreshing, rich user experience using custom controls - all those requirements needs you to write code. And this code, as any other code, can quickly turn into a [big ball of mud](http://en.wikipedia.org/wiki/Big_ball_of_mud). It can happen when you lack proper tools in your toolbox to design it correctly.

In this course I want to share with you techniques and tools we're using in our day-to-day work. Some of those allow you to **create easier, more testable code**. Some of those allow you to **develop it faster, without losing quality.** I believe it's really worth to try these techniques and choose which suits you most.

In the part one, I want to present you a simple case of refactoring of a badly written front-end code to a stand-alone micro-app with proper encapsulation.

<!-- more -->

It's **quite common to see CoffeeScript code which is an imperative chain of DOM transformations and event handlers mixed with AJAX calls**. It is a complete disaster when it comes to maintaining and adding new features to it. In addition, all responsibilities in such *spaghetti code* are entangled. Luckily **it's quite easy to segregate dependencies** and create an Application class, which responsibility is to create and configure all objects you've separated during refactoring.

Let's see an example code that you may find in (bad written) front-end codebase. It's responsible for loading photos data (via an AJAX call) and displaying it on the screen. After clicking on a photo it should be grayed out:

```coffeescript
$(document).ready ->
  photoHTML = (photo) =>
    "<li>
       <a id='photo_#{photo.id}' href='#{photo.url}'>
         <img src='#{photo.url}' alt='#{photo.alt}' />
       </a>
    </li>"
 
  $.ajax
    url: '/photos'
    type: 'GET'
    contentType: 'application/json'
    onSuccess: (response) =>
      for photo in response.photos
        node = $(photoHTML(photo)).appendTo($("#photos-list"))
 
        node.on('click', (e) =>
          e.preventDefault()
          node.find('img').prop('src', 
            photo.url + '.grayscaled.jpg')
        )
    onFailure: =>
      $("#photo-list").append("<li>
                                 Failed to fetch photos.
                               </li>")
```

## Why we should bother?

There are several problems with this code:

* There is a callback within a callback - and it's an anti-pattern in JS. It leads to a **callback hell** - which is **unmaintainable in the long term**.
* Initialization is not separated from definition of this code. That means **if we don't want to always run this code we need to create conditionals** (like `if $("#photos-list").length > 0`).
* **SRP is cleanly violated**. You have data fetching, DOM manipulation and domain logic (creating grayscaled photo's URL), event binding - all in one place. There are too many reasons to edit this code at all.
* Code is not revealing intentions. It's not a problem now. But think about further features that can be introduced. It can be a real problem when you expand this code to about 50-100 lines.

Fortunately, you can easily refactor this code. 

## Let's do this!

As I've mentioned before, **this code has several responsibilities**:

* Fetching data via an AJAX call
* Manipulating DOM
* Knowledge about presenting photo (see line 2 and 18)
* Logic of creating grayscaled photo URL
* Binding handlers to DOM events

**Your first step should be to create classes with its responsibilities**. In our projects it's quite usual that we have `Gui` class (often it is composed of a few smaller classes), `Backend` class (which fetches data from Rails backend and pre-processes them) and `UseCase` class (which contains business logic within, operating on domain objects). Since this example does not contain much business logic at all, you can stick with only `Backend` and `Gui` classes. 

Since there is a business rule that is worth to be contained in an intention revealing interface, it's a good decision to create a `Photo` domain object.

## Start with a domain

When I work in a Sprockets-based stack I usually create a module definition within application.js to make my new classes accessible globally and namespaced. It's quite simple - you can put `Photos = {}` in the body of your `application.js` file. Then you can require your new classes. They'll be available in a web inspector and in a code in a `Photos` namespace.

There is a rule of thumb to **always start with domain (or use case)**. In our case it's a tiny part of code that encapsulates grayscale photo URL transformation logic:

```coffeescript
class Photos.Photo
  constructor: (@id, @url, @alt) ->
 
  grayscaledURL: =>
    @url + ".grayscaled.jpg"
 
  @fromJSON: (json) ->
    new Photos.Photo(json.id, json.url, json.alt)
```

You can **easily transform existing code** to accommodate this change. That means you **take this as a series of small steps** - feel free to stop this refactoring now and jump into next task.

## Talking with Rails

Let's proceed with further decomposition of this code. Right now your can create our Backend class to accommodate AJAX fetching behavior.

I mostly **extracted existing implementation here to a method**. Here is how I could create such a class:

```coffeescript
class Photos.Backend
  fetchPhotos: =>
    request = $.ajax(
      url: '/photos'
      type: 'GET'
      contentType: 'application/json'
    )
    .then (response) =>
      photos = []
      for photo in response.photos
        photos.append(Photos.Photo.fromJSON(photo))
      photos
```

I've removed `onSuccess` and `onFailure` callbacks here and replaced it with a [Promise object](http://api.jquery.com/category/deferred-object/). That allows me to expose 'status' of AJAX call to anyone interested in a result - exactly what I want if I want to pass control to another object. I've also used a neat trick with [`#then`](http://api.jquery.com/deferred.then/) - data for a caller of this method will come encapsulated in your new `Photos.Photo` object, not raw JSON data.

You can argue that responsibility of backend is not to encapsulate JSON in a domain object. For me **Backend is for 'separating' world from the heart of your application** - which should operate only on a domain objects. In a puristic implementation of a backend, you should create an object which is reponsible for mapping from JSON to domain object - and transform raw JSON data returned by a backend using this object as an intermediate step.

## Make it visible

The last step is to create a `Gui` class, which is responsible for rendering and binding events to the DOM objects. There are different approaches here - in Arkency we're using Handlebars for templating or React.js for creating the whole `Gui` part. You can use whatever technology you want - but **be careful to not extend responsibilities**. The rules of thumb are: 

* When the change hits DOM, it's Gui (or another objects that Gui is composed of) responsibility to handle DOM manipulation.
* When an event from UI invokes domain action, Gui should only delegate it to the domain object, not perform it by itself.

There is an example implementation that I've written:

```coffeescript
class Photos.Gui
  constructor: (@dom) ->
 
  photoRow: (photo) =>
    $("<li>
         <a id='photo_#{photo.id}' href='#{photo.url}'>
           <img src='#{photo.url}' alt='#{photo.alt}' />
         </a>
       </li>")
 
  addPhoto: (photo) =>
    photoNode = @photoRow(photo).appendTo(@dom)
    @linkClickHandlerToPhoto(photoNode, photo)
 
  linkClickHandlerToPhoto: (photoNode, photo) =>
    photoNode.on('click', (e) =>
      e.preventDefault()
      @switchPhotoToGrayscaled(photoNode, photo)
      
  switchPhotoToGrayscaled: (photoNode, photo) =>
    photoNode.find('img').prop('src', photo.grayscaledURL())
 
  fetchPhotosFailed: =>
    $("<li>Failed to fetch photos.</li>").appendTo(@dom)
```

That's it. These components contain all the logic we've implemented in the previous code. Now we need to coordinate those classes to make a real work.

## Putting it all together

Classes that you've created cannot do their work alone - they need some kind of coordination between each other. On backend, coordination like that is contained within a service object. If you don't have service objects, you usually put this responsibility in a controller, [which can be done better](http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/). That's why you should **create an Application class to initialize and coordinate all newly created objects**.

It's a really simple code. When you perform this refactoring step-by-step, you'll notice that the end effect of your changes is quite similar to this code. The biggest difference is that you generally want to separate definition of your classes from a real work.

This is what such application object could look like:

```coffeescript
class Photos.App
  constructor: ->
    @gui = new Photos.Gui($("#photos-list"))
    @backend = new Photos.Backend()
 
  start: =>
    @backend.fetchPhotos()
      .done(
        (photos) =>
          for photo in photos
            @gui.addPhoto(photo)
      )
      .fail(@gui.fetchPhotosFailed)
```

This makes the complete, stand-alone app. You'll notice that you do not run this code yet. That's because **it's advisable to separate initialization of our app from its definition**.

Creating such initializer is easy:

```coffeescript
$(document).ready =>
  # put logic about starting your app here.
  app = new Photos.App()
  app.start()
```

You can see the end result [here](https://gist.github.com/Killavus/13676d46afab12e81f7d).

## Summary:

Creating a stand-alone application is a **first step to create robust and rich front-end code**. Testing it is way easier since responsibilities are segregated and maintainability of this code is increased - when you want to make changes in backend fetching rules you need to focus only on a backend class. It's only a starting point of course. But it's a **good start for further improvements**.

## Want more?

This post is a part of the 6-day course about front-end techniques for Rails developers. It's **absolutely free** - just register to our newsletter (using a box below) and we'll teach you 6 techniques we're using in a day-to-day work, including:

* Using **React.js** to **ship your Gui faster** code and **make it easily composable**.
* Techniques we use to **prototype front-end without backend** to **make your clients happier** and **tighten the feedback loop**. 
* Why you should **segregating apps by its purpose, not its placement** - and how to achieve it in an easy way.
* Designing your front-end as a **many small apps** rather than a big one to **improve maintainability** of your code.
* Easily make actions on reaction for a domain change, in a **dependency-free way** using **reactive programming** with RxJS.

<%= show_product_inline(item[:newsletter]) %>

## Resources

* [Hexagonal architecture](http://hexagonaljs.com) - it is a good way to thinking about creating JS applications at all. Also it comes with a great tooling and even better techniques to improve testability by reducing dependencies (to zero!)
* [Sugar.js](http://sugarjs.com) - a library which provides us great stdlib extensions to work with domain code within our stand-alone apps. We're heavily using it in Arkency.
* [YouAreDaBomb](https://github.com/gameboxed/YouAreDaBomb) - little library which introduces aspect-oriented programming to JavaScript - a great way to provide communication between application objects without specifying dependencies at all. You create a glue class to 'stitch' all your adapters and a use case / domain objects together. Neat!

