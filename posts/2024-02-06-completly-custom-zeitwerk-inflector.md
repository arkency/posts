---
created_at: 2024-02-06 17:01:52 +0100
author: Piotr Jurewicz
tags: [ 'rails', 'zeitwerk', 'autoload' ]
publish: false
---

# Completly custom Zeitwerk inflector

In [my previous post](https://blog.arkency.com/the-mysterious-litany-of-require-depndency-calls/), I described the
general difference between how the classic autolader and Zeitwerk autoloader match
constant and file names. Short reminder:

- Classic autoloader maps missing constant name `Raport::PL::X123` to a file name by
  calling `Raport::PL::X123.to_s.underscore`
- Zeitwerk autoloader finds `lib/report/pl/x123/products.rb` and maps it to `Report::PL::X123::Products` constant name
  with the help of defined __inflector__ rules.

## What really is an inflector?

In general, an inflector is a software component responsible for transforming words according to predefined rules.
In the context of web frameworks like Ruby on Rails, an inflector is specifically designed to handle various linguistic
transformations, such as pluralization, singularization, __acronym handling__, and humanization of
attribute names.

`Rails::Autoloader::Inflector` is the one that is used by default in Rails integration with Zeitwerk:

```ruby
module Rails
  class Autoloaders
    module Inflector # :nodoc:
      @overrides = {}

      def self.camelize(basename, _abspath)
        @overrides[basename] || basename.camelize
      end

      def self.inflect(overrides)
        @overrides.merge!(overrides)
      end
    end
  end
end
```

It's `camelize` method checks for the overrides and if it finds one, it uses it. Otherwise, it
utilizes `String#camelize`
method which is a part of ActiveSupport core extensions for String:

```ruby
def camelize(first_letter = :upper)
  case first_letter
  when :upper
    ActiveSupport::Inflector.camelize(self, true)
  when :lower
    ActiveSupport::Inflector.camelize(self, false)
  else
    raise ArgumentError, "Invalid option, use either :upper or :lower."
  end
end
```

As you can see `String#camelize` uses `ActiveSupport::Inflector` underneath.

`ActiveSupport::Inflector` has been a part of Rails since the very beginning and is used to transforms words from
singular to plural, class names to table names, modularized class names to ones without, and class names to foreign
keys.

However, in the context, of Zeitwerk, __acronym handling__ is a crucial feature of inflector.

An example of acronym can be "REST" (Representational State Transfer). It's not uncommon to have a constant including it
in, let's say `API::REST::Client`.

Classic autoloader, in case of undefined constant `API::REST::Client`, would call `API::REST::Client.to_s.underscore`
and look for `api/rest/client.rb` file in autoloaded directories.

Zeitwerk, on the other hand, when encountering `api/rest/client.rb`, would invoke `'api/rest/client'.camelize` and
unless we provide acronym handling rules, it would result in `Api::Rest::Client` constant.
To obtain `API::REST::Client`, we need to provide an inflector with acronym handling rules. There are at least 4 ways to
do that.

## 1. Configure ActiveSupport::Inflector

An intuitive and pretty common way is to configure ActiveSupport::Inflector directly. But doing so you affect how
ActiveSupport inflects these phrases globally. It's not always desired.

```ruby
# config/initializers/inflections.rb

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
  inflect.acronym 'REST'
end
```

## 2. Set overrides for Rails::Autoloader::Inflector

In some cases, you won't populate some autoloader specific rules to the ActiveSupport inflector. And you don't have to.
You can override some specific rules just for Zeitwerk and keep the Rails global inflector untouched.
However, when you do that this way, Zeitwerk will still fallback to the 'String#camelize' and ActiveSupport::Inflector
when specific key cannot be found.

```ruby
# config/initializers/zeitwerk.rb

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "api" => "API",
    "rest" => "REST",
  )
end
```

## 3. Zeitwerk::Inflector

Zeitwerk is a gem designed to be used independently from Rails and it provides an alternative implementation of
inflector that you can use instead of `Rails::Autoloader::Inflector`.
If you do so, you will have full control over the acronyms you use in file naming conventions in single place and 
avoid the ActiveSupport inflector being polluted with autoloader specific rules.

```ruby
# config/initializers/zeitwerk.rb

Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "api" => "API",
    "rest" => "REST",
  )
end
```

## 4. Your custom inflector

Consider a scenario where except the `API::REST::Client` you have also `User::Activities::Rest` constant in your
codebase. Both of them include the `/rest/i` substring, but you can't use the same inflection rule to obtain the
constant name from the file name.

This is a perfect example of when you can provide your custom inflector implementation.

Let's take a look at standard `Rails::Autoloader::Inflector#camelize` method implementation once again:

```ruby

def self.camelize(basename, _abspath)
  @overrides[basename] || basename.camelize
end
```

As you can see it is designed to take 2 arguments: `basename` and `abspath`. The `basename` is the file name without
the extension and the `abspath` is the absolute path to the file. Note that the `abspath` is not used not in
the `Rails::Autoloader::Inflector` nor in the `Zeitwerk::Inflector` implementation.

But what stops you from using it in your custom unconventional implementation?

```ruby
# config/initializers/zeitwerk.rb

class UnconventionalInflector
  def self.conditional_inflection_for(basename:, inflection:, paths:)
    Module.new do
      define_method :camelize do |basename_, abspath|
        if basename_ == basename && paths.map { |p| Rails.root.join(p).to_s }.include?(abspath)
          inflection
        else
          super(basename_, abspath)
        end
      end
    end
  end

  prepend conditional_inflection_for(
            basename: 'rest',
            inflection: 'REST',
            paths: %w[lib/api/rest],
          )

  # ...

  def initialize
    @inflector = Rails::Autoloader::Inflector
  end

  def camelize(basename, abspath)
    @inflector.camelize(basename, abspath)
  end

  def inflect(overrides)
    @inflector.inflect(overrides)
  end
end

Rails.autoloaders.each do |autoloader|
  autoloader.inflector = UnconventionalInflector.new
  autoloader.inflector.inflect(
    'api' => 'API'
  )
end
```

The implementation above utilizes `Rails::Autoloader::Inflector` module, however, it prepends it's `camelize`
implementation with the one that checks if the file path matches unconventional rules. If it does, unconventional
inflection is used. Or else, it falls back to the standard implementation.