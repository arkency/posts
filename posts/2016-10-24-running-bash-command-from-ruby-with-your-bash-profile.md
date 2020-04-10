---
title: "Running bash command from Ruby (with your bash_profile)"
created_at: 2016-10-24 13:14:46 +0200
publish: true
tags: [ 'ruby' ]
author: Andrzej Krzywda
---

Whenever I try to automate some of my daily tasks, I end up with a mix of Ruby and Bash scripts. This is the time when I look up to the differences between `system`, `exec`, `%x`, backticks and others.

However, there's additional thing with actually executing a bash script not just shell script.


<!-- more -->

Yesterday I've been optimizing my blogging flow. One part of it is to open my favourite editor with the current draft file.

Until yesterday I did it manually. I've had this in my `bash_profile`:

```
alias ia="open $1 -a /Applications/iA\ Writer.app/Contents/MacOS/iA\ Writer"
```

so just typing `ia content/posts/a_long_path_to_the_file.md` was opening the editor.

Now, I have a script which not only generates the draft file, but also git pushes it, opens the browser to preview it and opens the editor.

```
  def call
    create_local_markdown_file_based_on_template
    git_add_commit_push
    open_browser_with_production_url
    open_draft_in_editor
  end
```

See my previous blogpost to [read more about this specific Ruby service object](http://blog.arkency.com/2016/10/the-esthetics-of-a-ruby-service-object/)

The thing is, if you just use `system` it's not enough. You need to invoke `bash` in a special mode `-ilc` to actually get the `bash_profile` loaded. Otherwise, the `ia` alias is not recognized.

So, I ended up with this:

```ruby
  def open_draft_in_editor
    system("bash", "-lic", "ia #{path}")
  end
```

Which works great so far. It helped me speeding up my blogging process and hopefully will result in more blogposts ;)

Happy blogging!

-----

BTW, if you want to improve your blogging skils, my "Blogging for Busy Programmers" book is now part (for a limited time) of the [Smart Income For Developers bundle](http://www.smartincomefordevelopers.com). Check it out!
