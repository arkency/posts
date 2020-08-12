---
created_at: 2020-04-02 10:24:17 +0200
author: Andrzej Krzywda
tags: [ 'rails', 'architecture' ]
publish: false
---

# The truth about Rails Convention over Configuration

This blogpost is a work in progress. It's also a call for collaboration to Arkency friends (via pull requests - [https://github.com/arkency/posts/edit/master/posts/2020-04-02-the-truth-about-rails-convention-over-configuration.md](https://github.com/arkency/posts/edit/master/posts/2020-04-02-the-truth-about-rails-convention-over-configuration.md) ) if the goal of this blogpost resonates with you.

The goal of this post is to:

* show definition of the word "convention"
* remind what configuration meant before Rails appeared (maybe examples from Struts XML?)
* provide as many examples of Rails conventions as possible
* summarize/group those conventions - it's likely that many of those are just metaprogramming or "magic"
* explain why those conventions optimize for the first N days of developing the Rails app
* explain, provide examples - how some of the conventions introduce coupling at the design level
* conclude that Rails Convention over Configuration may lead and often leads to technical debt
* explain ideas behind Architecture over Convention
* provide alternative solutions to the listed Rails conventions - link to other blogposts/resources, including Arkency ones, but not limited to them

Feel free to help with any of the points here, just create a section and contribute. Probably the easiest contributions (but helpful!) would be listing more examples of Rails conventions.

Once the goals are accomplished, this blogpost will be published, linked from Arkency blog index and linked from the sitemap. Before it happens, it has its own URL which you can send to other potential collaborators - [https://blog.arkency.com/the-truth-about-rails-convention-over-configuration](https://blog.arkency.com/the-truth-about-rails-convention-over-configuration)
 
<!-- more -->

# Convention - the definitions

# The old days of XML Configuration hell

# Examples

* copying controller instance variables into views 
* automatic mapping from column names to ActiveRecord attributes

# How the conventions help

# Coupling - examples

# Convention over Configration leading to a Technical debt

# Architecture over Convention

# Alternative solutions to typical Rails conventions

