---
created_at: 2022-06-10 12:11:31 +0200
author: Andrzej Krzywda
tags: []
publish: false
---

# Rails integration tests without service objects and commands

Today I worked on the Arkency Ecommerce project.

I have noticed that we're still relying on commands in the integration tests.
If you don't use commands, you can think of them as similar stuff to service objects for this scope of the problem.

In this post I 

<!-- more -->

This is what the tests were like:


```ruby
```


This is how it was changed.


```ruby
```



As you see it's mostly relying on testing via the HTTP Api (which uses Rails views so it returns html).

What is the problem of having service objects in the integration tests?

The main one is that we skip the controllers from being tested. 
Testing them in isolation is usually an overkill with mocking but some kind of tests are needed.

How did this happen that we had them in the first place?

In this project we've had an UI for showing/using products and customers but we didn't have any UI to create them.
This means that temporarily we had to rely on commands in those tests.

However, once the UI was created, we could replace the commands with real http calls.


