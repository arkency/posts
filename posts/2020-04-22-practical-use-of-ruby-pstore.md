---
title: Practical use of Ruby PStore
created_at: 2020-04-22T21:27:22.797Z
author: Paweł Pacana
tags: ['ruby', 'nanoc']
publish: false
---

Arkency blog has undergone several improvements over recent weeks. One of such changes was opening [the source of blog articles](https://github.com/arkency/posts). We've have concluded that having posts in the open would shorten the feedback loop and allow our readers to [collaborate](https://github.com/arkency/posts/pull/3#issuecomment-611449023) and make [the](https://github.com/arkency/posts/pull/1) [articles](https://github.com/arkency/posts/pull/2) [better](https://github.com/arkency/posts/pull/3) for all.

## Nanoc + Github

For years this blog has been driven by [nanoc](https://nanoc.ws), which is a static-site generator. One of its prominent features is [data sources](https://nanoc.ws/doc/data-sources/). One could render content not only from a local filesystem. With appropriate adapter posts, pages or other data items can be fetched from 3rd party API. Like SQL database. Or Github!

Choosing Github as a backend for posts was no-brainer. Developers are familiar with it. It has quite a nice integrated web editor with Markdown preview — this gives in-place editing. Pull requests create the space for discussion. Last but not least there is [octokit gem](https://github.com/octokit/octokit.rb) for API interaction, taking much of the implementation burden out of our shoulders.

An initial data adapter looked like this:

```ruby
class Source < Nanoc::DataSource
  identifier :github

  def items
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    client
      .contents(ENV['GITHUB_REPO'])
      .select { |item| item.end_with?(".md") }
      .map    { |item| client.contents(ENV['GITHUB_REPO'], path: item[:path]) }
      .map    { |item| new_item(item[:content], item, Nanoc::Identifier.new(item[:path])) }  
  end
end
```

This code:

- gets a list of files in repository
- filters it by extension to only let markdowns stay
- gets content of each markdown file
- transforms it into a nanoc item object

Good enough for a quick spike and exploration of the problem. Becomes problematic as soon as you start using it *for real*. Can you spot the problems?

## Source data improved

For a repository with 100 markdown files we will have to make 100 + 1 HTTP requests in order to retrieve the content

- it takes time and becomes annoying when you're in the change-layout-recompile-content cycle of the work on the site 
- there is an API request limit per hour (slightly bigger when using token but still present)

Making those requests parallel will only make the process of hitting request quota faster. Something has to be done to limit number of requests we need. 

Luckily enough octokit gem used faraday library for HTTP interaction and some kind souls [documented](https://github.com/octokit/octokit.rb#caching) how one could leverage faraday-http-cache middleware.

```ruby
class Source < Nanoc::DataSource
  identifier :github

  def up
    stack = Faraday::RackBuilder.new do |builder|
      builder.use Faraday::HttpCache,
                  serializer: Marshal,
                  shared_cache: false
      builder.use Faraday::Request::Retry,
                  exceptions: [Octokit::ServerError]
      builder.use Octokit::Middleware::FollowRedirects
      builder.use Octokit::Response::RaiseError
      builder.use Octokit::Response::FeedParser
      builder.adapter Faraday.default_adapter
    end
    Octokit.middleware = stack
  end

  def items
    repository_items.map do |item|
      identifier     = Nanoc::Identifier.new("/#{item[:name]}")
      metadata, data = decode(item[:content])

      new_item(data, metadata, identifier, checksum_data: item[:sha])
    end
  end

  private

  def repository_items
    pool  = Concurrent::FixedThreadPool.new(10)
    items = Concurrent::Array.new
    client
      .contents(repository, path: path)
      .select { |item| item[:type] == "file" }
      .each   { |item| pool.post { items << client.contents(repository, path: item[:path]) } }
    pool.shutdown
    pool.wait_for_termination
    items
  rescue Octokit::NotFound => exc
    []
  end

  def client
    Octokit::Client.new(access_token: access_token)
  end

  def repository
    # ...
  end
  
  def path
    # ...
  end

  def access_token
    # ...
  end

  def decode(content)
    # ...
  end
end
```

Notice two main additions:

- `up` method used by nanoc when spinning the data source, which introduces cache middleware
- `Concurrent::FixedThreadPool` from `ruby-concurrency` gem for parallel requests (which are mostly I/O)

If only that cache worked... Faraday ships in-memory cache, which is useless for the flow of work one has with nanoc. We'd like to persist the cache across compile process runs. Documentation shows how one could switch cache backend to one from Rails, which is not helpful advice in nanoc context either. 

Time to roll-up sleeves again. Documenation [clarifies]() what API is expected from such cache backend. And there little-known standard library gem we could use to free ourselves of reimplementing the basics again.


## Enter PStore

```ruby
class Cache
  def initialize(cache_dir)
    @store = PStore.new(File.join(cache_dir, "nanoc-github.store"), true)
  end

  def write(name, value, options = nil)
    store.transaction { store[name] = value }
  end

  def read(name, options = nil)
    store.transaction(true) { store[name] }
  end

  def delete(name, options = nil)
    store.transaction { store.delete(name) }
  end

  private
  attr_reader :store
end
```

```ruby
class Source < Nanoc::DataSource
  identifier :github

  def up
    stack = Faraday::RackBuilder.new do |builder|
      builder.use Faraday::HttpCache,
                  serializer: Marshal,
                  shared_cache: false,
                  store: Cache.new(tmp_dir)
      # ...            
    end
    Octokit.middleware = stack
  end
end 
```






