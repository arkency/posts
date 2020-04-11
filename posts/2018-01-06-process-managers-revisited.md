---
title: "Process Managers revisited"
created_at: 2018-01-09 21:00:00 +0100
publish: true
author: Paweł Pacana
tags: [ 'process', 'manager', 'rails_event_store', 'ddd' ]
---

I've been telling my story with process managers [some time ago](https://blog.arkency.com/2017/06/dogfooding-process-manager/). In short I've explored there a way to source state of the process using nothing more but domain events. However I've encountered an issue which led to a workaround I wasn't quite happy about. With the release of [RailsEventStore v0.22.0](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.22.0) this is no longer a case!

Let's remind ourselves what was the original problem to solve:

>  You’re an operations manager. Your task is to suggest your customer a menu they’d like to order and at the same time you have to confirm that caterer can deliver this particular menu (for given catering conditions). In short you wait for `CustomerConfirmedMenu` and `CatererConfirmedMenu`. Only after both happened you can proceed further. You’ll likely offer several menus to the customer and each of them will need a confirmation from corresponding caterers.
>  If there’s a match of `CustomerConfirmedMenu` and `CatererConfirmedMenu` for the same `order_id` you cheer and trigger `ConfirmOrder` command to push things forward.

The issue manifested when I was about to "publish" events that process manager subscribed to and eventually received:

```
ActiveRecord::RecordNotUnique:
  PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_event_store_events_on_event_id"
  DETAIL:  Key (event_id)=(bddeffe8-7188-4004-918b-2ef77d94fa65) already exists.
```

I wanted to group those events in a short, dedicated stream from which they could be read from on each process manager invocation. Within limitations of RailsEventStore version at that time I wasn't able to do so and resorted to looking for past domain events in streams they were originally published to. That involved filtering them from irrelevant events (in the light of the process) and most notably knowing and depending on such streams (coupling).

## Linking events to the rescue

Recently released RailsEventStore v0.22.0 finally brings long-awaited `link_to_stream` API. This method would simply make reference to a published event in a given stream. It does not duplicate the domain event — it is the same fact but indexed in another collection.

From the outside it looks quite similar to `publish_event` you may already know. It accepts stream name and [expected version](http://railseventstore.org/docs/expected_version/) of an event in that stream. The difference is that you can only link published events so it takes event ids instead of events as a first argument:

```ruby
TestEvent = Class.new(RubyEventStore::Event)

specify 'link events' do
  client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
  first_event   = TestEvent.new
  second_event  = TestEvent.new

  client.append_to_stream(
    [first_event, second_event],
    stream_name: 'stream'
  )
  client.link_to_stream(
    [first_event.event_id, second_event.event_id],
    stream_name: 'flow',
    expected_version: -1
  )
  client.link_to_stream(
    [first_event.event_id],
    stream_name: 'cars',
  )

  expect(client.read_stream_events_forward('flow')).to eq([first_event, second_event])
  expect(client.read_stream_events_forward('cars')).to eq([first_event])
end
```

Just like when publishing, you cannot link same event twice in a stream.

Now you may be wondering why is that this API wasn't present before and just now became possible. From the inside we've changed how events are persisted — the layout of database tables in `RailsEventStoreActiveRecord` is a bit different. There's a single table for domain events (`event_store_events`) and another table to maintain links in streams (`event_store_events_in_streams`).

It was quite a [big change along v0.19.0 release](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.19.0) and a challenging one to do it right. Overall, our goal was to make streams cheap. This opens a range of possibilities:

- [partitioning for particular reader](https://eventstore.org/blog/20130210/the-cost-of-creating-a-stream/index.html):

> Generally when people are wanting only a few streams its because they want to read things out in a certain way for a particular type of reader.

> What you can do is repartition your streams utilizing projections to help provide for a specific reader. As an example let’s say that a reader was interested in all the InventoryItemCreated and InventoryItemDeactivated events but was not interested in all the other events in the system.

> Its important to remember that the way you write to your streams does not have to match the way you want to read from your streams. You can quite easily choose a different partitioning for a given reader.

- [indexing events by type](https://github.com/RailsEventStore/rails_event_store/issues/72)

- [interim streams](https://blog.scooletz.com/2016/11/21/event-sourcing-and-interim-streams/)

How would our process manager look like with `link_to_stream` then? Below you'll find `store` method which takes advantage of it.

```ruby
class CateringMatch
  class State
    def initialize
      @caterer_confirmed  = false
      @customer_confirmed = false
      @version = -1
      @event_ids_to_link = []
    end

    def apply_caterer_confirmed_menu
      @caterer_confirmed = true
    end

    def apply_customer_confirmed_menu
      @customer_confirmed = true
    end

    def complete?
      caterer_confirmed? && customer_confirmed?
    end

    def apply(*events)
      events.each do |event|
        case event
        when CatererConfirmedMenu  then apply_caterer_confirmed_menu
        when CustomerConfirmedMenu then apply_customer_confirmed_menu
        end
        @event_ids_to_link << event.id
      end
    end

    def load(stream_name, event_store:)
      events = event_store.read_stream_events_forward(stream_name)
      events.each do |event|
        apply(event)
      end
      @version = events.size - 1
      @event_ids_to_link = []
      self
    end

    def store(stream_name, event_store:)
      event_store.link_to_stream(
        @event_ids_to_link,
        stream_name: stream_name,
        expected_version: @version
      )
      @version += @event_ids_to_link.size
      @event_ids_to_link = []
    end
  end
  private_constant :State

  def initialize(command_bus:, event_store:)
    @command_bus = command_bus
    @event_store = event_store
  end

  def call(event)
    order_id = event.data(:order_id)
    stream_name = "CateringMatch$#{order_id}"

    state = State.new
    state.load(stream_name, event_store: @event_store)
    state.apply(event)
    state.store(stream_name, event_store: @event_store)

    command_bus.(ConfirmOrder.new(data: {
      order_id: order_id
    })) if state.complete?
  end
end
```

Whenever process manager receives new domain event it is processed and linked to the corresponding `CateringMatch$` stream. If the process is complete, we trigger a command. Otherwise we have to wait for more events.

## Inspecting Process Manager state

Processes like this happen over time and it's nice addition to be able to inspect their state. Is it nearly done? Or what are we waiting for? It's not uncommon that [some processes may never complete](https://blog.arkency.com/2017/06/dogfooding-process-manager/#the_domain).

A [stream browser](http://railseventstore.org/docs/browser/) that now ships with RailsEventStore helps with that. Mount it in your application, launch the app and navigate to the stream you're interested in:

<%= img_fit("process-managers-revisited/stream-browser.png") %>

## Tell us your RailsEventStore story

Isn't it funny that as creators we mostly learn about new people using what we've created from [github issues](https://github.com/RailsEventStore/rails_event_store/issues) when we break something or make it harder than necessary?

We'd love to [hear from you](https://goo.gl/forms/uidZdxzxjibLG0a92) when things are going well too 😅

<iframe src="https://docs.google.com/forms/d/e/1FAIpQLSc1NnRMIanTCEhFRbRR0Kjp4emqcPeEpprrj4dLT7yEgN-KsQ/viewform?embedded=true" width="100%" height="2400" frameborder="0" marginheight="0" marginwidth="0">Ładuję...</iframe>
