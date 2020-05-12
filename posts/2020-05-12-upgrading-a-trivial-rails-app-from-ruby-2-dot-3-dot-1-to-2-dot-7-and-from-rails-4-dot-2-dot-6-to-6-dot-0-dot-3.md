---
title: Upgrading a trivial Rails app from Ruby 2.3.1 to 2.7 and from Rails 4.2.6 to 6.0.3
created_at: 2020-05-12T12:05:55.324Z
author: Andrzej Krzywda
tags: [ruby upgrade, rails upgrade, heroku, plusone]
publish: true
---

This blogpost describes the upgrading process of a trivial Rails app. 
The app is called PlusOne (it's [open-sourced](https://github.com/arkency/plusone)) and it's a small but fun Slack bot (MS Teams support coming).

This app doesn't rely on any external gems, consists only of 3 database tables. It just stores who gave upvote to whom. 
Additionally it shows some stats - who has how many points.

Upgrading Ruby and Rails for such no-external-gems apps is mostly trivial, but there are some gotchas which I have documented
along the way.

The actual initial trigger for those upgrades was the enforcement of Heroku to upgrade the stack. This required newer Ruby, so here we are.

The app was still on Ruby 2.3.1 (and Rails 4), so I decided to make a small step first - upgrade to the latest Ruby from the 2.3 series - to the 2.3.8 version.

This went smoothly. Bundle install went fine. All tests passed. Commit, push, deploy.

Next step - upgrade to 2.4.10 - the most recent one in the 2.4 series.

A typical problem while upgrading Ruby versions in Rails apps is the bundler version. Usually when you install recent Ruby versions, it comes with a new bundler gem. The fix is to uninstall the new one and install the required older one.

In my case it was:

`gem uninstall bundler --version 2.1.4`

`gem install bundler --version 1.17.3`

After a successful 2.4.10 upgrade, it was time to upgrade to the 2.5 series. At the moment of writing this post, the newest one is 2.5.8.

This went smoothly, the same with going 2.6.3.

At this stage some deprecation warnings appeared.

It’s also here, where I had to make an upgrade from Rails 4 to Rails 5, before I upgrade to Ruby 2.7 easily.

```
Expected to find a manifest file in `app/assets/config/manifest.js`
But did not, please create this file and use it to link any assets that need
to be rendered by your app:

Example:
  //= link_tree ../images
  //= link_directory ../javascripts .js
  //= link_directory ../stylesheets .css
and restart your server (Sprockets::Railtie::ManifestNeededError)
```

This showed up after upgrading to Rails 5.2.4.3 (newest one from Rails 5 series).

In my app I could probably just disable Sprockets, but it’s not an obvious solution - I’d need to unpack railites/all to all the components manually.

The alternative is a temporary hack:

```
mkdir -p app/assets/config && echo '{}' > app/assets/config/manifest.js
```

Which means we’re just creating an empty manifesto file.

After doing this, my tests could finally be run. They failed with some errors, though:

```
ArgumentError: unknown keywords: team_domain, trigger_word, text, team_id, user_name, user_id, format
```

I’ve had a number of such failures, all in Rails integration tests - the ones inheriting from `ActionDispatch::IntegrationTest`

The issue is that now the API for simulating http requests has changed:

Instead of:

```ruby
get :show, id: field.id
```

It needs to use named parameter `params`:

```ruby
get :show, params: {id: field.id}
```

After this fix, all my tests passed.

During the Heroku deploy, though, a new problem appeared:

```
Detecting rake tasks
 !
 !     Could not detect rake tasks
 !     ensure you can run `$ bundle exec rake -P` against your app
 !     and using the production group of your Gemfile.
 !     rake aborted!
 !     NameError: uninitialized constant Rake::TestTask
```

In my case, it was a “legacy” piece of code in my Rakefile:

```ruby
Rake::TestTask.new do |/t/|
  /t/.libs << “test”
  /t/.pattern = “test/services/*.rb”
end
```

It wasn’t really needed anymore, so I just dropped it.

In more complex scenarios, heroku recommends a technique like this:

```ruby
begin
  require ‘minitest/autorun’
rescue LoadError => e
  raise e unless ENV[‘RAILS_ENV’] == “production”
end
```

During the production deployment (it’s a common pattern to discover problems only at production environment) I’ve had another issue:

```
Running: rake assets:precompile
       rake aborted!
       LoadError: cannot load such file — uglifier
```

As a hotfix I added this to Gemfile:

```ruby
gem ‘uglifier’
```

and the deploy went fine.

After this I was ready to try the newest Rails version - 6.0.3.

It failed during tests with:

```
Error loading the ‘sqlite3’ Active Record adapter. Missing a gem it depends on? can’t activate sqlite3 (~> 1.4), already activated sqlite3-1.3.13
```

The fix was fairly simple:

```ruby
gem 'sqlite3', '~> 1.4'
```

in the Gemfile.

That’s it. My app now works with Ruby 2.7 and Rails 6. Yay!

You can see all commits [here](https://github.com/arkency/plusone/commits/master).
