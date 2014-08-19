---
title: "How we structure our front-end Rails apps with React.js"
created_at: 2014-08-19 02:28:05 +0200
kind: article
publish: true 
author: Wiktor Mociun
tags: [ 'front-end', 'react.js', 'javascript' ]
newsletter: :arkency_form
---

<p>
  <figure>
    <img src="/assets/images/react-file-structure/image-fit.jpg" width="100%">
  </figure>
</p>

We've tried almost everything for our Rails frontends - typical Rails views, Backbone, Angular and others. What we settled with is React.js. In this post we're showing you, how we structure a typical React.js app when it comes to the files structure.

<!-- more -->

Our file structure per a single mini-application: 

```
app_init.js.coffee
--- app_directory
    --- app.module.js.coffee
    --- backend.module.js.coffee
    --- components
        --- component_file1.module.js.coffee
        ...
    --- domain.module.js.coffee
    --- glue.module.js.coffee
```    

app_init - we got one per each application. We always keep it simple:

```
#!coffeescript
#= require_tree ./app_directory

App = require('app_directory/app')

$('[data-app=appFromAppDirectory]').each ->
  window.app = new App(@)
  window.app.start()
```

* **app**        - starting point of application. Here we initialize and start every component of application

* **backend**    - here we fetch and send data to backend. It is also a place, where we create domain objects

* **components** - our React.js components we use to render an application.

* **domain**     - definitions of domain objects used in view. Example: immutable list of single entries (which are domain objects too).

* **glue**       - [hexagonal.js](http://hexagonaljs.com/) glue

Further reading
==

**Hexagonal.js** - implementation of clean hexagonal architecture - http://hexagonaljs.com/

**RxJS** - we use reactive data streams to communicate between apps - https://github.com/Reactive-Extensions/RxJS
