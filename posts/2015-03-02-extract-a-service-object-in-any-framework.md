---
created_at: 2015-03-02 15:10:14 +0100
publish: true
tags: [ 'rails', 'refactoring', 'service objects' ]
author: Andrzej Krzywda
---

# Extract a service object in any framework

Extracting a service object is a natural step in any kind of framework-dependent application. In this blog post, I’m showing you an example from Nanoc, a blogging framework.

<!-- more -->

#### The framework calls you

The difference between a library and a framework is that you call the library, while the framework calls you.

This slight difference may cause problems in applications being too dependent on the framework. Another potential problem is when your app lives inside the framework code.

The ideal situation seems to be when your code is separated from the framework code.

The “Extract a service object” refactoring is a way of dealing with the situation. In short, you want to **separate your code from the framework code**. 

A typical example is a Rails controller action. An action is a typical framework building block. It’s responsible for several things, including all the HTTP-related features like rendering html/json or redirecting.
Everything else is probably your application code and there are gains in extracting it into a new class.

#### Before

We’re using the nanoc tool for blogging in our Arkency blog. It serves us very well, so far. One place, where we extended it was a custom [Nanoc command](http://nanoc.ws/docs/basics/).

The command is called “create-post” and it’s just a convenience function to automate the file creation with a proper URL generation.

Here is the code:

```ruby
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
created_at: #{date}
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
---

# #{title}

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

````ruby
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
created_at: #{date}
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
---

# #{title}

TEMPLATE
  end
end
````


I've created a new class and passed the arguments into it. While doing it, I've also extracted some small methods to hide implementation details. Thanks to that the main algorith is a bit more clear.

There's more we could do at some point, like isolating from the file system. However, for this refactoring exercise, this effect is enough. It took me about 10 minutes to do this refactoring. I don't need to further changes now, it's OK to do it in small steps.

It's worth to consider this techniqe whenever you use any framework, be it Rails, Sinatra, nanoc or anything else that calls you. **Isolate early**.

If you're interested in such refactorings, you may consider looking at the book I wrote: [Fearless Refactoring: Rails Controllers](http://rails-refactoring.com). This book consists of 3 parts: 

* the refactoring recipes, 
* the bigger examples,  
* the "theory" chapter

Thanks to that you not only learn how to apply a refactoring but also know what are the future building blocks. The building blocks include service objects, repositories, form objects and adapters.

