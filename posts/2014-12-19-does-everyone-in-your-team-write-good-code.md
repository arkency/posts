---
title: "Does everyone in your team write good code?"
created_at: 2014-12-19 16:40:03 +0100
kind: article
publish: true
author: Andrzej Krzywda
tags: ['refactoring']
---

How does it feel when someone pushes new code to the repo and the code doesn’t fit your standards?

Any emotions?

Is there anything you can do about it?

<!-- more -->

You could start an argument, but is it really the best way? Negative emotions won’t help here.

You could fix the code, but are you sure that this time your code will be acceptable by the other person?

If the team has totally the same opinions on the code, fixing is OK - no possible conflict here. Otherwise, you need to step back and improve the same understanding.

How can you get the team to have a similar understanding of code quality?

Each of us has a different background. Different projects, different languages, different paradigms. We read different books. We value different gurus/blogs. 

It’s close to impossible to get the same understanding, easily. Luckily, we can get there, step by step. We can help each other educate.

This all sounds very abstract. Luckily, the Rails community is a bit more unified. 

Well, OK, we’re not really unified. That was a lie. Simplifying things a bit, there are two Rails camps - the OOP camp and the Rails Way camp. Both camps seem to be unified on their own. If you have a mix of those people in the team, then you may have a hard time to agree on some principles.

The OOP camp (I don’t like the name, but don’t know any better one) seems to share some common fundamentals. They read Martin Fowler, Uncle Bob, Kent Beck, Michael Feathers, Greg Young and very often agree with their words.

As a side note - there’s a more fundamental difference between OOP and The Rails Way than there is between OOP and FP.

Let me focus on the OOP camp here. In this camp, it’s mostly OK to extract new methods, extract new classes, create new layers (like services or repos).

If your team is mostly OOP, then the differences in coding standards won’t be big. Some of the differences may be a result of only slight differences in understanding. Some of them may be  just because someone wasn’t really familiar with the exact variation of the concept.

I know at least 4 ways of implementing a form object. 

I know at least 6 ways of implementing a service object.

See the problem?

Some coding inconsistencies are OK to have within one codebase. 

Just recently, in our team we’ve discussed where does authentication belong in a typical Rails app. Even in the OOP camp, there’s not much discussion about it - authentication is handled at the controller level. 

There’s a problem with authentication at the controller level, though. It makes the controllers deal with non-http concerns. 

Moving the authentication to the service objects also doesn’t sound ideal. In fact, we will not easily find a good place for authentication. It is a cross-cutting concern, so it doesn’t fit nicely into the OOP paradigm.

I could talk about how we can use Aspect Oriented Programming for that, but that’s a topic for another occasion. In a way, we’ve covered that in our blog post - http://blog.arkency.com/2013/07/ruby-and-aop-decouple-your-code-even-more/

What I’m trying to tell here is that, sometimes different standards are OK. They may show us in the code which approach is better. I’d accept all approaches to authentication in a code review, assuming that we all understand the pros/cons.

Some code changes are harder to accept

Adding new controller filters is one example. I’m very sceptical about it. Most of the logic in filters belong to the service layer. If I see a commit that introduces such change, I try to explain why it may not be the best idea. 

Another example is when I see that we pass some data to the Rails view and we do it with an instance variable. There are some reasons, why it’s not always the best idea. In the code review comments I try to explain that.

Explaining such cases takes time. I usually try to explain the bigger picture - why certain things fit better in the overall architecture.

The refactoring recipes

Over time, I’ve collected all of such arguments and released a whole book on this topic. The “Fearless Refactoring: Rails Controllers” is exactly this - a way of encapsulating those arguments into one place. It’s not only that, though. I’m focusing on the explanation how to apply the refactoring in a fast way. I call it - recipes. Thanks to the recipes, I can expect that people can take the instructions and apply the code change within 30 minutes of their time.

Being time efficient is one of the reasons why the recipes exist. I’ve seen refactorings taking DAYS and ending with bugs. This is not a refactoring.

Recipes are about quick 20-30 minutes (pomodoro anyone?) sessions of super-safe code improvements.

The refactoring recipes represent a consistent way of thinking about the code in a Rails app. I call it The Next Way. We often work with legacy The Rails Way apps, so we need to get the code from such state and gradually improve it.

“This codebase looks like a collection of random blog posts” 

That’s one of the problem of applying random advices from different places, how to change the Rails code. It’s a problem, indeed.

The Next Way is not The Best Way by any means. What I tried to do is to create a consistent approach.

Since the book started it was much easier to work in a team and just point to the recipes and chapters whenever we tried to explain some concepts. Everyone in the team has the book.

I’ve also noticed other teams doing the same - this is what I received from one of the readers:

“In our company each developer who achieved basic knowledge about rails way and all of it benefits and disadvantages gets a really important ticket - read Fearless Refactoring asap. 

This book helps us refactor old legacy code that is a lot more complicated that it should be for given feature. All solutions included there give us knowledge how to resolve complex problems by writing clear and well-organized code using the best OOP rules.”

As much as I’d love everyone to own a copy of the book, I know it’s not possible. So, the teams where only one member knows about the recipes won’t really get much value from it - it’s not that easy to transfer the knowledge.

The Rails Refactoring Recipes website

That’s why the Rails Refactoring Recipes website was born. It’s impossible to move the whole book to the website, but we’ve moved what’s most useful - the recipes algorithms and before/after code examples. 

If you own the book, you know there’s much more to it, in the book we list warning and edge cases on each recipe. We also show every step with the code, while here just have the final result. Still, what the website gives to all of us is the fact that each recipe now has an URL. 

Each recipe has an URL so you can always link to it in the code review comments. This may be a huge time-saver for you and your team. Now, instead of explaining the suggested refactoring you can just paste the URL.

http://rails-refactoring.com/recipes/

What can you do with this website?

First, have a look at the existing recipes. Find the ones, that may be most relevant to your project. If there were recent commits in this area, jump to github, find the Pull Request or commit and paste the URL of the recipe in the commit comment. This way, you will communicate the idea to the team and to the author of the code.

Second, if you know that your team would benefit from knowing of a recipe that is not on our website yet, then please hit "Reply" and let me know about it. We want the recipes collection to grow fast!

Additionally, if you think the whole team would benefit from reading the full book, I've added a special deal - you can now buy 5 copies in the price of 4, if you use the link:

Fearless Refactoring: Rails Controller x 5 reader license

The REFACTORING discount code will make it another 20% off!

