---
title: "Quarantine your non-deterministic tests with a time limit"
created_at: 2017-11-22 10:02:37 +0100
publish: true
author: Robert Pankowecki
tags: [ 'quarantine', 'testing' ]
newsletter: arkency_form
---

In a fantastic article [Eradicating Non-Determinism in Tests](https://martinfowler.com/articles/nonDeterminism.html) Martin Fowler shares his strategies for dealing with random failures in your test suite. I especially like the idea of quarantine: to temporarily disable a certain test and come back later to fix it. But disabling a randomly failing test is the easy part. The question is, what to do next?

<!-- more -->

> Then the question is what to do with the quarantined test suites. They are useless as regression tests, but they do have a future as work items for cleaning up. You should not abandon such tests, since any tests you have in quarantine are not helping you with your regression coverage.

> Place any non-deterministic test in a quarantined area. (But fix quarantined tests quickly.)

We want to come back to it, we want to fix the test and make it a first class citizen again.

But how do we track quarantined tests? What do we do about them?

Here is what Martin says:

> The general approach with quarantine is to take the quarantined tests out of the main deployment pipeline so that you still get your regular build process. However a good team can be more aggressive. Our Mingle team puts its quarantine suite into the deployment pipeline one stage after its healthy tests. That way it can get the feedback from the healthy tests but is also forced to ensure that it sorts out the quarantined tests quickly.

This can be achieved quite easily with RSpec by using tags. Imagine your build process has 3 phases/steps:

* normal tests (`rspec --tag ~quarantine`)
* deploy
* quarantined tests (`rspec --tag quarantine`)

You could also add tasks about quarantine specs to your project management tool so they remind you about waiting to be prioritized. But in Arkency, we prefer not to put technical tasks in a backlog, but rather business oriented tasks. Anything technical is part of shipping a business feature. It doesn't matter if it is writing code, tests, migrating data, doing deploys or fixing random tests.

I've just joined a project which needed our help. It took me a bit of time to achieve a green build on a CI. There were some hidden dependencies in tests, a bit of shared state that had to be tracked. Finally almost everything worked except for one test. I waited on feedback about how we wanted to proceed with it and I decided to put it in a quarantine. But I did not want to forget about it. So I disabled the test but with an expiration date. I gave myself one week of break. By that time we should have more info about the issue and more ideas on how to proceed.

```ruby
require 'test_helper'

weekly_quarantine = ENV['CI'] && Date.today <= Date.new(2017, 11, 22)

class XyzTest < ActiveSupport::TestCase
  test "shipping rates" do
    # ...
  end
end unless weekly_quarantine
```

I kept a private about this test and my communication with the team around it. But I also coded an expiration time for the quarantine in the test itself. I also made sure it fails on local machines in case someone works around that code (that's up to you, usually we quarantine on all machines). One week after introducing the quarantine it would disable and the failing test on CI would remind everyone that we have a decision to be made. Should we extend the quarantine, remove the test, or spend some time investigating and improving it.

2 days before the quarantine deadline, I had all the information I needed. I fixed the test and removed the quarantine.

BTW. I disabled the whole class (because it only had one test method) but you could easily achieve the same with a smaller scope limited to one method only.

```ruby
require 'test_helper'

class XyzTest < ActiveSupport::TestCase
  weekly_quarantine = ENV['CI'] && Date.today <= Date.new(2017, 11, 22)

  test "shipping rates" do
    # ...
  end unless weekly_quarantine
end
```

It was first time I put a test in a quarantine with a time limit. I don't know if that technique will stay with me for longer, but it was certainly an interesting experiment to put a time boundary. Do you sometimes disable your tests? How do you come back to them?

### Get More

If you need help with your Rails app, we are [available for one project](/assets/misc/How-can-Arkency-help-you.pdf) since November, 27th.

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our everyday struggles and solutions for building maintainable Rails apps which don't surprise you.

Also worth reading:

* [Unit tests vs class tests](/2014/09/unit-tests-vs-class-tests/) - There’s a popular way of thinking that unit tests are basically tests for classes. Andrzej would like to challenge this understanding.
* [Service objects as a way of testing Rails apps (without factory_girl)](/2014/06/setup-your-tests-with-services/) - using service objects to set up a test state instead of factory_girl
* [Rails and adapter objects: different implementations in production and tests](/2016/11/rails-and-adapter-objects-different-implementations-in-production-and-tests/) - this article describes how to have a different implementation being passed in the production environment and an in-memory one in the tests.
* [Relative Testing vs Absolute Testing](/relative-testing-vs-absolute-testing/) - consciously recognizing and switching between these 2 ways of testing can make it much easier for you sometimes.
