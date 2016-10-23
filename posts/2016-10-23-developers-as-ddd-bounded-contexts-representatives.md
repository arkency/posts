---
title: "Developers as DDD bounded contexts representatives"
created_at: 2016-10-23 16:54:16 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :skip
---

Recently, I've been preparing to my webinar about introducing DDD to existing projects/teams.

One DDD part which is not always easy to explain is actually the main strategic pattern - bounded contexts. For the webinar purpose I came up with the idea of showing that in our programming teams we also have bounded contexts. What's better, most of us, represent different bounded contexts.

In this blogpost I'd like to highlight some of such contexts.

<!-- more -->

The thing I'd like you to focus on is that the different types of developers - they all use different vocabulary when they play different roles. It's worth noting it just for the purpose of a successful communication but also to learn that it's the main point of DDD - find the domain language.

## Performance oriented developer

- "we should have written it in SQL"
- "there's nothing faster than reading from a file"
- loves performance benchmarks
- favourite words: cache, traffic, rpm (requests per minute)

## Framework-man

- excited about new frameworks
- loves having many buzzwords in the resume
- believes in the current The Framework Way
- honours only developers who created frameworks
- silently dreams about writing own framework
- always up to date with the new framework of the week
- great for writing prototypes

## TDDer

- can't sleep if someone wrote production code without tests first
- when reviews code of others, starts with tests
- with all new features thinks "how am I going to test it?"
- great at refactoring critical pieces of code
- makes sure about test coverage
- excited about mutation testing

## Sad FP programmer

- super intelligent
- can't accept that some people see the world as mutable
- modeling business means writing math equations
- is sad, because can't write code in the purest FP language
- great at dealing with concurrency


## Over-excited agiler

- open-space fan
- loves when people talk to each other
- loves post-it notes on the wall
- loves moving post-it notes between columns
- generally loves post-it notes

## Clerk

- the first one to establish a "code style guide" in the team
- can argue about tabs/spaces for ages
- good at documenting
- will install all the possible code metrics tools
- is happy when the build fails because of his post-push lint rules

## Devpreneur

- with each feature thinks how much money it is going to bring
- did calculations and know how much each line of code is worth
- able to introduce a hack just to have the feature faster on production "making money"
	- then forgets about removing the hack
- the best friend of product owners / customers
- instead of writing tests, prefers to write bank account monitoring script - alerting when it's balance is increasing slower
- never a passionate of some specific tool - whatever gets the job done
- thinks in budget terms

## Summary

There's definitely more such types/contexts. If you can name some - feel free to do it in the comments!

Please note, that each of us can play any of the roles at any time. However, sometimes some roles are more natural for each of us.

Note the language that we're using. Even though we can have some fun describing the personas, all the contexts are important at specific times. 

What contexts do we see here?

- Performance
- Technology/Tools
- Tests / Refactoring / Regressions
- Concurrency / Math / Proofs
- Communication 
- Documentation / Standards
- Budget / Finances / Accounting

This is all for our internal needs - to safely/efficiently deliver software. 

Now look similarly at the actual project you're working on. What subdomains do you see?

If you're working on some kind of e-commerce, you'll probably see:

- Inventory
- Catalog
- Ordering
- Accounting
- Invoicing
- Reports
- Pricing
- Promotions

and many others. It's not uncommon to see ~30 potential bounded contexts.

Are they clearly represented in your system? 

Each of them deserve a dedicated module. It's truly bounded if they don't talk to each other directly. They either communicate with events or there's a layer above (app layer) which orchestrates them. Each of them should have a separate storage (conceptually) and never ever look at each other storage directly.

When I first encountered DDD - this all was a mystery to me. How to actually achieve this? Now, after seeing this happen in our projects it all seems much simpler.

Each context is either a separate module/directory in the repo or it's a separare microservice/repository.

When I work on Accounting features, I'm not bothered by the concepts of other contexts. I'm only surrounded by things like accounts, revenues, profits. This makes me much easier "to get into the zone".

Heck, thanks to the CQRS (I consider this to be part of the bigger DDD family) techniques, I don't need to bother too much about how it displays on the UI. The "read" code is also separated.

--------------


Pssssst, if you're interested in applying DDD in your Rails projects, consider coming for 2 days to Wrocław, Poland and attend our [Rails DDD workshops](http://blog.arkency.com/ddd-training/). The next edition is 24-25 November, 2016.

This is how the first 2 hours of the workshops look like in the first edition - a heaven for the agilers - post-it notes everywhere ;) It's a technique called Event Storming - we visualize a system with events/commands/aggregates - each having a different color of a post-it note.

<blockquote class="twitter-video" data-lang="en"><p lang="en" dir="ltr">Our <a href="https://twitter.com/hashtag/Rails?src=hash">#Rails</a> <a href="https://twitter.com/hashtag/DDD?src=hash">#DDD</a> Workshop is happening right now! <a href="https://t.co/qzMbL8tNwt">pic.twitter.com/qzMbL8tNwt</a></p>&mdash; Arkency (@arkency) <a href="https://twitter.com/arkency/status/777798532132638720">September 19, 2016</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>