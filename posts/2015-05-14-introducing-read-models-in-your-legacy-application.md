---
title: "Introducing Read Models in your legacy application"
created_at: 2015-05-14 18:20:44 +0200
kind: article
publish: true
author: Rafał Łasocha
tags: [ 'rails_event_store', 'read model', 'event', 'event sourcing' ]
newsletter: :arkency_form
img: "introducing-read-models-in-your-legacy-application/books.jpg"
---

<p>
  <figure align="center">
    <img src="<%= src_fit("introducing-read-models-in-your-legacy-application/books.jpg") %>">
  </figure>
</p>

Recently on our blog you could read many posts about Event Sourcing. There're a lot of new concepts around it - event, event handlers, read models... In his [recent blogpost](http://blog.arkency.com/2015/05/building-a-react-dot-js-event-log-in-a-a-rails-admin-panel/) Tomek said that you can introduct these concepts into your app gradually. Now I'll show you how to start using Read Models in your application.

<!-- more -->

## Our legacy application

<p>
  <figure align="center">
    <img src="<%= src_fit("introducing-read-models-in-your-legacy-application/ranking.png") %>">
  </figure>
</p>

In our case, the application is very legacy. **However, we already started publishing events there because adding a line of code which publishes an event really cost you nothing.** Our app is a website for board games' lovers. On the games' pages users have "Like it" button. There's a ranking of games and one of the columns in games' ranking is "Liked count". We want to introduce a read model into whole ranking, but we prefer to refactor slowly. Thus, we'll start with introducing our read model into only this one column - expanding it will be simple. We'll use just a database's table to make our read model.

The events which will be interesting for us (and are already being published in application) are `AdminAddedGame`, `UserLikedGame` and `UserUnlikedGame`. I think that all of them are pretty self-explanatory.

But why would you like to use read models in your application anyway? First of all, because it'll make reasoning about your application easier. Your event handlers are handling writes: they update the read models. After that, reading data from database is simple, because you just need to fetch the data and display them.

The first thing we should do is introducing `GameRanking` class inherited from `ActiveRecord::Base` which will represent a read model. It should have at least columns `game_id` and `liked_count`.

Now, we are ready to write an event handler, which will update a read model each time when an interesting event occurs.

## Creating an event handler

Firstly, we will start from having records for each game, so we want to handle `AdminAddedGame` event.

```
#!ruby
class UpdateGameRankingReadModel
  def handle_event(event)
    case event.event_type
    when "Events::AdminAddedGame" then handle_admin_added_game(event)
    end
  end

  def handle_admin_added_game(event)
    GameRanking.create!(game_id: event.data[:game][:id],
                       game_name: event.data[:game][:name])
  end
end
```

In our `GamesController` or wherever we're creating our games, we subscribe this event handler to an event:

```
#!ruby
game_ranking_updater = UpdateGameRankingReadModel.new
event_store.subscribe(game_ranking_updater, ['Events::AdminAddedGame']
```

Remember, that this is legacy application. **So we have many games and many likes, which doesn't have corresponding `AdminAddedGame` event, because it was before we started gathering events in our app.** Some of you may think - "Let's just create the GameRanking records for all of your games!". And we'll! But we'll use events for this : ). However, there's also another road - publishing all of the events "back in time". We could fetch all likes already present in the application and for each of them create `UserLikedGame` event.

## Snapshot event
So, as I said, we are going to create a snapshot event. **Such event have a lot of data inside, because basically it contains all of the data we need for our read model.**

Firstly, I created `RankingHadState` event. 

```
#!ruby
module Events
  class RankingHadState < RailsEventStore::Event
  end
end
```

Now we should create a class, which we could use for publishing this snapshot event (for example, using rails console). It should fetch all games and its' likes count and then publish it as one big event.

```
#!ruby
class CopyCurrentRankingToReadModel
  def initialize(event_store = default_event_store)
    @event_store = event_store
  end

  attr_reader :event_store

  def default_event_store
    RailsEventStore::Client.new
  end

  def call
    game_rankings = []

    Game.find_each do |game|
      game_rankings << {
        game_id: game.id,
        liked_count: game.likes.count
      }
    end

    event = Events::RankingHadState.new({
      data: game_rankings
    })
    event_store.publish_event(event)
  end
end
```

Now we only need to add handling method for this event to our event handler.

```
#!ruby
class UpdateGameRankingReadModel
  def handle_event(event)
    ...
    when "Events::RankingHadState" then handle_ranking_had_state(event)
    ...
  end

  ...

  def handle_ranking_had_state(event)
    GameRanking.delete_all
    event.data.each do |game|
      GameRanking.create!(game)
    end
  end
end
```

After this deployment, we can log into our rails console and type:

```
#!ruby
copy_object = CopyCurrentRankingToReadModel.new
event_store = copy_object.event_store
ranking_updater = UpdateGameRankingReadModel.new
event_store.subscribe(ranking_updater, ['Events::RankingHadState'])
copy_object.call
```

Now we have our GameRanking read model with records for all of the games. **And all new ones are appearing in GameRanking, because of handling `AdminAddedGame` event.**

## Polishing the details

We can finally move on to ensuring that `liked_count` field is always up to date.
As I previously said, I'm assuming that these events are already being published in production, so let's finish this!

Obviously, we need handling of like/unlike events in the event handler:

```
#!ruby
class UpdateGameRankingReadModel
  def handle_event(event)
    ...
    when "Events::UserLikedGame" then handle_user_liked_game(event)
    when "Events::UserUnlikedGame" then handle_user_unliked_game(event)
    ...
  end

  ...

  def handle_user_liked_game(event)
    game = GameRanking.where(game_id: event.data[:game_id]).first
    game.increment!(:liked_count)
  end

  def handle_user_unliked_game(event)
    game = GameRanking.where(game_id: event.data[:game_id]).first
    game.decrement!(:liked_count)
  end
end
```

After that you should subscribe this event handler to `UserLikedGame` and `UserUnlikedGame` events, in the same way we did it with `AdminAddedGame` in the beginning of this blogpost.

## Keeping data consistent

Now we're almost done, truly! Notice that it took some time to write & deploy code above it. **Thus, between running `CopyCurrentRankingToReadModel` on production and deploying this code there could be some `UserLikedGame` events which weren't handled.** And if they weren't handled, they didn't update `liked_count` field in our read model. 

But the fix for this is very simple - we just need to run our `CopyCurrentRankingToTheReadModel` in the production again, in the same way we did it before. Our data will be now consistent and we can just write code which will display data on the frontend - but I believe you can handle this by yourself. Note that in this blog post I didn't take care about race conditions. They may occur for example between fetching data for `HadRankingState` event and handling this event.
