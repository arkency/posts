---
created_at: 2023-03-17 11:05:49 +0100
author: Szymon Fiedler
tags: [team consulting]
publish: false
---

# How to write a good incident postmortem

Sometimes, not everything goes smooth when introducing changes in your application. When it happens, you introduce hotfix as soon as possible, usually followed by the coldfix. Such situations are great to take a learning from.

<!-- more -->

## Purpose

The postmortem serves a purpose of finding the root cause of an incident, providing insights to the team to make the system more resilient in the future.

## It ain't cheap

It costs time, but you should consider this as an investment. Sometimes it can be hard to find the origin of the problem which occurred in your system. However, fixing the effects of incident without deep understanding of its origin is putting patches on patches.

## Losing control

Every incident in the system makes management think that you don't have control. This can have several outcomes which you may want to avoid:

- adding more checks like mandatory pre–deployment review
- adding new policies, e.g. no commits to master branch
- adding yet another supervisor to decide whenever you can introduce changes

## Regaining control

We're already responsible developers. Postmortem is a great way to mitigate all the doubts and propose reasonable solutions to prevent further issues.

## How to postmortem

Here's not very opinionated list of elements the postmortem should consists of. Remember about the most important outcome of it: to make a change and improve both your system and organization.

### Title

Brief description of what happened, e.g. _Cat gifs library RuntimeError_.

### Status

To inform whether it's resolved or not.

### Severity

State how severe this issue was to your platform, if your organization has this formalized, follow accordingly, e.g. _HIGH AF_.

### Commander

Who is responsible for the investigation, e.g. _Andy Dwyer_.

### First occurrence

When the issue occurred, eg. `2023-02-28 15:03:45 UTC`, maybe followed by a link to favorite bugtracker.

### Description

A bit broader on what really happened: _Broken cat images generation, 1410 of our customers were disappointed on not getting cute cat images while visiting our website._

### Communication channel

Where did you perform the investigation, it can be a link to slack thread, issue on the one–who–must–not–be–named _Jira_, whatever works in you organization.

### Reason

Describe what exactly happened, as detailed as possible:

- the package `cutecatgifs` should live under `/usr/bin` since it's installed as a system package,
- the gem `cutecatgifs-binary` has been removed from `Gemfile` since it was duplicating the feature already living in the system under `/usr/bin`,
- unfortunately, due to gem itself being present in the Docker image, but no longer in the `Gemfile`, library called `CuteCatGifsComposer` tried to use the `cutecatsgifs-binary` bin wrapper instead of system–wide package. This happened since `cutecatgifs-binary` was present earlier in the `$PATH`: `usr/local/yourfavouritrrubyversionmanager/gems/ruby-2.7.7/bin:/usr/local/bin:/usr/bin`,
- it was expected that binstub won't be present in a new deployment.

### Fix

Describe how you've resolved the issue: _reverting the changes in `Gemfile` and `Gemfile.lock` resolved the issue_.

### Summary

TL;DR for the lazy people with key points taken:

- Incorrect, non–existing in the bundle binary was called causing `RuntimeError`,
- Binary path was resolved incorrectly because `bundle exec which cutecatgifs` returned its path based on `$PATH` which was prepended by binstubs directory.

### Prevention

Describe in points how similar issues can be avoided in the future, it serves a purpose of improving your development process and system itself:

- Avoid shared state coming from Docker image which contributed to the issue
- Add automated post–deployment check whether _cute cat gif_ appears on the website after deployment
- Reduce deployment time from 40 to 4 minutes, so only few people wouldn't see the picture of a cat, rather than 1410, due to quick revert

## Plot twist

This is based on a true story. What's even more funny is the fact that the development process consisted of all the points mentioned in [Losing Control](#losing_control) paragraph. It lacked the most important one: ability to act quickly when the issue occurs. Mistakes will happen, especially if taking the risk is cheaper than preventing all the edge cases.

But it's a topic for a different story.
