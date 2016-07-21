---
title: "respond_to |format| is useful even without multiple formats"
created_at: 2016-07-21 16:39:29 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'respond_to', 'format' ]
---

You might think that if a controller action is only
capable of rendering HTML, there is not much reason
to use `respond_to`. After all, this is what
Rails scaffold probably taught you.

<!-- more -->

```
#!ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

There is, however, one very annoying situation in which
this code will lead to an exception: when a silly client
asks to get your page in XML format.

Try for yourself:

```
curl -H "Accept: application/xml" localhost:3000/posts
```

You will get an exception:

```
Missing template posts/index, ... :formats=>[:xml]
```

The client will get `500` error indicating that the
problem was on the server side.

```
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <status>500</status>
  <error>Internal Server Error</error>
</hash>
```

This problem will be logged by an
exception tracker, that you use for your Rails app.
However, there is nothing we can do about the
fact that someone out there thinks they can get
a random page in our app via XML. We don't need
a notification every time that happens. And the
bigger your website, the more often such random
crap happens.

But we also don't want to ignore those errors completely
when they occur. There could be a situation in
which they can help us catch a real problem i.e.
a refactoring which went wrong.

How can we fix the situation? Just add `respond_to`
section indicating which formats we support.
You don't even need to pass a block to `html`
method call.

```
#!ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
    respond_to do |format|
      format.html
    end
  end
end
```

Alternatively, you can go with `respond_to :html`.
But that itself is not sufficient and requires
using it together with `respond_with`.

```
#!ruby
class PostsController < ApplicationController
  respond_to :html

  def index
    @posts = Post.all
    respond_with @posts
  end
end
```

After such change, the client will get `406` error
when the format is not supported.

```
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <status>406</status>
  <error>Not Acceptable</error>
</hash>
```

And _missing template_ exception leading to `500` error code
will occur only when you really have a problem with the template
for supported MIME types (HTML in our example).

P.S. If you haven't heard yet, [Post-Rails Way Book Bundle](http://www.railsbookbundle.com/)
is ending soon. With 55% discount you can buy 8 products that will help you a lot. Especially
if you work with bigger or legacy Rails applications. Enjoy!
