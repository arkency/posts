---
created_at: 2024-02-06 17:01:52 +0100
author: Piotr Jurewicz
tags: [ 'rails', 'zeitwerk', 'autoload' ]
publish: false
---

# Completly custom Zeitwerk inflector

In my previous post, I described the general difference between how the classic autolader and Zeitwerk autoloader match
constant and file names. Short reminder:

- Classic autoloader maps missing constant name `Raport::PL::X123` to a file name by
  calling `Raport::PL::X123.to_s.underscore`
- Zeitwerk autoloader finds `lib/report/pl/x123/products.rb` and maps it to `Report::PL::X123::Products` constant name
  with the help of __inflector__ rules.

What really is an inflector?

In general, an inflector is a software component responsible for transforming words and linguistic elements according to
predefined rules. In the context of web frameworks like Ruby on Rails, an inflector is specifically designed to handle
various linguistic transformations, such as pluralization, singularization, __acronym handling__, and humanization of
identifiers.

In the context, of Zeitwerk, acronym handling is crucial.

An example of acronym can be "REST" (Representational State Transfer). It's not uncommon to have a constant including it
in, let's say `CRM::RESTClient`.

Classic autoloader, in case of undefined constant `CRM::RESTClient`, would call `CRM::RESTClient.to_s.underscore` and
look for `crm/rest_client.rb` file in autoloaded directories.

Zeitwerk, on the other hand, when encountering `crm/rest_client.rb`, would
invoke `'crm/rest_client.rb'.delete_suffix!(".rb").camelize` and unless we provide acronym handling rules, it would
results in `Crm::RestClient` constant. To obtain `CRM::RESTClient`, we need to provide Zeitwerk with acronym
handling rules. There are at least 4 ways to do that.

## 1. ActiveSupport::Inflector

ActiveSupport global inflector is the one that is used by default in Rails integration with Zeitwerk.
It's been a part of Rails since the very beginning and is used to transforms words from singular to plural, class names
to table names, modularized class names to ones without, and class names to foreign keys.
As you can see, it has a lot of responsibilities and it's not always a best choice to give it another one.

However, if you want to use it, you can do it like this:

```ruby
# config/initializers/inflections.rb

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'REST'
end
```

## 2. ActiveSupport::Inflector with overrides

In some cases, you won't populate some autoloader specific rules to the global inflector. And you don't have to.
You can override some specific rules just for Zeitwerk and keep the global inflector untouched.
However, when you do that this way, Zeitwerk will still fallback to the ActiveSupport::Inflector when specific key is
not found.

```ruby
# config/initializers/inflections.rb

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "rest" => "REST",
  )
end
```

## 3. Zeitwerk::Inflector

Zeitwerk provides an implementation of inflector that you can use.
If you do so, you will have full control over the acronyms you use in file naming conventions in single place.
Doings so, you can avoid the global inflector being polluted with autoloader specific rules.

```ruby
# config/initializers/inflections.rb

Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "rest" => "REST",
  )
end
```

## 4. Your custom inflector

Considera scenario where except the `RESTClient` you have also `RestOfTheWorld` or `UserDoesRestInPeace` constant in
your codebase. All of them include the `/rest/i` substring, but you can't use the same inflection rule to obtain the
constant name from the file name.

This is a perfect example of when you should consider creating your own inflector.
