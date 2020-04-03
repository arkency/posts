---
title: "Testing client-side views in Rails apps"
created_at: 2013-09-02 13:05:51 +0200
kind: article
publish: true
author: Jan Filipowski
newsletter: frontend_course
tags: [ 'TDD', 'coffeescript', 'Rails', 'testing']
---

In previous post I've only showed you [how to implement most basic tests](http://blog.arkency.com/2013/07/coffeescript-tests-for-rails-apps/) for your front-end code. Now I want to show you how to unit test your views and, what's more important, how to make your views testable.

<!-- more -->

## View definition

First let's define what is the view in front-end app.

> View is an object responsible for presenting model to user as piece of HTML (DOM subtree) and giving ability to interact with system - by passing events based on click, key pressed etc. to controller or any other object.

Depending on model's complexity and quality of your code view object can be really big or small. It can just show one label or be a complex multi-step form - which could be container of smaller views, btw. ;) I will assume, that view also contains view-model - data object important in scope of view, but meaningless outside.

## Simple example

Let's start with something really simple - cyclic color change on button click. Let's assume, that cycle contains only two colors: red and blue. You've got following HTML:

```html
<div id="color-changer">
  <button value="Change color"></button>
  <div>Text</div>
</div>
```

And following CoffeeScript:

```coffeescript
$ ->
  color = "blue"
  $("#color-changer button").click((e) =>
    if color == "blue"
      color = "red"
    else
      color = "blue"
    $("#color-changer div").css("color", color)
  )
```

Looks pretty familiar, right? Before we can write test we have to do the first refactoring: separate definition from start-up. That's really simple:

```coffeescript
## color_changer.coffee
@colorChanger = ->
  color = "blue"
  $("#color-changer button").click((e) =>
    if color == "blue"
      color = "red"
    else
      color = "blue"
    $("#color-changer div").css("color", color)
  )
```

```coffeescript
## color_changer_startup.coffee
#= require color_changer

$ ->
  colorChanger()
```

Now we can test it. Let's focus on what should be tested - what are our requirements for this piece of code. It should change Text's color to red on odd clicks and to blue on even. We also want to start with blue color (you may notice there's a bug in code - good catch!).

### Tests foundation

Let's start with "odd clicks should mark Text's color to red" requirement. Implementation of this first requirement will be also a foundation for all other tests.

```coffeescript
## color_changer_spec.coffee
#= require color_changer

describe "colorChanger", ->
  beforeEach ->
    $("body").append('<div id="color-changer">
        <button value="Change color"></button>
        <div>Text</div>
      </div>')
    @container = $("#color-changer")

  afterEach ->
    @container.remove()

  it "should set color to red on first click on button", ->
    colorChanger()
    @container.find("button").click()
    expect(@container.find("div").css("color")).to.equal("red")
```

As you can see we need to deliver part of DOM that our colorChanger can bind to - we do it by copy&pasting our view's HTML and appending to *body* node. Yes, this is a smell, but we'll get rid of this in next step of refactoring.

Let's focus on test case. We call ```colorChanger``` function which binds to existing DOM, then we click button - we use jQuery *click* event trigger. At last we check whether color of Text really changed to red.

### Missing test cases

Now that we have test foundation we can implement missing test cases - Text should be blue by default, and after even number of clicks:

```coffeescript
## color_changer_spec.coffee
#= require color_changer

describe "colorChanger", ->
  # old "foundation" code

  it "should set color to blue as a default", ->
    colorChanger()
    expect(@container.find("div").css("color")).to.equal("blue")

  it "should set color to blue after even number of clicks", ->
    colorChanger()
    @container.find("button").click()
    @container.find("button").click()
    expect(@container.find("div").css("color")).to.equal("blue")
```

You should have "should set color blue as a default" test case failing, because it's not met with current code. I leave fixing ```colorChanger``` to pass tests as an exercise.

Side note: If you're going to use jQuery heavily you may want to install [chai matchers for jQuery](https://github.com/chaijs/chai-jquery). The easiest way is to install [konacha-chai-matchers gem](https://github.com/matthijsgroen/konacha-chai-matchers) - it contains many useful chai matchers easily embedable by asset pipeline.

### Hardcoded HTML

Let's get back to smell introduced in view test foundation - HTML hardcoded in test suite. Of course the problem is that your app's HTML may change, so you have to remember to update test's HTML every time you touch similar subtree of DOM in real app. At first you may think of test's HTML as a contract for your real app - if following HTML occured and function was called then declared behaviour should be applied. But that kind of thinking leads you to additional test for your Rails view - make sure that following HTML exists in given view. What's worse - you still don't have any relationship between back-end view test and front-end view test, so after 2 months you won't remember why you test such thing.

The other way is to move responsibility of rendering most of HTML from back-end to front-end. You may achieve it by using view objects with inlined HTML - good enough for a start. You may also use some templating language, especially one supported by asset pipeline, i.e. [Handlebars.js](http://handlebarsjs.com/).

This leads us to new understanding of ```colorChanger```. Previously it was just a function, that binds to already existing DOM subtree, and now we have to think about as an object, that can both render itself (or be rendered by something else) and bind to rendered DOM, to interact with user. Here's how we can refactor our ```colorChanger``` to an object:

```coffeescript
## color_changer.coffee

class @ColorChanger = ->
  template: '<div id="color-changer">
        <button value="Change color"></button>
        <div>Text</div>
      </div>'

  constructor: ->
    @color = "blue"

  render: (container) =>
    @element = $(@template)
    container.append(@element)

    @element.find("div").css("color", @color)
    @element.find("button").click((e) =>
      if @color == "blue"
        @color = "red"
      else
        @color = "blue"
      @element.find("div").css("color", @color)
    )
```

There are things that ask for refactoring, but you see that main goal is achieved - our view object can be rendered inside of any container and then can receive click events from button. This makes it reusable and easier to maintain:

```coffeescript
#= color_changer
## color_changer_spec.coffee

describe "colorChanger", ->
  beforeEach ->
    @colorChanger = new ColorChanger()

  afterEach ->
    $("body").empty()

  it "should set color to red on first click on button", ->
    @colorChanger.render($("body"))
    $("body button").click()
    expect($("body div").css("color")).to.equal("red")

  # other tests the same way
```

## Summary

If you want to test your already existing views follow these steps:

1. Separate definition from start-up.
2. Write tests with duplicated HTML.
3. Extract HTML as template and render it client-side.

## In next post

In this post I've tried to show you how to write tests for your front-end views and how to make them testable. Next time we'll try to write acceptance test for Single Page Application. If you want to follow this series just sign up to newsletter below.
