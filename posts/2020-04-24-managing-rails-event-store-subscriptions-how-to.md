---
title: Managing Rails Event Store Subscriptions — How To
created_at: 2020-04-24T21:10:56.807Z
author: Paweł Pacana
tags: ['rails event store']
publish: false
cover_image: 'iker-urteaga-TL5Vy1IM-uA-unsplash.jpg'
---

Recently we got asked about patterns to manage subscriptions in Rails Event Store:

<blockquote class="twitter-tweet mx-auto"><p lang="en" dir="ltr"><a href="https://twitter.com/arkency?ref_src=twsrc%5Etfw">@arkency</a> Hiya, do you have any patterns for managing lots of subscriptions? <br>i.e. adding to initializers file only scales for short time!</p>&mdash; Ian Vaughan (@IanVaughan) <a href="https://twitter.com/IanVaughan/status/1253318752977907714?ref_src=twsrc%5Etfw">April 23, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

It's a very good question which made me realize how much knowledge there is yet to share from my everyday work. I took it as an opportunity to gather knowledge in one place — chances are this question will be asked again in the future, thus a blog post in response.


## Bootstrap

Subscription in Rails Event Store is [a way to connect]( https://railseventstore.org/docs/subscribe/) an event handler with the events it responds to. Whenever an event is published all its registered handlers are called. We require such handlers to respond to `#call` method, taking the instance of an event as an argument. By convention we recommend to start with a single file to hold these subscriptions. Usually this is an initializer:

```ruby
# config/initializers/rails_event_store.rb

module Sample
  class Application < Rails::Application
    config.to_prepare do
      Rails.configuration.event_store = event_store = RailsEventStore::Client.new
      
        event_store.subscribe(InvoiceReadModel.new, to: [InvoiceCreated, InvoiceUpdated])
        event_store.subscribe(send_invoice_email,to: [InvoiceAccepted])
    end
  end
end
```

The idea for such glue file came straight from one on my favourite keynotes. Greg Young in his ["8 Lines of Code"](https://www.infoq.com/presentations/8-lines-code-refactoring/) talk presents a concept of a bootstrap method, which ties together various dependencies. It is a single place to look at to understand the relationships between collaborators. There is no "magic" in it, it is a boilerplate code. And such is best kept out of the code that really matters.

At some point in project lifecycle the dependencies will differ in production as compared to development and test environments. In tests we prefer [fake adapters](https://blog.arkency.com/2016/11/rails-and-adapter-objects-different-implementations-in-production-and-tests/) to real ones for 3rd party services. So we substitute them in a bootstrap for appropriate environments. 

Having a different bootstrap method for test environment has an additional benefit of the possibility to [disable particular handlers](https://blog.arkency.com/optimizing-test-suites-when-using-rails-event-store/). Or quite the opposite — very selectively enable them for the subset of integration tests when they're most needed.

Here we extracted a map of subscriptions to `ApplicationSubscriptions` bootstrap: 

```ruby
# config/initializers/rails_event_store.rb

module Sample
  class Application < Rails::Application
    config.to_prepare do
      Rails.configuration.event_store = event_store = RailsEventStore::Client.new
      ApplicationSubscriptions.new.call(event_store)
    end
  end
end
```

```ruby
# lib/application_subscriptions.rb

class ApplicationSubscriptions
  def global_handlers
    [
      Search::EventHistory,
      RailsEventStore::LinkByCorrelationId,
      RailsEventStore::LinkByCausationId,
    ]
  end
  
  def handlers
    { 
      send_invoice_email   => [InvoiceAccepted],
      InvoiceReadModel.new => [InvoiceCreated, InvoiceUpdated]
    }
  end

  def call(event_store)
    global_handlers.each do |handler|
      event_store.subscribe_to_all_events(handler)
    end

    handlers.each do |handler, events|
      event_store.subscribe(handler, to: events)
    end
  end
end
```


## Modules

Single file for subscriptions or a bootstrap method takes you this far. With sufficiently complex applications you will eventually discover many bounded contexts. Speaking of code, one way of representing bounded contexts in a monolithic application may be via [modules](https://blog.arkency.com/rails-components-neither-engines-nor-gems/). Below are some events from insuring context, defined in its own module. 

```ruby
# insuring/lib/insuring.rb

module Insuring
  OrderInsured                      = Class.new(RailsEventStore::Event)
  FilledIn                          = Class.new(RailsEventStore::Event)
  CustomerDataReminderDelivered     = Class.new(RailsEventStore::Event)
  CustomerDataReminderDeliverFailed = Class.new(RailsEventStore::Event)
  PolicyCreated                     = Class.new(RailsEventStore::Event)
  CompletionFailed                  = Class.new(RailsEventStore::Event)
end
```

Now let's take a sip of inspiration from Elm and scaling its [architecture pattern](https://guide.elm-lang.org/architecture/). One can be found in an excellent [elm-spa](https://github.com/rtfeldman/elm-spa-example/blob/cb32acd73c3d346d0064e7923049867d8ce67193/src/Main.elm#L207-L280) example.

In short: 

- `update` from Main module is a glue, composed of smaller functions from particular modules
- messages are dispatched to appropriate `update` from a module
- each module handles changes in their context

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    case url.fragment of
                        Nothing ->
                            -- If we got a link that didn't include a fragment,
                            -- it's from one of those (href "") attributes that
                            -- we have to include to make the RealWorld CSS work.
                            --
                            -- In an application doing path routing instead of
                            -- fragment-based routing, this entire
                            -- `case url.fragment of` expression this comment
                            -- is inside would be unnecessary.
                            ( model, Cmd.none )

                        Just _ ->
                            ( model
                            , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                            )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( GotSettingsMsg subMsg, Settings settings ) ->
            Settings.update subMsg settings
                |> updateWith Settings GotSettingsMsg model

        ( GotLoginMsg subMsg, Login login ) ->
            Login.update subMsg login
                |> updateWith Login GotLoginMsg model

        ( GotRegisterMsg subMsg, Register register ) ->
            Register.update subMsg register
                |> updateWith Register GotRegisterMsg model

        ( GotHomeMsg subMsg, Home home ) ->
            Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        ( GotProfileMsg subMsg, Profile username profile ) ->
            Profile.update subMsg profile
                |> updateWith (Profile username) GotProfileMsg model

        ( GotArticleMsg subMsg, Article article ) ->
            Article.update subMsg article
                |> updateWith Article GotArticleMsg model

        ( GotEditorMsg subMsg, Editor slug editor ) ->
            Editor.update subMsg editor
                |> updateWith (Editor slug) GotEditorMsg model

        ( GotSession session, Redirect _ ) ->
            ( Redirect session
            , Route.replaceUrl (Session.navKey session) Route.Home
            )

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )
```

Translating above example to Ruby and RES:

- there is na event from different bounded context, i.e. `Ordering`, we will be subscribing to it

```ruby
module Ordering
  OrderCompleted = Class.new(RailsEventStore::Event)
end
```

- there is an event handler which reacts to `Ordering::OrderCompleted` and applies changes withing `Insuring`

```ruby
module Insuring
  class OrderCompleted < ActiveJob::Base
    prepend RailsEventStore::AsyncHandler

    def perform(event)
      order_id = fact.data.fetch(:order_id)
      ApplicationRecord.transaction do
        completion = InsuranceCompletion.lock.find_by_billing_order_id(order_id)
        # and the boring rest ;)
      end
    end
  end
end
```

- finally theres is an actual glue code

  Bootstrap method in a module to subscribe any `Insurance` handlers to events from external contexts and `ApplicationSubscriptions` collecting all module subscriptions it knows about

```ruby
module Insuring
  def subscribe(event_store)
    event_store.subscribe(OrderCompleted, to: [::Ordering::OrderCompleted])
  end
  module_function :subscribe
end

class ApplicationSubscriptions
  def call(event_store)
    Insuring.subscribe(event_store)
    # ...
  end
end
```

That is the gist of it. I can imagine one could make module subscriptions to be discovered dynamically but the general idea is more or less the same. 

## Different perspectives for different problems

An ability to look on subscriptions not only from handler-to-events but also event-to-handlers comes handy in some situations, most notably when debugging. We don't yet have a tool yet in RES ecosystem to help in such use cases. However my [colleague](https://blog.arkency.com/authors/rafal-lasocha/) made a following script to generate both mappings. Consider this to be a quick spike. With RubyMine code analysis and its _Jump to Definition_ this actually becomes very handy when navigating the code.

```ruby
class GenerateFiles
  EVENT_TO_HANDLERS_FILE = "lib/event_to_handlers.rb"
  HANDLER_TO_EVENTS_FILE = "lib/handler_to_events.rb"

  def generate_event_to_handlers
    File.open(EVENT_TO_HANDLERS_FILE, "w") do |f|
      f.puts event_to_handlers_header

      all_fact_classes.sort_by(&:name).each do |fact|
        event_type = fact.name
        f.puts indent("#{event_type} => [", 6)
        subscriptions.all_for(event_type).each do |subscription|
          f.puts indent("#{subscription}, # #{handler_type(subscription)}", 8)
        end
        f.puts indent("],", 6)
      end

      f.print footer
    end
  end

  def generate_handler_to_events
    handler_to_events = all_fact_classes.each_with_object({}) do |fact, acc|
      subscriptions.all_for(fact.name).each do |subscription|
        acc[subscription] ||= []
        acc[subscription] << fact
      end
    end

    File.open("lib/handler_to_events.rb", "w") do |f|
      f.puts handler_to_events_header

      handler_to_events.keys.sort_by(&:name).each do |handler|
        f.puts indent("#{handler.name} => [", 6)
        handler_to_events[handler].sort_by(&:name).each do |event|
          f.puts indent("#{event.name},", 8)
        end
        f.puts indent("],", 6)
      end

      f.print footer
    end
  end

  def all_fact_classes
    ::RailsEventStore::Event.descendants
  end

  def subscriptions
    Rails.configuration.event_store.send(:broker).send(:subscriptions)
  end

  def handler_to_events_header
    return <<~EOF
    class HandlerToEvents
      # File autogenerated with script/regenerate.rb
      def events
        {
    EOF
  end

  def event_to_handlers_header
    return <<~EOF
    class EventToHandlers
      # File autogenerated with script/regenerate.rb
      def handlers
        {
    EOF
  end

  def footer
    return <<~EOF
        }
      end
    end
    EOF
  end

  def handler_type(subscription)
    subscription.respond_to?(:perform_async) ? "async" : "SYNC"
  end

  def indent(str, spaces)
    (" " * spaces) + str
  end
end

script = GenerateFiles.new
script.generate_event_to_handlers
script.generate_handler_to_events
```

I would very much welcome this or simillar tool in Rails Event Store for a broader audience. Something like `rails routes` but for subscriptions. Either in the console or in the [browser](https://railseventstore.org/docs/browser/). 

Who knows, maybe that could be [your contribution](https://github.com/RailsEventStore/rails_event_store)? 🙂

## Not only events

So far the code examples circulated around events. The very same ideas can be applied to commands and command handlers, with little help of [command bus](https://github.com/arkency/command_bus#command-bus).



