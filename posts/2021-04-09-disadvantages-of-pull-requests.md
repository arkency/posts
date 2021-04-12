---
title: Costs of Pull Requests
created_at: 2021-04-09T13:33:57.200Z
author: Tomasz Wróbel
tags: []
publish: false
---

Pull requests with blocking reviews (sometimes mandatory) are widespread. Sometimes they're unavoidable (low-trust environment), but often people work with PRs just because everyone else does. And nobody ever got fired for it.

But what are the costs of working in such style? And what are the alternatives?

Why do I write this post? To be able to make a more informed decision, by knowing all the costs involved.

## More long living branches, more merge conflicts

PRs promote developing code in branches, which increases the time and amount of code in divergent state, which increases chances of merge conflicts. And merge conflicts can be terrible, especially if the branch waited for a long time.

<!-- If you think -->

Now branches are unavoidable, even if you only commit to master and never type `git branch`. You're still creating a _logical branch_ at the very moment you change a file in your local working directory. But it's up to us:

* how long this does a piece of code live in this divergent state, and
* what is the size of this piece of code involved
 
Limiting these factors can make merge conflicts happen way less often.

<!-- google docs -->

<!-- I like to work ... preparatory refactorings k beck -->

<!-- size of piece of code end reviewability -->

## Short feedback loop is what makes programming fun

Why is programming so much more fun compared to other engineering disciplines? Perhaps it can be so quick to build something and see the result of your work. If you're building skyscrappers or airplanes, it takes years to see the product. This is also the reason why a lot of programmers find UI (or game) programming more enjoyable, because you can code something up and quickly see a fancy effect on the screen, which makes you want to do more.

Now PRs make this feedback loop longer. You code something up but it's nowhere close to being integrated and working. You now have to wait for the reviewer, go through his remarks, discuss them, change the code... 

There are a lot of processes for managing programmers' time, quality of the code, but I believe it pays of to also manage programmer's _energy_ and _momentum_.

## Reviews tend to be superficial

I bet it's familiar to you:

* someone reviewed your PR, but only pointed out simple things — actually relevant things were not addressed: data flow, architecture, corner cases
* you were asked for a review, but you were only able to point out some simple things — you submitted it to give impression you made a thorough review

Why is that? In order to review 


this cost is amplified by
* mandatory-ness
* size of PR
* randomness of person involved
* lack of shared context of the reviewer

## integration blocked by stuff that shouldn't be blocking

## put away the responsibility mindset

slower learning

## it takes the same focus

## less responsibility

## doesn't promote action

## short feedback look is what makes programming fun

## discourages continuous refactoring

## switching branches/PRs and migrations

https://twitter.com/nateberkopec/status/1377348675291111426?s=21

## approvals get traded


## random

10 KLOC PR - LGTM, or nitpicks random issues
10 LOC PR — finds 10 bugs

push to master and it feels like I'm flying

pull requests VS pushing to master — is like — emailing new doc versions VS realtime google docs collaboration https://twitter.com/tomasz_wro/status/1374660731082248192

## How to make the 10% change

* let developer choose - commit to mainline or PR if he really wants it reviewed first, perhaps suggesting the places he'd like to discuss
* make reviews post factum
* don't require approval
* go with PRs but allow merging right away
* encourage post factum improvements instead of comments
* only point out stuff that really shouldn't go to master
* allow pushes to master
* trunk based development
* try a feature flags, flipper
* pair programming, perhaps not in a full blown way, that meme
* split the change into a couple commits or PRs, behind a flag, or into pieces
