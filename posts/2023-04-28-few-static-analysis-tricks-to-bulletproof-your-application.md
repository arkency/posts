---
created_at: 2023-04-28 11:17:58 +0200
author: Piotr Jurewicz
tags: []
publish: false
---

# Few static analysis tricks to bulletproof your application

## Bad named tests

Recently, while tracking down unused code in our client's application,
We came across a rspec test that we thought had no chance for passing.
In fact, when we ran it by passing it's location to `rspec`, it failed.
However, when we ran the whole test suite with `bundle exec rspec`, it was green.
It turned out that this test file didn't follow rspec's naming convention.

From the Rspec docs:
```bash
# Default: Run all spec files (i.e., those matching spec/**/*_spec.rb)
$ bundle exec rspec
```
We wanted to check if there are any other test files that might be skipped by rspec.
The project was huge so we dind't want to check every file manually.

With this command:
```bash
find ./spec -type f -not -name \*_spec.rb -not -path "./spec/factories/*" -not -path "./spec/support/*" | xargs rg RSpec\.describe
```
We were able to find all the problematic files. We have discovered pretty much of them with names ending with `*.spec.rb`, `_sepc.rb` and so on.
It turned out that, after renaming them, a half wasn't passing. 

## Not resolving constants

In one of my previous post, I described in detail how we [tracked down not resolving constants with a parser gem](https://blog.arkency.com/tracking-down-not-resolving-constants-with-parser/).
I shared our script on the [public repo](https://github.com/arkency/constants-resolver) so you can copy [collector.rb](https://github.com/arkency/constants-resolver/blob/main/collector.rb) and easily run it against your project.
```bash
bundle exec ruby collector.rb app/
```

## Unnecessary routes

Another script to tidy up the codebase is the one checking if your routes.rb file define any routes which do not have a corresponding controller action.
```ruby
require_relative "config/environment"

Rails.application.routes.routes.map(&:requirements).each do |route|
  next if route.blank?
  next if route[:internal]

  controller_name = "#{route[:controller].camelcase}Controller"
  next if controller_name.constantize.new.respond_to?(route[:action])

  implicit_render_view = Rails.root.join("app", "views", *route[:controller].split('::'), "#{route[:action]}.*")
  next if Dir.glob(implicit_render_view).any?

  puts "#{controller_name}##{route[:action]}"
rescue NameError, LoadError
  puts "#{controller_name}##{route[:action]} - controller not found"
end
```
Just copy it and run with `ruby unused_routes.rb`.

