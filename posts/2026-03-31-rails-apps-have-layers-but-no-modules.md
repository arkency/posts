---
created_at: 2026-03-31 12:00:00 +0100
author: Andrzej Krzywda
tags: ['rails', 'ddd', 'architecture', 'bounded contexts']
publish: false
---

# Rails apps have layers but no modules

You can have 200 models and zero modules. That's the problem with typical Rails conventions. Rails supports layers - models, views, controllers. **But layers are not modules.** Within one layer - especially models - usually all is mixed together. There are no boundaries.

<!-- more -->

```ruby
Order.first.user.invoices.last.line_items
```

Such code is not so uncommon. It crosses **4 business boundaries**.    In just 1 line of code. All thanks to associations.

## The problem with associations

One of the first thing we teach in Rails is associations. 

```ruby
class Order < ApplicationRecord
  belongs_to :user
end
```

It's very readable, feels right. Allows us to call it like this:

```ruby
Order.first.user
```

Then we have the User class:

```ruby
class User < ApplicationRecord
  has_many :orders
  has_many :invoices
end
```

and the Invoice class:

```ruby
class Invoice < ApplicationRecord
  belongs_to :order
  has_many   :line_items
end
```

and this is how we allow the original code:

```ruby
Order.first.user.invoices.last.line_items
```

This is how we boil the frog. One step at a time. One column at a time. One association at a time. 

The result?
A User class with **100 columns** in the database.

## DRY and god models

There is a misconception about DRY - Don't Repeat Yourself. We have an existing User class. It feels right to just add things there.

**No one was ever fired for adding a new column to the users table.**

It feels like the User class is the right abstraction for DRY. Yet, it always ends as the god model. 

## Service Objects don't help with modularisation

Many Rails teams believe that Service Objects are the solution.  They are, but to a different problem.

Service objects help us when our controllers become too big. They are called from the controllers and they are the ones orchestrating ActiveRecord models. Often they handle transactions too.

What is good about them?

They are creating a boundary between the HTTP layer (controllers) and the domain layer. 
They also are a good solution to the transaction boundary.

Service objects are a new layer. We could now call it MVCS. Model View Controller Service. It's not bad. It does help with unit testing - it's easier to unit test a service object than a controller action. 

**Service objects do nothing about modularisation.**

They don't create new boundaries. They don't help with composing modules. 

Service objects are just **another horizontal slice**.

## Microservices

It's usually around this phase in the architecture - MVCS - when a decision is made. 

We will go microservices. 

Sometimes it comes from the team itself - what can be a stronger boundary than a network? The team hopes it will enforce a better design. Microservices bring the hope of starting fresh — new language, new design, better boundaries. But the boundaries **still aren't modules**.

Are microservices helping with the modularisation?
Nope. They are just yet another horizontal layer. This time we add a layer behind a network call. We no longer have transactions, it's harder to run tests, the build takes longer. All for the benefit for having 3 new Go microservices and adding new layers of serialisation/deserialisation.

**More layers, less performance, but still no modules.**

## A bitter conclusion

Rails makes it easy to add code. It doesn't make it easy to **isolate it**.

200 models. Five layers. Zero modules. That's the default.

In 1972, Parnas wrote that a module hides a design decision from the rest of the system. Fifty years later, Rails apps hide nothing.

What does your User class hide?