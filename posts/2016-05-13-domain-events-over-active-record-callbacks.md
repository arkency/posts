---
title: "Domain Events over Active Record Callbacks"
created_at: 2016-05-13 17:02:23 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'domain event', 'active record', 'callbacks', 'ddd', 'rails' ]
newsletter: arkency_form
---

Recently [Marcin](https://twitter.com/killavus) wrote an article about [ActiveRecord callbacks being the biggest code smell in Rails apps](https://medium.com/planet-arkency/the-biggest-rails-code-smell-you-should-avoid-to-keep-your-app-healthy-a61fd75ab2d3#.q537fl3g5), that can easily get out of control. It was posted on Reddit and a very interesting comment appeared [there](https://www.reddit.com/r/ruby/comments/4hr125/the_biggest_rails_code_smell_you_should_avoid_to/):

<!-- more -->

_Imagine an important model, containing business vital data that changes very rarely, but does so due to automated business logic in a number of separate places in your controllers._

_Now, you want to send some kind of alert/notification when this data changes (email, text message, entry in a different table, etc.), because it is a big, rare, change that several people should know about._

_Do you:_

_A. Opt to allow the Model to send the email every time it is changed, thus encapsulating the core functionality of "notify when changes" to the actual place where the change occurs?_

_Or_

_B. Insert a separate call in every spot where you see a change of that specific Model file in your controllers?_

_I would opt for A, as it is a more robust solution, future-proof, and most to-the-point. It also reduces the risk of future programmer error, at the small cost of giving the model file one additional responsibility, which is notifying an external service when it changes._

  
The author brings very interesting and very good points to the table. I, myself, used a few months ago a callback just like that:

```ruby
class Order < ActiveRecord::Base  
  after_commit do |order|  
    Resque.enqueue(IndexOrderJob,  
      order.id,  
      order.shop_id,  
      order.buyer_name,  
      order.buyer_email,  
      order.state,  
      order.created_at.utc.iso8601  
    )  
  end  
end
```

To schedule indexing in ElasticSearch database. It was the fastest solution to our problem. But I did it knowing that it does not bring us any further in terms of improving our codebase. But I knew that we were doing at the same time other things which would help us get rid of that code later.

So despite undeniable usefulness of those callbacks, let's talk about a couple of problems with them.  

## They are not easy to get right

Imagine very similar code such as:

```ruby
class Order < ActiveRecord::Base  
  after_save do |order|  
    Elasticsearch::Model.client.index(  
      id: id,   
      body: {  
        id:              id.to_s,  
        shop_id:         shop_id,  
        buyer_name:      buyer_name,  
        email:           buyer_email,  
        state:           state,  
        created_at:      created_at  
    })  
  end  
end
```

At first sight everything looks all right. However **if the transaction gets rolled-back**( saving Order can be part of a bigger transaction that you open manually)** **you would have indexed incorrect state in the second database. You can either live with that or switch to `after_commit`.

Also, what happens if we get an exception from Elastic. It would bubble up and rollback our DB transaction as well. You can think of it as a good thing (we won't have inconsistent DBs, there is nothing in Elastic and there is nothing in SQL db) or a bad thing (error in the less important DB preventend someone from placing an order and us from earning money).

So let's switch to `after_commit` which might be better suited to this particular needs. After all the documentation says:

_These callbacks are useful for interacting with other systems since you will be guaranteed that the callback is only executed when the database is in a permanent state. For example `after_commit` is a good spot to put in a hook to clearing a cache since clearing it from within a transaction could trigger the cache to be regenerated before the database is updated_

So in other words. `after_commit` is a safer choice if use those hook to integrate with 3rd party systems/APIs/DBs . `after_save` and `after_update` are good enough if the sideeffects are stored in SQL db as well.

```ruby
class Order < ActiveRecord::Base  
  after_commit do |order|  
    Elasticsearch::Model.client.index(  
      id: id,   
      body: {  
        id:              id.to_s,  
        shop_id:         shop_id,  
        buyer_name:      buyer_name,  
        email:           buyer_email,  
        state:           state,  
        created_at:      created_at  
    })  
  end  
end
```

So we know to use `after_commit`. Now, probably most of our tests are transactional, meaning they are executed in a DB transaction because that is the fastest way to run them. Because of that those hooks won't be fired in your tests. This can also be a good thing because you we bothered with a feature that might be only of interest to a very few test. Or a bad thing, if there are a lot of usecases in which you need those data stored in Elastic for testing. You will either have to switch to non-transactional way of running tests or use [`test_after_commit` gem](https://github.com/grosser/test_after_commit) or [upgrade to Rails 5](https://github.com/rails/rails/pull/18458).

Historically (read in legacy rails apps) exceptions from `after_commit` callbacks were swallowed and only logged in the logger, because what can you do when everything is already commited? But it's been [fixed since Rails 4.2](https://github.com/rails/rails/pull/14488), however your stacktrace might not be as good as you are used to.

So we know that most of the technical problems can be dealt with one way or the other and you need to be aware of them. The exceptions are what's most problematic and you need to handle them somehow.  

## They increase coupling

Here is my gut feeling when it comes to Rails and most of its problems. There are not enough technical layers in it by default. We have views (not interesting at all in this discussion), controllers and models. So by default the only choice you have when you want to trigger a side-effect of our action is between controller and model. That's where we can put our code into. Both have some problems.

If you put your sideffects (API calls, caching, 2nd DB integration, mailing) in controllers you might have problem with testing it properly. For two reasons. Controllers are tightly coupled with HTTP interface. So to trigger them you need to use the HTTP layer in tests to communicate with them. Instantiating your controllers and calling their methods is not easy directly in tests. They are managed by the framework.

If you put the sideeffects into your models, you end up with a different problem. It's hard to test the domain models without those other integrations (obviously) because they are hardcoded there. So you must either live with slower tests or mock/stub them all the time in tests.

That's why there are plenty of blog posts about Service Objects in Rails community. When the complexity of an app rises, people want a place to put _after save_ effects like sending an email or notifying a 3rd party API about something interesting. In other communities and architectures those parts of code would be called [Transaction Script](http://martinfowler.com/eaaCatalog/transactionScript.html) or [Appplication/Domain/Infrastructure Service](http://gorodinski.com/blog/2012/04/14/services-in-domain-driven-design-ddd/). But by default we are missing them in Rails. That's why everyone (who needs them) is re-inventing services based on blog posts or using gems (there are at least a few) or new frameworks ([hanami](http://hanamirb.org/), [trailblazer](https://github.com/apotonick/trailblazer)) which don't forget about this layer.
You can read our [Fearless Refactoring book](http://rails-refactoring.com/) to get knowledge how to start introducing them in your code without migrating to a new framework. It's a great step before you start introducing more advanced concepts to your system.

## They miss the intention

When your callback is called you know that the data changed but you don't know why. Was the Order placed by the user. Was it placed by an POS operator which is a different process. Was it paid, refunded, cancelled? We don't know. Or we do based on `state` attribute which in many cases is an antipattern as well. Sometimes it is not a problem that you don't know this because you just send some data in your callback. Other times it can be problem.

Imagine that when User is registered via API call from from mobile or by using a different endpoint in a web browser we want to send a welcome email to them. Also when they join from Facebook. But not when they are imported to our system because a new merchant decided to move their business with their customers to our platform. In 3 situations out of 4 we want a given side effect (sending an email) and in one case we don't want. It would be nice to know the intention of what happened to handle that. `after_create` is just not good enough.  

## Domain Events

What I recommend, instead of using Active Record callbacks, is publishing domain events such as `UserRegisteredViaEmail`, `UserJoinedFromFacebook`, `UserImported`, `OrderPaid` and so on... and having handlers subscribed to them which can react to what happened. You can use one the many PubSub gems for that (ie. [`whisper`](https://github.com/krisleech/wisper)) or [`rails_event_store`](http://railseventstore.arkency.com/docs/publish.html) gem if you additionally want to have them saved on database and available for future inspection, debugging or logging.

If you want to know more about this approach you can now watch my talk: [2 years after the first domain event - the Saga pattern](https://blog.arkency.com/course/saga/). I describe how we started publishing domain events and using them to trigger sideeffects. You can use that approach instead of AR callbacks.

After some time whenever something changes in your application you have event published and you don't need to look for places changing given model, because you know all of them.

## P.S.

It only [gets worse in Rails 5](https://www.reddit.com/r/ruby/comments/4j3097/rails_5_activerecord_suppress_a_step_too_far/)
