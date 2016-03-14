---
title: "Creating new content types in Rails 4.2"
created_at: 2016-03-13 00:57:16 +0100
kind: article
publish: true 
author: Marcin Grzywaczewski
tags: [ 'rails', 'jsonapi', 'paramsparser' ]
newsletter: :arkency_form
img: "creating-custom-types/header.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("creating-custom-types/header.jpg") %> alt="" width="100%" />
  </figure>
</p>

While working on the application for [React.js+Redux workshop](http://blog.arkency.com/2016/02/how-to-teach-react-dot-js-properly-a-quick-preview-of-wroc-love-dot-rb-workshop-agenda/) I've decided to follow the [JSON API](http://blog.arkency.com/2016/02/how-and-why-should-you-use-json-api-in-your-rails-api/) specification of responses for my API endpoints. Apart from a fact that following the spec allowed me to avoid bikeshedding, there was also an interesting issue I needed to solve with Rails.

In JSON API specification there is a requirement about the `Content-Type` being set to [an appropriate value](http://jsonapi.org/format/#content-negotiation). It's great, because it allows generic clients to distinguish JSONAPI-compliant endpoints. Not to mention you can serve your old API while hitting the endpoint with an `application/json`  Content-Type and have your new API responses crafted in an iterative way for the same endpoints.

While being a very good thing, there was a small problem I've needed to solve. First of all - how to inform Rails that you'll be using the new `Content-Type` and make it possible to use `respond_to` in my controllers? And secondly - how to tell Rails that JSON API requests are very similar to JSON requests, thus request params must be a JSON parsed from the request's body?

I've managed to solve both problems and I'm happy with this solution. In this article I'd like to show you how it can be done with Rails.

<!-- more -->

## Registering the new `Content-Type`

First problem I needed to solve is usage of a new content type with Rails and registering it so Rails would be aware that this new content type exists. This allows you to use this content type while working with `respond_to` or `respond_with` inside your controllers - a thing that is very useful if you happen to serve many responses dependent on the content type.

Fortunately this is very simple and Rails creators somehow expected this use case. If you create your new Rails project there will be an initializer created which is perfect for this goal - `config/initializers/mime_types.rb`.

All I needed to do here was to register a new content type and name it:

```
#!ruby
# Be sure to restart your server when you modify this file.

Mime::Type.register "application/vnd.api+json", :jsonapi

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
```

This way I managed to use it with my controllers - `jsonapi` is available as a method of `format` given by the `respond_to` block:

```
#!ruby
class EventsController < ApplicationController
  def show
    respond_to do |format|
      format.jsonapi do  
        Event.find(params[:id]).tap do |event|
          serializer = EventSerializer.new(self, event.conference_id)
          render json: serializer.serialize(event)
      end

      format.all { head :not_acceptable }
    end
  end
end
```

*That's great!* - I thought and I forgot about the issue. Then during preparations I've created a simple JS client for my API to be used by workshop attendants:

```
#!javascript
const { fetch } = window;

function APIClient () {
  const JSONAPIFetch = (method, url, options) => {
    const headersOptions = {
      method,
      headers: {
        'Accept': 'application/vnd.api+json',
        'Content-Type': 'application/vnd.api+json'
      }
    };

    return fetch(url, Object.assign({}, options, headersOptions));
  };

  return {
    get (url) {
      const request = JSONAPIFetch("GET", url, {});
      return request;
    },
    post (url, params) {
      const request = JSONAPIFetch("POST", url,
                        { body: JSON.stringify(params) });
      return request;
    },
    delete (url) {
      const request = JSONAPIFetch("DELETE", url, {});
      return request;
    }
  };
}

window.APIClient = APIClient();
```

Then I've decided to test it...

## Specifying how params should be parsed - ActionDispatch::ParamsParser middleware

Since I wanted to be sure that everything works correctly I gave a try to the `APIClient` I've just created. I opened the browser's console and issued the following call:

```
#!javascript
APIClient.post("/conferences", { conference: 
                                 { id: UUID.create().toString(), 
                                  name: "My new conference!" } });
```

Bam! I got the HTTP 400 status code. Confused, I've checked the Rails logs:

```
Processing by ConferencesController#create as JSONAPI
Completed 400 Bad Request in 7ms

ActionController::ParameterMissing (param is missing or the value is empty: conference):
  app/controllers/conferences_controller.rb:66:in `conference_params'
  app/controllers/conferences_controller.rb:16:in `block (2 levels) in create'
  app/controllers/conferences_controller.rb:13:in `create'
```

Oh well. I passed my params correctly, but somehow Rails cannot figure how to handle these parameters. And if you think about it - why it should do it? For Rails this is a *completely* new content type. Rails doesn't know that this is a little more structured JSON request.

Apparently there is a Rack middleware that is responsible for parsing params depending on the content type. It is called `ActionDispatch::ParamsParser` and its `initialize` method accepts a Rack app (which every middleware does, honestly) and an optional argument called `parsers`. In fact the constructor is very simple I can copy it here:

```
#!ruby
# File actionpack/lib/action_dispatch/middleware/params_parser.rb, line 18
def initialize(app, parsers = {})
  @app, @parsers = app, DEFAULT_PARSERS.merge(parsers)
end
```

As you can see there is a list of DEFAULT parsers and by populating this optional argument you can provide your own parsers.

Rails loads this middleware by default without optional parameter set. What you need to do is to unregister the "default" version Rails uses and register it again - this way with your custom code responsible for parsing request parameters. I did it in `config/initializers/mime_types.rb` again:

```
#!ruby
# check app name in config/application.rb
middlewares = YourAppName::Application.config.middleware
middlewares.swap(ActionDispatch::ParamsParser, ActionDispatch::ParamsParser, {
  Mime::Type.lookup('application/vnd.api+json') => lambda do |body|
    ActiveSupport::JSON.decode(body)
  end
})
```

Let's take a look at this code in a step by step manner:

1. First of all, the variable called `middlewares` is created. It is an object of [`MiddlewareStackProxy`](http://api.rubyonrails.org/classes/Rails/Configuration/MiddlewareStackProxy.html) type which represents a chain of your loaded middlewares.
2. `swap` is a function to replace the chosen middleware with another middleware. In this use case we're replacing the default `ActionDispatch::ParamsParser` middleware with the same type of middleware, but we're recreating it with custom arguments. `swap` also takes care of putting the middleware in the same place that the previous middleware sat before - that can avoid us subtle errors that could be possible with wrong order of middlewares.
3. The `parsers` object is keyed with identifiers of a content type which can be accessed using `Mime::Type.lookup` method. A value is a lambda that will be called upon request's body every time the new request arrives - in this case it is just calling method for parsing the body as JSON. The result should be an object representing parameters.

As you can see this is quite powerful. This is a very primitive use case. But this approach is flexible enough to extract parameters from any content type. This can be used to pass `*.Plist` files used by Apple technologies as requests (I saw such use cases) and, in fact, anything. Waiting for someone crazy enough to pass `*.docx` documents and extracting params out of it! :)

## Summary

While new content types are often useful, there is a certain work needed to make it work correctly with Rails. Fortunately there is a very simple way to register new document types - and as long as you don't need to parse parameters out of it is easy.

As it turns out there is a nice way of defining your own parsers inside Rails. I was quite surprised that I had this issue (well, Rails is _magic_ after all! :)), but thanks to `ActionDispatch::ParamsParser` being written in a way adhering to [OCP](https://en.wikipedia.org/wiki/Open/closed_principle) I managed to do it without monkey patching or other cumbersome solutions.

If you know a better way to achieve the same thing, or a gem that makes it easier - let us know. You can write a comment or catch us on [Twitter](http://twitter.com/arkency) or [write an e-mail](mailto:dev@arkency.com) to us.
