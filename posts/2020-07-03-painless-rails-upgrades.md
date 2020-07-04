---
title: "Painless Rails upgrades"
created_at: 2020-07-03 15:35:09 +0200
author: Szymon Fiedler
tags: [rails]
publish: true
---

Sooner or later your _Rails_ application will require an upgrade of the framework itself. There are many reasons behind that. Bugs, incompatibility with modern libraries, or the worst: the version you use will no longer receive security updates. Living on the edge might be tempting, but it can also end badly for the business which relies on the application. User data leak, frauds, this all can simply lead to serious legal and financial issues.

<!-- more -->

# Upgrade all the things

At _Arkency_ we mostly work with legacy applications. Customers that we tend to cooperate with are successful businesses. They often need assistance with improving existing codebase, implementing new business features, and rather technical tasks like upgrading the _Ruby_ & _Rails_ version. It's not a rare case when they hit the wall and can't progress with their app because of outdated libraries. You might think: _it's easy, just fasten your seatbelts and run_ `bundle update` 🙈

I must disappoint you, it usually doesn't work that way. It's rather:

```shell
Bundler could not find compatible versions for gem "rails":
  In gemfile:
    rails (~> 6.0.3.2)

    it_doesnt_really_matter (~> 1.4.10) was resolved to 1.4.10, which depends on
      rails (= 5.2.4.2)
```

Even if you don't run into could not find compatible versions and it will work somehow, you may run into:

- multiple test failures on your CI which will simply prevent you from deployment and you'll spend hours/days/weeks on trying to find the root cause
- successful deployment exposing numerous bugs and affecting the business and you'll spend hours/days/weeks... you know it

# Give me the silver bullet!

I must disappoint you, I don't have such. However, as _Arkency_, we successfully helped numerous clients in this area. We have well-established practice for doing so. I will show you how to prepare for Rails upgrade, what to avoid while developing your application and how to write code which won't bother you while upgrading the Rails itself. It's simpler than you think. Your next upgrade will end up in bumping _Rails_ version number in `Gemfile` and running bundle update rails. Just follow the rules below and everything will be fine.

# Successful upgrade guide

## Test Coverage

Keep your app test coverage on a high level. Static analysis tools won't tell you whole truth, especially `rake stats` saying that you have 140% coverage if test/code ratio is high enough. They can be helpful, give you some basic information, but you can't fully really on them. If you want to be sure about your coverage you should dive into [mutation testing](https://blog.arkency.com/tags/mutation-testing/).

## Application monitoring

It's good to know about errors happening in the app. Especially this might be crucial if you pushed some significant changes to production. But let's stay here for a moment. Are errors the only sign of something bad happening in the application? My experience tells me that the app might now work properly, eg. checkout flow is completely not working but no error will appear in bug tracker. Track your business metrics. Get notified if the payments level drops significantly. Maybe people can't finalize checkout, but you're not aware and no error happens because something is wrong on the frontend only?

## Take small, preemptive steps

Push often, release often. Let each gem bump land on production as a separate release. You will instantaneously realize if something is not working as expected because you monitor how things are going. It's easier to revert single commit than pull request with gazillion of changes. You'll probably spot the problem easier if single, atomic change is taken into account, rather than multiple ones.

## The Boy Scouts Rule

_Always leave the campground cleaner than it was_ – it says. You've probably heard it before in `s/campground/code` version. If you work in given area of code, improve it. It uses outdated library, bump it upfront to make further _Rails_ upgrade easier.

## Upgrade Ruby separately from Rails

- Rails 6 requires Ruby 2.5.0 or newer (2.5.x reaches EOL in 2021)
- Rails 5 requires Ruby 2.2.2 or newer
- Rails 4 prefers Ruby 2.0 and requires 1.9.3 or newer
- Rails 3.2.x is the last branch to support Ruby 1.8.7

You can bump your _Ruby_ version even today, it's usually easier than upgrading the _Rails_ itself. Don't try upgrading both _Ruby_ and _Rails_ in a single step since it may hit you hard. At least it can confuse you and waste your time.

## Read Rails upgrade guide

[It covers most of the topics](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html) you have to be aware of when bumping your framework version. It can be good starting point for creating backlog tickets and planning the upgrade.

## Read Rails Release Notes

Each _Rails_ version has a dedicated page with [Release Notes](https://edgeguides.rubyonrails.org/6_0_release_notes.html). It usually dives into details more than _Upgrade guide_ mentioned in previous paragraph. It covers _Removals_, _Deprecations_ and _Notable Changes_.

## Read CHANGELOGs of gems you use

Check their compatibility with your desired _Rails_ version. Maybe a library is no longer maintained? Maybe someone forked it and supports modern _Rails_? It's good to know such things upfront. Digging into _GitHub_ issues, especially the open ones is also a good idea. Gem maintainers not always put everything into `CHANGELOG`, sometimes the _issues_ become the only source of knowledge.

## Address deprecations early

Don't wait until the feature will be removed or completely changed. This can be a huge blocker for you, trust me. When you see a deprecation, fix it or at least put it into backlog to make rest of your team aware and not forget about it.

## Prepare your backlog

Put all the knowledge you've gained up to that point into backlog. Probably you won't be working alone on that. Discuss it with the team and communicate with management about potential issues if you see any. [Over-communication](https://blog.arkency.com/2016/10/overcommunication-is-required-for-async-slash-remote-work/) might be a key to success.

## Avoid gems highly coupled with framework

Gems monkey patching `ActiveRecord` can be really harmful to your maintenance process. Everything goes fine unless it no longer does. Do you remember `protected_attributes`? It was extracted from _Rails_ and maintained by core team, then it was no longer maintained and someone renamed it to `protected_attributes_continued`. Now it's payback time, it won't work with _Rails 6_. I've seen many stories similar to this. All those _state machine_ gems relying highly on callbacks, blocking applications for upgrades for months, or even years.

## Write better, framework agnostic code

Go for tactical DDD patterns for your core domain. Modularize your code, extract [Bounded Contexts](https://blog.arkency.com/tags/bounded-context/). Use _Rails_ where they shine: `ApplicationController`, `ActiveRecord` used for writes and reads without the callback hell and STI. We've shown you the alternative approach many times: [commands](https://blog.arkency.com/tags/commands/), [service objects](https://blog.arkency.com/tags/service-objects/), [process managers](https://blog.arkency.com/tags/process-manager/), etc. Believe us, your next upgrade will be just a matter of _Rails_ version bump in your `Gemfile`.
