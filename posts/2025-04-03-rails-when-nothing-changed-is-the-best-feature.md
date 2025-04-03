---
created_at: 2025-04-03 21:42:38 +0200
author: Szymon Fiedler
tags: [rails, legacy]
publish: false
---

# Rails: when "nothing changed" is the best feature

Recently, I had a chat with a friend of mine, who used to do Rails back in the days. Since ~10 years he’s focused on mobile development. I was curious what are his observations and asked if he’s happy with his decision or maybe he actually misses web development. 

<!-- more -->

He replied:

> I miss doing backend, but I’m disgusted with web development. I’m too old to chase every new framework to do the same thing in every new ES flavor of JS... Jumping around npm, yarn, pnpm, bun or whatever is cool this quarter...

But then he followed:

> Recently I had to implement a tiny backend app. I dusted off Rails and everything was the same. Same commands, same gems, even nokogiri crashed the same way during bundle install, just like 10 years ago...

For me it’s an impressive story about boring software. Boring software that’s highly regarded. I absolutely love Rails longevity.

## Low learning curve for returnees
Someone who worked with Rails in 2010 can pick up a Rails application in 2025 and still recognize core patterns, conventions and commands. It all remained fundamentally similar.

## Knowledge retention
The skills developers build working with Rails tend to stay relevant for years, which is rare in the fast–moving web development world.

## Team flexibility
New team members who have Rails experience can become productive quickly without extensive onboarding.

## Documentation stability
Solutions and patterns documented years ago often still apply, creating a rich knowledge base that remains useful.

## Reduced "framework fatigue"
While Rails has evolved, it hasn’t required developers to 
completely relearn their workflow every quarter or two like JS ecosystem does.

This stability creates enormous practical value. It means companies can maintain Rails applications for the long term without constantly rewriting them to keep up with framework changes. It also means the pool of developers who can work on a Rails project is broader, including those who may have been away from Rails for years but can quickly get back up to speed.

From a domain modeling perspective, this stability means you can focus on evolving your business logic and domain models without constantly rebuilding the technical foundation underneath them.

I smile to myself every time I see a JS app team implementing from scratch a framework feature that is simply available in Rails. Apparently, not everyone gets a chance to work with a mature web framework.
