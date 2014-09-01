---
title: "CoffeeScript tests for Rails apps"
created_at: 2013-07-26 10:41:20 +0200
kind: article
publish: true
author: Jan Filipowski
newsletter: :arkency_form
tags: [ 'TDD', 'CS', 'Rails' ]
---

You may know this pain too well - you've created rich client-side in you Rails app and when your try to test CoffeeScript features it consumes much time to run all test scenarios with capybara and any of browser drivers (selenium, webkit, phantomjs). Let's apply painkiller then - move responsibility of testing front-end to... front-end.

<!-- more -->

This is just a beginning of series about testing CoffeeScript in Rails stack, so if you're familiar with basics - you know toolset and you know how to test your models - don't waste your time. In next post I'll show how to extract existing views and write unit tests for them. Next I want to cover acceptance tests topic. If you're interested just subscribe with [RSS](http://feeds.feedburner.com/arkency.xml) or [mailing list](#newsletter-form).

## Tools

Let's start with toolset, because it will influence a way we test - with frameworks' syntax and behaviours. I recommend you to use [konacha gem](https://github.com/jfirebaugh/konacha) - it's dedicated for Rails apps, it uses [mocha.js](http://visionmedia.github.io/mocha/) + [chai.js](http://chaijs.com/) as test framework and can be easily run in browser and command line. Each test suite is run in iframe, which prevents leaks on global state - both global variables and DOM. You can try [jasmine](https://github.com/pivotal/jasmine-gem) or [evergreen](https://github.com/jnicklas/evergreen) as well, but you'll eventually get back to konacha ;)

I won't run into details of konacha installation, but I recommend you to use ```:webkit``` or any other headless browser driver instead of default - selenium.

## First test

You shouldn't start with complicated tests of your views or any other hard piece of code. Start with testing small model or value object. Here's how I would test Money value object:

```
#!coffeescript
#= require money

describe "Money", ->
  beforeEach ->
    @money = new Money(15)

  describe "#isEqual", ->
    it "should return true for same amount", ->
      expect(@money.isEqual(new Money(15)).to.be.true

    it "should return false for different amount", ->
      expect(@money.isEqual(new Money(5)).to.be.false # not.to.be.true
```

At first sight it should resemble RSpec with its newest "expectations" syntax. Let's distinguish **mocha.js** and **chai.js** responsibility first. **mocha.js** provides test case syntax - so: ```#describe```, ```#it```, ```#beforeEach``` etc. **chai.js** is assertions library, so it defines ```#expect``` function and all matchers. I like *expectation* style, but you can use *assertion* or *should* as well - they all are wrappers on same concept of assertion.

How test suite is built? It has root ```#describe``` which informs about object or feature under test - good practice is to use [object's constructor name](http://blog.arkency.com/2012/10/javascript-objects-philosophy/). ```#describe``` (not only root one) function can call other ```#describe``` functions in it, but also test cases - ```#it``` and some setup and teardown code - ```#beforeEach``` and ```#afterEach``` accordingly.

As I mentioned ```#it``` contains single test case - in perfect world it should always have one assertion. Test case without callback, so without function with test case's body, will be marked as pending.

Of course you have to remember to load object or function you want to test. Look at the first line - I use Rails' assets pipeline for this.

## Assertions

Let's get back to assertions. ```#expect``` function wraps result that we want to check - it can be result of function under test or [function spy/mock](http://sinonjs.org/). This wrapper provides chainable language to construct assertions - there are few special methods that are used just as chains, without any assertion: ```#to```, ```#be```, ```#been```, ```#is```, ```#that```, ```#and```, ```#have```, ```#with```, ```#at```, ```#of``` and ```#same``` - they are just syntactic sugar. Let's name few basic assertions:

* ```not``` - negates any assertion following in the chain
* ```equal(value)``` - asserts target is equal (===) to *value*
* ```include(value)``` - asserts target contains value
* ```true``` / ```false``` - asserts target is true / false

 You'll find more chainable assertions in [chai.js BDD API](http://chaijs.com/api/bdd/).

## Running tests

Ok, you know how to write tests, but how can you run them? While developing feature it might be useful to run all tests in browser - it will be easier to debug by using ```console.log``` or browser's debugger. You can serve all tests using following command:

```
#!bash
$ rake konacha:serve
```

It will run server on http://localhost:3500/ with mocha.js HTML reporter.

You can also run all tests with command line - you just have to use selenium or any headless browser. Konacha uses capybara as browser driver, so you can use any of provided capybara drivers like webkit, poltergeist etc. To run tests in command line just execute:

```
#!bash
$ rake konacha:run
```

## In next blog

You've learned basics about testing CoffeeScript front-end in Rails stack. This is just a very beginning of blog series - in next posts I want to show how to extract and test already existing views, then how to write front-end-level acceptance tests. Of course if any other topic related to CS testing comes up I'll also write few lines about it, so don't hesitate to comment.

