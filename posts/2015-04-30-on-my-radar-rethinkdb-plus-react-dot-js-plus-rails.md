---
title: "On my radar: RethinkDB + React.js + Rails"
created_at: 2015-04-30 09:50:31 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rethinkdb', 'react.js', 'rails' ]
newsletter: :skip
newsletter_inside: :react_books
img: "rethinkdb-react-js-rails-sse/rethink-db-release-banner-react-rails.png"
---

<p>
  <figure align="center">
    <img src="<%= src_fit("rethinkdb-react-js-rails-sse/rethink-db-release-banner-react-rails.png") %>">
  </figure>
</p>

Sometimes you hear positive things about a technology and
you put it on your radar. To explore it when you have some time.
To get a feeling if it is fun at all. To mix and match things
together to see what comes out of it.

For me recently it was [RethinkDB](http://www.rethinkdb.com/) .
Its slogan says **The open-source database for the realtime web**.
Interesting enough to get me curious. _RethinkDB
pushes JSON to your apps in realtime_ also sounded good.

I was sick one week ago so I had a moment to give it a try.

<!-- more -->

If RethinkDB pushes changes and React can automatically re-render
a page effectively it would seem that merging these two technologies
together could give us nice real time page updates. We just need a
glue technology that would connect the DB to the browser and
authorize the request. Let's go with Rails.

If you want to learn the basics of RethinkDB I highly recommend their
[Ten-minute guide with RethinkDB and Ruby](http://www.rethinkdb.com/docs/guide/ruby/) .
The installation process with provided OS X and Ubuntu packages was
very simple for me as well.

### Building blocks

We start by adding `puma`, `nobrainer` and `react-rails` to our Gemfile.

We are going to use Puma because going with multi-threaded servers is fastest
way for us to start enjoying the results.

[NoBrainer](http://nobrainer.io/) is a Ruby ORM for RethinkDB. Similar in taste
to ActiveRecord.

And finally [react-rails](https://github.com/reactjs/react-rails) is fastest
way to start using react in rails environment.

### Starting point

If we go with `rails g scaffold Article title:string text:string` we will have a basic
structure generated. But it will use `NoBrainer` instead of `ActiveRecord`. Our
document looks like that:

```
#!ruby
class Article
  include NoBrainer::Document
  include NoBrainer::Document::Timestamps

  field :title, :type => String
  field :author, :type => String
end
```

You can find out more about integrating [RethinkDB with Rails](http://rethinkdb.com/docs/rails/)
in their own documentation. We are gonna leave the entire write side untouched. But we will
fiddle with the read part. How we display the document.

### React component

Instead of using `html & erb` to display an article, we will play with a React component.
When written with CoffeeScript it looks similar to HAML. Of course you could go with
[JSX](https://facebook.github.io/react/docs/displaying-data.html) if that's your flavor.

```
#!coffeescript
DOM = React.DOM

window.ShowArticle = React.createClass
  name: "ShowArticle"
  render: ->
    DOM.div null,
      DOM.p null,
        DOM.strong null, "Title: "
        @props.title
      DOM.p null,
        DOM.strong null, "Text: "
        @props.text
```

`@props` are the properties passed to the component when rendered.

### First render

We are going to use `react_component` helper that comes from the `react-rails` gem.
It makes easier to start react components that will run when a browser fetches
the page.

And with `prerender: true` they even render the component server-side
first and then react.js in a browser handles the lifecycle of that component. And
interactions with it. And all that stuff that your UX is responsible for.

```
#!erb
<p id="notice"><%%= notice %%></p>

<div class="well bs-component">
  <%%= react_component('ShowArticle',
         @article.to_json, 
         prerender: true,
         id: 'article',
         data: {reactive: start_show_path}) 
  %%>
</div>

<%%= link_to 'Edit', edit_article_path(@article) %%> |
<%%= link_to 'Back', articles_path %%>
```

`data: {reactive: start_show_path}` is a path for URL that will be used for streaming
changes. Let's dive into it.

### SSE in Browser

So we've got the first render covered. But we need to make this component auto updates
when the data changes. We are going to use [Server Sent Events](http://www.html5rocks.com/en/tutorials/eventsource/basics/)
for that. It's a browser API for one way, server to browser communication over
HTTP connection. It even has automatic re-connections built-in.

```
#!coffeescript
ShowArticleFactory = React.createFactory(ShowArticle)

$ ->
  $('[data-reactive]').each (_nop, element) ->
    reactivePath = $(element).attr('data-reactive')

    source = new EventSource(reactivePath);
    source.addEventListener 'message', (e) ->

      React.render(
        ShowArticleFactory( JSON.parse(e.data) )
        element
      )
```

We look for `data-reactive` elements and make a connection
to the URL. On event we ask react to re-render a new version of the
component in the same place.

### SSE in Rails

This is just a tiny wrapper for formatting data according to SSE spec.

```
#!ruby
require 'json'

class JsonSSE
  def initialize(io)
    @io = io

  end

  def write(object)
    @io.write "data: #{JSON.dump(object)}\n\n"
  end

  def close
    @io.close
  end
end
```

For SSE streaming in Rails I used `ActionController::Live`. You can read
a great blog-post by [Aaron Patterson where he introduced Live Streaming in 2012](http://tenderlovemaking.com/2012/07/30/is-it-live.html)
to get familiar with it.
Yep, it was that long time ago. And [Rails documentation for `ActionController::Live`](http://api.rubyonrails.org/v4.2.1/classes/ActionController/Live.html)

```
#!ruby
class StartController < ApplicationController
  include ActionController::Live

  def show
    response.headers['Content-Type'] = 'text/event-stream'

    sse = JsonSSE.new(response.stream)

    article = RethinkDB::RQL.new.table( Article.table_name ).get(Article.last.id)
    article.changes.run(NoBrainer.connection.raw).each do |change|
      sse.write(change['new_val'])
    end
  rescue *client_disconnected
  ensure
    sse.close rescue nil
    NoBrainer.disconnect rescue nil
  end

  private

  def client_disconnected
    return ActionController::Live::ClientDisconnected, IOError
  end
end
```

Here we use the feature of [changefeeds](http://rethinkdb.com/docs/changefeeds/ruby/) from RethinkDB.
You can subscribe to changes from a table, a single document or even a query and be notified every time
something changed. In our example we subscribe to `changes` from one document, the last Article:

```
#!ruby
RethinkDB::RQL.new.table( Article.table_name ).get(Article.last.id)
```

This syntax mixes higher-level API (Nobrainer ORM) with low-level API (RethinkDB official driver)
but that's how I managed to get it work.

You can do much more with changefeeds but that's what I needed for our basic use-case.

## Final effect

Surprisingly (or not) it works. You can watch the 20s demo.

<iframe width="640" height="360" src="https://www.youtube.com/embed/P9Upn194b9M?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>

You can see the whole code on github [arkency/rethinkdb-reactjs](https://github.com/arkency/rethinkdb-reactjs) . 

## Dragons

I had to use `config.cache_classes = true` and `config.eager_load = true` to get
[SSE working in development mode](http://stackoverflow.com/a/18662297/1924951).

I set the `config.per_thread_connection = true` config option for `NoBrainer` as we
use puma, a multi-threaded web server.

I have a feeling that `react_component()` with `prerender: true` is not very
performant but I haven't benchmarked yet. It might highly depend on the JS engine
and the ruby version that you build your app with. But that's my gut feeling for now.
I want to truly benchmark one day.

The RethinkDB query from our Live Controller is blocking and taking one thread
out of the puma's pool. This can lead to thread pool exhaustion if too many people are
connected and the pool size is too small. But one of the next things I want to investigate
is sending the stream of changes with EventMachine and/or Thin instead of Puma. This should be possible as
the official driver comes with the [`em_run` ](http://www.rethinkdb.com/api/ruby/#em_run)
method which can be used in EventMachine single-threaded non-blocking environment
and should scale much better.

Also the thread used by SSE is not stopped if the user navigates away and the browser disconnects.
That is because as I said we are waiting (and blocking) for changes from RethinkDB.
If those changes occur the attempt to write to the disconnected browser will fail, and
a proper exception will be raised (that we catch) so we can end this thread.

People using [redis pub-sub experienced](http://stackoverflow.com/questions/18970458/redis-actioncontrollerlive-threads-not-dying)
similar problem and as a workaround they publish ping every now and then. You could
achieve similar thing with RethinkDB:

Subscribe to both notifications.

```
#!ruby
rql = RethinkDB::RQL.new
rql.table( Article.table_name ).filter({id: Article.first.id}).union(
  rql.table( "pings" ).filter({id: Process.pid})
).changes.run(NoBrainer.connection.raw).each do |change|
  # ...
end
```

Send pings.

```
#!ruby
r.db("rethinkapp_development").table("pings").
  insert({id: Process.pid, on: Time.now.to_i, ping: "ping"}).run

loop do
  r.db("rethinkapp_development").table("pings").
    filter{|ping| ping["id"].eq(Process.pid)}.
    update(on: Time.now.to_i).run

  sleep(10)
end
```

## Final thoughts

Despite many dragons I have a feeling that there is a big potential in RethinkDB.
I will keep it on my radar and explore more deeply.

<%= show_product_inline(item[:newsletter_inside]) %>
