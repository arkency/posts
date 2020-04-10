---
title: "A potential problem with PStore and Rails"
created_at: 2017-02-06 16:40:01 +0100
publish: true
tags: [ 'rails' ]
author: Andrzej Krzywda
---


Today, I've noticed an interesting [post about PStore in Ruby](http://blog.redpanthers.co/pstore-ruby-standard-library/). This reminded me a recent story we've had with PStore.

Let me start by saying that I like PStore. It's a simple solution which can definitely work.

<!-- more -->

I like to think about persistence as something that can be easily replaced if needed. At least in theory ;) In our projects , we often use the pattern of repository. As long as you provide another repository implementation which has the same API, persistence should still work.

In one of our >5.years projects, we've been migrating servers to a better machine. As part of this, we've made one app to work on several nodes instead of 1 as it was so far. The database node was already separated, all cool.

During the migration, the developer followed the Capistrano file (code never lies, that's the beauty of Capistrano!) and noticed that as part of the deployment we link to the pstore file. After quick investigation, he noticed that one module of the app doesn't use the relational database, but used PStore. It's a very rarily used module and a very small one (as in 2 "tables").

This made the server migration a bit more complex. We either need to have a network-based file system now, so that 2 nodes can use it, or we need to refactor the module (write a new repo object) to use database. Refactoring sounds easier.

The story here is that while PStore was a nice experiment here, there were infrastructural consequences of this decision :) Accessing the filesystem is not the thing that cloud providers like to give us nowadays ;)
