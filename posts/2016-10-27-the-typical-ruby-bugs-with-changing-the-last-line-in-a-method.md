---
title: "The typical Ruby bugs with changing the last line in a method"
created_at: 2016-10-27 23:00:34 +0200
publish: true
tags: [ 'ruby', 'service objects' ]
author: Andrzej Krzywda
---

In Ruby, we don't have to type `return` at the end of the method. As many other things in our favourite language, this is implicit, not explicit. The value of the last line in a method is also automatically the value of the whole method. Which is a good thing as it helps making the code less verbose and more poem-like. But it also has some dangers.

<!-- more -->

Only this year, we've had two different situations where experienced developers introduced bugs into a system.

The first story started when business wanted us to remove one existing feature from the application. This feature was something about analytics code in the view. The intention was to no longer track something.

There was something like this in the code.

```ruby

def analytics_code
  setup_which_is_meant_to_stay_here
  track_something
end
```

The developer looked at the code. It was quite clear that the last call should be removed, so he did that.

```ruby

def analytics_code
  setup_which_is_meant_to_stay_here
end
```

Apparently, it was crucial that the value returned by this method was actually used in the view.

```
= tracker.analytics_code
```

It went through several layers, so it wasn't that easy to spot.
The result?

The result was actually very bad - the `setup_which_is_meant_to_stay_here` call returned a hash with a lot of information about internals of our system. And it all went to the front page of one of the systems. Which we learnt only a few hours later.

The second story happened just recently, in my project. There's a place in the UI (react+redux), where we register new customers. Submitting the form creates an ajax request, which goes to the backend, which then calls a special microservice (bounded context) and then we get the response back to let the UI know that all is good with some additional information to display. It was all good and working.

But then, we've had a need to extend the existing backend code with publishing an event. The code was a typical service object in a Rails app:

```ruby

class RegisterNewCustomer
  def call
    customer = Customer.new(customer_params)
    customer_repo.save(customer)
  end
end
```

After extending the service object, it looked like this:

```ruby

class RegisterNewCustomer
  def call
    customer = Customer.new(customer_params)
    customer_repo.save(customer)
    event_bus.publish(customer_registered)
  end
end
```

The thing is, this service object was used from a controller, like this:

```ruby

def create
  customer = RegisterNewCustomer.new.call(customer_params)
  render json: customer
end
```

We haven't noticed the problem at first. The visible difference was that the UI now showed a failure message, but it was actually adding the customer to the system!

And the exception under the hood was something about `IOError`, which didn't help in debugging it.

As you see, two different stories, but the same problem - changing the last line of a method. Be careful with that :)
