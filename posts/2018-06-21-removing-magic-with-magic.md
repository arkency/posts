---
title: "Removing magic with magic"
created_at: 2018-06-21 16:34:39 +0200
kind: article
publish: true
author: Rafał Łasocha
tags: [ 'legacy', 'removing code' ]
newsletter: :arkency_form
img: "removing_magic_with_magic.jpg"
---

<%= img_fit("removing_magic_with_magic.jpg") %>

Some gems, like InheritedResources, help us by reducing the lines of code we have to write by providing definitions automatically. However, depending on how the gem is written, it can be done "magically". In some cases, we want to remove such gems.

<!-- more -->

By "magic" I obviously mean defining methods, or in this case, controller actions, without any explicit call to the functions provided by this gem. Such implicit behaviour makes life on legacy codebases harder. It's harder to remove the feature (or model), because how do we know whether it is used or not? Similarly, it is harder to add feature correctly, because it's easy to overlook some dependency or usecase which is available in our program. That can lead to sad bugs, where we have overlooked something and our code breaks.

That said, I wanted to remove the gem from one of ours applications. There was only one explicit usage...

```ruby
class Admin::BaseController < InheritedResources::Base
  ...
end
```

And `BaseController` was a parent for every controller used in admin panel, so the implicit actions could be in ANY of these controller. Well, that's not easy to clean up. How do you safely remove such gem, if you don't know where it is even used? Obviously one could just remove the gem and watch production burn, but you don't have to be that brutal.
You can fight magic with magic :)

This is the moment where you are actually thankful for having open classes in Ruby. I've written following code and dynamically extended `InheritedResources` gem with additional behaviour, which would notify me where it is used.

```ruby
module InheritedResourcesRemoval
  InheritedResourcesUsed = Class.new(StandardError)

  def index(options = {}, &block)
    Honeybadger.notify(InheritedResourcesUsed.new("Inherited resources used at controller `#{params[:controller]}` and action `#{params[:action]}`"))
    super(options, &block)
  end

  def show(options = {}, &block)
    Honeybadger.notify(InheritedResourcesUsed.new("Inherited resources used at controller `#{params[:controller]}` and action `#{params[:action]}`"))
    super(options, &block)
  end

  def new(options = {}, &block)
    Honeybadger.notify(InheritedResourcesUsed.new("Inherited resources used at controller `#{params[:controller]}` and action `#{params[:action]}`"))
    super(options, &block)
  end

  def edit(options = {}, &block)
    Honeybadger.notify(InheritedResourcesUsed.new("Inherited resources used at controller `#{params[:controller]}` and action `#{params[:action]}`"))
    super(options, &block)
  end

  def create(options = {}, &block)
    Honeybadger.notify(InheritedResourcesUsed.new("Inherited resources used at controller `#{params[:controller]}` and action `#{params[:action]}`"))
    super(options, &block)
  end

  def update(options = {}, &block)
    Honeybadger.notify(InheritedResourcesUsed.new("Inherited resources used at controller `#{params[:controller]}` and action `#{params[:action]}`"))
    super(options, &block)
  end

  def destroy(options = {}, &block)
    Honeybadger.notify(InheritedResourcesUsed.new("Inherited resources used at controller `#{params[:controller]}` and action `#{params[:action]}`"))
    super(options, &block)
  end
end
```

Now we only need to open one specific module and prepend our hack into it:

```ruby
module InheritedResources
  module Actions
    prepend(::InheritedResourcesRemoval)
  end
end
```

As you can see, each time one of the methods is used, I get notification on Honeybadger, with exact controller and action where it is used. One could now use [automatic rewrites using parser gem](/rewriting-deprecated-apis-with-parser-gem/) to add the necessary code, but in my case it was only a few actions where it was used, so it was not worth it. I've just manually wrote couple lines of controller code and respectively changed the views in order to not use byzantine `@resource` variable name.

After few weeks of this code in production, I've removed the code and safely removed the gem :)

### Enjoyed reading?

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our every day struggles and solutions for building maintainable Rails apps which don't surprise you.
You might also like:

* [Rewriting deprecated APIs with parser gem](/rewriting-deprecated-apis-with-parser-gem/)

* [Using Ruby parser and the AST tree to find deprecated syntax](/using-ruby-parser-and-ast-tree-to-find-deprecated-syntax/) — when `grep` is just not good enough

