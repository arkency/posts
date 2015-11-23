---
title: "Simple feature toggle for Rails app"
created_at: 2015-11-22 22:58:31 +0100
kind: article
publish: false
author: Szymon Fiedler
tags: [ 'rails', 'feature toggle' ]
newsletter: :fearless_refactoring_1
img: "/assets/images/simple-feature-toggle-for-rails-app/header.jpg"
---

<p>
  <figure>
    <img src="/assets/images/simple-feature-toggle-for-rails-app/header-fit.jpg" width="100%">
    <details>
      <a href="https://flic.kr/p/7zHjDq">Photo</a> available thanks to the courtesy of
      <a href="https://www.flickr.com/photos/33852688@N08/">Chris Costes</a>.
      <a href="https://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

You've probably heard before about [feature toggle](http://martinfowler.com/bliki/FeatureToggle.html). Theory looks fine on the paper, but you’re possibly wondering how to implement such feature in your Rails app.

<!-- more -->

## Why even use feature toggles?

It's neat to use feature toggle when:

  * you want to present some features earlier to the product owner, sales or support teams. It’s much easier to do that on a real system, with real data and not merge multiple branches to staging, seed it with data and then ask everyone to visit it
  * when you work on a big feature and like to commit straight to master. Just disable the new feature on production env so no one can see it and push code to CI
  * you create a dedicated solution for a key customer of the platform you’re working on. Just enable it for given user

[Robert](http://blog.arkency.com/by/pankowecki/) recently mentioned interesting use case of feature toggle in his post titled _[Advantages of working on a legacy application](http://blog.arkency.com/2015/10/advantages-of-working-on-a-legacy-rails-application/)_

## Somebody already did that

Exactly, there are several gems available which will bring feature toggle to your rails app. I looks like the most popular ones are [chili](https://github.com/balvig/chili) and [feature](https://github.com/mgsnova/feature). However, they seemed to be too heavy for our use case and we didn’t want to add another one dependency to our codebase. We wanted to find a dead simple solution.

## Implementation

```
#!ruby

class FeatureToggle
  def initialize
    @flags = Hash.new
  end

  def with(name, *args, &block)
    block.call if on?(name, *args)
  end

  def on?(name, *args)
    @flags.fetch(name, proc{|*_args| false }).call(*args)
  end

  def for(name, &block)
    @flags[name] = block
  end
end

```

### Defining toggles

There's not so much to comment here. The `for` method is used to define given toggle, eg.

```
#!ruby

FT = FeatureToggle.new.tap do |ft|
  ft.for(:new_user_profile) do |user_id:|
    Admin.where(user_id: user_id).exists?
  end
end

```

And that's it, now it can be used in the codebase. An instance of _FeatureToggle_ class is assigned to constant `FT`, so it will be globally available.

### Enabling given feature via toggle

Let's use it for example in controller action to render different, redesigned view instead of the basic one. It will only work for admin users as we stated in toggle definition.

```
#!ruby

class UserProfilesController < ApplicationController
  def show
    FT.with(:new_user_profile, user_id: current_user.id) do
      return render :new_user_profile, locals: { user: NewUserProfilePresenter.new(current_user) }
    end

    render :show, locals: { user: UserProfilePresenter.new(current_user) }
  end
end

```

When given user will meet the criteria (is an admin), a different view will be rendered with new presenter applied.

## Final thoughts

This solution is very lightweight and has limited possibilities comparing to gems mentioned at the beginning of the article. However, it helped me a lot with dropping branching. Committing straight to master became a habit. Sales & support team can see features earlier than other users. They are able to review them on a daily basis while normally using the platform. They’re getting more and more familiar with the new behavior, often give valuable feedback. When everything is fine, simple toggle change makes given feature available to all of the users.
