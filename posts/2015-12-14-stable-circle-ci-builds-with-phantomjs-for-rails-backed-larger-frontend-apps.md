---
title: "Stable Circle CI builds with PhantomJS for larger Rails-backed frontend apps"
created_at: 2015-12-14 10:50:00 +0100
kind: article
publish: true
author: Marcin Domański
tags: [ 'circleci', 'react', 'phantomjs', 'rails' ]
newsletter: :skip
img: "stable-circle-ci-builds-with-phantomjs-for-rails-backed-larger-frontend-apps/header.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("stable-circle-ci-builds-with-phantomjs-for-rails-backed-larger-frontend-apps/header.jpg") %>" width="100%">
    <details>
      The original photo is available on <a href="https://stocksnap.io/photo/ABMMJRIYZF">stocksnap</a>. Author: Stephen Radford.
    </details>
  </figure>
</p>

One of the projects we work on is a rather large frontend app, built with React and backed by Rails. The app has quite a few tests and obviously we want them to run as fast as possible. We have tried a few drivers along the way but eventually we have chosen PhantomJS. So far we are pretty much happy about the choice, but it wasn't always like that. Especially when it comes to our CI server where the tests would quite often fail randomly and prevent the app from being deployed. The __random__ failures have been the biggest pain so far and so here are a few tricks that have helped us keep the build green.

<!-- more -->

## Make sure you wait for ajax

Our app is a typical frontend application, which means there are AJAX requests sent all over the place. Even the simplest edit and save operation sends one and then shows a flash message when it's done. Now to have a test that checks if the proper flash message is visible, we need to wait for AJAX, it's not enough to simply do:

```ruby

expect(actor).to see "Success messaage"
```

even though ["Capybara is ridiculously good at waiting for content"](http://www.elabs.se/blog/53-why-wait_until-was-removed-from-capybara). In our case this fails from time to time and so we have resorted to a custom `wait_for_ajax` helper method that checks if there are any AJAX requests still running:

```ruby

# snippet of spec/support/helpers.rb
def wait_for_ajax
  wait_until do
    page.evaluate_script('jQuery.active').zero?
  end
end
```

Then in our tests we call it after clicking a Save button:

```ruby

# snippet of an acceptance test
def set_reward_attribute(actor, reward)
  actor.fill_in "reward", with: reward
  actor.click_on 'Save'
  actor.wait_for_ajax
  expect(actor).to see_flash "Reward updated successfully."
  expect(actor).to see value
end
```

## Consider switching parallel builds off

In our case, this one seems to be __the main cause__ of our random failures. Switching it off has brought the build back to its green color and random failures are a very rare thing now. The downside is that the tests take much longer to run but it's pretty much guaranteed that the app will be built and deployed right away without the need of rebuilding the whole thing again and again. In our worst cases, we had to do it quite a few times and already started to hate the rebuild option, knowing that it might not help and that we still have a problem somewhere else.

## PhantomJS 2.0

Initially, we were using PhantomJS 1.9.8, but it didn't have the `bind` method needed to support React (we had to add it ourselves). It also had some other issues, like clicking other elements than buttons or inputs. Eventually, we decided to upgrade to version 2.0 where most of the issues were eliminated. So far it has been the most stable version. Oh, and it's slightly faster, too!

Now, to actually use PhantomJS 2.0 on CircleCI, you need to have this in your circleci.yml:

```ruby

# snippet of: circleci.yml

dependencies:
  pre:
    - sudo apt-get update; sudo apt-get install libicu52
    - curl --output /home/ubuntu/bin/phantomjs-2.0.1-linux-x86_64-dynamic https://s3.amazonaws.com/circle-support-bucket/phantomjs/phantomjs-2.0.1-linux-x86_64-dynamic
    - chmod a+x /home/ubuntu/bin/phantomjs-2.0.1-linux-x86_64-dynamic
    - sudo ln -s --force /home/ubuntu/bin/phantomjs-2.0.1-linux-x86_64-dynamic /usr/local/bin/phantomjs
```

## Use Puma instead of WEBrick

Here is a trick that may also make your build more stable. We have noticed that WEBrick, which is the default server, hangs from time to time and gives us weird timeouts during the test runs. So we searched for alternatives and ended up using Puma instead. It seems to be much more stable and here is how you can plug it in:

```ruby

# fragment of: spec/spec_helper.rb
Capybara.server do |app, port|
  require 'rack/handler/puma'
  Rack::Handler::Puma.run(app, Port: port)
end
```

## Disable animations

Our frontend uses different animations, like fading out and in. This all looks nice but obviously also makes some functions slower, and as it turns out, causes some tests to fail randomly. For tests, however, the animations are totally unnecessary, so why not turn them off? Here is how we do it.

First, we add a custom CSS class to our `<body>` tag, for the test environment only:

```erb

<body<%%= Rails.env.test? ? ' class="disable-animations"'.html_safe : '' %>>
```

Then we use the following styles:

```sass

.disable-animations *,
.disable-animations *:after,
.disable-animations *:before
  transition-property: none !important
  -o-transition-property: none !important
  -moz-transition-property: none !important
  -ms-transition-property: none !important
  -webkit-transition-property: none !important
  transform: none !important
  -o-transform: none !important
  -moz-transform: none !important
  -ms-transform: none !important
  -webkit-transform: none !important
  animation: none !important
  -o-animation: none !important
  -moz-animation: none !important
  -ms-animation: none !important
  -webkit-animation: none !important
```

It's one of the things that won't hurt but may help eliminate the random test failures.

## Summary

Those few tricks have helped us eliminate most the random failures and are saving us long minutes, if not hours, of rebuiling the app over and over again. We hope they can also work for you.