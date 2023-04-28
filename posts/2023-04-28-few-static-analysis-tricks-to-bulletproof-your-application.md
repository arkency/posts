---
created_at: 2023-04-28 11:17:58 +0200
author: Piotr Jurewicz
tags: ['ruby', 'rails', 'static analysis']
publish: true
---

# Few static analysis tricks to bulletproof your application

Static analysis is the process of examining code without executing it to identify potential issues and improve its quality.
By employing valuable static analysis techniques, you can enhance your application's robustness and reliability.
In this article, I discuss three practical techniques that can help you prevent and resolve issues in your codebase.

## Badly named tests

Recently, while tracking down unused code in our client's application,
We came across a RSpec test that clearly could not pass.
Indeed, when we executed the test individually using `rspec` and specifying its path, it failed as expected.
However, when running the entire test suite with `bundle exec rspec`, all tests passed.
Upon further investigation, it turned out that this test file didn't follow RSpec's test naming convention.

As stated in the RSpec documentation:
```bash
# Default: Run all spec files (i.e., those matching spec/**/*_spec.rb)
$ bundle exec rspec
```
We wanted to verify whether other test files might be bypassed by RSpec.
The project was huge, so it was impossible to do it manually.

Using the following command, we managed to identify all problematic files:
```bash
find ./spec -type f -not -name \*_spec.rb -not -path "./spec/factories/*" -not -path "./spec/support/*" | xargs rg RSpec\.describe
```
We found numerous files with incorrect naming patterns, such as `*.spec.rb`, `*_sepc.rb`, and so on. After renaming these files, we ran them and half of them failed...

## Not resolving constants

In one of my previous posts, I explained in-depth how we [tracked down not resolving constants with a parser gem](https://blog.arkency.com/tracking-down-not-resolving-constants-with-parser/).
These not resolving constants represent potential runtime errors that can be easily prevented with static analysis.
I have shared our script on the [public repository](https://github.com/arkency/constants-resolver) allowing you to copy [collector.rb](https://github.com/arkency/constants-resolver/blob/main/collector.rb) and effortlessly run it against your project.
```bash
bundle exec ruby collector.rb app/
```

## Unnecessary routes

Another useful script for cleaning up your codebase checks if your `routes.rb` file define any routes which do not have a corresponding controller action nor a view for implicit rendering.
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
Simply copy the script and run it using `ruby unused_routes.rb`. You may be surprised by the results.
