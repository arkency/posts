---
title: Faces of tech debt
created_at: 2020-07-17T11:34:07.875Z
author: Tomasz Wróbel
tags: []
publish: false
---

Most IT projects fail. Reasons are many, but tech debt is one of them. Tech debt has many faces. Know your enemy.


## Spaghetti code

## Coupling everywhere

## Implicit side effects

## Global state

## Too many dependencies

## Long-overdue upgrades

## No tests

## Tests running a loooong time

## Failing tests

## Tests difficult to modify

## No CI/CD

## var

From weekly

* you wanna change 1 thing, but you need to do it in 10 places
* conversely, you wanna change 1 thing, but you cannot do it because it would affect 10 other places you don't want to change
* hard to express invariants in code
* web app - syncing data
* inconsistent data, old data that changed, new code breaks invariants
* organizational tech debt
* coupled read and write
* conditionals
* callbacks (-> implicit...)
* complexity
* customer doesn't understand "tech debt"

rails debt cleaners, fixing + education



Which one you've got?

Which ones can we help with.
