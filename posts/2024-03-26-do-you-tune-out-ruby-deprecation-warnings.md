---
created_at: 2024-03-26 16:11:04 +0100
author: Piotr Jurewicz
tags: [ 'ruby', 'rails' ]
publish: true
---

# Do you tune out Ruby deprecation warnings?

Looking into deprecation warnings is an essential habit to maintain an up-to-date tech stack.
Thanks to the explicit configuration of `ActiveSupport::Deprecation` in the environment-specific configuration
files, it's quite common to handle deprecation warnings coming from Rails.
However, I rarely see projects configured properly to handle deprecation warnings coming from Ruby itself.
As we always want to keep both Rails and Ruby up-to-date, it's crucial to handle both types of deprecation warnings.

## How does Rails handle its deprecation warnings?

In the environment configuration files, Rails sets up the `ActiveSupport::Deprecation` like this:

```ruby
# config/environments/development.rb
# Print deprecation notices to the Rails logger.
config.active_support.deprecation = :log

# Raise exceptions for disallowed deprecations.
config.active_support.disallowed_deprecation = :raise

# Tell Active Support which deprecation messages to disallow.
config.active_support.disallowed_deprecation_warnings = []
```

It simply means that, in the development environment, all deprecation warnings will be logged to the Rails logger and if
there are any deprecations we won't accept, an exception will be raised.
We usually want to disallow for deprecations that we have already handled to avoid regressions.

Available behaviors for `config.active_support.deprecation` are: `:raise`, `:stderr`, `:log`, `:notify`, `:report`, and
`:silence`. You can also pass any object that responds to the `call` method, i.e. a lambda.

We usually set it to `:raise` or `:log` in the development. It's a good practice to collect them into an artifact on CI
in the test environment.

```ruby
# config/environments/test.rb
if ENV.has_key?('CI')
  logger = Logger.new('log/deprecations.txt')
  config.active_support.deprecation = logger.method(:info)
else
  config.active_support.deprecation = :log
end
```

In the production environment, on the other hand, we normally want to log but never raise.
However, an auto-generated `config/environments/production.rb` file sets
`config.active_support.report_deprecations = false` which is equivalent to `:silence` behaviour.
We need manual intervention to start collecting deprecation warnings from the production environment.

## How about Ruby deprecation warnings?

Ruby can also emit deprecation warnings, but it's not as straightforward as in Rails and requires an explicit setup.

It uses the built-in `Warning` module to notify about deprecated features being used.
However, by default warnings issued by Ruby are printed to `$stderr`, which is usually ignored by developers.
Moreover, [Ruby starting from version 2.7.2](https://bugs.ruby-lang.org/issues/17591), would not issue this certain type
of warning unless we explicitly tell it to do so with `Warning[:deprecated] = true`.

An approach that I recommend is to apply the same strategy to Ruby deprecation warnings as it is configured for Rails.

We can do it by overriding the `Kernel#warn` method, which is used by Ruby to print warnings and make it pass certain
messages to the ActiveSupport::Deprecation#warn method.

```ruby
# config/initializers/capture_ruby_warnings.rb
Rails.application.deprecators[:ruby] = ActiveSupport::Deprecation.new(nil, 'Ruby')

module CaptureRubyWarnings
  def warn(message, category: nil)
    if category == :deprecated
      Rails.application.deprecators[:ruby].warn("#{message}", caller)
    else
      super
    end
  end
end

Warning[:deprecated] = true
Warning.extend(CaptureRubyWarnings)
```

<figcaption align="center">
Ruby >= 3, Rails >= 7.1
</figcaption>

Before Ruby 3, there is no `category` keyword argument in the `Kernel#warn` method, so we need to perform some string
matching to determine if the warning is a deprecation warning.

```ruby
# config/initializers/capture_ruby_warnings.rb
Rails.application.deprecators[:ruby] = ActiveSupport::Deprecation.new(nil, 'Ruby')

def warn(message)
  if message =~ /deprecated/i
    Rails.application.deprecators[:ruby].warn("#{message}", caller)
  else
    super
  end
end

Warning[:deprecated] = true if Warning.respond_to?(:[]=) # Warning responds to []= since Ruby 2.7.0
Warning.extend(CaptureRubyWarnings)
```

<figcaption align="center">
Ruby < 3, Rails >= 7.1
</figcaption>

[Prior to Rails 7.1](https://github.com/rails/rails/pull/46049), there were not a collection of deprecators in
application configuration to define one per dependency. We used to call global `ActiveSupport::Deprecation` singleton
directly back then.

```ruby
# config/initializers/capture_ruby_warnings.rb

module CaptureRubyWarnings
  def warn(message, category: nil)
    if category == :deprecated
      Rails.application.deprecators[:ruby].warn("#{message}", caller)
    else
      super
    end
  end
end

Warning[:deprecated] = true
Warning.extend(CaptureRubyWarnings)
```

<figcaption align="center">
Ruby >= 3, Rails < 7.1
</figcaption>

```ruby
# config/initializers/capture_ruby_warnings.rb

module CaptureRubyWarnings
  def warn(message)
    if message =~ /deprecated/i
      ActiveSupport::Deprecation.warn("[RUBY] #{message}", caller)
    else
      super
    end
  end
end

Warning[:deprecated] = true if Warning.respond_to?(:[]=) # Warning responds to []= since Ruby 2.7.0
Warning.extend(CaptureRubyWarnings)
```

<figcaption align="center">
Ruby < 3, Rails < 7.1
</figcaption>