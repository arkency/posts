---
title: "Introducing Read Models in your legacy application"
created_at: 2015-05-14 18:20:44 +0200
kind: article
publish: false
author: Rafał Łasocha
tags: [ 'rails_event_store', 'read model', 'event', 'event sourcing' ]
newsletter: :arkency_form
---

Recently on our blog you could read many posts about Event Sourcing. There're a lot of new buzzwords aroung it - event, event handlers, read models... In his recent blogpost Tomek said that you can introduct these concepts into your app gradually. Now I'll show you how to start using Read Models in your application.

<!-- more -->

## Read Model

What is the read model anyway? For simplicity, we can think that this is just a table in the database which have data ready to display on your webpage. No costly joins and other things you usually do to display data on your webpage. This of course means, that the data you keep in your read model tables is redundant.
For example, you want to display the list of articles and author names associated to it. How would you do this usually? You probably have `Article` and `Author` classes, and you do have `author_id` field in your `Article` class.
When you want to display it, you just use SQL's join to fetch all the articles with author's names merged with article data.

There's another road. Apart from `Article` and `Author` classes, you may have an `ListArticle` read model, which is similar to the `Article` model, but it has columns for all the data you need from the `Author` class - `login`, `name`, `email` etc.

But why would you like to use read models in your application anyway? First of all, because it'll make reasoning about your application easier. Thanks to the event sourcing, writes and reads are decoupled - that's nice! Your event handlers are handling writes: they update the read models. After that, reading data from database is simple, because you just need to fetch the data and display them.

## Our legacy application

In our case, our application is very legacy. However, we already started publishing events there because adding a line of code which publishes an event really cost you nothing. In our app there's a ranking of products. On the products' pages users have "Like it" button. One of the columns in products' ranking is "Liked count". We want to introduce a read model into whole ranking, but we prefer to refactor slowly. Thus, we'll start with introducing our read model into only this one column - expanding it will be simple.

The events which will be interesting for us (and are already being published in application) are `AdminAddedProduct`, `UserLikedProduct` and `UserUnlikedProduct`. I think that all of them are pretty self-explanatory.

The first thing we should do is introducing `ProductRanking` class inherited from `ActiveRecord::Base` which will represent a read model. It should have at least columns `product_id` and `liked_count`.

Now, we are ready to write an event handler, which will update a read model each time when an interesting event occurs.

## Creating an event handler

Firstly, we will start from having records for each product, so we want to handle `AdminAddedProduct` event.

```
class UpdateProductRankingReadModel
  def handle_event(event)
    case event.event_type
    when "Events::AdminAddedProduct" then handle_admin_added_product(event)
    end
  end

  def handle_admin_added_product(event)
    ProductRanking.create!(product_id: event.data[:product][:id],
                       product_name: event.data[:product][:name])
  end
end
```

In our `ProductsController` or wherever we're creating our products, we subscribe this event handler to an event:

```
product_ranking_updater = UpdateProductRankingReadModel.new
event_store.subscribe(product_ranking_updater, ['Events::AdminAddedProduct']
```

Remember, that this is legacy application. So we have many products and many likes, which doesn't have corresponding `AdminAddedProduct` event, because it was before we started gathering events in our app. Some of you may think - "Let's just create the ProductRanking records for all of your products!". And we'll! But we'll use events for this : ).

## Snapshot event
We are going to create a snapshot event. Such event have a lot of data inside, because basically it contains all of the data we need for our read model.

Firstly, I created `RankingHadState` event. 
```
module Events
  class RankingHadState < RailsEventStore::Event
  end
end
```

Now we should create a class, which we could use for publishing this snapshot event (for example, using rails console). It should fetch all products and its' likes count and then publish it as one big event.

```
class CopyCurrentRankingToReadModel
  def initialize(event_store = default_event_store)
    @event_store = event_store
  end

  attr_reader :event_store

  def default_event_store
    RailsEventStore::Client.new
  end

  def call
    product_rankings = []

    Product.all.each do |product|
      product_rankings << {
        product_id: product.id,
        liked_count: product.likes.count
      }
    end

    event = Events::RankingHadState.new({
      data: product_rankings
    })
    event_store.publish_event(event)
  end
end
```

In your case, maybe you have too many products to call `Product.all`. Remember that in these cases you should use batching to retrieve data. In our case, we have a little bit more than 1000 products, so this is working just fine.

Now we only need to add handling method for this event to our event handler.

```
class UpdateProductRankingReadModel
  def handle_event(event)
    ...
    when "Events::RankingHadState" then handle_ranking_had_state(event)
    ...
  end

  ...

  def handle_ranking_had_state(event)
    ProductRanking.delete_all
    event.data.each do |product|
      ProductRanking.create!(product)
    end
  end
end
```

After this deployment, we can log into our rails console and type:

```
copy_object = CopyCurrentRankingToReadModel.new
event_store = copy_object.event_store
ranking_updater = UpdateProductRankingReadModel.new
event_store.subscribe(ranking_updater, ['Events::RankingHadState'])
copy_object.call
```

Now we have our ProductRanking read model with records for all of the products. And all new ones are appearing in ProductRanking, because of handling `AdminAddedProduct` event.

## Polishing the details

We can finally move on to ensuring that `liked_count` field is always up to date.
As I previously said, I'm assuming that these events are already being published in production, so let's finish this!

Obviously, we need handling of like/unlike events in the event handler:

```
class UpdateProductRankingReadModel
  def handle_event(event)
    ...
    when "Events::UserLikedProduct" then handle_user_liked_product(event)
    when "Events::UserUnlikedProduct" then handle_user_unliked_product(event)
    ...
  end

  ...

  def handle_user_liked_product(event)
    product = ProductRanking.where(product_id: event.data[:product_id]).first
    product.with_lock do
      product.liked_count += 1
      product.save
    end
  end

  def handle_user_unliked_product(event)
    product = ProductRanking.where(product_id: event.data[:product_id]).first
    product.with_lock do
      product.liked_count -= 1
      product.save
    end
  end
end
```

After that you should subscribe this event handler to `UserLikedProduct` and `UserUnlikedProduct` events, in the same way we did it with `AdminAddedProduct` in the beginning of this blogpost.

## Keeping data consistent

Now we're almost done, truly! Notice that it took some time to write & deploy code above it. Thus, between running `CopyCurrentRankingToReadModel` on production and deploying this code there could be some `UserLikedProduct` events which weren't handled. And if they weren't handled, they didn't update `liked_count` field in our read model. 

But the fix for this is very simple - we just need to run our `CopyCurrentRankingToTheReadModel` in the production again, in the same way we did it before. Our data will be now consistent and we can just write code which will display data on the frontend - but I believe you can handle this by yourself.
