---
title: Disadvantages of Pull Requests
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

Perhaps it's familiar to you:

* someone reviewed your PR, but only pointed out simple things — actually relevant things were not addressed: data flow, architecture, corner cases
* you were asked for a review, but you were only able to point out some simple things — you submitted it to give impression you made a thorough review

Why is that? In order to properly review a non-trivial piece of code, I need to focus, get deep and build enough context almost to the extent that the PR author did. All this without the privilege of being able to put my hands on the keyboard and without enough time. **Proper review takes the same amount of focus as actual coding. Why not pair-program instead?**

The superficiality of reviews is amplified by following factors:

* reviews being mandatory
* size of the pull request
* randomness of person involved
* lack of shared context of the reviewer

## Merging is blocked by remarks that shouldn't be blocking

Remarks made by the reviewer can fall anywhere on the spectrum of whether they should block merging or not: from a mistake that'll bring production down to cosmetic/subjective suggestions (with more of the latter ones). How do we account for this variety? Typically, any PR comment makes a dispute that needs to be resolved before merging.

## It's easier to fix than to explain

Now the reviewer has an idea how to make a piece of code in you PR better. He explains it in a comment. The original author has to understand it, and is expected to implement. Often it's better to let the original author merge his thing, and let the reviewer implement his remark post-factum? Faster, less costly, less frustrating. PRs promote more words instead of action.

## _Responsibility mindset_ weakened

Compare these two developers:

* Developer 1 makes subsequent commits to a branch, then creates a PR, then has it reviewed and merged.
* Developer 2 breaks his feature into small non-breaking pieces, makes subsequent commits to mainline, his code is integrated right away and possibly deployed

Which developer will faster learn to code responsibly? The first one knows, that whatever he commits, lands on a branch, and doesn't affect anything. Then there's the review, so if he commited anything blatantly wrong, perhaps the reviewier will catch it.

The second one knows that every line he writes can screw up things for other developers or even bring production down. He watches his step, he knows he's the only one responsible for this change. It shortens the delay between making a mistake and seeing the effect of it.

People argue that you need PRs because of junior programmers. Probably yes, but do you consider how fast can such a person stop relying on reviews on develop his own sense of responsibility?

## PRs discourage _continuous refactoring_

I believe refactoring is an activity that should be performed continuously. It's good to follow boy scouts' rule: always leave the place better that it was before. Over time it can lead to nice codebases. With PRs, though, this rule is harder to apply: if I see a piece of code worth fixing while working in this specific area, I can now:

* fix it in my PR and worsen the reviewability of it by including a non-essential change
* change the branch, create another PR, refactor, wait for review, merge the PR into your original PR, continue

<!-- Without PRs I typically -->

## How do you switch to branches with migrations

You obviously sometimes need migrations while working on a branch. What do you do if you then have to switch back to another branch locally? Cumbersome. See [this tweet](https://twitter.com/nateberkopec/status/1377348675291111426?s=21).

## Negative emotions and pathology

Mandatory PR reviews can induce a way more negative emotions that needed. Someone nitpicks on my PR because he has to point out something. The original author takes it personally. We all have limited emotional budgets — it's better not to waste on avoidable stuff. Sometimes PRs lead to outright pathology: developers making arrangements behind the scenes: _I'll approve your PR, you'll approve mine_.

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
