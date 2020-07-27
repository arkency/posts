---
title: Against DRY. Challenging Rails dogmas.
created_at: 2020-07-27T08:39:15.913Z
author: Tomasz Wróbel
tags: []
publish: false
---

We've been taught to make our code DRY. It seems so obvious. Almost like the fact that earth orbits the sun.

Well, agressive dryification can lead to so many problems. Over time people started to realize you should not always try to dry up your code at all costs.

Let's see an example

if statements
wrong abstraction
accidental vs actual

People have come up with new interesting acronyms: [WET](https://dev.to/wuz/stop-trying-to-be-so-dry-instead-write-everything-twice-wet-5g33), [AHA](https://kentcdodds.com/blog/aha-programming).

Read models and bounded contexts help you make your code less dry. Let's look at some examples.
