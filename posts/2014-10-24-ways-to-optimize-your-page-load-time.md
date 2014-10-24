---
title: "Ways to optimize your page load time"
created_at: 2014-10-24 15:05:26 +0200
kind: article
publish: false
author: Kamil Lelonek
tags: [ 'optimization', 'optimisation', 'speed', 'load', 'frontend', 'css', 'html', 'js', 'javascript' ]
newsletter: :frontend_course
---

<p>
  <figure>
    <img src="/assets/images/frontend-performance/performance-fit.jpg" width="100%">
  </figure>
</p>

Optimization has always been a tough topic. [Donald Knuth](https://www.youtube.com/watch?v=75Ju0eM5T2c) said that *premature optimization is the root of all evil*. Performance is something that always causes emotions in Rails community. When we need it, we tune up our applications, try different and [new servers](http://www.rubyraptor.org/), use load balancers, speed up our applications by playing with threads and processes, but sometimes we forget about frontend at all. Server side is important too, but if we need to provide fast, responsive webstes we have to optimize them in our browsers too. **In this article I'd like to focus on client side and how to efficiently deliver content to user.**

<!-- more -->

# What won't be about

Before I start, I'd like to precise what won't be mentioned in this article. So let's summarize briefly what won't be covered to give you a general overview about the overall content.

- Nginx setup and performance setting
- Caching
- Gzipping
- HTTP Headers (`cache-control`, `max-age`, `expires`, `vary`, `etag`, ...)
- CDNs

**A lot of useful links covering those topics are included in resources under this blogpost.** Not a lot left, huh?

# Rationale

When I was preparing to this article I was thinking about something unique, what is not *mostly obvious*, especially for Rails developers. We all know the server side quite well, but sometimes we don't have an opportunity to take care of client side - maybe because we have frontend developers in our team, maybe because we just don't want or like to do frontend at all, maybe because we only maintain server stuff and don't have any usecases to do much on client side or for any other reason when we actually have some fear before touching code that we are not experts in. A lot of us know how to configure workers, set proper HTTP headers, gzip and cache contend and distribute it by CDN, but very few know about improving load processes for client side content, especially styles and scripts.

# So what is this about?

In this blogpost I'll focus on the following things:

**JS:** 
- `defer`
- `async`

**CSS:**
- `prefetch`
- `subresource`
- `pretender`
- `reconnect`
- `preload`

# JS

# CSS

# Bonus

## GA

GoogleAnalytics provides asynchronous syntax for loading tracking script.

The snippet below represents the minimum configuration needed to track a page asynchronously. It uses `_setAccount` to set the page's web property ID and then calls `_trackPageview` to send the tracking data back to the Google Analytics servers.

```
#!javascript
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-XXXXX-X']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
```

You can read about it in the [offical documentation](https://developers.google.com/analytics/devguides/collection/gajs/).

## PageSpeed or ySlow

There are some tools as extensions to our browsers for measuring load times and suggest some optimization improvements for them. Chrome offers [PageSpeed](https://chrome.google.com/webstore/detail/pagespeed-insights-by-goo/gplegfbjlmmehdoakndmohflojccocli), which I find a great tool and in Firefox you can use [ySlow](https://addons.mozilla.org/pl/firefox/addon/yslow/), which is quite nice web page performance analyzer.

# Resources

- https://kinsta.com/learn/page-speed/
- https://medium.com/@luisvieira_gmr/html5-prefetch-1e54f6dda15d
- https://www.igvita.com/2014/01/31/optimizing-web-font-rendering-performance/
- http://betterexplained.com/articles/speed-up-your-javascript-load-time/
- http://www.mobify.com/blog/beginners-guide-to-http-cache-headers/
- https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Tips_for_authoring_fast-loading_HTML_pages
- http://www.yottaa.com/17-user-experience-and-site-performance-metrics-you-should-care-about-ebook