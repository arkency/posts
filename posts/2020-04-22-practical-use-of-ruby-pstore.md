---
title: Practical use of Ruby PStore
created_at: 2020-04-22T21:27:22.797Z
author: Paweł Pacana
tags: ['ruby', 'nanoc']
publish: false
---

Arkency blog has undergone several improvements over recent weeks. One of such changes was opening [the source of blog articles](https://github.com/arkency/posts). We've have concluded that having posts in the open would shorten the feedback loop and allow our readers to [collaborate](https://github.com/arkency/posts/pull/3#issuecomment-611449023) and make [the](https://github.com/arkency/posts/pull/1) [articles](https://github.com/arkency/posts/pull/2) [better](https://github.com/arkency/posts/pull/3) for all.

For years this blog has been driven by [nanoc](https://nanoc.ws), which is a static-site generator. One of its prominent features is [data sources](https://nanoc.ws/doc/data-sources/). One could render content not only from a local filesystem. With appropriate adapter posts, pages or other data items can be fetched from 3rd party API. Like SQL database. Or Github!

Choosing Github as a backend for posts was no-brainer. Developers are familiar with it. It has quite nice and integrated web editor with Markdown preview — this gives in-place editing. Pull requests create the space for discussion. Last but not least there is [octokit gem](https://github.com/octokit/octokit.rb) for API interaction, taking much of the implementation burden out of our shoulders.

An initial data adapter looked like this:

```ruby
class Source < ::Nanoc::DataSource
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

FIXME:
- problems with naive data source
- faraday and middleware
- http cache
- pstore pesistent cache
- bonus: max-age
- nanoc-github promo





