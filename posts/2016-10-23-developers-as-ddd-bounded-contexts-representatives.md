---
title: "Developers as DDD bounded contexts representatives"
created_at: 2016-10-23 16:54:16 +0200
kind: article
publish: false
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

