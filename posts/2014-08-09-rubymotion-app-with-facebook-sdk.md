---
title: "RubyMotion app with Facebook SDK"
created_at: 2014-08-09 22:16:53 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :skip
newsletter_inside: :mobile
tags: [ 'facebook', 'sdk', 'ruby', 'rubymotion', 'ios', 'mobile' ]
stories: ['rubymotion']
---

<p>
  <figure align="center">
    <img src="/assets/images/mobile/ruby-motion-facebook-fit.png" width="100%">
  </figure>
</p>

This will be short, simple, but painless and useful. We'll show you **how to integrate Facebook SDK with RubyMotion** application.

<!-- more -->

[Recently  we encouraged you to start using RubyMotion](http://blog.arkency.com/2014/07/one-ruby-to-rule-them-all/) and we presented some useful gems to start developing with.

Now, we'd like to show you how to integrate Facebook iOS SDK with RubyMotion and create sample application from scratch.

## Boilerplate

Firstly, we have to generate RubyMotion application. We will use awesome [RMQ gem](http://rubymotionquery.com/) for building initial skeleton.

    gem install ruby_motion_query
    rmq create ruby-motion-facebook
    cd ruby-motion-facebook
    bundle
    rake
    
Our application is up and running.

## Integrate Facebook SDK

Now it's time to include FB pod in our project. [Pods](http://cocoapods.org/) are dependencies, something like gems, for iOS and are compatible with RubyMotion too.

In our `Gemfile` we need to uncomment or add the following line:

    gem 'motion-cocoapods'
    
Then, in `Rakefile` inside `Motion::Project::App.setup` block we should add:

```
#!ruby
app.pods do
  pod 'Facebook-iOS-SDK', '~> 3.16.2'
end
```

After all that let's install all dependencies:

    bundle              # to install motion-cocoapods
    pod setup           # to setup pods repository
    rake pod:install    # to fetch FB SDK
    
That installs Facebook SDK for iOS in our RubyMotion project. We can now build all logic as we want.

## Prerequisites

Let's build some kind of login feature. The use case may be as follows:

1. When user opens our app, there's a login screen with Facebook button
2. After user clicks on it, safari opens webpage asking user to authorize our application
3. As soon as user confirms permission, web page redirects us back to our application
4. Now the main screen with user basic data is displayed.

In order to use FB application, we should create it on [Facebook developers portal](https://developers.facebook.com/apps/) first. However, if you don't want to follow [simple tutorial](https://developers.facebook.com/docs/ios/getting-started#appid) how to do that, you still can use sample FB app ID provided by Facebook itself `211631258997995`.

To be able to be redirected back to our application from Safari, we should register appropriate `URL Scheme` for `URL types` in `Info.plist`, which [stores meta information](https://developer.apple.com/library/iOs/documentation/General/Reference/InfoPlistKeyReference/Introduction/Introduction.html) in each iOS app.

Just below `app.pods` in `Rakefile` add:

```
#!ruby
FB_APP_ID = '<FB_APP_ID>'
app.info_plist['CFBundleURLTypes'] = [{ CFBundleURLSchemes: ["fb#{FB_APP_ID}"] }]
```

What is more, we have to register our Facebook app ID too:

```
#!ruby
app.info_plist['FacebookAppID'] = FB_APP_ID
```

## Login screen

Now is the time to build login screen with big blue button.

In `app/controllers/main_controller.rb` in `vievDidLoad` method add the following line:


```
#!ruby
@fb_login_button = rmq.append(FBLoginView.new, :fb_login_button).get
@fb_login_button.delegate = self
```

It tells RMQ to add Facebook login button instance as a subview and apply `fb_login_button` style to it. What is more, it registers itself as a delegate to handle all login methods.

We have to create our style yet. For that open `app/stylesheets/main_stylesheet.rb` and add the following code:

```
#!ruby
def fb_login_button(st)
  st.frame = { centered: :both }
end
```

That will center FB button.

`AppDelegate` class is entry point to every iOS application. It should manage login state so we need to configure it as follows:

```
#!ruby
def application(_, openURL: url, sourceApplication: sourceApplication, annotation: _)
  FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication)
end

def applicationDidBecomeActive(application)
  FBSession.activeSession.handleDidBecomeActive
end

def applicationWillTerminate(application)
  FBSession.activeSession.close
end
```

Now, run application with `rake`. You should be able to see `login` or `logout` button accordingly to your current state.

## Login logic

We have to handle login state now. On the very beginning we can just set navbar title for our application to be changed when user logs in and out. Let's do it in `MainController` class:

```
#!ruby
def loginViewShowingLoggedInUser(_)
  set_title 'User logged in'
end

def loginViewShowingLoggedOutUser(_)
  set_title 'User logged out'
end

def set_title(text)
  self.title = text
end
```

Let's `rake` and play with that.

We can display user info too. Here's how it works:

```
#!ruby
def loginViewFetchedUserInfo(_, user: user)
  rmq(@fb_login_button).animate { |btn| btn.move(b: 400) }
  @name_label      = rmq.append(UILabel, :label_name).get
  @name_label.text = "#{user['first_name']} #{user['last_name']}"
  rmq(@name_label).animations.fade_in
end

def loginViewShowingLoggedOutUser(_)
  set_title 'User logged out'
  if @name_label
    rmq(@name_label).animations.fade_out
    @name_label.removeFromSuperview
    rmq(@fb_login_button).animate { |btn| btn.move(b: 300) }
  end
end
```

And some styling for that:

```
#!ruby
def label_name(st)
  st.frame          = { w: app_width, h: 40, centered: :both }
  st.text_alignment = :center
  st.hidden         = true
end
```

## Summary

And that's it. I'm happy that you went through this article. In case you need ready code, I created [repository with example application](https://github.com/KamilLelonek/ruby-motion-facebook). Enjoy!

<%= inner_newsletter(item[:newsletter_inside]) %>

For now, stay tuned for more mobile blogposts!

## Resources

- https://developers.facebook.com/docs/ios/getting-started/
- https://developers.facebook.com/docs/facebook-login/ios/v2.1
- https://developers.facebook.com/docs/reference/ios/current/
