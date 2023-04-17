---
created_at: 2023-04-17 10:52:52 +0200
author: Piotr Jurewicz
tags: []
publish: false
---

# The most important boundary in your app

Recently, we continued working on the update I referred to in [my previous post](https://blog.arkency.com/tracking-down-not-resolving-constants-with-parser/).
When planning an update from Rails 4.2 to Rails 5.0 and then to Rails 5.1, I realized again how crucial it is to not couple your application to the framework internal details.

# Introduction

To illustrate the importance of decoupling, let's look at the changes in `ActionController::Parameters` in Rails 4.2 to 5.1.

### Rails 4.2
In Rails 4.2, `ActionController::Parameters` was a subclass of Ruby's core `Hash` class, making it easy to pass around and use like any other hash.

### Rails 5.0
Rails 5.0 introduced a significant change: ActionController::Parameters was no longer a subclass of Hash, but a separate class entirely.
This change was implemented to improve security and prevent mass assignment vulnerabilities.
However, all the methods that were available on hashes were still available on `ActionController::Parameters` through the `missing_method` hook.

### Rails 5.1
In Rails 5.1, the `missing_method` hook was removed. So that the methods like `#each`, `#map`, `#select`, etc. were no longer available on `ActionController::Parameters` instances.


|method <td colspan=2>Rails 4.2</td><td colspan=2>Rails 5.0</td><td colspan=2>Rails 5.1</td>
|------------|:----------------------------:|:--------:|:--------------:|:--------:|:--------------:|:--------:|
|            |       only permitted?        | Indifferent access? | only permitted? | Indifferent access? | only permitted? | Indifferent access? |
| `params.to_hash` |              ❌               |     ❌      |       ❌         |     ❌      |       ✅         |     ❌      |
| `params.to_h`    |              ✅               |     ❌      |       ✅         |     ✅      |       ✅         |     ✅      |
| `params.(some native hash method)` |              ❌               |     ✅      |       ❌         |     ✅      |       ⛔         |           |



# The problem

The app we were working on ...

<!-- more -->

FIXME: Place post body here.

```ruby
Person.new.show_secret
# => 1234vW74X&
```
