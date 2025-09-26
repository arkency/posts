---
created_at: 2025-09-25
author: Piotr Jurewicz
tags: ['rails', 'ruby', 'json', 'rails upgrade']
publish: false
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

The intention was simple: replace the private database ID with a public identifier used for inter-service communication.

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

Rails would internally call `as_json`, which deduplicated keys. The final JSON always used the last provided value under the string key.

## What changed in Rails 8?

Rails 8 introduced [this optimization](https://github.com/rails/rails/commit/42d75ed3a8b96ee4610601ecde7c40e9d65e003f) combined with [another one from Rails 7.1](https://github.com/rails/rails/pull/48614/commits/66db67436d3b7bcdf63e8295adb7c737f76844ad#diff-c202bc84686ddd83549f9603008d8fb9f394a05e76393ff160b7c9494165fc4a).

Both changes were performance-driven:

* **Rails 7.1 PR (#48614)** — optimized `render json:` by avoiding unnecessary calls to `as_json` on hashes that were already in a suitable format. The idea was to save work when serializing hashes, especially large ones, since calling `as_json` for every nested value introduced overhead.
* **Rails 8 commit (42d75ed3a)** — went further and skipped even more redundant conversions by directly passing through hashes to the JSON encoder whenever possible. Again, the goal was reducing allocations and method dispatch during rendering.

Together, these optimizations meant that in many cases Rails stopped normalizing keys through `as_json`.  
That shaved off some cycles, but in our case it exposed the subtle bug with mixed string/symbol keys.

As a result, we ended up sending JSON with **duplicate keys**:

```json
{"id":1,"id":"one"}
```

That’s exactly what broke our consumer.

## The changelog confusion

Interestingly, the [Rails 7.1.3 changelog](https://github.com/rails/rails/blob/main/activemodel/CHANGELOG.md#rails-713) claimed:

```
Fix `ActiveSupport::JSON.encode` to prevent duplicate keys.

    If the same key exist in both String and Symbol form it could
    lead to the same key being emitted twice.
```

This gave the impression that duplicates would never occur.  
Unfortunately, that fix was reverted before release — the changelog was misleading.  
We ended up creating a [PR to correct it](https://github.com/rails/rails/pull/55735).

## Guarding yourself before the upgrade

All of this could have been avoided if we had upgraded the `json` gem to **2.14.0** beforehand.  
That version introduced stricter handling of duplicate keys:

> **Add new `allow_duplicate_key` generator option.**  
> By default a warning is now emitted when a duplicated key is encountered.  
> In JSON 3.0 this will raise an error.

Example:

```ruby
Warning[:deprecated] = true

puts JSON.generate({ foo: 1, "foo" => 2 })
# (irb):2: warning: detected duplicate key "foo" in {foo: 1, "foo" => 2}.
# {"foo":1,"foo":2}

JSON.generate({ foo: 1, "foo" => 2 }, allow_duplicate_key: false)
# JSON::GeneratorError: detected duplicate key "foo" in {foo: 1, "foo" => 2}
```

If we had been on `json >= 2.14.0`, we would have seen deprecation warnings during testing — long before this issue made it into production.

We actively monitor Ruby deprecation warnings (I wrote a separate post on that [here](https://blog.arkency.com/do-you-tune-out-ruby-deprecation-warnings/)).  
Had JSON 2.14.0 been available at the time of our upgrade, we might have spotted this regression earlier.  
Unfortunately, the release came out just a week after we finished our upgrade.

Even if you’re not yet on `json >= 2.14.0`, there’s a way to guard against this kind of bug during development and testing.  
Rails allows you to treat specific deprecations as **disallowed** — and raise an exception whenever they occur.

By adding the following to your environment configuration (e.g. `config/environments/test.rb`):

```ruby
config.active_support.disallowed_deprecation_warnings = [/detected duplicate key/]
config.active_support.disallowed_deprecation = :raise
```

You turn the `"detected duplicate key"` warning into a **hard error**.

This way, if your automated test suite — or even manual QA runs — ever trigger rendering of JSON with duplicate keys, the test will fail immediately.  
Much better to catch it there than discover it from an angry API consumer in production. 🚨

---

### Takeaway

Before jumping to Rails 8, **make sure your project depends on `json >= 2.14.0`**.  
It will warn you about duplicate keys, helping you avoid subtle, hard-to-debug issues with string vs symbol hash keys sneaking into your JSON API.

Happy upgrading 🚀
