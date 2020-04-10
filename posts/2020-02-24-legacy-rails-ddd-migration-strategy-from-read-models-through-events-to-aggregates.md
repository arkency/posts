---
title: "Legacy Rails DDD Migration strategy - from read models, through events to aggregates"
created_at: 2020-02-24 15:08:12 +0100
kind: article
publish: true
author: Andrzej Krzywda
tags: ['ddd', 'legacy', 'aggregate', 'service object', 'read model', 'domain event']
---

How to migrate legacy Rails apps into DDD/CQRS in a relatively safe way?

<!-- more -->

Recently, I was answering a question on our [Rails Architect Masterclass](https://arkency.com/masterclass/) Slack channel. The question was related to a video which explained the strategy of extracting read models as the first step. The part which wasn't clear enough was on the topic how the read models extraction can help in designing aggregates. Here's my written attempt to explain this strategy:

# Introduce a Service objects layer (aka application layer)


```ruby
class RegisterUser
  def call
    User.create
    Mailer.send
  end
end 
```

# Start publishing events in service objects

In the service objects introduce publishing events, so when there’s a `RegisterUser` service object it would have a line event_store.publish(UserRegistered)

```ruby
class RegisterUser
  def call
    Transaction.begin
	    User.create
	    event_store.publish(UserRegistered.new)
	  end
    Mailer.send
  end
end 
```

# Build read models

Build read models like `UsersList` as the reaction to those events (and only to those events). Note that this read models can use its own "internal detail" ActiceRecord, which resembles the original one, but it's just for view purpose.

```ruby
class UsersList
  def register_user
    UsersList::User.create
  end
  
  def ban_user
    UserList::User.destroy
  end
end
```

# Detect the suffix in the event names

Once you have all the events required for a UsersList view, you will see the pattern that the suffix (the subject the events start with) will suggest aggregate names. In our example that would be `User` aggregate (probably in the `Access` bounded context)

# Recognize the verbs in event names

Additionaly, the event names (the what was done) - the  verbs in passive - `Registered`, `Rejected`, `Banned` may suggest the method names in that aggregate

# Design the aggregate

This brings us to the potential design of the aggregate

```ruby
module Access
  class User
    def register
    def approve
    def ban
  end
end
```

# Explore other possible designs of business objects

Once you learn more about the other flavours of implementing aggregates, business objects (objects which ensure business constraints), you will see that verbs can suggest the state changes and the polymorphism-based aggregates:

```ruby
class RegisteredUser
class BannedUser
```

See more aggregates flavours examples in our [aggregates](https://github.com/arkency/aggregates) repo.
