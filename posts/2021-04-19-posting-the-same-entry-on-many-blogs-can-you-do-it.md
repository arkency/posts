---
created_at: 2021-04-19T13:08:16.313Z
author: Paweł Pacana
tags: ['blogging', '5days5blogposts']
publish: true
---

# Write once, publish in many places, keep SEO happy

One of the questions that we frequently receive on [arkademy blogging course](https://arkademy.dev) is about reusing and sharing the same post multiple times:

> When you got your own blog, do you blog only on this website, or you can blog on platform like Medium or dev.to too? If you blog on many sites, do you centralize all blog’s titles somewhere or do you duplicate the content on your blog?

## Why to re-publish the content

Before diving into technical aspects of reusing your blog content, let's examine the reasons why you'd may want to do it in first place.

### Starting blogging on a blogging platform but moving to your own website later

Blogging is great. When you're a developer starting this journey, it is unfortunately very easy to fall into a trap of doing your own blog platform or engine first. Endless layout tweaks, picking fonts, code example highlighting, comment system and whatnot. It is interesting for sure! When you're just beginning blogging it may quickly wear off all your initial enthusiasm. It's a way to procrastinate instead of writing too.
  
Instead — start on an existing platform. Accept all of the platform limitations. Let it help you taking away the distractions for writing. You're not deciding on service permanently after all. Write your first ten or twenty blogposts there. And only then consider moving to your own website. 

When moving, most of the time you can export and take all of your posts. Then re-publish them on your website.
  
  
### Blogging on your website, reposting on blogging platforms for greater reach

You have your own blog. Maybe it is this fancy static-site kind of blog. Or it's a Wordpress installation. It doesn't matter.
	
What matters is getting your message through. You can write for your own sake but your posts won't help anyone if people can't reach them. Re-posting your content on blog platforms like Medium or dev.to gives you additional exposure:
	
* chances are some people do not look outside those post aggregators

* platform can drive you some traffic from your content being featured, recommended or categorized
		
### Featuring your posts 

You're a specialist and blog about some very intricate topics. Perhaps those topics and your content align well with someone's else business. You decide to collaborate with them and now your post is featured on their blog. 
	
For example: "Optimist's Guide to Pessimistic Library Versioning" presented on [schneems blog](https://www.schneems.com/blogs/optimists-guide-pessimistic-library-versioning) and featured on [a third party](https://www.cloudbees.com/blog/optimists-guide-pessimistic-library-versioning/).

## The drawbacks of re-publishing content in the web and how to avoid them

The drawback of duplicating content on the web is the SEO. Doing so will hurt the way search engines rank your content. Unless you're very explicit what is the original post and what is duplicate. 
To do so, use [canonical link element](https://moz.com/blog/cross-domain-rel-canonical-seo-value-cross-posted-content). Duplicate posts are indexed by search engines [less frequently](https://developers.google.com/search/docs/advanced/crawling/consolidate-duplicate-urls).

For example this is an article originally posted on arkency blog, that is also on [Medium](https://medium.com/planet-arkency/one-simple-trick-to-make-event-sourcing-click-762457e6c28). Inspect its source to find `rel="canonical"` link buried inside:

```html
<link data-rh="true" rel="canonical" href="http://blog.arkency.com/one-simple-trick-to-make-event-sourcing-click/">
```

Besides telling the machines what is duplicate and what is not, I cared for the reader too. There was a note at the end telling about the source:

<p>
  <figure>
    <img src="<%= src_fit('canonical-medium.png') %>" width="100%">
  </figure>
</p>

Do blogging platforms actually allow you to place canonical link reference? In the past Medium allowed it. There's a way to do in on [dev.to](https://dev.to/michaelburrows/comment/125j0) for sure.


Happy blogging!

