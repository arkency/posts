---
title: "Why we follow the Rails repo structure in Rails Event Store"
created_at: 2017-08-30 18:47:00 +0200
kind: article
publish: true
author: Paweł Pacana
tags: [ 'rails', 'event_store' ]
newsletter: :arkency_form
---


A complete Rails Event Store solution consists of following gems:

* **ruby\_event\_store** — core concepts and and mechanics of an event store
* **rails\_event\_store** — thin wrapper over ruby\_event\_store with additions possible in Rails framework (like automatically capturing some of the request params into event metadata) and necessary glue to make it work out of the box
* **rails\_event\_store\_active_record** — a database adapter based on ActiveRecord
* **aggregate\_root** — library useful for making event-sourced aggregates

<!-- more -->
## The problem

Until recently, each of the gems lived in a repository of it's own. That's how you usually develop a gem and what majority of tools assume. Bundler for example in of it's release-helping [Rake tasks](https://github.com/bundler/bundler/blob/master/lib/bundler/gem_helper.rb#L54-L57) provides a code for tagging git repo with gem version number for a RubyGems release.

Each gem in it own's repository provides a separation and some gems like `aggregate_root` or `ruby_event_store` can be used completely on their own.

This split however has several drawbacks if you're already a contributor or wishing to become one:

* the code is harder to navigate if you have to jump between repositories, that makes a difference for `rails_event_store` which depends on the rest
* if you introduce a change in one of the gems you have to be sure how it affects the rest, integration tests are that span components are easier to write and maintain in a monorepo
* bigger changes that affect several components are harder to coordinate and become split into smaller commits in each repo
* separate repositories also mean several places where issues are reported and pull-requests submitted — not necessarily the right ones and that multiple sources make code reviews and discussions painful
* it might be confusing for newcomers to figure out what is the right place to start the journey with OSS contribution in Rails Event Store

In short it was easier to start that way but it's painful in the long run.

## What Rails does

If you look at [Rails repository](https://github.com/rails/rails) you immediately notice the code layout:

* each framework that goes into Rails (`actioncable`, `actionmailer`, etc.) lives in it's directory and it is a gem (with gem spec and all that jazz)
* there's a top-level `Rakefile` with tasks ranging from [running test for each gem](https://github.com/rails/rails/blob/master/Rakefile#L21-L33), [updating release version](https://github.com/rails/rails/blob/master/Rakefile#L53-L54) across all components to [pushing each gem to RubyGems](https://github.com/rails/rails/blob/master/Rakefile#L53-L54)

It is also worth noting that each of the components gets the same version number as Rails release. It might be tempting to keep component versioning separate but it simpler from end-user perspective to refer to only one number (i.e. when reporting issues).


## How we approached git migration

Being sold to the idea of monorepo we had to figure out "The How". For sure we wanted to keep most popular repo alive (and base for others to be merged in).

We could think of 3 possible approaches:

#### **git subtree merge**
	* original commit SHA retained (refering to SHA from commit messages and refering to existing tags should work)
	*  on a graph it is several roots going into one HEAD
	* breaks file history as the paths after merge are different and it shows only the merge commit


#### **git filter-branch and pull --allow-unrelated-histories**
	* commit SHA changed as this is modifying history 😱
	* on a graph it is several roots going into one HEAD as well
	* file history works as paths are rewritten in commits

#### **git mv and pull --allow-unrelated-histories**
	* original commit SHA retained (refering to SHA from commit messages and refering to existing tags should work)
	* on a graph it is several roots going into one HEAD (surprise)
	* file history works (with `--follow` flag that tracks renames) but not necessarily on GitHub UI

For us, from contributor perspective, working file history is more important than preserving original commit identifiers. So we chose approach involving `git filter-branch`.

The migration involved running following snippet on each repo:

```
SUB_DIR=ruby_event_store

git filter-branch --index-filter \
  'git ls-files -s | gsed "s-\t\"*-&'"$SUB_DIR"'/-" |
  GIT_INDEX_FILE=$GIT_INDEX_FILE.new \
  git update-index --index-info &&
  mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"' HEAD
```

Finally each of rewritten repos where merged into destination one with following `git pull` modifier:

```
git pull --allow-unrelated-histories ../ruby_event_store
```

Sidenote: `gsed` stands for GNU Sed. BSD Sed available on MacOS caused me [some trouble](https://twitter.com/pawelpacana/status/901416064252338176).

## What changed for end users

All these changes were mostly for contributors and maintainers convenience. If you're a happy Rails Event Store user you might be wondering if that change should be on your radar.

- we still publish separate gems to RubyGems like we did
- you can still refer to [git sources of a gem in a monorepo](https://stackoverflow.com/questions/14536742/referencing-the-unreleased-activesupport-4-0-gem-in-a-gemfile/14551999#14551999) (via `Gemfle` and `git:` source)
- you can submit issues on [RailsEventStore repo](https://github.com/RailsEventStore/rails_event_store) as before, as a plus there are no other repos which could confuse you
- there was a [bump in version number](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.15.0) so that all components can have the same but generally there's no breaking change here either (as a bonus it easier to reason about versions of involved components and there's a single changelog catching all changes you'd be interested in when upgrading)

Last but not least Rails Event Store got new [website](http://railseventstore.org). I encourage you to check it out and consider using RES to support your business.
