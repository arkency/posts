---
title: "The esthetics of a Ruby service object"
created_at: 2016-10-23 20:55:15 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

A service object in Ruby has some typical elements. There are some minor difference which I noted in the way people implement them. Let's look at one example.

<!-- more -->

This example may be a bit unusual, as it doesn't come from a Rails codebase. The service object actually comes from the engine of this very own blog. The blog is nanoc-based and the service object is used to locally generate a new draft of a blogpost.

You can read the first part of the story in the blogpost where I talked how this [service object was extracted](http://blog.arkency.com/2015/03/extract-a-service-object-in-any-framework/) from a previous script.

The final result was the following:

```
#!ruby

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
```


Today, I was trying to optimize and automate my blogging flow. This involved:

- managing the typical git commands (add/commit/push) 
- opening the draft in the browser
- opening the editor of my choice (iaWriter)

The code ended up looking like this:

```
#!ruby
class PublishNewDraftFromAndrzejTemplate

  def initialize(title, date)
    @title = title
    @date  = date
  end

  def call
    create_local_markdown_file_based_on_template
    git_add_commit_push
    open_browser_with_production_url
    open_draft_in_browser
  end
  
  ...
end
```

When I tweeted it (just the call method), I've got one interesting reply from my friend who is not working with Ruby:

<blockquote class="twitter-tweet" data-conversation="none" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/andrzejkrzywda">@andrzejkrzywda</a> this may actually convince me to use <a href="https://twitter.com/hashtag/ruby?src=hash">#ruby</a>....</p>&mdash; Pawel Klimczyk (@pwlklm) <a href="https://twitter.com/pwlklm/status/790214598255382530">October 23, 2016</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

followed by this:

<blockquote class="twitter-tweet" data-conversation="none" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/psmyrdek">@psmyrdek</a> <a href="https://twitter.com/andrzejkrzywda">@andrzejkrzywda</a> not lines, rather the pure simplicity in code. This awesome.</p>&mdash; Pawel Klimczyk (@pwlklm) <a href="https://twitter.com/pwlklm/status/790257330755661824">October 23, 2016</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

which got me thinking and inspired to write this blogpost (thanks Paweł!).



