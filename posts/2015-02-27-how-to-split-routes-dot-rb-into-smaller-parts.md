---
title: "How to split routes.rb into smaller parts?"
created_at: 2015-02-27 16:56:10 +0100
publish: true
author: Tomasz Rybczyński
newsletter: react_books
tags: [ 'rails', 'routes' ]
img: "routes/splitting-routes.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("routes/splitting-routes.jpg") %>" width="100%">
  </figure>
</p>

Each application created using Ruby on Rails framework has a routing engine and config/routes.rb file where we define routes paths. 
That file very often becomes very large in the proces of development. Each additional line makes the routing file harder to maintain. 
Also, searching for specific paths during the development phase becomes increasingly difficult. 
Currently, I work on an application in which the routing file contains about 500LOC. 
Quite a lot, isn't it? The solution is very simple. All you need to do is split the file into a couple of smaller ones.

<!-- more -->

## Order of loading files

When a request comes, routes.rb file is processed in "top to bottom" order. When the first suitable entry is found, the request is forwarded to the appropriate controller. 
In case of not finding a matching path in the file, Rails will serve 404. Because of the possibility of sorting the order of loading files, we can define the priorities for our namespaces.

## Solution

The following example is a short part of routes.rb:

```ruby
ActionController::Routing::Routes.draw do
  root to: "home#index"
  get "/about
  get "/login" => "application#login"
 

  namespace :api do
    #nested resources
  end

  namespace :admin do
    #nested resources
  end

  namespace :messages do
    #nested resources
  end

  namespace :orders do
    #nested resources
  end
end
```

There are some some default namespace (with /home, /about, /login routes) and four other namespaces. 
These namespaces define nicely existing contexts in our application. So, they are great canditates for division to other files. 
So we have created api.rb, admin.rb, messages.rb and orders.rb. Usually, I put the separated files in config/routes/ directory which is created for this purpose.
Next step is to load above files. We can do this in several ways. In applications based on Rails 3, loading route files from application config is a very popular method . 
Finally, we have to add to our application.rb following line:

```ruby
config.paths["config/routes"] += Dir[Rails.root.join('config/routes/*.rb’)]
```

If you want to have control over the order of loading files you can do this this way:

```ruby
config.paths["config/routes"] = %w(
      config/routes/messages.rb
      config/routes/orders.rb
      config/routes/admin.rb
      config/routes/api.rb
      config/routes.rb
    ).map { |relative_path| Rails.root.join(relative_path) }
```

However, since version 4 of Ruby on Rails if you attempt to add the above line application will throw an exception. 
The Rails 4 does not provide ['config/routes'] key in Rails::Engine. There is another option that works in both versions of the framework. 
Here we have another solution:

```ruby
YourApplication::Application.routes.draw do

def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
end
  
  draw :messages
  draw :orders
  draw :api
  draw :admin

  root to: "home#index"
  get "/about
  get "/login" => "application#login" 
 
end
```

It allows us to add a new method to ActionDispatch::Routing module which helps as to load paths. 
Rails 4 initially had a similar solution but it has been removed. 
You can check out the git commit here: https://github.com/rails/rails/commit/5e7d6bba79393de0279917f93b82f3b7b176f4b5

## Conclusion

Splitting files is a very simple solution for improving the condition of our routes files and developers lives. In this regard, this solution makes life easier in this. 
