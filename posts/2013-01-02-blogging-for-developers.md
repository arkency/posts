---
title: "Blogging for developers"
created_at: 2013-01-02 10:11:52 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :aar
tags: [ 'blog', 'nanoc']
---

There are many possible blogging platforms out there to be used, yet we decided not to use any of them.
It was a controversial decision even inside our own, small team. Before we started blogging there was
a heated discussion whether we should use something that can quickly get you running so that when you
feel in a mood for a blog post, there are no obstacles preventing you from writing. Or the alternative
was to build something custom and have more control. We ended up using existing tools
but put a little effort to combine them together into something that we like.

<!-- more -->

## Nanoc as a starting platform

We are developers, we use console daily, feel comfortable using it and prefer text over fancy GUI. We
like to be in control. But there is no need to reinvent the wheel so we started with
[nanoc](http://nanoc.stoneship.org/). It even comes with built-in helpers for blogging. Built with Ruby
so perfect fit for a company that started by creating Rails application. I won't go into much details
about Nanoc itself as you can read more about it [on its website](http://nanoc.stoneship.org/docs/1-introduction/)
and see basic [nanoc blog example on github](https://github.com/clarkdave/nanoc-blog-example). So Nanoc
gives us the bricks to build a house, a basic infrastructure or framework for blogging as some would call it
(because it seems that these days everything can be called a framework).

Pro:

* developers friendly
* markdown for writing blog posts
* rsync for deployment to our server
* written in Ruby (good for us, Ruby developers)

Cons:

* written in Ruby (bad for non-technical people, but we do not have such in our team)

## Responsive layout

About 20% of our traffic comes from mobile devices. I love reading blog posts on my mobile when
moving around the city. Especially those that are comfortable, so no wonder that it was important
for us to keep readers using mobile devices happy. We achieved it simply by using
[bourbon](https://github.com/thoughtbot/bourbon). You can see how our blog looks when using
different devices using [responsive.is](http://responsive.is/blog.arkency.com) (seriously, 
click the link to see it). Overall we are very happy with bourbon and started using it in
many other projects.

However we've been hit by one bug when using it with nanoc. You can read more about how to
[properly use bourbon and nanoc](http://dutygeeks.github.com/article/using-bouron/) on dutygeeks blog
and see [the issue on github](https://github.com/thoughtbot/bourbon/issues/68) if your are curious.

## Lightbox

I really like lightboxes for displaying images from posts. They work great on desktops. However I have
yet to see a lightbox that works great on desktop and mobile device. I tested dozen of them and every
one had an issue on mobile. Is it with zooming, taking too much space, bad navigation, poor performance, lack of
support for swipe, or too small button for closing the popup with image. So our solution is very simple.
We use lightbox on desktop and turn it off for mobiles. Clicking an image on mobile will simply display
the image itself using your mobile browser. And guess what... It works great. It is super fast,
pinch-to-zoom works flawlessly, the image is displayed with proper zoom and when you want to close it you
just press "Back" and browsers redirect you back to the previous page (the blog post) and position the
screen at the place where you finished reading. Works way better than any lightbox that I have tested.

However if you think that I am wrong and there is lightbox of such high quality, please leave a comment.
I would be more than happy to try it out.

## Images

For every image we generate additional 2 versions.

Thumbnail that can be used when displaying multiple
images in a gallery box:

<a href="/assets/images/blog-developers/gallery.png" rel="lightbox"><img src="/assets/images/blog-developers/gallery-fit.png" class="fit"></a>

And "fit" version that is as wide as it can be on a tablet in landscape position.

<a href="/assets/images/blog-developers/wide.png" rel="lightbox"><img src="/assets/images/blog-developers/wide-fit.png" class="fit"></a>

The code for doing that is pretty straightforward and uses ImageMagick `convert` binary:

```
#!ruby
class Thumbnailize < Nanoc::Filter
  identifier :thumbnailize
  type       :binary

  def run(filename, params={})
    system(
      'convert',
      '-resize',
      params[:width].to_s,
      filename,
      output_filename
    )
  end
end
```

```
#!ruby
compile '/assets/images/*/', rep: :thumbnail do
   filter :thumbnailize, :width => '160x160'
end

compile '/assets/images/*/', rep: :fit do
   filter :thumbnailize, :width => '530x530'
end

route '/assets/images/*', :rep => :thumbnail do
  item.identifier.chop + '-thumbnail.' + item[:extension]
end

route '/assets/images/*', :rep => :fit do
  item.identifier.chop + '-fit.' + item[:extension]
end
```

Other nice optimization are yet to be added such as:

* [image compression](http://dutygeeks.github.com/article/optipng/)
* [conversion to webp format](https://developers.google.com/speed/webp/)
* [supporting responsive images](https://blogs.adobe.com/webplatform/2012/09/19/responsive-images-for-html5/)

## Code

Nothing fancy here, we use good, old [pygments](http://pygments.org/) with
a [ruby wrapper](https://github.com/tmm1/pygments.rb) .

```
#!ruby
compile '/posts/*/' do
  filter :erb
  filter :redcarpet, options: {
    fenced_code_blocks: true, 
    autolink: true
  }
  filter :colorize_syntax, default_colorizer: :pygmentsrb
  layout 'post'
end
```

Does it look good ? You bet :) Here is an example:

```
#!ruby
class AviaryController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:create]

  def create
    @user = User.last
    @user.remote_avatar_url = params[:url]
    @user.save!
    head :created
  end
end
```

## Newsletter

If you ever read our blog before you might have noticed that we usually try to end our posts
with call to action. That is in most situations invitation to one of our newsletters or link to
[chillout.io landing page](http://chillout.io). Fortunately we don't need to add them
manually. Instead we use a feature of nanoc which let's you include
metadata to every post.

<a href="/assets/images/blog-developers/metadata.png" rel="lightbox"><img src="/assets/images/blog-developers/metadata-fit.png" class="fit"></a>

At the end of post layout file we use custom `#newsletter` helper method to output proper code
based on the metadata. If we ever decide to change it, we can do so in one place.

```
#!html+erb
<section class='metadata'>
  <p class='date'>
    <time datetime="<%%= post_date(item, :iso) %>" pubdate>
      <%%= post_date(item) %>
    </time>
  </p>
  <p class='author'>
    by <%%= item[:author] %>
  </p>
  <p class='tags'>
    <%%= tags_for(item, none_text: "", base_url: "#") %>
  </p>
  <p class='comments'>
    <a href='#disqus_thread'></a>
  </p>
</section>

<%%= yield %>

<%%= newsletter(item[:newsletter]) %>
```

Here is the simplified version of the helper:

```
#!ruby
module NewsletterHelper
  Newsletters = {
    arkency: {
      url: "http://eepurl.com/mD-Hn",
      action: "Subscribe to our tech newsletter.",
      ad: "Sharpen the saw."
    },

    chillout: {
      url: "http://chillout.io",
      action: "Chill Out",
      ad: "And Impress Your Customers"
    },
  }

  def newsletter_link(type, newsletter)
    html = <<-HTML
      <a href="#{newsletter.url}" data-event-category="newsletter" data-event-action="#{type}" data-event-label="after post">#{newsletter.action}<br><strong>#{newsletter.ad}</strong></a>
    HTML
  end

  def newsletter(type)
    newsletter = OpenStruct.new Newsletters[type]
    inner_html = newsletter_link(type, newsletter)
    html = <<-HTML
      <section class="newsletter newsletter-#{type}">
        #{inner_html}
      </section>
    HTML
    html
  end
end
```

Thanks to custom google analytics events we can easily track user actions on our blog.
We described this technique in our
[previous "Google Analytics for developers" post](/2012/12/google-analytics-for-developers/)

## Beta

Before we publish a new post we first ask for opinion our coworkers. We show them new entries by
deploying to different internal host visible only for those connected via VPN. Nanoc supports
multiple deployments natively in `config.yaml` :

```
#!yaml
deploy:
  default:
    kind: rsync
    dst:  "blog@production-blog.arkency:current/public"
    options: ['-gpPrtvz', '--delete-after']
  beta:
    kind: rsync
    dst:  "blog@staging-blog.arkency:current/public"
    options: ['-gpPrtvz', '--delete-after']
```

## Hosting

We host our blog in our own infrastructure that we manage with chef for our customers. It is built
around LXC containers and our blog requires only nginx for serving it. It works nicely even when
you hit front page of Hacker News or Reddit. And if we decide
to [serve our blog using SPDY](https://twitter.com/arkency/status/277890218340806656) there is
nothing to stop us.

You can expect more blog posts about the infrastructure and SPDY experiment soon.

## Conclusion

You might be tempted to say that this is lot of effort just to have a company blog. Probably you are right,
but on the other hand we have fun, knowledge and area for experiments that teach us valuable lessons
and can be further used in other, commercial projects.

Blogging and sharing knowledge is one thing, having fun and learning new things is another.
But nobody said we cannot mix those two. Blog is an important medium for us to communicate our ideas
but also is a little toy project. Do you have a toy project in your company
to test your crazy ideas in the wild ?
