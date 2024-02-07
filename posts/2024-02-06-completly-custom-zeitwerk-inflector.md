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

An example of acronym can be REST (Representational State Transfer). It's not uncommon to have a constant including it
in, let's say `CRM::RESTClient`.

Classic autoloader, in case of undefined constant `CRM::RESTClient`, would call `CRM::RESTClient.to_s.underscore` and
look for `crm/rest_client.rb` file in autoloaded directories.

Zeitwerk, on the other hand, when encountering `crm/rest_client.rb`, would
invoke `'crm/rest_client.rb'.delete_suffix!(".rb").camelize` and unless we provide acronym handling rules, it would
results in `Crm::RestClient` constant. To obtain `CRM::RESTClient`, we need to provide Zeitwerk with acronym
handling rules. There are at least 4 ways to do that.
