---
title: "How we structure our front-end Rails apps with React.js"
created_at: 2014-08-19 01:01:05 +0200
kind: article
publish: true
author: Wiktor Mociun
tags: [ 'front-end', 'react.js', 'javascript' ]
newsletter: :arkency_form
---

We've tried almost everything for our Rails frontends - typical Rails views, Backbone, Angular and others. What we settled with is React.js. In this post we're showing you, how we structure a typical React.js when it comes to the files/directories structure.

<!-- more -->

Our file structure per a single mini-application: 

```
app_starter.js.coffee
--- app_directory
    --- app.module.js.coffee
    --- backend.module.js.coffee
    --- components
        --- component_file1.module.js.coffee
        ...
    --- domain.module.js.coffee
    --- glue.module.js.coffee
```    

app_starter - we got one per each application. It is a code like this:

```
#!coffeescript
#= require_tree ./app_directory

App = require('app_directory/app')

$('[data-app=appFromAppDirectory]').each ->
  window.app = new App(@)
  window.app.start()
```

**app**        - starting point of application. Here we initialize every component of application

**backend**    - here we fetch and send data to backend. It is also a place, where we create domain objects

**components** - our React.js components, we use to render an application.

**domain**     - definitions of domain objects used in view. Example: immutable list of single entries (which are domain objects too).

**glue**       - hexagonal.js glue

Further reading for hexagonal.js - http://hexagonaljs.com/
Also, we use data streams from RxJS: https://github.com/Reactive-Extensions/RxJS
