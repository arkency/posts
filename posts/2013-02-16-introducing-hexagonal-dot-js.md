---
title: "Introducing hexagonal.js"
created_at: 2013-02-18 12:10:11 +0100
kind: article
publish: true
author: Jan Filipowski
newsletter: :react_books
tags: [ 'javascript', 'hexagonal', 'architecture', 'coffeescript', 'hexagonal.js' ]
---

There's an idea we were working on for more than one year till now. As backend developers we were thrown into mysterious world of frontend (client-side) apps without any good pattern how to create Single Page App. So we ([GameBoxed](http://gameboxed.com) + Arkency) invented one - [hexagonal.js](http://hexagonaljs.com).

<!-- more -->

Our main inspiration was Alistair Cockburn's [Hexagonal architecture](http://alistair.cockburn.us/Hexagonal+architecture). In short hexagonal.js is its JavaScript's implementation, but with some unusual solutions and additional philosophy. Let's focus on philosophy first, because it'll let you judge if you're still interested in this idea.

# hexagonal.js philosophy

1. Business logic is software's heart and have to be exposed properly.
2. Business logic is pure: uses only objects that represents domain in domain-valid state.
3. Client-side app is core of whole project, should be implemented as first.
4. Server-side API development should be driven by client-side needs.
5. Client-side and server-side are separated.
6. Both layers implements MVC.

In this post I want to focus on client-side layer, because it is most interesting part. All snippets in this post are copied from hexagonal.js' [hello-world](https://github.com/hexagonaljs/hello-world) project.

# Structure

Architecture is build with:

1. Business logic
    1. Use cases
    2. Models
2. Glue (ports)
3. Adapters
    1. GUI
    2. Server-side
    3. WebSockets, LocalStorage etc.

# Business logic

You're probably familiar with [use case](http://martinfowler.com/bliki/UseCases.html) term. If you have some experience with DCI (or figured it out different way) you probably know, that use cases can be represented as objects - and this is core idea.

```
#!coffeescript
class UseCase
  constructor: ->

  start: =>
    @askForName()

  askForName: =>

  nameProvided: (name) =>
    @greetUser(name)

  greetUser: (name) =>

  restart: =>
    @askForName()
```

Our story is quite simple: we want to greet user that uses app - ask for his name and greet him using name. As you can see it uses only plain objects and don't care about booting, GUI or storage.

# Adapters

This sample app has only one adapter, the most basic - GUI. Let's have a look at code of GUI for just first step of UseCase - askForName. ```GUI#showAskForName``` shows simple form and binds to click event of its confirm button. It has no idea about domain objects and doesn't contain any logic.

```
#!coffeescript
class Gui
  constructor: ->

  createElementFor: (templateId, data) =>
    source = $(templateId).html()
    template = Handlebars.compile(source)
    html = template(data)
    element = $(html)

  showAskForName: =>
    element = @createElementFor("#ask-for-name-template")
    $(".main").append(element)
    confirmNameButton = $("#confirm-name-button")
    confirmNameButton.click( => @confirmNameButtonClicked($("#name-input").val()))
    $("#name-input").focus()
```

# Glue

You probably wonder how GUI know what to present and how can it interact with our business logic. hexagonal.js uses Glue objects to glue those two layers:

```
#!coffeescript
class Glue
  constructor: (@useCase, @gui, @storage)->
    After(@useCase, "askForName", => @gui.showAskForName())
    After(@useCase, "nameProvided", => @gui.hideAskForName())
    After(@useCase, "greetUser", (name) => @gui.showGreetMessage(name))
    After(@useCase, "restart", => @gui.hideGreetMessage())
    
    After(@gui, "restartClicked", => @useCase.restart())
    After(@gui, "confirmNameButtonClicked", (name) => @useCase.nameProvided(name))
```

Ok, so this part can be hard, because your don't know what ```After``` means. It's shortcut from [YouAreDaBomb](https://github.com/gameboxed/YouAreDaBomb) library, which can be described by following code:

```
#!coffeescript
After = (object, methodName, advice) ->
  originalMethod = object[methodName]
  object[methodName] = (args...) ->
    result = originalMethod.apply(object, args...)
    advice.apply(object, args...)
    result
```

So basically - it adds to original function additional behaviour. There are also ```Before``` and ```Around``` functions that let you prepend or surround original function with additional behaviour.

# Booting

To make it all run we have to implement some booting code, that'll build all required objects: domain, glue, gui and other adapters and start use case. Here's an example from hello-world app.

```
#!coffeescript
class App
  constructor: ->
    useCase      = new UseCase()
    gui          = new Gui()
    glue         = new Glue(useCase, gui)

    useCase.start()

new App()
```

# Conclusion

I showed you some basics of [hexagonal.js](http://hexagonaljs.com) and now it's time for your action. If you're interested in this idea, please join our small community - we're on [Github](https://github.com/hexagonaljs), [freenode](irc://chat.freenode.net/hexagonal-js), [Google Groups](https://groups.google.com/forum/?fromgroups#!forum/hexagonaljs) and [Twitter](https://twitter.com/hexagonaljs).

In about two weeks our beautiful city will host [wroc_love.rb](http://wrocloverb.com) conference. If you're going to participate in this event I have small announcement for you - I'll provide QA session and hackathon / workshop on hexagonal.js on friday. It's not an official part of conference and of course it will be free, to confront (production proved) idea with other developers. If you want to join please leave a comment, ping me on [Twitter](http://twitter.com) or just look for me on friday. There'll be also fight between ember.js and hexagonal.js on saturday. To be honest: whole agenda looks very promising.
