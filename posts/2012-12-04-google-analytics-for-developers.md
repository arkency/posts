---
title: "Google Analytics for developers"
created_at: 2012-12-04 23:08:47 +0100
kind: article
publish: false
author: 'Jan Filipowski'
newsletter: :chillout
tags: [ 'google analytics', 'business metrics', 'marketing' ]
---

Yes, we have to be honest - we're doing content marketing for [our product for Rails developers](http://chillout.io), but we want that content to be meaty and very useful. So today I'm gonna focus on basic functions of Google Analytics you could not know and how we use them on our blog and landing page.

<!-- more -->

## Basic features

You probably use most of basic features of [http://www.google.com/analytics](Google Analytics) - you know how to get information how many visits was made each day, you know your users browser segmentation etc. But how can you measure effects of your blog post?

You can check what happened when you posted link to Hacker News or Reddit in Real-Time - just go "Home" and click "Real-Time".

<a href="/assets/images/google-analytics-for-developers/ga-realtime.png" rel="lightbox"><img src="/assets/images/google-analytics-for-developers/ga-realtime-fit.png" class="fit"></a>

## Users actions

When you promote product with blog you should be able to meassure how many readers did what you want - click link or sign up with some form. Here's our little script that solves that problems.

```
#!javascript
function trackEvent(category, action, label) {
  window._gaq.push(['_trackEvent', category, action, label])
}

$("article a").click(function(e) {
  var element = $(this)
  var label = element.attr("href")
  trackEvent("Outbound link", "Click", label)
});

$("form").submit(function(e) {
  var element = $(this)
  var label = element.attr("action")
  trackEvent("Form", "Submit", label)
});
```

As you can see it requires jQuery, but of course can be easily rewritten to not use. To be honest we use additional attributes to make our events more readable - our links can define category, actions and labels of event.

We track events, so where can we find them?

<a href="/assets/images/google-analytics-for-developers/ga-events.png" rel="lightbox"><img src="/assets/images/google-analytics-for-developers/ga-events-fit.png" class="fit"></a>

In this section you can choose which category, action or label is interesting for you and show only occurences of that type. You can also see flow of your users in terms of events - below "Events overview" you can find "Events Flow".

## Goals

You now have quite good insight what's happening on your site, but that's not all. You can set goals based, for example, on events. Here's where you can define them:

<a href="/assets/images/google-analytics-for-developers/ga-goals-1.png" rel="lightbox"><img src="/assets/images/google-analytics-for-developers/ga-goals-1-fit.png" class="fit"></a>

<a href="/assets/images/google-analytics-for-developers/ga-goals-2.png" rel="lightbox"><img src="/assets/images/google-analytics-for-developers/ga-goals-2-fit.png" class="fit"></a>

We set two goals - for event with label http://chillout.io/ and for newsletter sign up event.

How to use goals? You can find them in "Standard Reporting" in "Convertions -> Goals" section. It's useful, that you can see which page have biggest conversion to goals.

## Start meassuring now

Don't waste your creative effort - start tracking what's catchy and interesting. It could be useful if you're trying to make product or if you looking for interesting trend in your industry.
