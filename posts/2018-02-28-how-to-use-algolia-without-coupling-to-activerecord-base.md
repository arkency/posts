---
title: "How to use Algolia without coupling to ActiveRecord::Base"
created_at: 2018-02-28 19:00:00 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'search', 'algolia', 'rails', 'react' ]
newsletter: :arkency_form
---

In my [video course](https://blog.arkency.com/search-rails/), I present using Algolia with Rails using the more direct integration provided by `algoliasearch-rails` gem. Like many gems in Rails ecosystem, the integration relies on `ActiveRecord::Base` and its callbacks. And while it certainly can be very convenient and fast to add to your app, there is also a certain amount of magic involved. Ie, when your classes are loaded, they send HTTP request to Algolia with the index settings. And for me, that's a big no-no. I prefer the more explicit approach in which I treat those settings as database schema and update it in migrations so there is a history in the code.

<!-- more -->

But Algolia made a good decision by splitting their solution into 2 gems. There is algoliasearch gem written in Ruby and not coupled at all to Rails. And there is `algoliasearch-rails` which integrates with the Rails ecosystem and `ActiveRecord::Base` in particular. And you are free to just not use it :) You don't like Rails magic? You can opt out from it. I like it!

### Use algoliasearch gem instead of algoliasearch-rails

https://github.com/algolia/algoliasearch-client-ruby

The first thing you need to know is how to configure your search indexes.

```ruby
require 'algoliasearch'

Algolia.init(
  application_id: '...',
  api_key:        '...',
)
freeride = Algolia::Index.new("freeride")
freeride.set_settings({
  searchableAttributes:  %w[title subtitle unordered(description)],
  attributesToSnippet:   %w[description],
  attributesForFaceting: %w[category filterOnly(starts_at) filterOnly(ends_at)],
  replicas: ["freeride_by_starts_at_asc_development"],
 }, {
  forwardToReplicas: true,
})

f_replica = Algolia::Index.new("freeride_by_starts_at_asc_development")
f_replica.set_settings({
  ranking: ["custom"],
  customRanking: ["asc(starts_at)"],
})
```

If you want to make sure not a single value changes over time due to some defaults that Algolia might introduce, then use get_settings method to obtain all possible config values with their defaults and provide all of them:

```ruby
freeride = Algolia::Index.new("freeride")
freeride.set_settings({
 :replicas=>["freeride_by_starts_at_asc_development"],
 :attributesForFaceting=> ["category", "filterOnly(starts_at)", "filterOnly(ends_at)"],
 :attributesToSnippet=>["description:10"],
 :searchableAttributes=>["title", "subtitle", "unordered(description)"],

 :minWordSizefor1Typo=>4,
 :minWordSizefor2Typos=>8,
 :hitsPerPage=>20,
 :maxValuesPerFacet=>100,
 :version=>2,
 :numericAttributesToIndex=>nil,
 :attributesToRetrieve=>nil,
 :unretrievableAttributes=>nil,
 :optionalWords=>nil,
 :attributesToHighlight=>nil,
 :paginationLimitedTo=>1000,
 :attributeForDistinct=>nil,
 :exactOnSingleWordQuery=>"attribute",
 :ranking=>
   ["typo",
    "geo",
    "words",
    "filters",
    "proximity",
    "attribute",
    "exact",
    "custom"],
 :customRanking=>nil,
 :separatorsToIndex=>"",
 :removeWordsIfNoResults=>"none",
 :queryType=>"prefixLast",
 :highlightPreTag=>"<em>",
 :highlightPostTag=>"</em>",
 :snippetEllipsisText=>"",
 :alternativesAsExact=>["ignorePlurals", "singleWordSynonym"]
})
```

If you have many indices to configure it's OK to create a class for building those configs more dynamically:

```ruby
module Searching
  class EventIndexConfiguration
    def initialize(env: Rails.env)
      @env_name = env.to_s
    end

    def fetch(index_name)
      settings.fetch(index_name)
    end

    def index_names
      settings.keys
    end

    def event
      baseline_configuration.merge({
       "replicas" => [
         "#{env_name}_event_starts_at_asc",
         "#{env_name}_event_starts_at_desc",
       ]
     })
    end

    def event_starts_at_asc
      set_ranking("asc(starts_at)")
    end

    def event_starts_at_desc
      set_ranking("desc(starts_at)")
    end

    def primary_index_name
      "#{env_name}_event"
    end

    def sortable_index_names
      index_names.map { |index_name| "#{env_name}_#{index_name}" }
    end

    private

    def settings
      {
        event: event,
        event_price_asc:  event_starts_at_asc,
        event_price_desc: event_starts_at_desc,
      }.with_indifferent_access
    end

    def env_name
      @env_name
    end

    def set_ranking(field)
      replica_configuration.merge({
        "customRanking" => field,
      })
    end

    def replica_configuration
      baseline_configuration.merge({
        "primary" => primary_index_name,
        "ranking" => [
          "custom",
          "typo",
          "geo",
          "words",
          "filters",
          "proximity",
          "attribute",
          "exact",
        ]
      })
    end

    def baseline_configuration
      {
       :attributesForFaceting=> ["category", "filterOnly(starts_at)", "filterOnly(ends_at)"],
       :attributesToSnippet=>["description:10"],
       :searchableAttributes=>["title", "subtitle", "unordered(description)"],

       :minWordSizefor1Typo=>4,
       :minWordSizefor2Typos=>8,
       :hitsPerPage=>20,
       :maxValuesPerFacet=>100,
       :version=>2,
       :numericAttributesToIndex=>nil,
       :attributesToRetrieve=>nil,
       :unretrievableAttributes=>nil,
       :optionalWords=>nil,
       :attributesToHighlight=>nil,
       :paginationLimitedTo=>1000,
       :attributeForDistinct=>nil,
       :exactOnSingleWordQuery=>"attribute",
       :ranking=>
         ["typo",
          "geo",
          "words",
          "filters",
          "proximity",
          "attribute",
          "exact",
          "custom"],
       :customRanking=>nil,
       :separatorsToIndex=>"",
       :removeWordsIfNoResults=>"none",
       :queryType=>"prefixLast",
       :highlightPreTag=>"<em>",
       :highlightPostTag=>"</em>",
       :snippetEllipsisText=>"",
       :alternativesAsExact=>["ignorePlurals", "singleWordSynonym"]
      }
    end
  end
end
```

And that's how you can work with index settings without putting them into ActiveRecord class like `algoliasearch-rails` does:

```ruby
class Event < ApplicationRecord
  include AlgoliaSearch

  algoliasearch do
    searchableAttributes %w[title subtitle unordered(description)]
    attributesToSnippet %w[description]
    attributesForFaceting %w[category filterOnly(starts_at) filterOnly(ends_at)]

    add_replica STARTS_AT_ASC_INDEX, inherit: true do
      ranking ['custom']
      customRanking ['asc(starts_at)']
    end
```

That's the 1st step to decoupling this code from ActiveRecord.

### Integrate using domain events and handlers

Now we need something to use instead of ActiveRecord callbacks to trigger indexing of our records.

We can use meaningful domain events and event handlers over callbacks. This can be done with [`RailsEventStore`](https://railseventstore.org/), or anything else that you use like `RabbitMQ` or `Kafka` or `SQS`. The premise is identical. Publish info about changes happening in your application and in reaction update the search index.

There are 2 approaches that can you can go with. Full reindexing all the time or partial updates. Full reindexing is usually a safer approach. You use the domain events only as a trigger to gather all the data and send an updated version of your object to `Elastic` or `Algolia`. It's easy to handle retries in case of a networking error because you can just build a new version of your object again based on latest data and send it. But the downside is that you need to have a way of collecting all the necessary data. Sometimes it might be simple and it could be just mapping your active record attributes to a proper `json`. But sometimes you might have an event sourced aggregate and you don't want it to expose its internal fields. Or your search object (remember: read model) might have attributes coming from multiple objects from the write-side of your app. For example, the party in your search index can have data from the part, from its organizer, from attendees, from the venue, etc etc.

If you go with full reindexing you are usually going to have a mapper converting the attributes and their format from your domain object to search object.

```ruby
module Searching
  class EventToAlgoliaMapper
    def to_hash(event)
      {
        starts_at: event.starts_at.utc.to_i,
        ends_at:   event.ends_at.utc.to_i,
        title: event.title,
        description: event.description,
        category: event.category,
        state: event.state,
        image_url: event.image.url,
      }
    end
  end

  class EventToAlgolia < ActiveJob::Base
    def perform(fact)
      fact = YAML.load(fact)
      index = Algolia::Index.new(EventIndexConfiguration.new.primary_index_name)
      mapper = EventToAlgoliaMapper.new
      index.add_object(mapper.to_hash(Event.find(fact.data.fetch(:event_id))))
    end
  end
end

Rails.
  configuration.
  event_store.
  subscribe(Searching::EventToAlgolia, [EventAdded])
```

As you can see, you put composed the solution together on your own, instead of putting everything into Event class like you would do with `algoliasearch-rails` gem:

```ruby
class Event < ApplicationRecord
  include AlgoliaSearch

  STARTS_AT_ASC_INDEX = "Event_by_starts_at_asc_#{Rails.env}"
  ADMIN_INDEX_NAME = "Admin_Event_#{Rails.env}"

  algoliasearch enqueue: true, per_environment: true do
    attribute :title, :description, :category,
              :state, :image_url

    attribute :starts_at do
      starts_at.to_i
    end

    attribute :ends_at do
      ends_at.to_i
    end

    searchableAttributes %w[title subtitle unordered(description)]
    attributesToSnippet %w[description]
    attributesForFaceting %w[category filterOnly(starts_at) filterOnly(ends_at)]

    add_replica STARTS_AT_ASC_INDEX, inherit: true do
      ranking ['custom']
      customRanking ['asc(starts_at)']
    end
```

There is a class for index configuration, there are domain events triggering the indexing and re-indexing, there is a mapper for mapping attributes (ie Time to Unix timestamp in UTC), and there is a handler actually invoking the Algolia API. Everything under your control, and everything in plain sight. No direct coupling with `ActiveRecord::Base`, just your app reactively updating the search index.

Partial updates, on the other hand, can be more convenient sometimes, especially when published events contain all the information necessary to perform an update, without the need to load domain object and map all fields. Imagine that you publish a domain event (_fact_) when someone moves a party to a different date. In such case you can add a handler reacting to the fact, which only updates 2 fields in the search index:

```ruby
Rails.
  configuration.
  event_store.
  subscribe(Searching::UpdatedEventDatesInAlgolia, [EventMoved])

module Searching
  class UpdatedEventDatesInAlgolia < ActiveJob::Base
    def perform(fact)
      fact = YAML.load(fact)
      index = Algolia::Index.new(EventIndexConfiguration.new.primary_index_name)
      index.partial_update_object(
        objectID:  fact.event_id,
        starts_at: fact.starts_at.utc.to_i,
        ends_at:   fact.ends_at.utc.to_i,
      )
    end
  end
end
```

Someplace in your code, you publish the fact:

```ruby
fact = EventMoved.new(data: {
  event_id: 1,
  starts_at: Time.utc(2018, 1, 13, 12),
  ends_at:   Time.utc(2018, 1, 13, 22)
})
event_store.publish_event(fact, stream_name: "Event$1")
```

P.S. If your domain is all about events (conferences, parties, exhibitions, concerts etc) then I like to use the synonym _fact_ for domain events (which you publish and save in a DB).

_Are you also feeling the pain of building search pages from scratch every time? Or maybe you just want to learn how to deal with it upfront? We have a [video course](https://blog.arkency.com/search-rails/) that can help :)_
