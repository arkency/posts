---
title: "How and why should you use JSON API in your Rails API?"
created_at: 2016-02-23 01:41:11 +0100
kind: article
publish: true
author: Marcin Grzywaczewski
tags: [ 'rails', 'jsonapi', 'api' ]
newsletter: skip
img: "json-api-rails-ams/header.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("json-api-rails-ams/header.jpg") %> alt="" width="100%" />
  </figure>
</p>

**Crafting a well-behaving API is a virtue.** It is not easy to come up with good standards of serializing resources, handling errors and providing [HATEOAS](https://en.wikipedia.org/wiki/HATEOAS) utilities to your design. There are a lot application-level concerns you need to make - whether you want to send back responses in mutation requests (like PUT/PATCH/POST requests) or just use HTTP headers. And it is hard - and by hard I mean you need to spend some time to get it right.

There are other things you need to be focused on which are far more important than your API. **Good understanding of your domain, choosing a right architecture of your whole app or implementing business rules in a testable and correct way - those are real challenges you need to solve in the first place.**

**[JSON API](http://jsonapi.org) is a great solution to not waste hours on reinventing the wheel in terms of your API responses design.** It is a great, extensible response standard which can save your time - both on the backend side and the client side. Your clients can leverage you're using an established standard to implement an integration with your API in a cleaner and faster way.

There is an easy way to use JSON API with using a great [Active Model Serializers](https://github.com/rails-api/active_model_serializers) gem. In this article I'd like to show you how (and why!).

<!-- more -->

## JSON API dissected

JSON API is a standard for formatting your responses. It handles concerns like:

* How to present your resources to allow clients to recognize it just by the response contents? It is often the case that if you want to deserialize custom JSON responses you need to know both response contents and an endpoint details you just hit. JSON API solves this problem by [exposing data type as a first class data](http://jsonapi.org/format/#document-resource-objects) in your responses.

* How to read errors in an automatic way? In JSON API there is a [specified format](http://jsonapi.org/format/#error-objects) for errors. This allows your client to implement their own representations of errors in an easy way.

* How to expose data relationships in an unobtrustive? In JSON API [attributes and relationships of a given resource are separate](http://jsonapi.org/format/#document-compound-documents). That means that clients which are not interested in relationships can use the same code to parse response having them or not. Also it allows to implement backends which can include or exclude given relationships on demand, for example by passing an `include` GET option to a request in a very easy way. This can make performance tuning much easier.

* There is a great trend of creating "self-descriptive APIs" for which a client can configure all endpoints by itself by following links included in the API responses. [JSON API supports links like these](http://jsonapi.org/format/#document-links) and allows you to take a full advantage of the [HATEOAS](https://en.wikipedia.org/wiki/HATEOAS) approach.

* There is a clear distinction [between resource-related data and an auxillary data](http://jsonapi.org/format/#document-meta) you send in your responses. This way it is easier to not make wrong assumptions about responses and scope of their data.

  Summarizing, JSON API solves many problems you'd like to solve by yourself. In reality you won't use all features of JSON API together - but it is liberating that all paths you can propably take in your API development are propably covered within this standard.

  Thanks to being standard there is a variety of [client libraries](http://jsonapi.org/implementations/#client-libraries) that can consume JSON API-based responses in a seamless way. In Ruby [there are also alternatives](http://jsonapi.org/implementations/#server-libraries-ruby), but we'll stick with the most promising one - Active Model Serializers.

## Installation

JSON API support for AMS comes with the newest unrealeased versions, currently in the RC stage. To install it, you need to include it within your `Gemfile`:

```ruby
gem 'active_model_serializers', '0.10.0.rc4'
```

That's it. Because it is the RC version it is unfortunately not supporting the whole JSON API spec (for example it's hard to embed links inside relationships), but the codebase is still growing. 

## Configuration

With 0.10.x versions of Active Model Serializers uses the idea of [adapters](http://blog.arkency.com/2014/08/ruby-rails-adapters/) to support multiple response types. By default it ships with a pretty bare response format, but it can be changed by a configuration. You're interested in JSON API, so the adapter should get changed to JSON API adapter.

To configure it, enter this line of code in `config/environments/development.rb`, `config/environments/test.rb` and `config/environments/production.rb`:

```ruby
ActiveModelSerializers.config.adapter = :json_api
```

This way the response format will be transformed into format conforming JSON API specification.

## Usage

The idea of using AMS is pretty simple:

* You have a resource which is an ActiveRecord/ActiveModel object.
* You create the `ActiveModel::Serializer` for it.
* Every time you `render` it as JSON, the serializer will be used.



Let's take the simplest example:

```ruby
class Conference < ActiveRecord::Base
  include ConferenceErrors
  include Equalizer.new(:id)

  has_many :conference_days,
           inverse_of: :conference,
           autosave: true,
           foreign_key: :conference_id

  def initialize(id:, name:)
    super(id: id, name: name)
  end

  def schedule_day(id:, label:, from:, to:)
    ConferenceDay.new(id: id, label: label, from: from, to: to).tap do |day_to_schedule|
      raise ConferenceDaysOverlap.new if day_overlaps?(day_to_schedule)
      conference_days << day_to_schedule
    end
  end

  def days
    conference_days
  end

  private
  def day_overlaps?(day)
    days.any? { |existing_day| existing_day.clashes_with?(day) }
  end
end
```

This is a piece of code taken from the [backend application written for the React.js workshops](http://blog.arkency.com/2016/02/how-to-teach-react-dot-js-properly-a-quick-preview-of-wroc-love-dot-rb-workshop-agenda/). The `Conference` consists of a `name` and an `id`. There is also a relationship between a `Conference` and `ConferenceDay` in a one-to-many fashion. Let's see the test for an expected response out of such resource. We assume there are no conference days defined (yet!). Also `jsonize` is transforming symbol keys into string keys deeply and `json` is just calling `MultiJson.load(response.body)`:

```ruby
  def test_planned_conference_listed_on_index
    conference_uuid = next_uuid
    post "/conferences", format: :json, conference: {
      id: conference_uuid,
      name: "wroc_love.rb 2016"
    }

    get "/conferences", format: :json

    assert_response :success
    assert_equal conferences_simple_json_response(conference_uuid), json(response)
  end

  private
  def conferences_simple_json_response(conference_uuid)
    jsonize({
      data: [{
        type: "conferences",
        id: conference_uuid,
        attributes: {
          name: "wroc_love.rb 2016"
        },
        relationships: {
          days: {
            data: []
          }
        }
      }]
    })
  end
```

As you can see, there is a clear distinction between three parts:

* `id` and `type` specifies identity and type of a given resource. It is enough to identify which resource it is.
* `attributes` store all attributes you need to be serialized within this response. It is specified by a serializer which attributes are shown there.
* `relationships` define what relationships are inside the given resource.

The whole response is wrapped with a `data` field. There are two different "root" fields like this: `links` if you'd like to implement HATEOAS pagination/other links for a given resource and `meta` where you put an information independent of the given resource, but still important for a client. Data field is necessary, other ones are optional.

So far, so good. But you need the controller code to make asking endpoint possible:

```ruby
  def index
    conferences_repository.all.tap do |conferences|
      respond_to do |format|
        format.html
        format.json do
          render json: conferences
        end
      end
    end
  end
```

`conferences_repository` is [an example of the `Repository` pattern](http://blog.arkency.com/2015/06/thanks-to-repositories/) you may also know from our [Rails Refactoring book](http://rails-refactoring.com). As you can it is quite normal controller - if you install AMS rendering through `json:`  option of `render` is getting handled by your serializer by default. While I find such implicitness bad I can live with it for now.

And, last but not least - a `ConferenceSerializer`:

```ruby
class ConferenceDaySerializer < ActiveModel::Serializer
  attributes :label, :from, :to
end

class ConferenceSerializer < ActiveModel::Serializer
  attributes :name
  has_many :days
end
```

As you can see a syntax is very similar to what you have inside your model (especially for relationships). Attributes specify which fields from a model you will expose. For example here both `created_at` and `updated_at` can be added if there's a need.

This piece of code makes the whole test pass. And this is the most basic usage of AMS. You can do much more with it.

## Links & Meta

Unfortunately for now AMS do not support links on a `relationships` level, making it a bit hard to implement HATEOAS on the relationship level. But you can implement links on a top level by passing an appropriate options.

### For meta field:

```ruby
  def index
    conferences_repository.all.tap do |conferences|
      respond_to do |format|
        format.html
        format.json do
          render json: conferences, meta: { conference_count: conferences_repository.count }
        end
      end
    end
  end

## OUTPUT:
   jsonize({
      data: [{
        type: "conferences",
        id: conference_uuid,
        attributes: {
          name: "wroc_love.rb 2016"
        },
        meta: {
          conference_count: 15
    },
        relationships: {
          days: {
            data: []
          }
        }
      }]
    })
```

### For links:

```ruby
  def index
    conferences_repository.all.tap do |conferences|
      respond_to do |format|
        format.html
        format.json do
          render json: conferences, links: { self: conferences_url, meta: { pages: 10 } }
        end
      end
    end
  end

## OUTPUT:
   jsonize({
      data: [{
        type: "conferences",
        id: conference_uuid,
        links: {
          self: "http://example.com/conferences",
          meta: { pages: 10 }
    },
        attributes: {
          name: "wroc_love.rb 2016"
        },
        relationships: {
          days: {
            data: []
          }
        }
      }]
    })
```

## Including related resources

By default JSON API specifies only an information needed to retrieve a related object using a separate HTTP call - `id` and `type`. So for having one day inside a conference the JSON response will look like this:

```ruby
    jsonize({
      data: [{
        type: "conferences",
        id: <conference_uuid>,
        attributes: {
          name: "wroc_love.rb 2016"
        },
        relationships: {
          days: {
            data: [
              {
                id: <day_uuid>,
                type: "conference_days"
              }
            ]
          }
        }
      }]
    })
```

As you can see even after we defined our relationship serializer to include attributes like `from`, `to` or `label`, they are not serialized at all!

This is because JSON API makes even another separation: **included resources are in the separate root field**.

To render the response with `days` included, we need to pass an additional option:

```ruby
  def index
    conferences_repository.all.tap do |conferences|
      respond_to do |format|
        format.html
        format.json do
          render json: conferences, links: { self: conferences_url, meta: { pages: 10 } }
        end
      end
    end
  end

## OUTPUT:
   jsonize({
      data: [{
        type: "conferences",
        id: conference_uuid,
        attributes: {
          name: "wroc_love.rb 2016"
        },
        relationships: {
          days: {
            data: [{
              id: <day_uuid>,
              type: "conference_days"
            }]
          }
        },
      }],
      included: [
      {
          "id": <day_uuid>,
          "type": "conference_days",
          "attributes": {
            "label": "Day 1",
            "from": "2000-01-01T10:00:00.000Z",
            "to": "2000-01-01T22:00:00.000Z"
      }
    }]     
    })
```

As you can see the whole object is contained within `included` root field. This way if you are not interested in included resources you can just read `data` and omit `included` completely. It is very neat and desirable if client wants to configure itself.

## Summary

JSON API is a great tool to have in your toolbox. It reduces [bikeshedding](https://en.wiktionary.org/wiki/bikeshedding) and allows you to focus on delivering features and good code. Active Model Serializers make it easy to work with this well-established standard. Your client code will benefit to thanks to tailored libraries available for reading JSON API-based responses.

If you'd like to learn more how we recommend to use JSON API within Rails apps, then look at our new book ["Frontend-friendly Rails](http://blog.arkency.com/frontend-friendly-rails/).
