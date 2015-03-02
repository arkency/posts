---
title: "Extract a service object in any framework"
created_at: 2015-03-02 15:10:14 +0100
kind: article
publish: false
author: Andrzej Krzywda
---

Extracting a service object is a natural step in any kind of framework-dependent application. In this blog post, I’m showing you an example from Nanoc, a blogging framework.

<!-- more -->

#### Framework calls you

The difference between a library and a framework is that you call the library, while the framework calls you.

This slight difference may cause problems in applications being too dependent on the framework. 

The “Extract a service object” refactoring is a way of dealing with the situation. In short, you want to extract everything that is not framework-related to a new class. At the same time, you keep all the framework-related code in the previous place.

A typical example is a Rails controller action. An action is a typical framework building block. It’s responsible for several things, including all the HTTP-related features like rendering html/json or redirecting.
Everything else is probably your application code and there are gains in extracting it into a new class.

#### Before

We’re using the nanoc tool for blogging in our Arkency blog. It serves us very well, so far. One place, where we extended it was a custom [Nanoc command](http://nanoc.ws/docs/basics/).

The command is called “create-post” and it’s just a convenience function to automate the file creation with a proper URL generation.

Here is the code:

```
#!ruby
require 'stringex'

usage       'create-post [options] title'
aliases     :create_post, :cp
summary     'create a new blog post'
description 'Creates new blog post with standard template.'

flag :h, :help,  'show help for this command' do |value, cmd|
  puts cmd.help
  exit 0
end

run do |opts, args, cmd|
  unless title = args.first
    puts cmd.help
    exit 0
  end

  date = Time.now
  path = "./content/posts/#{date.strftime('%Y-%m-%d')}-#{title.to_url}.md"
  template = <<TEMPLATE
---
title: "#{title}"
created_at: #{date}
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
---
TEMPLATE

  unless File.exist?(path)
    File.open(path, 'w') { |f| f.write(template) }
      puts "Created post: #{path}"
  else
    puts "Post already exists: #{path}"
    exit 1
  end

  puts "URL: http://blog.arkency.com/#{date.year}/#{date.month}/#{title.to_url}"
end
````

It was serving us well for over 3 years without any change. I'm extracting it to a service object, mostly as an example to show how it would work. 

#### After

````
#!ruby
require 'stringex'

usage       'create-post [options] title'
aliases     :create_post, :cp
summary     'create a new blog post'
description 'Creates new blog post with standard template.'

flag :h, :help,  'show help for this command' do |value, cmd|
  puts cmd.help
  exit 0
end

run do |opts, args, cmd|
  unless title = args.first
    puts cmd.help
    exit 0
  end
  CreateNewPostFromTemplate.new(title, Time.now).call
end


class CreateNewPostFromTemplate

  def initialize(title, date)
    @title = title
    @date  = date
  end

  def call
    unless File.exist?(path)
      File.open(path, 'w') { |f| f.write(template(@title, @date)) }
      puts "Created post: #{path}"
    else
      puts "Post already exists: #{path}"
      exit 1
    end

    puts "URL: #{likely_url_on_production}"
  end

  private

  def path
    "./content/posts/#{@date.strftime('%Y-%m-%d')}-#{@title.to_url}.md"
  end

  def likely_url_on_production
    "http://blog.arkency.com/#{@date.year}/#{@date.month}/#{@title.to_url}"
  end

  def template(title, date)
    <<TEMPLATE
---
title: "#{title}"
created_at: #{date}
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
---

TEMPLATE
  end
end
````


I've created a new class and passed the arguments into it. The new class is not aware of nanoc in any way. While doing it, I've also extracted some small method to hide implementation details. Thanks to that the main algorith is a bit more clear.

There's more we could do at some point, like isolating from the file system. However, for this exercise, this effect is enough.

If you're interested in such refactoring, you may consider looking at the book I wrote: [Fearless Refactoring: Rails Controllers](http://rails-refactoring.com). This book consists of 3 parts - the refactoring recipes, the bigger examples and the "theory" chapter. Thanks to that you not only learn how to apply a refactoring but also know what are the future building blocks, like service objects, repositories, form objects and adapters.

