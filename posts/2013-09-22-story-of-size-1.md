---
title: "Developers oriented project management: Story of size 1"
created_at: 2013-09-23 20:17:43 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter: aar_newsletter
tags: [ 'story', 'size', 'one', 'remote', 'work', 'project', 'management' ]
stories: ['async-remote']
---

<img src="<%= src_fit("story-1/full.png") %>" width="100%">

In one of our projects we decided to try a lot of new things in the area of
project management. One of the most beneficial change that I noticed was using very,
very small task as the primary tool to assign and track work.

<!-- more -->

## The Pain

It's the middle of the Wednesday. You thought it is gonna be such a good week.
You started coding your task on Monday, and you still keep working on it.
Your boss keeps asking for status update. Customer would
also like to know how things are going. It's the third day of working on
it. It's finally the time to deliver some code. You need to merge your branch
with master often to stay in the loop. And you can't help much your friends
working on different part of the system. Lot of time put into the task,
but yet no visible effects to anyone except you so far. This whole situation
feels little stressful. Not only for you, but actually for everyone.

This story might sound familiar to you. Maybe you don't experience it every
week but surely every now and then. If not, consider yourself lucky! There
are many factors that can lead to such situation but one of the problem is
usually the size of the story (ticket). It's just too big. The solution?
Make it small. How small? Really small. About the [size](http://agilefaq.wordpress.com/2007/11/13/what-is-a-story-point/)
of one point.

## One point story

Story of size one has few constraints:

* It's about **2-4 hours of work**. I like to think about it as half of working day.
I should be able to deliver at least 2 story points a day. The task will take
whole day in worst case scenario when it was underestimated 2x.
* It still **provides business value**. Meaning there is a benefit for the users, admins,
owners, or stakeholders.
* The story should be **indivisible**. If you can split it into two or more stories,
that still bring value, then go ahead and split it.

## The benefits

We sticked with this rule because it turned out to be beneficial:

* It's easier to track progress
* For me as a programmer, marking task as done is rewarding and gives me
a [closure](http://en.wikipedia.org/wiki/Closure_%28psychology%29). When you
mark two things a day as _done_ in project, you have a **sense of accomplishment**.
Working for a long time (days or even a week) without such feedback is
tiresome. I know that some companies give programmers a week long tasks and at
the of the week, the customer approves or rejects the stories (usually based on
code available on staging server). But how would you feel when your story is
rejected after 40 hours of work put into it? So the remedy in my opinion is to
have smaller tickets. And to create new tickets for things that needs to be
improved. Close tasks as soon as possible. Closure is emportant for everyone
in your team. Especially programmers who do the job, but managers and customers
also need it. Otherwise people get streesed that _nothing is done_ when in fact
a lot was done and finished. Let your tools reflect that.
* It improves **Collective Ownership**. Smaller tasks mean people can more often
work on different parts of the system and learn from each other.
* Keeping stories small, **makes people more mobile** across different projects that
your company is currently working on. It's way less cognitive overhead to start
working in another project on a story that is going to take 2-4 hrs vs. joining a
project only to find out that you need to do something that is going to take few
days.
* Having small tasks **minimizes your risk** of not deliviering in case of troubles.
* When things are delivered faster, the business is profiting from them earlier and
the feedback loop is shorter. With small stories you **deliver new features
gradually** and users get accustomed to them. Programmers can work better based on
the knowledge of the domain problem they are solving. So next estimates are more
accurate.

This technique can be used for managing all kinds of projects but in our case
it was battle tested on full team working remotely. Remote projects and teams
have their own nature and small tasks fits great in this environment.

## What's more

Did you like this article? You can find out more on this and similar topics
in our book _<%= landing_link() %>_.
You can also [subscribe to the newsletter](<%= aar_newsletter_subscription_link %>)
below if you want to receive tips and excerpts from our work on the book.
They will be similar in form to this blogpost.

## In this series

* [Story of size 1](/2013/09/story-of-size-1/)
* [Leave tasks unassigned](/2013/10/refactor-to-remote-leave-tasks-unassigned/)
* [Take the first task](/2013/10/take-the-first-task/)
* [Chronos vs Kairos: Find out how you think about time when working on a project](/2013/11/chronos-and-kairos/)
* [Developers oriented project management](/async-remote/)
