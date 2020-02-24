---
title: "Legacy Rails DDD Migration strategy - from read models, through events to aggregates"
created_at: 2020-02-24 15:08:12 +0100
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

How to migrate legacy Rails apps into DDD/CQRS in a relatively safe way?

<!-- more -->

Recently, I was answering a question on our Rails Architect Masterclass Slack channel. The question was related to a video which explained the strategy of extracting read models as the first step. The part which wasn't clear enough was on the topic how the read models extraction can help in designing aggregates. Here's my written attempt to explain this strategy:

1. introduce a Service objects layer (aka application layer)


```ruby
class RegisterUser
  def call
    User.create
    Mailer.send
  end
end 
```
2. in the service objects introduce publishing events, so when there’s a `RegisterUser` service object it would have a line event_store.publish(UserRegistered)

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
3. build read models like `UsersList` as the reaction to those events (and only to those events). Note that this read models can use its own "internal detail" ActiceRecord, which resembles the original one, but it's just for view purpose.

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
4. Once you have all the events required for a UsersList view, you will see the pattern that the suffix (the subject the events start with) will suggest aggregate names. In our example that would be `User` aggregate (probably in the `Access` bounded context)
6. Additionaly, the event names (the what was done) - the  verbs in passive - `Registered`, `Rejected`, `Banned` may suggest the method names in that aggregate
7. which brings us to the potential design of the aggregate

```ruby
module Access
  class User
    def register
    def approve
    def ban
  end
end
```

8. Once you go to the Aggregates module in the class, you can see that there might be alternative design flavours, where the verbs can suggest the state changes and the polymorphism-based aggregates:

```ruby
class RegisteredUser
class BannedUser
```
