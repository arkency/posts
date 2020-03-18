---
title: "Tracking dead code in Rails apps with metrics"
created_at: 2017-06-23 15:57:39 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'chillout', 'custom metrics', 'dead code' ]
newsletter: arkency_form
img: ruby-rails-metrics-for-detecting-unused-code/chillout-io-grafana-alert-unused-code2.jpg
---

When you work in big Rails application sometimes you would like to remove certain lines of code or even whole features. But often, you are not completely sure if they are truly unused. What can you do?

<!-- more -->

With [chillout.io](http://chillout.io/) and other monitoring solutions that's easy. Just introduce a new metric in the place of code you are unsure about.

```ruby
class SocialSharesController < ApplicationController
  def friendster
    Chillout::Metric.track('SocialSharesController#friendster')

    # normal code
  end
end
```

After you add a graph to your panel, you can easily [configure an alert](http://docs.grafana.org/alerting/rules/) with notifications to Slack, email or whatever you prefer, so that you are pinged if this code is executed.

<%= img_fit("ruby-rails-metrics-for-detecting-unused-code/chillout-io-grafana-alert-unused-code2.jpg") %>

Wait an appropriate amount of time such as a few days or weeks. Make sure the code was not invoked and talk to your business client, boss, CTO or coworkers to make the final call that the feature should be dropped. Now you have the arguments.

We all know that unused code is burden for our whole team because we keep supporting it, refactoring (yes, sometimes we do renames or upgrades and we spend time on code delivering no value, don't we?). Even because it keeps appearing in search results or occupying space in our mind.

As [Michael Feathers greatly explained](http://michaelfeathers.typepad.com/michael_feathers_blog/2011/05/the-carrying-cost-of-code-taking-lean-seriously.html)

> No, to me, code is inventory.  It is stuff lying around and it has substantial cost of ownership. It might do us good to consider what we can do to minimize it.

> I think that the future belongs to organizations that learn how to strategically delete code.  Many companies are getting better at cutting unprofitable features in their products, but the next step is to pull those features out by the root: the code.  Carrying costs are larger than we think. There's competitive advantage for companies that recognize this.

Or as [Eric Lee put it](https://blogs.msdn.microsoft.com/elee/2009/03/11/source-code-is-a-liability-not-an-asset/):

> However, the code itself is not intrinsically valuable except as tool to accomplish some goal.  Meanwhile, code has ongoing costs.  You have to understand it, you have to maintain it, you have to adapt it to new goals over time.  The more code you have, the larger those ongoing costs will be.  It’s in our best interest to have as little source code as possible while still being able to accomplish our business goals.

Or as [James Hague](http://prog21.dadgum.com/177.html) expressed it:

> To a great extent the act of coding is one of organization. Refactoring. Simplifying. Figuring out how to remove extraneous manipulations here and there.

