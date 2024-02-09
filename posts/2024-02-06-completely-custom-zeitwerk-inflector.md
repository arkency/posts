---
created_at: 2024-02-06 17:01:52 +0100
author: Piotr Jurewicz
tags: [ 'rails', 'zeitwerk', 'autoload' ]
publish: true
---

# Completely custom Zeitwerk inflector

In [my previous post](https://blog.arkency.com/the-mysterious-litany-of-require-depndency-calls/), I discussed the
difference between how the classic autoloader and Zeitwerk autoloader match constant and file names. Short reminder:

- Classic autoloader maps missing constant name `Raport::PL::X123` to a file name by
  calling `Raport::PL::X123.to_s.underscore`
- Zeitwerk autoloader finds `lib/report/pl/x123/products.rb` and maps it to `Report::PL::X123::Products` constant name
  with the help of defined __inflectors__ rules.

## What is an inflector?

In general, an inflector is a software component responsible for transforming words according to predefined rules.
In the context of web frameworks like Ruby on Rails, inflectors are used to handle different linguistic transformations,
such as pluralization, singularization, __acronym handling__, and humanization of attribute names.

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

Its `camelize` method checks for the overrides and if it finds one, it uses it, otherwise it calls `String#camelize`
method, which is part of ActiveSupport core extensions for String.

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

As you can see `String#camelize` delegates to `ActiveSupport::Inflector` under the hood.

`ActiveSupport::Inflector` has been a part of Rails since the very beginning and is used to transform words from
singular to plural, class names to table names, modularized class names to ones without, and class names to foreign
keys.

However, in the context, of Zeitwerk, __acronym handling__ is an essential feature of inflector.

An example of acronym is "REST" (Representational State Transfer). It is not uncommon to have a constant including it,
such as `API::REST::Client`.

When the classic autoloader encounters an undefined constant `API::REST::Client`, it
calls `API::REST::Client.to_s.underscore` to find the `api/rest/client.rb` file in the autoloaded directories.

On the other hand, Zeitwerk locates `api/rest/client.rb` and invokes `'api/rest/client'.camelize`. Without acronym
handling rules, this results in `Api::Rest::Client`. To get `API::REST::Client`, we need to supply an inflector with
acronym handling rules. There are at least four ways to do this.

## 1. Configure ActiveSupport::Inflector

An intuitive and pretty common way is to configure `ActiveSupport::Inflector` directly.
But doing so you affect how ActiveSupport inflects these phrases globally. It's not always desired.

```ruby
# config/initializers/inflections.rb

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
  inflect.acronym 'REST'
end
```

## 2. Set overrides for Rails::Autoloader::Inflector

In some cases, you won't add certain autoloader-specific rules to the ActiveSupport inflector. It's not mandatory.
You have the option to override some specific rules only for Zeitwerk and leave the Rails global inflector as it is
However, even if you do that, Zeitwerk will still fall back to `String#camelize` and `ActiveSupport::Inflector` when it
cannot find a specific key.

```ruby
# config/initializers/zeitwerk.rb

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "api" => "API",
    "rest" => "REST",
  )
end
```

## 3. Use Zeitwerk::Inflector

Zeitwerk is a gem designed to be used independently from Rails and it provides an alternative implementation of
inflector that you can use instead of `Rails::Autoloader::Inflector`.
By doing so, you will have complete control over the acronyms you use in file naming conventions in a single place.
Furthermore, it will help you avoid polluting the ActiveSupport inflector with autoloader-specific rules.

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

## 4. Implement your custom inflector

Consider a scenario where, apart from the `API::REST::Client`, you sldo have the `User::Activities::Rest` constant in
your
codebase. Both of them include the `/rest/i` substring, but you cannot use the same inflection rule to derive the
constant name from the file name.

This is a good example of when you may need to provide a custom inflector implementation.

Let's revisit the standard `Rails::Autoloader::Inflector#camelize` method implementation to better understand this.

```ruby
def self.camelize(basename, _abspath)
  @overrides[basename] || basename.camelize
end
```

As you can see it is designed to take 2 arguments: `basename` and `_abspath`. The `basename` is the file name without
the extension and the `_abspath` is the absolute path to the file.

Note that the `_abspath` is not used in wither the `Rails::Autoloader::Inflector` or the `Zeitwerk::Inflector`
implementation.

However, you can still take advantage of this argument presence in your custom implementation.

```ruby
# config/initializers/zeitwerk.rb

class UnconventionalInflector
  def self.conditional_inflection_for(basename:, inflection:, path:)
    Module.new do
      define_method :camelize do |basename_, abspath|
        if basename_ == basename && path.match?(abspath)
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
            path: /\A#{Rails.root.join('lib', 'api')}/,
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

The implementation above utilizes `Rails::Autoloader::Inflector` module. However, it prepends its `camelize`
implementation with the one that first checks if the file path matches an unconventional rule. If it does, the method
uses an non-standard inflection. If not, it falls back to the default implementation.

___
I understand that the example of `Rest` and `REST` may seem contrived, but it serves to illustrate the point. In
real-life situations, there may be more convincing reasons to implement a custom inflector, just as we did on a
project we were consulting, where it proved to be very helpful.