---
created_at: 2015-06-10 11:10:11 +0200
publish: true
author: Andrzej Krzywda
tags: ['testing', 'mutation testing', 'tdd']
newsletter: arkency_form
---

# How good are your Ruby tests? Testing your tests with mutant

## New-feature-bugs vs regression-bugs

There are many kinds of bugs. For the sake of simplicity let me divide them into new-feature-bugs and regression-bugs.

New-feature-bugs are the ones that show up when you just introduce a totally new feature.

Let's say you're working on yet another social network app. You're adding the "friendship" feature. For some reason, your implementation allows inviting a person, even though the invitee was already banned. You're showing this to the customer and they catch the bug on the testing server. They're not happy that you missed this case. However, it's something that can be forgiven, as it was caught quickly and wasn't causing any damage.

<!-- more -->

Now imagine that the feature was implemented correctly in the first place. It was all good, deployed to production. After 6 months, the programmers are asked to tweak some of the minor details in the friendship area. They're following the scout rule (always leave the code cleaner than it was) so they do some refactoring - some methods extractions, maybe a service object. Apparently, they don't follow the [safe, step-by-step refactoring technique to extract a service object](http://blog.arkency.com/2015/05/extract-a-service-object-using-simpledelegator/). One small feature is now broken - banned users can now keep inviting other users endlessly. Some of the bad users notice this and they keep annoying other people. The users are frustrated and submit the bug to the support. The support team notices the customer and the programmers team.

Can you imagine, what happens to the trust to the programming team? 

"Why on earth, did it stop working?" the customer asks. "Why are you changing code that was already working?"

It's so close to the famous "If it works, don't touch it".

From my experience, the second scenario is much harder to deal with. It breaks trust. Please note, that I used a not-so important feature, over all. It could be part of the cart feature in the ecommerce system and people not being able to buy things for several hours could be thousands dollars loss for the company.

## Writing tests to avoid regressions

How can we avoid such situations? How can we avoid regression bugs?

Is "not touching the code" the only solution?

First of all - there's no silver bullet. However, there are techniques that helps reducing the problem, a lot.

You already know it - write tests. 

Is that enough? It depends. Do you measure your test coverage? There are tools like rcov and simplecov and you may be already using them. Why is measuring the test coverage important? It's useful when you're about to refactor something and you may check how safe you are in this area of code. You may have it automated or you may run it manually just before the refactoring. In RubyMine, my favourite Ruby IDE, they have a nice feature of highlighting the test-covered code with green colour - you're safe here.

Unfortunately, rcov and simplecov have important limitations. They only check line coverage. 

What does it mean in practice?

In practice, those tools can give you the false feeling of confidence. You see 100% coverage, you refactor, the tests are passing. However, some feature is now broken. Why is that?
Those tools only check if the line was executed during the tests, they don't check if the semantics of this line is important. They don't check if replacing this line with another one changes anything in the tests result.

## Mutation testing to the rescue

This is where mutation testing comes in. 

Mutation testing takes your code and your tests. It parses the code to the Abstract Syntax Tree. It changes the nodes of the tree (mutates). It does it in memory. As a result we now have a mutant - a mutated version of your code. The change could be for example removing a method call, changing true to false, etc. There's a big number of such mutations. For each such change, we now run the tests for this class/unit. The idea here is that the tests should kill the mutant.

Killing the mutant happens when tests fail for a mutated code. Killing all mutants means that you have a 100% test coverage. It means that you have tests for all of your code details. This means you can safely refactor and your tests are really covering you. 

Again, mutant is not a silver bullet. However, it greatly increases the chance of catching the bugs introduced in the refactoring phase. It's a totally different level of measuring test coverage than rcov or simplecov. It's even hard to compare.

Suggested actions for you:

* If you're not using any kind of test coverage tools, try [simplecov](https://github.com/colszowka/simplecov) or [rcov](https://github.com/relevance/rcov). That's a good first step. Just check the coverage of the class you have recently changed.

* Watch this short video that I recorded to show you the mutant effect in a Rails controller

<iframe width="420" height="315" src="https://www.youtube.com/embed/G7c0_FlR-R4" frameborder="0" allowfullscreen></iframe>

and this video which shows visually how mutant changes the code runtime:

<iframe width="420" height="315" src="https://www.youtube.com/embed/awVUqUxhx8M" frameborder="0" allowfullscreen></iframe>

* Read those blogposts we wrote where I explain why mutant was introduced to RailsEventStore gem

[Why I want to introduce mutation testing to the rails_event_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)

[Mutation testing and continuous integration](http://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

* Listen to the third episode of the [Rails Refactoring Podcast](http://rails-refactoring.com/podcast/), where I talked to Markus, the author of mutant. Markus is a super-smart Ruby developer, so that's especially recommended.

* Subscribe to the [Arkency YouTube channel](https://www.youtube.com/channel/UCL8YpXFH1-y3AaELb0H7c3Q) - we are now regularly publishing new, short videos.

<a target="_blank" href="http://www.redbubble.com/people/arkency/works/15343339-kill-the-mutants?always_show=true">
  <div class="fashion flex justify-between">
    <img src="/assets/images/fashion/kill-the-mutants-mutation-testing-ruby-rails-mackbook.jpg">
    <img src="/assets/images/fashion/kill-the-mutants-bag.jpg">
    <img src="/assets/images/fashion/kill-the-mutants-pillow.jpg">
  </div>
</a>
