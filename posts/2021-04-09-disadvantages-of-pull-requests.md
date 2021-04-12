---
title: Disadvantages of Pull Requests
created_at: 2021-04-09T13:33:57.200Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Disadvantages of Pull Requests

Pull requests with blocking reviews (sometimes mandatory) are widespread. A lot of developers believe pushing to mainline should be prohibited. Sometimes it's unavoidable (in a low-trust environment), but often people work with PRs just because everyone else does. And nobody ever got fired for it.

But what are the costs of working in such style? And what are the alternatives?

I wrote this post to gather the disadvantages of typicall PR flow, so that you can make a better informed decision — by knowing all the potential costs involved. You can judge yourself how each particular aspect applies to your specific work setting. 

If you have anything to add, [ping me on twitter](https://twitter.com/tomasz_wro) or [submit a pull request to this blogpost](https://github.com/arkency/posts/edit/master/posts/2021-04-09-disadvantages-of-pull-requests.md) (how ironic 🙃).

## More long living branches => more merge conflicts

PRs promote developing code in branches, which increases the time and the amount of code staying in divergent state, which increases chances of merge conflicts. And merge conflicts can be terrible, especially if the branch waited for a long time.

Now branches are unavoidable, even if you only commit to master and never type `git branch`. You're still creating a _logical branch_ at the very moment you change a file in your local working directory. But it's up to us:

* how long this does a piece of code live in this divergent state, and
* what is the size of this piece of code involved
 
Limiting these factors can make merge conflicts happen less frequently.

When I have a feature to implement, I often like to work like this:

1. make a number of _preparatory refactorings_, delivered in small atomic commits, pushed as fast as possible
2. implement the actual feature in a small, clean commit — perhaps, after step 1, it's now a one-liner - peak reviewability achieved

(I believe this is what [Kent Beck meant](https://twitter.com/KentBeck/status/250733358307500032) saying _For each desired change, make the change easy (warning: this may be hard), then make the easy change_)

Think of Google-Docs-style realtime collaboration vs. emailing each other subsequent versions of a document. Of course we prefer realtime style and a lot of applications migrate towards it. But where do our code integration techniques fall on this spectrum? By allowing small atomic commits we're closer to realtime collaboartion with all the benefits ot it.

## The reviewability of a change decreases with size

I bet you can relate:

* 10 LOC piece of code — reviewer finds 10 issues
* 10 KLOC piece of code - reviewer says: _LGTM_ (or perhaps adds a couple nitpicks)

PRs tend to promote reviewing bigger chunks of code.

I also like to increase reviewability of my changes by annotating them (and mixing purposes as rarely as possible).

* `Refactor: ...`
* `Change formatting ...`
* `Add this feature ...`

This way I can suggest where the reviewer spends most attention.

## Short feedback loop is what makes programming fun

Why is programming so much more fun compared to other engineering disciplines? Perhaps it can be so quick to build something and see the result of your work. If you're building skyscrappers or airplanes, it takes years to see the product. This is also the reason why a lot of programmers find UI (or game) programming more enjoyable, because you can code something up and quickly see a fancy effect on the screen, which makes you want to do more.

Now PRs make this feedback loop longer. You code something up but it's nowhere close to being integrated and working. You now have to wait for the reviewer, go through his remarks, discuss them, change the code... 

There are a lot of processes for managing programmers' time, quality of the code, but I believe it pays of to also manage programmer's _energy_ and _momentum_.

OH (somewhere on twitter): _We agreed with our team to push to master and it feels like I'm flying._

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

## _Responsibility mindset_ develops slower

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

Some discussion with interesting arguments:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Hypothesis:<br><br>PR-based workflow kills continuous refactoring.<br><br>I see a piece of code I can improve while working on a feature and... no, I&#39;m not doing it now to avoid having irrelevant stuff in the PR (and reducing reviewability).</p>&mdash; Tomasz Wróbel (@tomasz_wro) <a href="https://twitter.com/tomasz_wro/status/1361663527593906177?ref_src=twsrc%5Etfw">February 16, 2021</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## How do you switch to branches with migrations

You obviously sometimes need migrations while working on a branch. What do you do if you then have to switch back to another branch locally? Cumbersome. See [this tweet](https://twitter.com/nateberkopec/status/1377348675291111426?s=21).

## Negative emotions and outright pathology

Mandatory PR reviews can induce way more negative emotions than needed. Let's say someone nitpicks on a PR because he has to point out something. The original author takes it personally. We all have limited emotional budgets — it's better not to waste it on avoidable stuff. Sometimes it can lead to outright pathology: developers making arrangements behind the scenes: _I'll approve your PR, and you'll approve mine_.

## Now, how to make the _10% change_ in your team today

I'm not suggesting a total outlawing of PRs. Gerald Weinberg says you can only make the 10% percent change in your organization. What are examples of such changes?

* Pair program on a complicated feature instead allowing feedback only when PR is finished.
* Try a feature toggle to prevent your unfinished work from affecting production (instead of keeping it on prod). Flipper is a nice gem for that, but you can simply start with an ENV var switch or hiding the feature on UI.
* Try getting into a habit or reviewing commits post-merge.
* Make approvals not mandatory - let the developer merge the PR right away and have it reviewd post factum.
* Make PRs not mandatory — let the developer choose if he wants to develop in a PR or commit to master.
* Encourage post factum improvements by reviewers instead of comments.
* Make it clear with PR comments are blocking, and which are free to be addressed after merging the PR.
* Try to learn how to split your feature into small shippable pieces which don't break production.

<!-- pair program meme -->
