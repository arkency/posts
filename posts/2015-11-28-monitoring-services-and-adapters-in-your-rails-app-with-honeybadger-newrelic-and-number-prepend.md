---
title: "Monitoring services and adapters in your Rails app with Honeybadger, NewRelic and #prepend"
created_at: 2015-11-28 21:06:10 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'monitoring', 'instrumentation', 'rails', 'apps', 'new relic', 'honeybadger', 'prepend' ]
newsletter: :skip
newsletter_inside: :clean
---

The bigger your app gets the higher chance that it will need to integrate with multiple of external
services, providers and APIs. Sometimes they work, sometimes they don't. Sometimes it doesn't matter
when they are down or behaving problematicly. Sometimes it costs your clients money.

Like when a payment gateway is having problems on Black Friday.

<img src="/assets/images/ruby-rails-new-relic-honeybadger-custom-metrics-monitoring-instrumentation/payment-gateway-problems-fit.jpg">

Can you imagine?

But the first step to know about the problem and the urgency of a situation is to monitor it.
So we will start with that.

<!-- more -->

Let's imagine a simple Service Object that is doing _something_ in your app. Something probably
important. Perhaps it communicates with a payment gateway to create a new payment. Sounds important
enough. The code is probably doing some db queries maybe even updates. It might use a gem or
[an adapter](/2014/08/ruby-rails-adapters/) to communicate with an external service. It probably
needs to catch some exceptions (especially networking related) in case anything goes wrong and
ancapsule them into something expected by the controller.

```
#!ruby
class Service
  Error = Class.new(StandardError)

  def call
    db.query
    adapter.do_something
    return whatever
  rescue Adapter::Error, OtherKindsOfErrors
    raise Error
  end
end
```

Now because this is a crucial part of our shopping application we would like
to monitor it in production and respond to troubles.

We could add the monitoring directly to this class but it would make
it less readable. I experimented with two different approaches and
both work.

## Send events/notifications

You send notifications (for example using standard rails
mechanism such as [`ActiveSupport::Notifications`](http://api.rubyonrails.org/v4.2.5/classes/ActiveSupport/Notifications.html)
) or any other event bus that you use in your app.

```
#!ruby
class Service
  Error = Class.new(StandardError)

  def call
    db.query
    adapter.do_something
    ActiveSupport::Notifications.instrument("Service::Ok")
    return whatever
  rescue Adapter::Error, OtherKindsOfErrors => e
    ActiveSupport::Notifications.instrument("Service::Error", error: e)
    raise Error
  end
end
```

and you subscribe to them:

```
#!ruby
# config/initializers/instrumentation.rb

N = ActiveSupport::Notifications

N.subscribe("Service::Error") do |_name, _start, _finish, _id, payload|
  ::NewRelic::Agent.increment_metric('Custom/Service/Error')
  Honeybadger.notify(payload.fetch(:error))
end

N.subscribe("Service::Ok") do |_name, _start, _finish, _id, _payload|
  ::NewRelic::Agent.increment_metric('Custom/Service/Ok')
end
```

This almost works but I noticed that for New Relic to actually handle those metrics
I had to made sure `#increment_metric` it is called from the inside of a directly 
traced code:

```
#!ruby
# config/initializers/instrumentation.rb
require 'new_relic/agent/method_tracer'

Service.class_eval do
  include ::NewRelic::Agent::MethodTracer
  instance_method(:call) or raise "Instrumentation broken for #call"
  add_method_tracer :call, 'Custom/Service/call'
end
```

## Using `#prepend` (AOP style)

Since Ruby 2.0 we have the ability to use [`#prepend`](http://dev.af83.com/2012/10/19/ruby-2-0-module-prepend.html) as a way to enrich the
behavior of our classes with mixins that can original method definition
with super. It's not as powerful as aspect oriented programming but it will suffice in our case.

The module that you prepend can be an anonymous one.

```
#!ruby
Service.class_eval do
  instance_method(:call) or raise "Instrumentation broken for #call"

  prepend(Module.new do
    include ::NewRelic::Agent::MethodTracer

    def call
      super.tap do
        ::NewRelic::Agent.increment_metric('Custom/Service/Ok')
      end
    rescue => error
      ::NewRelic::Agent.increment_metric('Custom/Service/Error')
      Honeybadger.notify(error)
      raise
    end

    add_method_tracer :call, 'Custom/Service/call'
  end)
end
```

In this case the whole instrumentation and `NewRelic` / `Honeybadger` instrumentation is kept
inside the anonymous module.

### Safety precautions

I like to use `Service.class_eval` instead of `class Service` because the former
won't work if `Service` class is not defined in your codebase. Whereas the latter
experssion would quitely just define the class for your.

I also check if the method `#call` is defined in the class with `instance_method(:call)`
just to make sure we are not instrumenting unexisting method anymore.

We don't have the benefit of compiler to check for it in Ruby unfortunatelly and
`add_method_tracer` does not verify it either.

## Decorator

I will leave this as an excercise to the reader ;)

## Why bother?

Such probes make it easier for you to have an insight into the internals of your
system. You can use them for crucial adapters and service to keep an eye on how
things are going. The next step is after monitoring is to have alerts and team
how can fix the problems.

In case of the problems that we detected with our payment gateway we were capable
to switch it to a different one using the Feature Toggle implementation that I 
showed you in [_Rolling back complex apps_](http://blog.arkency.com/2015/10/rolling-back-complex-apps/#use_feature_toggles)

```
#!ruby
class PaymentGatewaySetting < ActiveRecord::Base
  SettingNotFound = Class.new(StandardError)

  def self.fetch(country_id:, merchant_id:, product_id:)
    where(
      country_id:  country_id,
      merchant_id: [nil, merchant_id],
      product_id:  [nil, product_id],
    ).order("
      COALESCE(product_id, 0)  desc,
      COALESCE(merchant_id, 0) desc,
               country_id      desc
    ").first || raise SettingNotFound
  end
end
```

About 30 minutes later they managed their problems and we could switch back.

## Stay tuned

This blog-post was inspired by [Responsible Rails](/responsible-rails/). A book in which we
show you how to handle fuckups and be a more responsible developer.

If you liked reading this you can subscribe to our newsletter below and keep getting more
useful tips.

<%= inner_newsletter(item[:newsletter_inside]) %>

