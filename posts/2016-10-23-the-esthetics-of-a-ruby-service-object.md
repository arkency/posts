---
title: "The esthetics of a Ruby service object"
created_at: 2016-10-23 20:55:15 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

A service object in Ruby has some typical elements. There are some minor difference which I noted in the way people implement them. Let's look at some examples.

<!-- more -->

```
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

