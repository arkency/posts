---
title: "You don't inject for tests"
created_at: 2013-01-09 14:49:03 +0100
kind: article
publish: true
author: Jan Filipowski
newsletter: :arkency_form
tags: [ 'Ruby drama', 'dependency injection', 'OOD', 'mostly obvious', 'testing']
---

What is unit testing for? Is it a way to make sure that your code is correct and bugless? Or rather OOD tool, that expose most of places where you break object orientation principles? You may have your own answer (please comment though) but I would vote for the second one - of course it may assure me that I haven't introduced some totally stupid bug, but that's less interesting part.

<!-- more -->

## Valid argument with invalid conclusion

We started this week drama in Ruby community with DHH's ["Dependency injection is not a virtue"](http://david.heinemeierhansson.com/2012/dependency-injection-is-not-a-virtue.html) blog post. I agree that we shouldn't use dependency injection to make software testable - testability is not a basic goal when creating software. It's rather part of maintainability goal.

Let's walk through application parts and find out how testability helps in maintanance and by this why dependency injection is useful.

### Domain level

On this level unit tests shows you how complex your business objects are. Each line of test code on this level triggers question "Should I split this class to few smaller?", which is emanation of [SRP](http://en.wikipedia.org/wiki/Single_responsibility_principle). With constructor dependency injection you can expose how many other objects can get messages from current and decide if there is something that can be abstracted from what you found out.

Where's maintainability in this example? With smaller classes each change in one of them introduce less changes in dependencies. Communication of your objects have well defined flow.

### Application level

Let's suppose you use some external services like database or REST API. First of all you use them for a reason, like "I want to get all tweets with #sillycat hashtag". When you write classes that will communicate with those services you should expose that reason. And here's the place for border tests - you write them to make sure, that service adapters (which expose our need) do what they should really do. For db it would be getting records from that db, for REST API it would be making real request and checking if the answer is what we assumed.

```ruby
class TwitterMessageAdapter
  def initialize(app, secret) # configuration
    @app = app
    @secret = secret
  end

  def get_messages_with(hashtag)
    raw_messages = (...) # all the HTTP request stuff
    raw_messages.map do |raw_message|
      Message.new(raw_message['content'], raw_message['author_name'])
    end
  end
end

class MessageSeeker
  def initialize(message_adapter)
    @message_adapter = message_adapter
  end

  def print_interesting_messages
    puts @message_adapter.get_messages_with("#sillycat").map(&:to_s)
  end
end
```

With dependency injection in objects that use such adapters you get easiness of adding new similar services, single place to fix when you have problems with one of services etc. If you'd hardcode such adapter dependency (i.e. by instantiating) it could be hard to use different configurations too.

## Conclusion

As you can see dependency injection is a way to make you application more flexible, but what's more important - more ordered. With dependency injection you have to ask yourself very often on how many objects this one depends and how to minimize it.
