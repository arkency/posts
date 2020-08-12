---
created_at: 2016-11-06 18:07:14 +0100
publish: true
author: Andrzej Krzywda
tags: ['testing']
---

# Rails and adapter objects: different implementations in production and tests

If you work with service objects in Rails apps, very quickly you need to have the dependency being passed to the service object constructor. Which usually means, that the Rails controller needs to do it. This blogpost describes how to have a different implementation being passed in the production environment and an in-memory one in the tests.

<!-- more -->

There are several possible solutions, but one could be closer to the hearts of many Rails developers. Let's just use the built-in Rails environments and configure them appropriately:

```
$ ag foo_adapter config/environments/
config/environments/development.rb
187:  config.foo_adapter     = FooAdapter.new

config/environments/production.rb
164:  config.foo_adapter     = FooAdapter.new

config/environments/test.rb
184:  config.foo_adapter     = InMemoryFooAdapter.new
```

As you see, we have the same implementations in the production/dev environments, but a different one in the tests. The tests use an in-memory implementation which probably doesn't really send the requests to the Foo API.

In the Rails controller, you can then initialize the service object with:

```ruby

def create
  RegisterNewUser.new(Rails.application.config.foo_adapter).call
  #...
end
```

while in the service object you stay unaware of the difference:

```ruby

class RegisterNewUser
  def initialize(foo_adapter)
    @foo_adapter = foo_adapter
  end
end
```

