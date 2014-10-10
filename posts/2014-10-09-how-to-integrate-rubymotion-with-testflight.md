---
title: "How to integrate RubyMotion with TestFlight"
created_at: 2014-10-09 10:11:40 +0200
kind: article
publish: false
author: Kamil Lelonek
newsletter: :skip
newsletter_inside: :mobile
tags: [ 'testflight', 'testflightapp', 'ruby', 'rubymotion', 'ios', 'mobile' ]
stories: ['rubymotion']
---

<p>
  <figure align="center">
    <img src="/assets/images/mobile/ruby-motion-testflight-fit.png" width="100%">
  </figure>
</p>

[TestFlight](https://www.testflightapp.com/) is an awesome and free platform for mobile developers, testers and clients to perform beta testing, crash reporting, and analytics. It makes it easy to invite users to test pre-release versions of iOS apps and gather all necessary statistics before we release them on the App Store.

Although RubyMotion documentation has [an article](http://www.rubymotion.com/developer-center/articles/testflight/) about TestFlight already, it is worth to describe it more precisely, especially when TestFlight [no longer provides SDK](http://help.testflightapp.com/customer/portal/articles/1452760), which is required in that official RM guide.

<!-- more -->

## Prerequisites

In order to cover all the next steps, I assume that you have already acquired Apple Developer Certificate and Provisioning Profile. Without it you cannot test your application on your own device during development. This is quite huge topic and there are a bunch of articles how to set this up but if you need any help, please refer to [Josh Symonds article](http://joshsymonds.com/blog/2012/05/10/from-the-rubymotion-simulator-to-your-friends-iphone/) with quite nice explanation.

## How it works

<p>
  <figure align="center">
    <img src="/assets/images/mobile/ruby-motion-testflight-instruction-fit.png" width="100%">
  </figure>
</p>

The image above is quite self-explanatory, but let me summarize it briefly.

1. Create RubyMotion application
2. Setup TestFlight [account](https://testflightapp.com/register/)
3. Add [new application](https://www.testflightapp.com/dashboard/applications/create/)
4. Get required credentials
    - Developer API token
    - Team API token
    - Application ID
5. Upload your build
6. Let testers / clients to download and test your app using [TestFlight application](https://itunes.apple.com/us/app/testflight/id899247664)
7. Gather statistics, feedbacks and opinions to improve your product

## Gems are helpful

Everything in Ruby and [RubyMotion world](http://motion-toolbox.com/) has a nice wrapper gem for the almost every feature you just need. So not surprisingly, the same is with TestFlight. [Motion-testflight](https://github.com/HipByte/motion-testflight) allows RubyMotion projects to easily embed the TestFlight SDK and be submitted to the TestFlight platform. However, as I mentioned before, we don't have to care about including SDK in our project anymore.

## Basic setup

OK, let's finally jump into our project. The most interesting part is of course `Rakefile`, but before we configure it, firstly ensure to include corresponding line in `Gemfile`:

```
#!ruby
gem 'motion-testflight'
```

Now, open `Rakefile` and add the following entries:

```
#!ruby
testflight = TestFlightSettings.new

Motion::Project::App.setup do |app|
  app.development do
    app.entitlements['get-task-allow'] = true
    app.codesign_certificate           = "iPhone Developer: #{ENV['APPLE_DEVELOPER_NAME']}"
    app.provisioning_profile           = ENV['APPLE_PROVISIONING_PROFILE_PATH']

    app.testflight do
      app.testflight.api_token          = testflight.api_token
      app.testflight.team_token         = testflight.team_token
      app.testflight.app_token          = testflight.app_token
      app.testflight.notify             = testflight.notify
      app.testflight.identify_testers   = testflight.identify_testers
      app.testflight.distribution_lists = testflight.distribution_lists
    end
  end

  app.release do
    app.provisioning_profile = ENV['APPLE_PROVISIONING_PROFILE_PATH']
    app.codesign_certificate = 'iPhone Distribution: ENV['APPLE_COMPANY_NAME']'
  end
end
```

`TestFlightSettings` is a nice wrapper for TestFlight credentials:

```
#!ruby
class TestFlightSettings
  attr_reader :api_token,
              :team_token,
              :app_token,
              :notify,
              :target,
              :identify_testers,
              :distribution_lists

  def initialize
    @api_token          = ENV['TESTFLIGHT_API_TOKEN']
    @team_token         = ENV['TESTFLIGHT_TEAM_TOKEN']
    @app_token          = ENV['TESTFLIGHT_APP_TOKEN']
    @notify             = true
    @identify_testers   = true
    @distribution_lists = [ENV['TESTFLIGHT_APP_NAME']]
  end
end
```

Note that `distribution_lists` is something more than `APP_NAME`. TestFlight allows to separate developers by groups for example: `testers`, `clients` and so on. In case of having such a setup, we should include here all group names for which we want to publish our app.

## Release

And that's it. Now you only have to push your build to TestFlight. That can be done done so simple:

```
#!ruby
rake testflight notes='your release message for users'
```

In these shorts steps we walked through beta-release process of your RubyMotion application to TestFlight from where can be download directly on your users' devices.

Now you can download [TestFlight](https://itunes.apple.com/us/app/testflight/id899247664) on your and your clients' devices. Uploaded application will be available immediately.

## Caveats

Very important thing is that if you are interested in TestFlight you should create an account as soon as possible there. This is because [Apple acquired Burstly](http://thenextweb.com/apps/2014/09/10/apple-launches-native-testflight-beta-testing-app-globally-opens-internal-testers-initially/), creator of TestFlight and now [iTunes Connect](https://itunesconnect.apple.com) (platform for uploading applications to AppStore) [will be integrated with TestFlight](http://9to5mac.com/2014/06/02/apple-focuses-on-developer-features-for-ios-8-testflight-beta-testing-biggest-sdk-ever-inter-app-communication-and-more/). However for now we can still upload builds in regular way, current and even new accounts still work on the old rules and no Apple review is required right now yet.

## Alternatives

Yes, there are some:

1. Paid
    - [HockeyApp](http://hockeyapp.net/features/)
    - [Applause](http://www.applause.com/mobile-sdk)
    - [Appaloosa](https://www.appaloosa-store.com/)
2. Free
    - [HockeyKit](http://hockeykit.net/)

<%= inner_newsletter(item[:newsletter_inside]) %>

## Links

- https://testflightapp.com/
- https://developer.apple.com/app-store/testflight/
- http://www.imore.com/testflight-ios-8-explained
- http://www.imore.com/burstly-maker-testflight-app-testing-platform-acquired-apple
- http://www.neglectedpotential.com/2014/06/testflight/
- http://techcrunch.com/2014/02/21/rumor-testflight-owner-burstly-is-being-acquired-by-apple/