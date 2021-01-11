---
title: How well Rails developers actually test their apps
created_at: 2021-01-11T09:02:15.550Z
author: Tomasz Wróbel
tags: []
publish: false
---

# How well Rails developers actually test their apps

Here are the results of our _State of Testing in Rails apps_ survey results. Most interesting numbers distilled for your reading pleasure and efficiency. Number of surveyees: 142.

* 80% favor RSpec
* 79% find testing is inseparable from software development
* 54% say their app is well-tested
* 93% rely on unit tests
* 30% work with a project with over 100 db tables
* 33% work in a team of two or three
* 18% run a single test in "blink of an eye", 46% under 5s
* 19% need more than half an hour to run the full suite on a development machine
* 86% run their tests on CI
* 15% wait longer than half an hour for CI result
* 60% are "pretty much" confident in their test suite
* 57% drop everything and fix the build, if it happens to fail
* 57% say their biggest problem with tests is that they take ages to run
* 39% never allow skipped test cases
* 83% say tests help them refactor code
* 23% say they mostly test their JavaScript code
* 73% use mocks, 72% stubs, 35% fakes
* 39% do not assess coverage, 56% use simplecov
* 32% do not aim for a specific coverage level, 31% aim for over 90%
* 17% often get frustrated by random test failures
* 32% just retry the build upon encountering a random failure
* 50% do TDD sometimes, 23% do often, 9% do always

Want to see **detailed charts**? Jump into [this twitter thread](https://twitter.com/tomasz_wro/status/1348558886295506946). Also, it's the best place to **comment** or ask further questions.
