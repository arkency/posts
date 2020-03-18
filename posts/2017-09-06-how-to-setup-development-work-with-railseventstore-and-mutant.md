---
title: "How to setup development work with RailsEventStore and mutant"
created_at: 2017-09-06 12:39:16 +0200
kind: article
publish: true
author: Szymon Fiedler
tags: [ 'rails', 'event_store', 'mutant', 'ddd' ]
newsletter: arkency_form
---

<%= img_fit("development-work-with-res-and-mutant/rita-morais-108397.jpg") %>

As Arkency we’re making our efforts to inculcate **Domain Driven Design** into Rails community. You should be familiar with [Rails Event Store](http://railseventstore.org) ecosystem. We use it in our customers’ projects with success since quite some time.

<!-- more -->

One of the cornerstones of the Rails Event Store is [keeping it 100% covered with tests](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/). **Rails Event Store** can become an important part of the application. There’s no other way than keeping it well covered with tests. [Mutant](https://github.com/mbj/mutant) is the tool which supports us in achieving that.

## Missing brick
One of the missing parts of our ecosystem were RSpec matchers. In each customer’s project, we wrote custom matchers. Some of you who already use Rails Event Store will do the same sooner or later. Based on our experience we decided to provide matchers. They can be used out of the box via [rails_event_store-rspec](https://github.com/RailsEventStore/rails_event_store-rspec) library. I’ll try to describe it better in a separate post.

## Developing in _RailsEventStore_ ecosystem
For each of the RailsEventStore parts, we provide `Makefile`, for convenience use. After cloning the interesting repository run `make install` and you are ready to go. If you want to run tests, just run `make test`. To run mutant you do `make mutate`. The second one runs tests as an initial phase. Yet, I’ve got tired of constantly switching between my code editor and terminal. Running `make mutate` and switching back to code since it takes some time for the **Mutant** to complete the run.

## Looking for an improvement
I used [Guard](https://github.com/guard/guard) in past to track file changes and run tests but I remember that it was integrating with the code a bit too much. Adding to `Gemfile` and `.Guardfile` to a repository is such integration for me. I don’t want to force people to install stuff which is not necessary for [contributing](http://railseventstore.org/contributing/). Anarchy, you know.

I reminded myself that [jest](http://facebook.github.io/jest/) is using something under the hood for watching file changes. And there it is, please meet the [Watchman - A file watching service](https://facebook.github.io/watchman/). We can read on the project page that _Watchman exists to watch files and record when they change. It can also trigger actions (such as rebuilding assets) when matching files change._ Sounds good enough. I went through the docs. I’ve figured that there’s dedicated command for running `Makefile` tasks. It’s called [`watchman-make`](https://facebook.github.io/watchman/docs/watchman-make.html).

## How to use it
If you’re a Mac user, simply `brew install watchman`. More in the [installation](https://facebook.github.io/watchman/docs/install.html) section of the docs.

What’s the **magic** command to use with any part of `RailsEventStore` then?

```bash
watchman-make -p '**/*_spec.rb' '**/*.rb' 'Makefile' -t mutate
```

`-p` stands for the patterns to watch, we want to run a test on any spec or lib file. Just figured out that the second pattern includes a first one.

`-t` is for specifying the build target, in our case, it’s `mutate` task from `Makefile`

The tool is powerful. You can specify many targets responding to several patterns. But that’s not our case.

It might be cool to get some notification on success or failure. Current setup is good enough for me and improves my workflow. Yet I don't want to spend more time on that now.
