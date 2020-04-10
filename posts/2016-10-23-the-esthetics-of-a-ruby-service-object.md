---
title: "The esthetics of a Ruby service object"
created_at: 2016-10-23 20:55:15 +0200
kind: article
publish: true
tags: [ 'rails', 'ruby', 'service objects' ]
author: Andrzej Krzywda
---

A service object in Ruby has some typical elements. There are some minor difference which I noted in the way people implement them. Let's look at one example.

<!-- more -->

This example may be a bit unusual, as it doesn't come from a Rails codebase. The service object actually comes from the engine of this very own blog. The blog is nanoc-based and the service object is used to locally generate a new draft of a blogpost.

You can read the first part of the story in the blogpost where I talked how this [service object was extracted](http://blog.arkency.com/2015/03/extract-a-service-object-in-any-framework/) from a previous script.

The final result was the following:

```ruby

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
end
```


Today, I was trying to optimize and automate my blogging flow. This involved:

- managing the typical git commands (add/commit/push) 
- opening the draft in the browser
- opening the editor of my choice (iaWriter)

The code ended up looking like this:

```ruby
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


```ruby

  def call
    create_local_markdown_file_based_on_template
    git_add_commit_push
    open_browser_with_production_url
    open_draft_in_browser
  end
```

What we see here, is a typical run/execute/call method (I've settled with "call") which orchestrates other parts. The naming is a bit verbose but also quite explicit in describing what it does.

There's something Ruby-specific which makes the code appealing to certain developers. This was probably the part which brought me to Ruby back in 2004 (and I still didn't find a programming language which would be more esthetically appealing to me than Ruby!).

The lack of braces is one thing.

Then there's the **dynamic typing**, resulting in no type declaration. Less verbose thanks to that.

There's also a design choice here - **there's lack of params being passed**. The "call" method doesn't take anything, nor the other methods.

However, in fact, they do use some input data, but those 2 variables are set in the constructor method. This means that we can access them via "@title" and "@date" instance variables.

There are additional 7 private methods here, which are using the instance variables.

The topic of service objects in Rails apps was so fascinating to me that I wrote [a whole book](http://rails-refactoring.com) about it. One realisation I've had over my time spent on service objects is their connection to functions and to functional programming. Some people call them function objects or commands. My architectural journey led me to discover the beauty of Domain-Driven Development and CQRS (Command Query Responsibility Segregation). 

At some point, all those pieces started to fit together. I'm now looking at code in a more functional way. What I was doing with my "Rails Refactoring" actions was actually about **localizing the places where data gets mutated**.

In fact, [my current Rails/DDD teaching](http://blog.arkency.com/ddd-training/) how to build Rails apps feels almost like Functional Programming. 

So, the question appears - is this service object functional?

I'm not aware of all FP techniques, but being explicit with input/output of each function is one of the main rules, as I understand. Which means, that the 8 methods of my service object are not functional at all.

(the part of this object which **mutates the whole world around** - file system, git repo, operating system - is also not helping in calling it functional).

But let's focus on the input arguments part. What if we explicitly add them?

```ruby

  def call(title, date)
    create_local_markdown_file_based_on_template(title, date)
    git_add_commit_push(title, date)
    open_browser_with_production_url(title, date)
    open_draft_in_browser(title, date)
  end
```

Given that this post is about esthethics and it's always a subject to personal opinion - I'd say it's worse now. It's more verbose, it's even too explicit.

But there's one part which makes this new code better. As a big refactoring fan, I can tell that **when each method is explicit about the input it needs, the code is much more friendly towards extracting new classes and methods**.

In this specific situation, the estethics won over the being refactoring-friendly :)

What's your take on the esthetics here?
