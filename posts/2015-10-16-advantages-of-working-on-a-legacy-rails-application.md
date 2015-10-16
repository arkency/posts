---
title: "Advantages of working on a legacy application"
created_at: 2015-10-16 11:17:21 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'legcy', 'rails' ]
newsletter: :arkency_form
---

Are there any advantages to working on such an application?
Would you rather prefer working on a greenfield?
Here is my stance on this topic and my personal story.

<!-- more -->

## My first (legacy) Rails job

When I finished my Master's Degree about Ruby on Rails, **I had one dream.
To work with Ruby on Rails on daily basis**. I have already quit my first
job in a corporation a few months earlier to focus on studies. I was free
to start any job, anywhere. I couldn't find Rails job at my current city,
at that times Rails was not really that much popular in Poland. But I
found a new job in Warsaw and moved there. My first Rails job. How
exciting.

On my first day I sit down, pulled the repository, installed dependencies and
run the tests. Almost everything failing. I looked at the code and it was
terrible. So much business logic in controllers and views. **I wanted to cry**.
My contract obligated my to work there for 12 months and I wanted to run
away on day one.

**My dreams were crashed**. I read so many blogposts, articles and books about
Rails, about testing in Rails, doing TDD. I wanted to work in Rails because
I wanted to work with **codebase covered by tests**. Just like Ruby is, just like
Rails is. But the reality was radically different. Big codebase (>100 models
and controllers). Complicated business domain. And useless, failing, obsolete
**tests which don't give you much confidence in refactoring**.

You might think that after such experience my answer to the question, I asked
at the beginning would be very negative. But on the contrary. I've learnt
a lot since that time.

## The advantages of working on a legcy app

### Humble programmer

Legacy codebase teaches you humility. We, the programmers are writing this code.
We, our colleages, our friends. Not some mythical creatures from Wonderland. We,
ourselves. Doing our best, one commit at a time. And when we look later at our
codebase we are often not so happy about the final result. **And we need to live
with it**. Understand our limitations. Keep reading, keep getting inspired, keep
getting better.

### Long term effects

2 years later I was working in a different place and a developer called me,
trying to convince me to move to a new job. It was a marketing agency using Ruby
on Rails for websites for their customers. One of his argument when he was trying
to convince me was that **their projects have an average lifespan of 3 months**.
So if you make a bad decision regarding architecture or gems or you wrote a bad
code, you don't have to live very long with it. Soon, you will have a new chance
to start a fresh project. A new greenfield. **I rejected that offer**. Legacy
applications that you keep working on for years and maintain them give you
the ability to understand the long term effects of your decision. **You have to
live with the consequences**. You see which decisions were good and which were bad.
What helps you one year later and what you regret. Short them project, new
projects usually don't give you that kind of feedback.

From a few years old, big, inherited Rails app you will learn a lot. What it means to
couple every part of the application with every other part of it without any kind of
separation. On top of that, coupling with every gem that hook directly into Active
Record. After week (months, or even a year - depending on the state of code you
inherited) that you spent fighting with small and medium bugs happening everywhere (because
of the coupling) you will probably have a **much better understanding of the domain of
the business**. I am working in a project where I can easily name 20 different modules that
this application should consist of. Now, whenever a new feature is introduced I am careful
to think how it affects all the already existing features. In other words, you learn **how
the decision you make and others made before you play in the long term**.

As my client once said to me: _The only reward that we get for being successful (as a business) is more complexity_.
The bigger the organization, the more processes, features and use cases, the more complexity
needs to be handled by the code. That is our **curse** (because we try to fight the complexity
everywhere and there is alway accidental complexity added as well) **and our reward**. Because the
feeling that you can handle all that complexity for your client and keep things
working and profitable is nice.

Grown businesses and applications give you a tremendous opportunity to recognize bounded
contexts in the app. What modules it is built from. Even if you don't see it on the code
level, you start to **see it on the organizational level**. On the conceptual level.
This starts to give you clarity in terms of **which way the application should be
refactored into**.

### Keep calm and commit

It's true that there can be a lot of bad emotions, negativity, frustration, even **rage**
when you work with legacy codebase. It's interesting that codebase (non living thing,
not even a material object) can have such an impact on our feelings. But you
can treat it as a lesson. How to convert those emotions into something positive?
But to do that you [need](http://martinfowler.com/books/refactoringRubyEd.html) [to](https://www.goodreads.com/book/show/85041.Refactoring_to_Patterns) [have](https://www.goodreads.com/book/show/44919.Working_Effectively_with_Legacy_Code) [refactoring](http://rails-refactoring.com/) [and](https://www.goodreads.com/book/show/44936.Refactoring) [communication skills](http://andrzejonsoftware.blogspot.com/2014/01/refactoring-human-factor.html). And **desire
to keep improving**.
It's hard, it's tiresome and **exhausting**. But what other options do we have? To
give up?

It's not that you are alone with those problems and challenges. Small companies
write shitty code and [big companies write spaghetti code](http://www.safetyresearch.net/blog/articles/toyota-unintended-acceleration-and-big-bowl-%E2%80%9Cspaghetti%E2%80%9D-code) 
as well.
In the world where almost everything, from factories, power plants, planes and [cars](http://www.theverge.com/2015/10/7/9470551/volvo-self-driving-car-liability)
are controlled by software this problem is only going to get bigger. And we need to
take [responsibility](http://blog.cleancoder.com/uncle-bob/2014/11/15/WeRuleTheWorld.html) for [our actions](http://blog.cleancoder.com/uncle-bob/2015/10/14/VW.html) .

### Value driven negotiations

Working on a legacy application makes it easier to operate on value when
negotiating with business. Recently I've been implementing a cross-selling option
for one of our clients. From the frontend perspective it was one checkbox here
and a couple of text inputs later. Backend required more work, much more changes,
API integration, etc etc. 10 minutes after enabling it with a
[feature toggle](http://martinfowler.com/bliki/FeatureToggle.html) the first customer
already purchased this option. We knew it is working, valuable for people and they
will keep using. One day later we more-or-less knew the conversion rate. Multiply
it by their number of daily transactions, take average value of order into consideration
and you **have a pretty good guess as to how much money this brings to the table in the next
year**. Next time when you negotiate your salary or your rate you can **use those numbers**.
Yes, we cost you $ XYZ but the features we do for you give you $ ABC.

When you work on new projects you usually don't have such a comfort. There is not much
traffic, not so many customers and the startup might be still burning money. In such
case it is much harder to use the value that you bring to the customer as a starting
point for a salary negotiation.

Bigger, older, **legacy business are already verified** in some way. Either they are at least
very good at convincing investors. Or they are onto something and they are doing something
good for the customers. Otherwise, **why would they keep coming?**

Also, we found that it is much easier to handle billing with such mature organizations.
**They don't whine about every dollar** they need to pay you. They just pay. In fact, they
often want even more of our developers later. **They can afford us**.

### Feedback

And a final thing that I love most about it. Super fast customer feedback loop.
The cross-selling feature for the platform that I told you about, it took 2 weeks and dozens of
pull requests and deploys. It was used by an user within 10 minutes. Then I was working on
another feature. I was sceptical that people will buy it, but the business product owner wanted
to go for it. We did our best, shipped it, enabled on production. Same story. 10 days later
and we already knew that it was a success. **The fact that you can just ship something and get an
immediate feedback is a tremendous benefit**.

### TLDR

* Your legacy project is probably successful if it is capable of living that long
* The domain is probably quite big and interesting
* The customers can quickly provide a feedback and let you a/b test the solutions
* The company behind the project needs you and should pay without problems

**I wish you good luck in your legacy project and lot of learning opportunities.** 
