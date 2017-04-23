---
title: "Conditionality is filtering. Don't filter control flow, filter data."
created_at: 2017-04-21 11:33:52 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby', 'fp' ]
newsletter: :arkency_form
img: control-flow-filter-data-ruby-feathers/quote.jpg
---

I am not that smart. I didn't say it. Michael Feathers did.
But it got me thinking and I know it inspired my collegause as well.

<!-- more -->

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Conditionality is filtering. Don&#39;t filter control flow, filter data.</p>&mdash; Michael Feathers (@mfeathers) <a href="https://twitter.com/mfeathers/status/843074339322970112">March 18, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

A few weeks ago our client decided to change the URL structure of some of the
most important pages. There were a few reasons to do it. They don't matter so much right now.
The business just decided to prioritize one kind of benefits over another kind. They turned
out to be more important in the long term.

Instead of slugs provided by organizers such as `/wrocloverb2016/`
we now generate them ourselves based on the name of the event, its id, browser language,
some translations so it looks like `/e/wroc-love-rb-2016-tickets-111222333`.

But, of course, for a few months we need to support old URLs and continue to
redirect them to new URLs. We implemented it as redirects in routing.
Unfortunately they need to query database to find matching events to know
the new URL that the redirect should point to but I think that's acceptable.

Our platform also needs to support multiple languages and the URLs are a bit different
in every language (the word "tickets" is translated). And we don't need this redirecation
feature for new events which will only use the new URL structure.

This is the solution for redirecting.

```
#!ruby
EventRedirectDate = Time.new(2017, 4, 28, 14)

EventRedirect = -> (path_params) {
  slugged = begin
    event = Event.where(
      Event.arel_table[:created_at].lt(EventRedirectDate)
    ).friendly.find(path_params.fetch(:id))
    I18n.with_locale(path_params[:locale] || event.default_locale) do
      event.slugged
    end
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError.new('Not Found')
  end
  [path_params[:locale], "e", slugged].reject(&:blank?).join("/")
}

get '/:id', as: 'short_event', to: (redirect() do |path_params, _req|
  EventRedirect.(path_params)
end)
```

The line that I wanted to show you is:

```
#!ruby
[path_params[:locale], "e", slugged].reject(&:blank?).join("/")
```

We use [`routing-filter`](https://github.com/svenfuchs/routing-filter) gem and when the
URL path is `/whatever/` then `path_params[:locale]` is `nil` and we use the default language 
of current country (which we know based on the domain). If it is `/es/whatever` then 
`path_params[:locale]` is `es` and we know that the user wants to see the page in
Spanish. We normally recognize it and set `I18n.locale` in `ApplicationController`
but it works in routing as well, if you need it.

So there is nothing super unusual or fantastic in this line of code,
except that I originally wanted to write it as:

```
#!ruby
if path_params[:locale]
  # ...
else
  # ...
end
```

But the tweet which stayed in my mind and the _Don't filter control flow, filter data_ phrase
made me do it differently. I decided to filter _data_. All data. Even if `"e"` or `slugged` is
never empty. A bit more in a functional style.

```
#!ruby
[path_params[:locale], "e", slugged].reject(&:blank?).join("/")
```

It is a trivial example but if you want to see how far you can go with it,
I recommend watching [Norbert's talk](https://www.youtube.com/watch?v=l5ML_4WnAWg). For bonus, you
can learn more about scurvy ;) No wonder that `Enumberable` methods are
often [favorites](https://www.reddit.com/r/ruby/comments/665esj/whats_your_favorite_rubyrails_method/dgfrcxf/)
of best Ruby developers. I think one of the main reasons is that they often allow us to
avoid bunch of if-statements. Instead we can easily filter the data we work on.

There is a similar patterns in Redux reducers, especially [when they are combined](http://redux.js.org/docs/api/combineReducers.html).

```
#!javascript
import { combineReducers } from 'redux'
import todos from './todos'
import counter from './counter'

let reducer = combineReducers({
  todos,
  counter
})

let store = createStore(reducer)
store.dispatch({
  type: 'ADD_TODO',
  text: 'Use Redux'
})
```

When an action is dispatched, the `reducer` does not think whether `todos` or `counter` should
react to it. The action is passed to both of them and sometimes one of them decides to do nothing
and keeps its current state. It filters out uninteresting action.

BTW. Our [book Fearless Refactoring: Rails controllers](http://rails-refactoring.com/) contains a chapter
about _Extract routing constraint_ technique (as well as many others) that you might be interested in, as well.
