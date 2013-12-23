---
title: "CoffeeScript acceptance tests"
created_at: 2013-12-23 15:00:00 +0200
kind: article
publish: true
author: Jan Filipowski
newsletter: :cs_testing
tags: [ 'TDD', 'ATDD', 'CoffeeScript' ]
---

<img src="/assets/images/coffee-acceptance/coffeescript_acceptance_tests.png" width="100%">

You've already learned how to implement simple model and view tests, so as I promised now I'll show you how you can introduce acceptance tests on client-side. We're not too far from this goal - you know how to write test cases, make assertions and "click through DOM". Let's apply some abstraction then - to look at our app like the end user.

<!-- more -->

## Preparation

First let's think what our application really is - it could be single page app that control whole DOM or just a widget (subtree of DOM). The real question is where would you put the border between widget and rest of HTML. Here are some aspects of widget that should help you finding the border - from most to least important:

1. **clear responsibilities** - you should be able to write scenario of it's usage in end-user language
2. **inside one container** - it should have zero or minimized number of external elements it uses
3. **independent start-up** - it can render itself and load all initial data
4. **own data source** - it has an access to storage - through AJAX calls, LocalStorage etc.

If you go with the approach presented in [Testing client-side views in Rails app](/2013/09/testing-client-side-views-in-rails-apps/) you should be able to extract widget you've found - for a moment you can just assume it's a huge view with a state and access to external services (called "big ball of mud"). You know how to unit test the view, even if the unit is so big. The job is to handle external services interactions with mocks and write tests as scenarios using higher-level language.

## External services

Your application may use backend via AJAX, WebSockets or external library with backend - like Facebook's JS SDK. You may try to use real data sources, but it will be hard - if you use konacha gem you won't have easy access to your backend, it won't be easy to clear state on backend or in external service. So it will be easier to just mock them - it violates end-to-end testing principles, but I didn't find better way yet.

Please remember that there might be external services with easy access from DOM - like LocalStorage, Web Audio API - some of them could be used directly with no need to mock them, but you still might need to mock other - i. e. if you don't want to hear the sound when testing application which uses Web Audio API.

## Test scenarios

You probably know what Cucumber is, but just to remind you - testing framework that uses Gherkin DSL to describe context and expectations. You write your test suite almost in natural language and it translates instructions to real actions and assertions. I'm not a big fan of this approach, however it really influenced me on how should acceptance scenario look like. Such test should focus on end-user perspective - how one interacts with GUI and sees results.

Let's have the first attempt on writing test for sample TODO application using such perspective.

```
#!coffeescript
describe "TODO app", ->
  beforeEach ->
    @app = new TodoApplication()
    @app.start()

  it "user adds two items and finishes of them", ->
    itemsList = $("[data-container-name='items_list']")
    form = $("form[name='new_item']")
    form.find("input[name='label']").val("Buy milk")
    expect(itemsList).to.contain("Buy milk")
    form.submit()
    form.find("input[name='label']").val("Sell milk")
    form.submit()
    expect(itemsList).to.contain("Sell milk")
    itemsList.find(":checkbox:first").check()
    expect(itemsList).not.to.contain("Buy milk")
```

Yeah, you're right - it's not end user perspective. It's jQuery perspective. Let's fix this with our own capybara-like wrapper for DOM, based on jQuery:

```
#!coffeescript
describe "TODO app", ->
  beforeEach ->
    @app = new TodoApplication()
    @app.start()

  it "user adds two items and finishes of them", ->
    fillIn("Task", with: "Buy milk")
    submitForm()
    expect(itemsList()).to.contain("Buy milk")
    fillIn("Task", with: "Sell milk")
    submitForm()
    expect(itemsList()).to.contain("Sell milk")
    checkCheckbox("Buy milk")
    expect(itemsList()).not.to.contain("Buy milk")
```

It's still focused on GUI details, but for small scenarios it may be good enough. For longer scenarios you can extract chunks of interaction, like logging in, adding product to cart etc.

## What's next

In this blog series I didn't cover few interesting, but quite heavy, topics: object orientation (like [bbq](https://github.com/drugpl/bbq)), implementing own, meaningful assertions in chai.js and technics to work with 3rd party services. If you're interested please leave your email in the form below.
