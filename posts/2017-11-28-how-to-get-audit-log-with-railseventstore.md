---
created_at: 2017-11-28 20:20:20 +0100
publish: true
author: Paweł Pacana
tags: [ 'rails_event_store' ]
---

# How to get an audit log with RailsEventStore today

Did you know you can already get an audit log with [RailsEventStore](https://railseventstore.org) for free?

<!-- more -->

One of the benefits of having domains events as the source of the truth in application is that they naturally form log of what happened. Such trail of outcomes is much useful in debugging — not only for us developers but mostly for business people.

I've been consulting on a project where we've built a webapp solely for the purpose of showing such log. As an operations manager you were able to examine what happened for particular order — each one had a dedicated stream that grouped significant changes over whole lifecycle.
That allowed understanding what was the path that customer has taken and how to best help them in this such situation.

Building such UIs can be fun, no doubt. They aren't however very application-specific thus if you build it once...

## Enter RailsEventStore::Browser

If you build a solid one, you’ll be able to reuse it for most applications. Think of it as a Rails Admin for events. Except you’re only „reading” — events are like facts. They make sense being immutable.

Guess what — we’ve already build one! So how can you use it today?

1. `git clone git@github.com:RailsEventStore/rails_event_store.git`
2. `cd rails_event_store/rails_event_store-browser/elm`
3. Edit `src/index.js`. What you’re specifically looking for is:

	```javascript
	const app = Elm.Main.fullscreen({
	  eventUrl: "/event.json",
	  streamUrl: "/events.json",
	  streamListUrl: "/streams.json",
	  resVersion: "0.20.0"
	});
	```

	What you pass here are the endpoints of your app that provide input — streams and events for the browser.

	Such endpoints can look like this:

	```ruby
	class StreamsController < ApplicationController
	  def index
	    render json: [
		    { name: "Order$1" },
		    { name: "Customer$2" },

			  ...
	    ]
	  end

	  def show
	    render json: [
		    {
			    event_type: 'OrderPlaced',
			    event_id: '6dd35ebe-1dd7-42f9-97df-9ef2e6d933ce',
			    data: { order_id: 42 },
			    metadata: { timestamp: '2017-11-14 23:21:04 UTC' }
		    },

		    ...
	    ]
	  end
	end
	```

	```ruby
	class EventsController < ApplicationController
	  def show
	    render json: {
		    event_type: 'OrderPlaced',
		    event_id: '6dd35ebe-1dd7-42f9-97df-9ef2e6d933ce',
		    data: { order_id: 42 },
		    metadata: { timestamp: '2017-11-14 23:21:04 UTC' }
	    }
	  end
	end
	```

4. `yarn install`
5. `yarn build`
6. Examine `build/` contents. You’ll get `bundle.js` with complete client-side app and minimal `index.html` it needs to bootstrap. Your application needs to serve this — you can make it a separate layout in `app/views/layouts/` and a controller action with a view that uses it.

Having managed to fulfill those steps, this is what you should see:

<div style="width:100%;height:0;padding-bottom:65%;position:relative;"><iframe src="https://giphy.com/embed/3o6fJacEiYvOPRK8CI" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/rails-event-store-3o6fJacEiYvOPRK8CI">via GIPHY</a></p>


Isn’t it lovely and rewarding?


By the way, we can’t hide the fact that we’ve [used Elm to make it and we’re in love](https://blog.arkency.com/tags/elm). Go ahead and check out the [source code](https://github.com/RailsEventStore/rails_event_store/blob/0f7ee713a08d9b834c28cbfe25c00d995e3d8b64/rails_event_store-browser/elm/src/Main.elm) 😍.

## Free is not completely for free

You can tell by number of steps that it’s not that super effortless to get an audit log yet. On the other hand the hardest part has been already solved — you have events and you have a decent UI to dig through them.

What we’re planning next is a complete [Rails engine](http://guides.rubyonrails.org/engines.html) so that you mount a web interface for domain events and forget about the rest.

If you can’t wait, you can already reap all the benefits of a RailsEventStore browser today. Follow the steps and learn the secrets of your application event streams.
