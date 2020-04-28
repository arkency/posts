---
title: Practical use of Ruby PStore
created_at: 2020-04-28T20:00:00.000Z
author: Paweł Pacana
tags: ['ruby', 'nanoc']
publish: true
---

Arkency blog has undergone several improvements over recent weeks. One of such changes was opening [the source of blog articles](https://github.com/arkency/posts). We've have concluded that having posts in the open would shorten the feedback loop and allow our readers to [collaborate](https://github.com/arkency/posts/pull/3#issuecomment-611449023) and make [the](https://github.com/arkency/posts/pull/1) [articles](https://github.com/arkency/posts/pull/2) [better](https://github.com/arkency/posts/pull/3) for all.

## Nanoc + Github

For years the blog has been driven by [nanoc](https://nanoc.ws), which is a static-site generator. You put a bunch of markdown files in, drop a layout and on the other side out of it comes the HTML. Let's call this magic "compilation". One of nanoc prominent features is [data sources](https://nanoc.ws/doc/data-sources/). With it one could render content not only from a local filesystem. Given appropriate adapter posts, pages or other data items can be fetched from 3rd party API. Like SQL database. Or Github!

Choosing Github as a backend for our posts was no-brainer. Developers are familiar with it. It has quite a nice integrated web editor with Markdown preview — which gives in-place editing. Pull requests create the space for discussion. Last but not least there is [octokit gem](https://github.com/octokit/octokit.rb) for API interaction, taking much of the implementation burden out of our shoulders.

An initial data adapter looked like this to fetch articles looked like this:

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

Making those requests parallel will only make the process of hitting request quota faster. Something has to be done to limit number of requests that are needed. 

Luckily enough octokit gem used [faraday](https://github.com/lostisland/faraday) library for HTTP interaction and some kind souls [documented](https://github.com/octokit/octokit.rb#caching) how one could leverage [faraday-http-cache](https://github.com/sourcelevel/faraday-http-cache) middleware.

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

Notice two main additions here:

- the `up` method, used by nanoc when spinning the data source, which introduces cache middleware
- `Concurrent::FixedThreadPool` from [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby) gem for concurrent requests in multiple threads

If only that cache worked... Faraday ships with in-memory cache, which is useless for the flow of work one has with nanoc. We'd very much like to persist the cache across runs of the compile process. Documentation indeed shows how one could switch cache backend to one from Rails but that is not helpful advice in nanoc context either. You probably wouldn't like to start Redis or Memcache instance just to compile a bunch of HTML!

Time to roll-up sleeves again. Knowing what API is expected, we can build file-based cache backend. And there little-known standard library gem we could use to free ourselves of reimplementing the basics again. So much for standing on the shoulders of giants again.


## Enter PStore

[PStore](https://ruby-doc.org/stdlib-2.7.0/libdoc/pstore/rdoc/PStore.html) is a file based persistence mechanism based on a Hash. We can store Ruby objects — they're serialized with [Marshal](https://ruby-doc.org/core-2.7.0/Marshal.html) before being dumped on disk. It supports transactional behaviour and can be made [thread safe](https://blog.arkency.com/3-ways-to-make-your-ruby-object-thread-safe/). Sounds perfect for the job!

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

In the end that cache store turned out to be merely a wrapper on pstore. How convenient! Thread safety is achieved here by using Mutex internaly around `transaction` block.

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

With persistent cache store plugged into Faraday we can now reap benefits of cached responses. Subsequent requests to Github API are skipped. Responses are being served directly from local files. That is, as long as the cache stays fresh..

Cache validity can be controlled by several [HTTP headers](https://www.keycdn.com/blog/http-cache-headers). In case of Github API it is the `Cache-Control: private, max-age=60, s-maxage=60` that matters. Together with `Date` header this roughly means that the content will be valid for 60 seconds since the response was received. Is it much? For frequently changed content — probably. For blog articles I'd prefer something more long-lasting…

And that is how we arrive to the last piece of [nanoc-github](https://github.com/pawelpacana/nanoc-github). A faraday middleware to allow extending cache time. It is a quite primitive piece of code that substitutes max-age value to the desired one. For my particular needs I set this value 3600 seconds. 
The general idea is that we modify HTTP responses from API before they hit the cache. Then the cache middleware examines cache validity based on modified age, rather than original one. Simple and good enough. Just be careful to add this to middleware stack in correct order 😅

```ruby
class ModifyMaxAge < Faraday::Middleware
  def initialize(app, time:)
    @app  = app
    @time = Integer(time)
  end

  def call(request_env)
    @app.call(request_env).on_complete do |response_env|
      response_env[:response_headers][:cache_control] = "public, max-age=#{@time}, s-maxage=#{@time}"
    end
  end
end
```

And that's it! I hope you found this article useful and learned a bit or two. Drop me a line on [my twitter](https://twitter.com/pawelpacana) or leave a star on this project:

<div class="mt-4 github-card" data-github="pawelpacana/nanoc-github" data-width="400" data-height="" data-theme="default"></div>
<script src="//cdn.jsdelivr.net/github-cards/latest/widget.js"></script>


Happy hacking!
