---
title: "Don't forget about eager_load when extending autoload paths"
created_at: 2014-11-09 11:39:06 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'eager_load_paths', 'autoload_paths', 'code', 'production', 'development', 'defined' ]
newsletter: :skip
newsletter_inside: :arkency_form
---

<p>
  <figure>
    <img src="/assets/images/eager_load_autoload_paths/rails_path-fit.jpg" width="100%">
  </figure>
</p>

I am sure you know about [`config.autoload_paths`](http://api.rubyonrails.org/v4.1.7/classes/Rails/Engine/Configuration.html#method-i-autoload_paths).
A setting which allows you to add aditional directories (besides `app/*` which works out of box) that can be used for placing your `.rb` files.
The [documentation mentions](http://guides.rubyonrails.org/configuring.html#configuring-rails-components) a
`config.autoload_paths += %W(#{config.root}/extras)` example. But the most common way to use it is probably to add
`lib` directory (especially after the transition from [rails 2 to rails 3](http://stackoverflow.com/questions/3356742/best-way-to-load-module-class-from-lib-folder-in-rails-3)).

Another (maybe not that common) usecase is to have some components (such as `notification_center` for example)
in top-level directory. To make it possible for them to work with your app people are usually using:

```
#!ruby
config.autoload_paths += %W( #{config.root}/notification_center )
```

or

```
#!ruby
config.autoload_paths += %W( #{config.root}/notification_center/lib )
```

And it is all cool **except for one thing they might have forgotten to mention to you.
How it all works in production and what you can do to make it work better.**

<!-- more -->

## Example

Let's say we have two files

```
#!ruby
# root/extras/foo.rb
class Foo
end
```
and

```
#!ruby
# root/app/models/blog.rb
class Blog < ActiveRecord::Base
end
```

Our configuration looks like this:

```
#!ruby
# root/config/application.rb
config.autoload_paths += %W( #{config.root}/extras )
```

## Things are ok in development

Now, let's check how it behaves in development.

```
#!ruby
defined?(Blog)
# => nil 
defined?(Foo)
# => nil 

Blog
# => Blog (call 'Blog.connection' to establish a connection) 
Foo
# => Foo 

defined?(Blog)
# => "constant" 
defined?(Foo)
# => "constant"
```

As you can see from this trivial example, **at first nothing is loaded**. Neither `Blog`, nor `Foo`
is known. When we **try to use them, rails autoloading jumps in**. `const_missing` is handled, it
looks for the classes in proper directories based on the convention and bang. `app/models/blog.rb`
is loaded, `Blog` class is now known under `Blog` constant. Same goes for `extras/foo.rb` and `Foo`
class.

## Eager loading kicks in on production, doesn't it?

But on the production, the situation is a little different...

```
#!ruby
defined?(Blog)
# => "constant"

defined?(Foo)
# => nil

Blog
# => Blog (call 'Blog.connection' to establish a connection) 
Foo
# => Foo 

defined?(Blog)
# => "constant" 
defined?(Foo)
# => "constant"
```

**Even before we try to use `Blog` for the very first time, the class is already loaded and the constant
is known. Why is that so? Because of eager loading.**

In production **to make things faster Rails is using a slightly different strategy**. Before running our
app it is requiring `*.rb` files to load as much of our code as possible. This way, when the app
starts running and serving requests it doesn't spend time looking where classes are on the file
system based on the convention but can server the request immediately.

There is also one more reason.
When the webserver (unicorn, passenger, whatever) is using forking model to spawn workers it can leverage
[Copy-On-Write](http://en.wikipedia.org/wiki/Copy-on-write) technique for memory managment. Master has
all the code loaded, workers are created by forking master. **Workers share some of the memory with master**
as long as it is not changed. It means that workers don't take as much memory as they would be but a lower
amount. They processes don't know they share the memory. They can't interact with each other that way.
It does not work like threads. It just the operating systems knows that for now instead of copying
entire memory of master process to fork process, it can omit doing it. At least until they all just
read from this memory. Check out more [how passenger describes it](https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html#spawning_methods_explained)
or this [digital ocean blgopost](https://www.digitalocean.com/community/tutorials/how-to-optimize-unicorn-workers-in-a-ruby-on-rails-app).

But what I want you to focus on is not that `Blog` constant is defined and eagerly loaded (that's nothing
new since many Rails versions ago). **I want you to notice that `Foo` constant is not loaded in production
environment**.

```
#!ruby
defined?(Blog)
# => "constant"

defined?(Foo)
# => nil
```

Why is that a problem? For the opposite reasons why eager loading is a good thing. When `Foo` is
not eager loaded it means that:

* when there is HTTP request hitting your app which needs to know about `Foo` to get finished, it
will be **served a bit slower**. Not much for a one class, but still. Slower. It needs to find `foo.rb`
in the directoriess and load this class.
* All **workers can't share in memory the code where `Foo` is defined**. The copy-on-write optimization
won't be used here.

If all that was for one class, that wouldn't be much problem. But with some legacy rails applications
I've seen them adding lot more directories to `config.autoload_paths`. And **not a single class from
those directories is eager loaded on production**. That can hurt the performance of few initial requests
after deploy that will need to dynamicaly load some of these classes. **This can be especially painful
when you practice continuous deployment. We don't want our customers to be affected by our deploys.**

## How can we fix it?

There is another, less known rails configuration called
`config.eager_load_paths` that we can use to achieve our goals.

```
#!ruby
config.eager_load_paths += %W( #{config.root}/extras )
```

How will that work on production? Let's see.

```
#!ruby
defined?(Blog)
# => "constant" 
defined?(Foo)
# => "constant" 
```

**Not only is our class/constant `Foo` from `extras/foo.rb` autoloaded now, but it
is also eager loaded in production mode. That fixed the problem.**

Wait, does it mean you need to write two lines instead of one from now on?

```
#!ruby
config.autoload_paths += %W( #{config.root}/extras )
config.eager_load_paths += %W( #{config.root}/extras )
```

## Autoloading is using eager loading paths as well

I doesn't seem so.

If you just use

```
#!ruby
config.eager_load_paths += %W( #{config.root}/extras )
```

development and production environments seem to be working just fine. I think because
autoloading is configured to check for eager loaded paths.

```
#!ruby
def _all_autoload_paths
  @_all_autoload_paths ||= (
    config.autoload_paths   + 
    config.eager_load_paths + 
    config.autoload_once_paths
  ).uniq
end
```

in [`Rails::Engine`](https://github.com/rails/rails/blob/v4.1.7/railties/lib/rails/engine.rb#L684)
code. 

## One more thing

Unfortunately I've seen many people doing things like

```
#!ruby
config.autoload_paths += %W( #{config.root}/app/services )
config.autoload_paths += %W( #{config.root}/app/presenters )
```

It is completely unnecessary because `app/*` is already added there. You 
can just add any directory to `app/` and start use it like you use
`app/controllers` and `app/models`. **You might however need to restart your
console, server or spring server (`spring stop`) for it start working**. You can see
the [default rails 4.1.7 paths configuration](https://github.com/rails/rails/blob/v4.1.7/railties/lib/rails/engine/configuration.rb#L38-72)

```
#!ruby
def paths
  @paths ||= begin
    paths = Rails::Paths::Root.new(@root)

    paths.add "app",                 eager_load: true, glob: "*"
    paths.add "app/assets",          glob: "*"
    paths.add "app/controllers",     eager_load: true
    paths.add "app/helpers",         eager_load: true
    paths.add "app/models",          eager_load: true
    paths.add "app/mailers",         eager_load: true
    paths.add "app/views"

    paths.add "app/controllers/concerns", eager_load: true
    paths.add "app/models/concerns",      eager_load: true

    paths.add "lib",                 load_path: true
    paths.add "lib/assets",          glob: "*"
    paths.add "lib/tasks",           glob: "**/*.rake"

    paths.add "config"
    paths.add "config/environments", glob: "#{Rails.env}.rb"
    paths.add "config/initializers", glob: "**/*.rb"
    paths.add "config/locales",      glob: "*.{rb,yml}"
    paths.add "config/routes.rb"

    paths.add "db"
    paths.add "db/migrate"
    paths.add "db/seeds.rb"

    paths.add "vendor",              load_path: true
    paths.add "vendor/assets",       glob: "*"

    paths
  end
end
```

Notice the `glob` for `paths.add "app", eager_load: true, glob: "*"` that
explains subdirectories of `app` working.

You can always verify your settings in the console with

```
#!ruby
Rails.configuration.autoload_paths
Rails.configuration.eager_load_paths
```

to be sure.

## `config.paths` and a conclusion

If you look at [`Rails::Engine::Configuration`](https://github.com/rails/rails/blob/v4.1.7/railties/lib/rails/engine/configuration.rb#L78-88)
a litle bit down the lines, you will see how these methods are defined:

```
#!ruby
def eager_load_paths
  @eager_load_paths ||= paths.eager_load
end

def autoload_once_paths
  @autoload_once_paths ||= paths.autoload_once
end

def autoload_paths
  @autoload_paths ||= paths.autoload_paths
end
```

They all delegate first call to `paths` which is `Rails.config.paths`.
**Which leads us to a conclusion that we could configure our `extras` directory
the same way Rails does it.**

```
#!ruby
config.paths.add "extras", eager_load: true
```

Isn't that nice?

## Warning

Don't confuse _eager loading of code_ with _eager loding of active record objects_
which [we also happen to have an article about](/2013/12/rails4-preloading/).
The numenclature they use is similar but they mean completely different things.

<%= inner_newsletter(item[:newsletter_inside]) %>
