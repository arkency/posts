---
title: "Pretty, short urls for every route in your Rails app"
created_at: 2014-01-18 14:41:04 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :arkency_form
tags: [ 'rails', 'routing', 'slug', 'short', 'urls', 'render', 'redirect' ]
---

<p>
  <figure>
    <img src="/assets/images/short-urls/bench-fit.jpg" width="100%">
    <details>
      <a href="http://www.flickr.com/photos/aigle_dore/5626341059/in/photostream/">Photo</a> 
      remix available thanks to the courtesy of
      <a href="http://www.flickr.com/photos/aigle_dore/">Moyan Brenn</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

One of our recent project had the requirement so that admins are able to generate
short top level urls (like `/cool`) for every page in our system. Basically a
url shortening service inside our app. This might be especially usefull in your app
if those urls are meant to appear in printed materials (like `/productName` or
`/awesomePromotion`). Let's see what choices we have in our Rails routing.

<!-- more -->

## Top level routing for multiple resources

If your requirements are less strict, you might be in a better position to use a
simpler solution. Let's say that your current routing rules are like:

```
#!ruby
resources :authors
resources :posts

#author GET    /authors/:id(.:format)      authors#show
#  post GET    /posts/:id(.:format)        posts#show
```

We assume that `:id` might be either resource _id_ or its _slug_ and you
handle that in your controller (using friendly_id gem or whatever other
solution you use).

And you would like to add route like:

```
#!ruby
match '/:slug'
```

that would either route to `AuthorsController` or `PostController` depending on
what the slug points to. Our client wants Pretty Urls:

```
/rails-team
/rails-4-0-2-have-been-released
```

Well, you can solve this problem with constraints.

```
#!ruby
class AuthorUrlConstrainer
  def matches?(request)
    id = request.path.gsub("/", "")
    Author.find_by_slug(id)
  end
end

constraints(AuthorUrlConstrainer.new) do
  match '/:id', to: "authors#show", as: 'short_author'
end
```

```
#!ruby
class PostUrlConstrainer
  def matches?(request)
    id = request.path.gsub("/", "")
    Post.find_by_slug(id)
  end
end

constraints(PostUrlConstrainer.new) do
  match '/:id', to: "posts#show", as: 'short_post'
end
```

This will work fine but there are few downsides to such solution and you
need to remember about couple of things.

First, you must make sure that slugs are unique across all your resources
that you use this for. In our project this is the responsibility of 
<%= service_landing_link("services") %> which first try to reserve
the slug across the whole application,
and assign it to the resource if it succeeded. But you can also implement
it with a hook in your ActiveRecord class. It's up to you whether you choose
more coupled or decoupled solution.

The second problem is that adding more resources leads to more DB queries.
In your example the second resource (posts) triggers a query for authors first
(because the first constraint is checked first) and only if it does not match,
we try to find the post. N-th resource will trigger N db queries before we
match it. That is obviously not good.

## Render or redirect

One of the thing that you are going to decide is whether visiting such short url
should lead to rendering the page or redirection.

What we saw in previous chapter
gives us rendering. So the browser is going to display the visited url such as
`/MartinFowler` . In such case there might be multiple URLs pointing to the same
resource in your application and for best SEO you probably should standarize
which url is the [canonical](https://support.google.com/webmasters/answer/139394?hl=en): 
`/authors/MartinFowler` or `/MartinFowler/` ? Eventually you might also consider
dropping the longer URL entirely in your app to have a consistent routing.

You won't have such dillemmas if you go with redirecting so that `/MartinFowler`
simply redirects to `/authors/MartinFowler`. It is not hard with Rails routing.
Just change

```
#!ruby
constraints(AuthorUrlConstrainer.new) do
  match '/:id', to: "authors#show", as: 'short_author'
end
```

into

```
#!ruby
constraints(AuthorUrlConstrainer.new) do
  match('/:id', as: 'short_author', to: redirect do |params, request|
    Rails.application.routes_url_helpers.author_path(params[:id])
  end)
end
```

## Top level routing for everything

But we started with the requirement that every page can have its short
version if admins generate it. In such case we store the slug and the
path that it was generated based on in `Short::Url` class. It has the
`slug` and `target` attributes.

```
#!ruby
class Vanity::Url < ActiveRecord::Base
  validates_format_of     :slug, with: /\A[0-9a-z\-\_]+\z/i
  validates_uniqueness_of :slug, case_sensitive: false

  def action
    [:render, :redirect].sample
  end
end

url = Short::Url.new
url.slug = "fowler"
url.target = "/authors/MartinFowler"
url.save!
```

Now our routing can use that information.

```
#!ruby
class ShortDispatcher
  def initialize(router)
    @router = router
  end
  def call(env)
    id     = env["action_dispatch.request.path_parameters"][:id]
    slug   = Short::Url.find_by_slug(id)
    strategy(slug).call(@router, env)
  end

  private

  def strategy(url)
    {redirect: Redirect, render: Render }.fetch(url.action).new(url)
  end

  class Redirect
    def initialize(url)
      @url = url
    end
    def call(router, env)
      to = @url.target
      router.redirect{|p, req| to }.call(env)
    end
  end

  class Render
    def initialize(url)
      @url = url
    end
    def call(router, env)
      routing    = Rails.application.routes.recognize_path(@url.target)
      controller = (routing.delete(:controller) + "_controller").
        classify.
        constantize 
      action     = routing.delete(:action)
      env["action_dispatch.request.path_parameters"] = routing
      controller.action(action).call(env)
    end
  end
end

match '/:id', to: ShortDispatcher.new(self)
```

You can simplify this code greatly (and throw away most of it)
if you go with either render or redirect and don't mix those two
approaches. I just wanted to show that you can use any of them.

Let's focus on the `Render` strategy for this moment. What happens here.
Assuming some visited `/fowler` in the browser, we found the right `Short::Url` 
in the dispatcher, now in our `Render#call` we need to do some work that
usually Rails does for us. 

First we need to recognize what the long,
target url (`/authors/MartinFowler`) points to.

```
#!ruby
routing = Rails.application.routes.recognize_path(@url.target)
# => {:action=>"show", :controller=>"authors", :id=>"1"}
```

Based on that knowledge we can obtain the controller class.

```
#!ruby
controller = (routing.delete(:controller) + "_controller").classify.constantize 
# => AuthorsController
```

And we know what controller action should be processed.

```
#!ruby
action = routing.delete(:action)
# => "show"
```

No we can trick rails into thinking that the actual parameters coming from recognized url were different

```
#!ruby
env["action_dispatch.request.path_parameters"] = routing
# => {:id => "MartinFowler"}
```

If we generated the slug url based on nested resources path, we would have here two hash keys
with ids, instead of just one.

And at the and we create [new instance of rack compatible application](https://github.com/rails/rails/blob/64226302d82493d9bf67aa9e4fa52b4e0269ee3d/actionpack/lib/action_controller/metal.rb#L244)
based on the `#show()` method of our `controller`. And we put everything in motion with
`#call()` and pass it `env` (the `Hash` with [Rack environment](http://rack.rubyforge.org/doc/SPEC.html)).

```
#!ruby
controller.action(action).call(env)
# AuthorsController.action("show").call(env)
```

That's it. You delegated the job back to the rails controller that you
already have had implemented. Great job! Now our admins can generate
those short urls like crazy for the printed materials.

## Is it any good?

Interestingly, after prooving that this is possible, I am not sure whether
we should be actually doing it 😉 . What's your opinion? Would you rather
render or redirect? Should we be solving this on application level (render)
or HTTP level (redirect) ?

## Don't miss our next blog post

Subscribe to our newsletter below so that you are always
the first one to get the knowledge that you might find useful in your
everyday programmer job. Content is mostly focused on (but not limited to)
Rails, Webdevelopment and Agile. 2200 readers are already enjoying great content
and we are regularly included in [Ruby Weekly](http://rubyweekly.com) issues.

You can also
[follow us on Twitter](https://twitter.com/arkency)
[Facebook](https://www.facebook.com/pages/Arkency/107636559305814), or
[Google Plus](https://plus.google.com/+Arkency)

## More

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="/assets/images/fearless-refactoring-fit.png" width="15%" /></a>
<a href="/rails-react"><img src="/assets/images/react-for-rails/cover-fit.png" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/developers-oriented-project-management/"><img src="/assets/images/dopm-fit.jpg" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="/assets/images/blogging-small-fit.png" width="15%" /></a>
<a href="/responsible-rails"><img src="/assets/images/responsible-rails/cover-fit.png" width="15%" /></a>
