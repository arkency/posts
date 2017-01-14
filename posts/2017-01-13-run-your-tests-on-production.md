---
title: "Run your tests on production!"
created_at: 2017-01-13 13:16:56 +0100
kind: article
publish: false
author: Tomasz Wróbel
tags: [ 'tests', 'integration', 'microservices' ]
newsletter: :arkency_form
---

Running your tests on production? On the real, live system?
Sounds unorthodox? There might be situations, where it's actually a good idea. Read on!

<!-- more -->

## A little background

One of the projects we're working on is composed of **multiple microservices**. We have a lot of good lower level tests, but at some point we felt we lack proper integration tests. Also our UI code needed some more coverage.

In a project comprised of microservices there are many integration surfaces, so many things can go wrong and **setting up the test environment is not trivial**. To start the whole app locally we need to spin up 8 ruby processes, not counting databases, message queues and assets compilation.

Building a dedicated infrastructure to launch all the required processes in test environment was a no-go for us at the moment, because that would easily consume way too much time. Such an environment would also be a permanent source of **debugging why a certain thing works here and not there**.

So we thought why don't we try running some test cases on our production app. Something in the direction of [syntetic monitoring](https://en.wikipedia.org/wiki/Synthetic_monitoring). Of course we don't mean to run every single test case - that would easily be an overkill. We want to **cover the "critical" scenario, a typical use case**. Chances are it will catch a big part of integration/UI/infrastructural issues. Handling all the corner cases would of course stay in lower-level tests.

Important thing to note - it was easier for us to give it a try because we don't yet have real customers using our app - just the QA - so one could argue it's not really a production app. True. But chances are we'll stay with this approach for longer and there are considerable benefits involved.

## Immediate objection

An immediate objection is probably **"aren't you worried that the test actions will somehow affect regular users' experience?"**. For example when some test data would become visible to other users? Understandable. Our project is better suited here because it's a multitenant system. Which means there are completely separate tenants using our app and normally they don't deal at all with each other. So this was easy - we just need to run the tests on a new tenant everytime and this shouldn't affect other tenants' experience.

But one could say, what if your tenant isolation code is buggy and sometimes there's data leaking from one tenant to another. We're not perfect, so it's perfectly imaginable. But honestly **I'd rather discover this issue while running our tests than later** when some real user crashed on another tenant's data, where there could be more severe consequences.

Of course not everybody works on a multitenant system, but many apps have some **specific ways to limit the visibility of certain data** to some users. In our case this was particularly easy. In your case it may be harder or involve some trade-offs. I can also imagine situations where it's totally infeasible. But it's probably worth giving a thought before completely dismissing the idea.

## Cleaning up

Another concern that comes up quickly is how we're going to clean up the data created by running the tests. This is not the test environment, so we cannot clear the test db or rollback the test transaction. Initially I thought we'll need some **sophisticated procedure** that would clean up the data after every build. This would also be error prone & dangerous - what if you accidentally delete the wrong data?

I discussed this with my colleagues and an interesting idea came up. **"Just don't clean up"**. Sounds even sillier. But:

* If test data is isolated enough, it shouldn't affect other users
* If your dataset is small (eg. early stage of the project), it will get bigger, which can lead you to **discover potential performance issues** occurring in such situations, like a missing db index in an important query. Issues are of course better spotted earlier (when it's usually easier to fix things) than later (when the userbase grows and some solutions are more problematic to apply)
* Nothing stops you from eventually cleaning up the data. You can do it manually or automatically whenever you need. You can create a backup beforehand for additional confidency. Of course you will need a way to tell test data apart, which can be harder or easier (like in our case with tenants)

During our discussions there even was an idea of performing a **real credit card payment** in such a test. To clean it up, you could issue a refund (another use case covered by the way). Ok, there could be non-returnable costs involved, like transaction fees. But, if the reliability of a large app is at stake, why not? Consider the cost of your time lost battling bugs that could have been avoided, or users not being able to work with the app. The bottom line is: a lot is possible, it's just trade-offs everywhere.

## What are the benefits?

* What you're testing is closest to what your users are actually using. You can never eliminate all differences between test/prod environments and, in the end, it's the production that matters. In our case these tests quickly helped us to discover a **infrastructural issue on production** (memory problems on one of the nodes)
* You're sparing yourself the need to maintain a separate environment for integration tests, which can be especially difficult if there are many parts involved.

## Setting it up

Why not the good old [Capybara](https://github.com/teamcapybara/capybara)? Luckily it can run tests against a remote server. Here's a snippet with the base class for the tests:

```
#!ruby
require "capybara/dsl"
require "capybara/poltergeist"

Capybara.app_host = ENV.fetch("TESTED_HOST")
Capybara.run_server = false
Capybara.current_driver = :poltergeist

class ProductionTestCase < Minitest::Test
  include Capybara::DSL

  def teardown
    Capybara.reset_sessions!
  end
end
```

`run_server = false` tells capybara not to spin up a server itself. This code does not need to live in our rails app. It can (and it probably should) be a **separate repo**. This way you don't unnecessarily load any of the rails stuff, so it hopefully makes the test startup a little faster.

Basically, apart from the test cases itself, the only thing you will need there is the rake task to run the tests:

```
#!ruby
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end
```

## Random builds

How about the reliability of tests executing the whole stack, involving a complicated JS client code? Frequent random failures can be frustrating, especially that debugging is harder with such high level tests. It's a question for us too. So far we've had a tolerable amount of random builds and we hope that it stays this way (or if it doesn't, that we can do something about it). We'll keep you posted!

## Interacting with an api?

What if you don't need to test a webpage, just an api? Actually we have one scenario, where we chose to interact with the api directly. What to use to fire http requests? You don't need Capybara in such case, nor any other test specific tool. Just use a normal http library, and continue with your assertions. We went for [rest-client](https://github.com/rest-client/rest-client) because it handled file uploads in an easy way.

## Where to run these tests?

There are basically three three ways you can run such tests:

* from CI against the remote server
* from your local machine against the remote server - useful while working on test cases itself
* from your local machine against the local server - useful while working on features, especially if you wanna TDD

## Running on CI

Our goal is to make it all run automatically and see nice green notifications on our slack channel (or wherever else). Since it's the production server being tested, we cannot run the tests in the regular build process after a push, because the code is simply not yet there on production. Typically your push would trigger a build on CI and after it passes (of course if you also got continuous delivery set up), it would then trigger a deploy. Only then we can run the tests. So basically you just need to **trigger a build** of the repo containing the tests, **whenever the app was deployed successfully**.

If you happen to use **CircleCI**, there's an api endpoint that let's you trigger the build whe never you wa nt, all you need is to post to this url:

```
https://circleci.com/api/v1.1/project/github/yourGithubUsername/yourRepo/tree/master?circle-token=TOKEN
```

* Api docs [here](https://circleci.com/docs/api/)
* You can generate the CircleCI api token [here](https://circleci.com/account/api)
* This is also a good reason to have a separate repo for these tests - you can trigger the build separately from the app build

So you need to do that whenever there's a sucessful deployment. If you happen to host your app on **heroku**, you can use heroku's free "Deploy Hooks" addon to post to that url. Here's how to do it from CLI:

```
heroku addons:create deployhooks:http --url=TheUrlAbove
```

## That's it!

Let us know what you think, what are your experiences. Of course it's not the only way to do it. You could for example run the tests against the staging server, which would have its pros and cons. We're still experimenting with the idea too - we'll keep you posted. 

PS. If you're looking for some more interesting ideas that can foster a great development environment, have a look at our book [Async Remote](http://blog.arkency.com/async-remote/).
