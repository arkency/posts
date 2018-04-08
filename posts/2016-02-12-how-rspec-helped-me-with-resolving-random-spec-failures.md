---
title: "How RSpec helped me with resolving random spec failures"
created_at: 2016-02-12 01:10:19 +0100
kind: article
publish: true
author: Szymon Fiedler
tags: [ 'rails', 'rspec', 'test' ]
newsletter: :arkency_form
---

<p>
  <figure>
    <img src="<%= src_fit("how-rspec-helped-me-with-resolving-randoms-spec-failures/header.jpg") %>" width="100%">
    <details>
      <a href="https://flic.kr/p/dZEH5s">Photo</a> available thanks to the courtesy of
      <a href="https://www.flickr.com/photos/mkoneeye/">Robert Kash</a>.
      <a href="https://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

Recently we started experiencing random spec failures in one of our customer’s project. When the test was run in an isolation, everything was fine. The problem appeared only when some of the specs were run before the failing spec.

<!-- more -->

## Background
We use CI with four workers in the affected environment. The all of our specs are divided into the four groups which are run with the same seed. In the past, we searched for the cause of such problem doing manual bisection. It was time-consuming and a bit frustrating for us.

## RSpec can do a bisection for you
You probably already know RSpec’s `--seed` and `--order` flags. They are really helpful when trying surface flickering examples like the one mentioned in the previous paragraphs.
RSpec 3.4 comes with a nifty flag which is able to do that on behalf of a programmer. It’s called `--bisect`. According to the [docs](https://relishapp.com/rspec/rspec-core/docs/command-line/bisect), _RSpec will repeatedly run subsets of your suite in order to isolate the minimal set of examples that reproduce the same failures._

## How I solved the problem using RSpec’s `--bisect` flag
I simply copied the `rspec` command from the CI output with all the specs run on given worker with the `--seed` option and just added `--bisect` at the end. What happened next? See the snippet below:

    Running suite to find failures... (7 minutes 48 seconds)
    Starting bisect with 4 failing examples and 1323 non-failing examples.
    Checking that failure(s) are order-dependent... failure appears to be order-dependent

    Round 1: bisecting over non-failing examples 1-1323 .. ignoring examples 663-1323 (6 minutes 41 seconds)
    Round 2: bisecting over non-failing examples 1-662 .. ignoring examples 332-662 (4 minutes 44.5 seconds)
    Round 3: bisecting over non-failing examples 1-331 .. ignoring examples 166-331 (3 minutes 25 seconds)
    Round 4: bisecting over non-failing examples 1-166 .. ignoring examples 84-166 (2 minutes 14 seconds)
    Round 5: bisecting over non-failing examples 1-83 .. ignoring examples 1-42 (44.45 seconds)
    Round 6: bisecting over non-failing examples 43-83 .. ignoring examples 64-83 (56.97 seconds)
    Round 7: bisecting over non-failing examples 43-63 .. ignoring examples 43-53 (20.71 seconds)
    Round 8: bisecting over non-failing examples 54-63 .. ignoring examples 54-58 (20.02 seconds)
    Round 9: bisecting over non-failing examples 59-63 .. ignoring examples 59-61 (20.23 seconds)
    Round 10: bisecting over non-failing examples 62-63 .. ignoring example 62 (20.49 seconds)
    Bisect complete! Reduced necessary non-failing examples from 1323 to 1 in 19 minutes 53 seconds.

    The minimal reproduction command is:
      rspec './payment_gateway/spec/stripe/payment_gateway_spec.rb[1:8,1:9,1:10,1:11]' \
            './spec/services/backstage/fill_in_shipping_details_spec.rb[1:1:1]' \
             --color --format Fivemat --require spec_helper --seed 42035

## Recap
It took almost 20 minutes to find the spec which interfered with other ones. Usually, I had to spend 1-2 hours to find the issue. During this 20 minutes run of an automated task, I was simply working on a feature. The `--bisect` flag is a pure gold.

## But what was the reason for the failure?
It was simply `before(:all) {} ` used to set up the test. You shouldn’t use that unless you really know what you’re doing. You can read more about the differences between `before(:each)` and `before(:all)` in this `3.years.old`, but still valid [blog post](http://makandracards.com/makandra/11507-using-before-all-in-rspec-will-cause-you-lots-of-trouble-unless-you-know-what-you-are-doing).

## More

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="<%= src_fit("rbe/rbe-cover.png") %>" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
