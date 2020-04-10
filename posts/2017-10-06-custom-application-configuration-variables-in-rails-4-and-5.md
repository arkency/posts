---
title: "Custom application configuration variables in Rails 4 and 5"
created_at: 2017-09-16 12:39:49 +0200
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'configuration' ]
newsletter: arkency_form
---

You probably know that you can configure Rails in `config/application.rb` and `config/environments/development.rb` etc. But you can also leverage that for configuring your own custom settings for your application.

<!-- more -->

## Single level configuration

```ruby
# config/environments/development.rb
# or
# config/environments/production.rb

Rails.application.configure do
  config.my_custom_setting = "WOW"
end
```

```ruby
# config/application.rb
module ApplicationName
  class Application < Rails::Application
    config.load_defaults 5.1

    config.my_custom_setting = "DEFAULT"
  end
end
```

As with normal rails configuration, your own settings in `config/environments/*` take precedence over those specified in `config/application.rb`.

## Nested configuration

If you have multiple settings that you would like to group together, you can prefix them with `x.config_name`.

```ruby
# config/environments/development.rb
# or
# config/environments/production.rb

Rails.application.configure do
  config.x.external_api.timeout = 5
end
```

```ruby
# config/application.rb
module ApplicationName
  class Application < Rails::Application
    config.load_defaults 5.1

    config.x.external_api.timeout = 30
    config.x.external_api.url = "https://example.org/api/path"
  end
end
```

or you can just use `Hash`

```ruby
# config/environments/development.rb
# or
# config/environments/production.rb

Rails.application.configure do
  config.external_api[:timeout] = 5
end
```

```ruby
# config/application.rb
module ApplicationName
  class Application < Rails::Application
    config.load_defaults 5.1

    config.external_api = {
      timeout: 30,
      url: "https://example.org/api/path"
    }
  end
end
```

## Accessing in your model or controller

To read those preference, you can use `Rails.application.config` or its shorter version `Rails.configuration`.

```ruby
class User < ApplicationRecord
  def avatar
    avatar_url || Rails.configuration.default_avatar_url
  end
end
```

```ruby
Rails.configuration.x.external_api
# => {:timeout=>5, :url=>"https://example.org/api/path"}

Rails.configuration.x.external_api.timeout
# => 5

Rails.configuration.x.external_api.url
# => "https://example.org/api/path"

Rails.configuration.x.external_api.missing_element
# => nil
```

It will work anywhere in your application, including models and controllers.

## How does the x.my_config.something work under the hood?

What's the magic that allows you to define the keys in such way?

```ruby
Rails.configuration.x.class
# => Rails::Application::Configuration::Custom
```

Let's see if the setters and getters are implemented using `method_missing` ?

```ruby
Rails.configuration.x.method(:method_missing).source_location
 => ["/home/rupert/.rvm/gems/ruby-2.4.1/gems/railties-5.1.4/lib/rails/application/configuration.rb", 200]
```

Indeed they are. Let's see the code.

```ruby
class Custom
  def initialize
    @configurations = Hash.new
  end

  def method_missing(method, *args)
    if method =~ /=$/
      @configurations[$`.to_sym] = args.first
    else
      @configurations.fetch(method) {
        @configurations[method] = ActiveSupport::OrderedOptions.new
      }
    end
  end

  def respond_to_missing?(symbol, *)
    true
  end
end
```

That's quite a simple and small implementation. If it recognizes that the method name ends with `=` it sets the value. If it does not end with `=`, it sets `ActiveSupport::OrderedOptions.new` as the value and returns it.


```ruby
Rails.configuration.x
# => #<Rails::Application::Configuration::Custom:0x000000047a42a8 @configurations={}>

Rails.configuration.x.one
# => {}

Rails.configuration.x.one.class
# => ActiveSupport::OrderedOptions
```

So the 1st level (`x.one`, `x.one=`) is managed by `Rails::Application::Configuration::Custom` class and its implementation. The 2nd level (`x.one.two`, `x.one.two=`) is managed by `ActiveSupport::OrderedOptions`.

```ruby
Rails.configuration.x.one.two
# => nil

Rails.configuration.x.one.two = 2
# => 2
```

Let's see what's there.

```ruby
ActiveSupport::OrderedOptions.new.method(:method_missing).source_location
 => ["/home/rupert/.rvm/gems/ruby-2.4.1/gems/activesupport-5.1.4/lib/active_support/ordered_options.rb", 39]
```

```ruby
class OrderedOptions < Hash
  alias_method :_get, :[] # preserve the original #[] method
  protected :_get # make it protected

  def []=(key, value)
    super(key.to_sym, value)
  end

  def [](key)
    super(key.to_sym)
  end

  def method_missing(name, *args)
    name_string = name.to_s
    if name_string.chomp!("=")
      self[name_string] = args.first
    else
      bangs = name_string.chomp!("!")

      if bangs
        fetch(name_string.to_sym).presence || raise(KeyError.new("#{name_string} is blank."))
      else
        self[name_string]
      end
    end
  end

  def respond_to_missing?(name, include_private)
    true
  end
end
```

And that's how it works on the 2nd level.

```ruby
oo = ActiveSupport::OrderedOptions.new
# => {}

oo.foo = 1
# => 1
oo.foo
# => 1
oo.foo!
# => 1
oo.bar
# => nil

oo.bar!
#KeyError: key not found: :bar
#	from (irb):13
```

## Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your everyday Rails programmer job.

Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring big, complex Rails applications.
