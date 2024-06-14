---
title: Disadvantages of Pull Requests
created_at: 2021-04-12T11:33:57.200Z
author: Tomasz Wróbel
tags: ['async remote']
publish: true
---

# Disadvantages of Pull Requests

Pull requests with blocking reviews (sometimes mandatory) are widespread in our industry. A lot of developers believe pushing straight to the main branch should be prohibited. Sometimes it's unavoidable (in a low-trust environment), but **often people work with PRs just because everyone else does**. And nobody ever got fired for it.

But what are the **costs of working in such style**? And what are the alternatives?

I wrote this post to gather the disadvantages of a typical PR flow, so that you can make a better informed decision — by knowing all the potential costs involved. You can judge yourself how each particular aspect applies to your specific work setting.

If you have anything to add, [contact me on twitter](https://twitter.com/tomasz_wro) or [submit a pull request to this blogpost](https://github.com/arkency/posts/edit/master/posts/2021-04-09-disadvantages-of-pull-requests.md). How ironic 🙃

## 1. More long living branches, more merge conflicts

PRs promote developing code in branches, which increases **the time and the amount of code staying in divergent state**, which increases chances of merge conflicts. And merge conflicts can be terrible, especially if the branch waited for a long time.

Now branches are unavoidable, even if you only commit to master and never type _git branch_. You're still creating a _logical branch_ at the very moment you change a file in your local working directory. But it's up to us:

* how long does a piece of code live in this divergent state, and
* what is the size of the involved piece of code

Limiting these factors can make merge conflicts happen less frequently.

When I have a feature to implement, I often like to work like this:

1. make a number of _preparatory refactorings_, delivered in small atomic commits, pushed to the main branch as fast as possible
2. implement the actual feature in a small, clean commit — perhaps, after step 1, it's now a one-liner - peak reviewability achieved

(I believe this is what [Kent Beck meant](https://twitter.com/KentBeck/status/250733358307500032) saying _For each desired change, make the change easy (warning: this may be hard), then make the easy change_)

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">for each desired change, make the change easy (warning: this may be hard), then make the easy change</p>&mdash; Kent Beck (@KentBeck) <a href="https://twitter.com/KentBeck/status/250733358307500032?ref_src=twsrc%5Etfw">September 25, 2012</a></blockquote>

Think of Google-Docs-style realtime collaboration vs. emailing each other subsequent versions of a document. Of course, we prefer the realtime style and a lot of applications evolve towards it. But where do our code integration techniques fall on this spectrum? By allowing small atomic commits we're closer to realtime collaboration with all the benefits of it.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">From personal experience, it feels like using Google Docs compared to emailing each other Word documents.<br><br>Also refactoring much much more often since it&#39;s extremely cheap and fast. <br><br>Which helps with =&gt; <a href="https://t.co/jdN1eSmJPl">https://t.co/jdN1eSmJPl</a></p>&mdash; Miroslav Csonka (@miroslavcsonka) <a href="https://twitter.com/miroslavcsonka/status/1374497072884240391?ref_src=twsrc%5Etfw">March 23, 2021</a></blockquote>

## 2. The reviewability of a change decreases with size

I bet you can relate:

* 10 LOC piece of code — reviewer finds 10 issues
* 10 KLOC piece of code - reviewer says: _LGTM_ (or perhaps adds a couple nitpicks)

**PRs tend to promote reviewing bigger chunks of code**.

I also like to increase reviewability of my changes by annotating them (and by mixing purposes as rarely as possible — separate refactors from changing behavior).

* `Refactor: ...`
* `Change formatting ...`
* `Add this feature ...`

This way I can suggest where the reviewer spends the most attention.

## 3. Short feedback loop makes programming fun

Why is programming so much more fun compared to other engineering disciplines? Perhaps because it's so quick to build something and see the result of your work. If you're building skyscrapers or airplanes, it takes years to see the product you've been working on. This is also the reason why a lot of programmers find UI (or game) programming more enjoyable — because you can code something up and quickly see a fancy effect on the screen, which makes you want to do more.

Now **PRs make this feedback loop longer**. You code something up but it's nowhere close to being integrated and working. You now have to wait for the reviewer, go through his remarks, discuss them, change the code...

There are a lot of processes for managing programmers' time, quality of the code, but I believe it pays off to also manage programmer's _energy_ and _momentum_.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Working on a project now without a laborious PR review process, and it feels like I&#39;m flying.</p>&mdash; René Wiersma (@Rene_Wiersma) <a href="https://twitter.com/Rene_Wiersma/status/1360508416612048898?ref_src=twsrc%5Etfw">February 13, 2021</a></blockquote>

## 4. Reviews tend to be superficial

Perhaps it's familiar to you:

* someone reviewed your PR, but only pointed out simple things — actually relevant things were not addressed: data flow, architecture, corner cases
* you were asked to review a PR, but you were only able to point out some simple things — you just submitted them to give the impression that you made some effort reviewing the code

Why is that? In order to properly review a non-trivial piece of code, I need to focus, get deep enough and build enough context — almost to the extent that the PR author did while coding. The reviewer has to do it without the privilege of being able to put his hands on the keyboard and without the same amount of time. **Proper review takes the same amount of focus as actual coding. Why not pair-program instead?**

The superficiality of reviews is amplified by the following factors:

* reviews being mandatory
* size of the pull request
* randomness of the person involved
* lack of shared context of the reviewer

## 5. Merging is blocked by remarks that shouldn't be blocking

Remarks made by the reviewer can fall anywhere on the spectrum of whether they should block merging or not: from **a mistake that'll bring production down** to **cosmetic suggestions** or opinions (with more of the latter ones). How do we account for this variety? Typically, any PR comment makes a dispute that needs to be resolved before merging.

## 6. It's easier to fix than to explain the fix

Let's say the reviewer has an idea how to make a piece of code in you PR better. They explain it in a comment. The original author has to understand it first, agree with it, and then is expected to implement it. Often it's better to let the original author merge his thing, and let the reviewer implement his remark post-factum? Faster, less costly, less frustrating. **PRs promote more words instead of action**.

## 7. Developers are slower to adapt the _responsibility mindset_

Compare these two developers:

* Developer 1 makes subsequent commits to a branch, then creates a PR, then has it reviewed and merged.
* Developer 2 splits his feature into small non-breaking pieces, makes subsequent commits to mainline, his code is integrated right away and possibly deployed

Which developer will faster learn to _code responsibly_? The first one knows that whatever they commit, first lands on a branch, and doesn't affect anything. Then there's the review, so if they commited anything blatantly wrong, perhaps the reviewer will catch it.

The second one knows that every line they write can screw up things for other developers or even bring production down. They watch their step, they know they are the only one responsible for this change. **It shortens the delay between making a mistake and seeing the effect of it**.

People argue that you need PRs because of junior programmers. Probably yes, but do you consider how fast such a person can stop relying on reviews and develop his own sense of responsibility?

## 8. PRs discourage _continuous refactoring_

I believe refactoring is an activity that should be performed continuously. It's good to follow boy scouts' rule: **always leave the place better than it was before**. Over time it can lead to nice codebases. With PRs, though, this rule is harder to apply: if I see a piece of code worth fixing while working in this specific area, I can now:

* fix it in my PR and worsen the reviewability of it by including a non-essential change
* change the branch, create another PR, refactor, wait for review, merge the PR into your original PR, continue

The latter imposes some additional effort (_tax_) which means that some refactorings won't be attempted.

Some discussion with interesting arguments:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Hypothesis:<br><br>PR-based workflow kills continuous refactoring.<br><br>I see a piece of code I can improve while working on a feature and... no, I&#39;m not doing it now to avoid having irrelevant stuff in the PR (and reducing reviewability).</p>&mdash; Tomasz Wróbel (@tomasz_wro) <a href="https://twitter.com/tomasz_wro/status/1361663527593906177?ref_src=twsrc%5Etfw">February 16, 2021</a></blockquote>

## 9. Negative emotions

Mandatory PR reviews can induce way more negative emotions than needed. Let's say someone nitpicks on a PR because they had to point out something. The original author takes it personally. **We all have limited emotional budgets** — it's better not to waste it on avoidable stuff. In rare cases it can lead to absurd behaviors, e.g. developers making arrangements behind the scenes: _I'll approve your PR, and you'll approve mine_.

## 10. How do you switch to branches with migrations

You obviously sometimes need migrations while working on a branch. What do you do if you then have to switch back to another branch locally? Cumbersome.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">With a Rails app, how do you manage switching between a bunch of different branches that have different DB schemas/migration states? Blowing away the whole DB every time gets old fast.</p>&mdash; Nate Berkopec (@nateberkopec) <a href="https://twitter.com/nateberkopec/status/1377348675291111426?ref_src=twsrc%5Etfw">March 31, 2021</a></blockquote>

## Contributions from the readers:

### 11. PRs' impact on overall product quality

Here's a contribution from [@PavelKaczor](https://twitter.com/PavelKaczor):

> No one would argue against PRs if we were sure that they substantially contribute to overall product quality. In fact, are we sure PRs increase overall product quality at all? Probably yes, but how much? Probably not much because deciding factors are not the ones that are impacted by the PRs. How do PRs affect the architecture and the design of the system (division of responsibilities between services, how the services communicate with each other, etc.), how do they affect requirements gathering / domain distillation process? If we don't see positive impact on these factors then why should we invest time and energy on activities that do _not_ matter. In worst case scenario we could end up with overall product quality decreased due to uproductive consumption of time and energy and distraction from activities that _do_ matter. How often do PRs focus on implemenation details? Is it a big deal if the implementation of a service is not so clean, optimal as one could imagine, especially if the service is an independent application (aka micro-service)? How much time do you spend on discussing, cleaning the requirements _before_ starting the implementation of a new feature? How does this activity influence the quality of the produced code? Think about the universal Pareto's Law (80/20 Rule) and try to follow it. Concentrate on processes that contribute 80% of your product's value.

## Now, how to make the _10% change_ in your team today

I'm not suggesting a total outlawing of PRs. Gerald Weinberg says you can only make the 10% percent change in your organization. What are examples of such changes?

* Pair program with a teammate on a complicated feature instead allowing feedback only when PR is finished.
* Try a feature toggle to prevent your unfinished work from affecting production (instead of keeping it on prod). Flipper is a nice gem for that, but you can simply start with an ENV var switch or hiding the feature on UI.
* Try getting into a habit or reviewing commits post-merge.
* Make approvals not mandatory - let the developer merge the PR right away and have it reviewed post factum.
* Make PRs not mandatory — let the developer choose if they want to develop in a PR or commit to master.
* Encourage post factum improvements by reviewers instead of comments.
* Make it clear which PR comments are blocking, and which are free to be addressed after merging the PR.
* Try to learn how to split your feature into small shippable pieces which don't break production.
* An idea from [@CraigBuchek](https://twitter.com/CraigBuchek/status/1383976735922786304): You don't have to pair on writing the code, but you can pair with someone to do a code review (in real time).

If your manager thinks pair-programming is a waste of time, perhaps they can be convinced by a meme:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Super excited that you liked my last drawing. Here is a new one! 🤗 <a href="https://t.co/vULVb0uoFo">pic.twitter.com/vULVb0uoFo</a></p>&mdash; Vincent Déniel (@vincentdnl) <a href="https://twitter.com/vincentdnl/status/1252628160111394817?ref_src=twsrc%5Etfw">April 21, 2020</a></blockquote>

## Want to discuss?

* Reply in [this twitter thread](https://twitter.com/tomasz_wro/status/1381598019674587141)

<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
