---
created_at: 2025-09-25 12:26:59 +0200
author: Piotr Jurewicz
tags: ['rails', 'ruby', 'json', 'rails upgrade']
publish: true
---

# Rails 8 upgrade story: duplicate keys sneaking into our JSON responses

The upgrade from **Rails 7.2.2.2 to 8.0.2.1** went surprisingly smoothly.  
After deployment, we didn’t notice any new exceptions, and the application seemed stable.  
At least at first...

## First reports

After a while, we started receiving complaints from an external application consuming our JSON API.  
Identifiers that were supposed to be **strings** suddenly started arriving as **integers**. 🤔

We rolled back the changes and began debugging.

## The suspicious line

It turned out the problem originated in the code responsible for serializing an ActiveRecord object.  
We had something like this:

```ruby
attributes.merge(id: public_id)
```

The intention was simple: replace the primary key with a public identifier used for inter-service communication.

The problem? `attributes` returns a hash with **string keys**, and we were merging in a value under a **symbol key**.  
The result was a hash with both keys:

```ruby
{ "id" => 1, :id => "one" }
```

Up until Rails 7.2, this wasn’t a big deal.  
When the controller executed:

```ruby
render json: { "id" => 1, :id => "one" }
```

Rails would internally call `as_json`, which deduplicated keys, so the final JSON always used the last provided value, regardless of whether the key was a string or a symbol.

## What changed in Rails 8?

The real change came from this [Rails commit](https://github.com/rails/rails/commit/42d75ed3a8b96ee4610601ecde7c40e9d65e003f), which says:
```
Only add template options when rendering template
[...]
This commit avoids adding those keys unless we are rendering a template.

This improves performance both by avoiding calculating the templates to  
put into this options hash as well as enabling a fast path in `render json:`,  
which can only be used when `.to_json` is given no options.
```
That **fast path** improved JSON rendering performance - but with one important side effect:  
it no longer invoked `as_json`, which quietly normalized keys - turning symbol keys into strings.  
In our case, that invisible normalization prevented the duplicate key problem.

With Rails 8, the **fast path** skipped [this line](https://github.com/rails/rails/blob/c3ad0afaa8045da0f420a0b25bdf0d38da614e61/activesupport/lib/active_support/json/encoding.rb#L57). Our mixed-key hash (`{"id" => 1, :id => "one"}`) stayed exactly as it was, and the JSON encoder output a response with duplicate keys (`{"id":1,"id":"one"}`).

So the root cause was in our code, but for years we were unknowingly relying on Rails’ implicit key normalization.  
Once that disappeared, the bug became visible.

## The changelog confusion

Interestingly, the [ActiveSupport 7.1.3 changelog](https://github.com/rails/rails/blob/7-1-stable/activesupport/CHANGELOG.md#rails-713-january-16-2024) stated:

```
Fix `ActiveSupport::JSON.encode` to prevent duplicate keys.

    If the same key exist in both String and Symbol form it could
    lead to the same key being emitted twice.
```

This gave the impression that duplicates would never occur.  
Unfortunately, that fix was reverted before release - the changelog was misleading.  
We ended up creating a [PR to correct it](https://github.com/rails/rails/pull/55735).

## Guarding yourself before the upgrade

The most reliable way to catch this kind of regression is to have **request specs** that assert on the exact JSON response body.  
If you test for the precise shape of the payload, duplicate keys will immediately surface as a mismatch.

But let’s be honest: most projects don’t have 100% coverage of every single controller action at that level of detail.  
And that’s where the ecosystem itself can help.

Starting from `json 2.14.0`, the library emits a warning whenever a hash with both string and symbol versions of the same key is encoded:

```ruby
Warning[:deprecated] = true

puts JSON.generate({ foo: 1, "foo" => 2 })
# (irb):2: warning: detected duplicate key "foo" in {foo: 1, "foo" => 2}.
# {"foo":1,"foo":2}
```

In JSON 3.0, this will go even further and raise an error by default (unless you explicitly allow duplicates).

You can also surface such warnings in your Rails test or development environments by treating them as disallowed deprecations:

```ruby
config.active_support.disallowed_deprecation_warnings = [/detected duplicate key/]
config.active_support.disallowed_deprecation = :raise
```

**But this requires setting up non-Rails deprecation warnings to also be captured by the ActiveSupport deprecation framework.**
I described how to achieve this in [this blog post](https://blog.arkency.com/do-you-tune-out-ruby-deprecation-warnings/#how_about_ruby_deprecation_warnings_).

This way, even if you don’t assert every response body in detail, there’s still a good chance your automated or manual tests will trip over a duplicate key and fail early.

It’s not a silver bullet - but it’s a lightweight safeguard that makes it much less likely duplicate keys sneak into your JSON responses unnoticed.

Happy upgrading 🚀
