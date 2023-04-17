---
created_at: 2023-04-17 10:52:52 +0200
author: Piotr Jurewicz
tags: ['rails', 'framewrok', 'decoupling']
publish: true
---

# The most important boundary in your app

Recently, we continued working on the update I referred to in [my previous post](https://blog.arkency.com/tracking-down-not-resolving-constants-with-parser/).
When planning an update from Rails 4.2 to Rails 5.0 and then to Rails 5.1, I realized again how crucial it is to avoid coupling your application to the framework's internal details.

# Introduction

To illustrate the importance of decoupling, let's look at the changes in `ActionController::Parameters` in Rails 4.2 to 5.1.

### Rails 4.2
In Rails 4.2, `ActionController::Parameters` were a subclass of Ruby's core `Hash` class, making it easy to pass around and use like any other hash.

### Rails 5.0
Rails 5.0 introduced a significant change: `ActionController::Parameters` were no longer a subclass of Hash but a separate class entirely.
This change was implemented to improve security and prevent mass assignment vulnerabilities.
However, all the methods available on hashes were still available on `ActionController::Parameters` through the `missing_method` hook.

### Rails 5.1
In Rails 5.1, the `missing_method` hook was removed.
It further emphasized the separation between ActionController::Parameters and regular Ruby hashes so that methods `#each`, `#map`, `#each_key`, `#each_value`, etc., were no longer available on `ActionController::Parameters` instances.

# The problem

As you can see, the difference in public API differs significantly between the following Rails versions.
<table>
<thead>
<tr>
<th>
</th>
<th colspan="2">
Rails 4.2
</th>
<th colspan="2">
Rails 5.0
</th>
<th colspan="2">
Rails 5.1
</th>
</tr>
</thead>
<tbody>
<tr>
<td>
</td>
<td>
only permitted params?
</td>
<td>
has indifferent access?
</td>
<td>
only permitted params?
</td>
<td>
has indifferent access?
</td>
<td>
only permitted params?
</td>
<td>
has indifferent access?
</td>
</tr>
<tr>
<td>params.to_hash</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
<td>✅</td>
<td>❌</td>
</tr>
<tr>
<td>params.to_h</td>
<td>✅</td>
<td>❌</td>
<td>✅</td>
<td>✅</td>
<td>✅</td>
<td>✅</td>
</tr>
<tr>
<td>params.(some native hash method)</td>
<td>❌</td>
<td>✅</td>
<td>❌</td>
<td>✅</td>
<td colspan="2"><b>Missing method error</b></td>
</tr>
</tbody>
</table>

The app we were working on has its service layer called from the controllers.
The service layer is responsible for handling some business logic. Its outcome is often persisted in the database.

Unfortunately, the service objects were initialized with `ActionController::Parameters` instances.

In multiples places they were checked against an inheritance from `Hash`:
```ruby
# ... 
return results unless hash.kind_of?(Hash)
# ...
```

They were even passed to the storage layer and serialized with ActiveModel `serialize` method.
```ruby

class Attachment < ActiveRecord::Base
  serialize :data, Hash
  # ...
end
```
When trying to upgrade Rails, existing tests started to fail. We saw a bunch of `ActiveRecord::SerializationTypeMismatch` errors.

# Always decouple
A seemingly simple Rails upgrade turned out to be time-consuming because the domain services were coupled to the internals of `ActionController` module.
To avoid such problems, it is crucial to maintain a clear boundary between domain logic and framework internals.
Be aware of passing around framework objects to your domain layer. Use standard Ruby types or your own value objects instead.

Decoupling has several advantages:
- **Flexibility**: Decoupling allows developers to switch frameworks, libraries, or even languages without having to rewrite the entire application.
- **Testability**: When domain logic is decoupled from framework internals, it is easier to test the core functionality without complex setups or dependencies.
- **Maintainability**: Decoupled applications are easier to maintain because they have a clearer separation of concerns, making it easier to identify and fix issues.

Similar examples will be addressed in the upcoming Rails Business Logic Masterclass course. Subscribe to the newsletter below so you don't miss any updates.