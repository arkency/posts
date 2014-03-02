---
title: "2 ways to deal with big and complicated features"
created_at: 2014-02-28 22:45:56 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :aar_newsletter
tags: [ ]
---

<p>
  <figure>
    <img src="/assets/images/vision/feature_vision_to_stories.jpg" width="100%">
    <details>
      <a href="http://www.flickr.com/photos/24141546@N06/7710205034/sizes/z/">Photo</a>
      remix available thanks to the courtesy of
      <a href="http://www.flickr.com/photos/24141546@N06/">EladeManu</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

## From feature vision to stories

One of the challenges of managing software projects is delivering big features.
We already told you that we prefer to work with [small](/2013/09/story-of-size-1/), 
[prioritized and unassigned](/2013/10/refactor-to-remote-leave-tasks-unassigned/)
stories that [anyone can take and finish](/2013/10/take-the-first-task/). But how
do any up there? Especially, if what the customer comes to you with, is a big document,
describing the features that you must implement.

<!-- more -->

## Create tickets upfront

You can create all the tickets upfront based on the document
you received or vision of the customer.

This is sometimes possible. **When the change or feature 
request by the customer is in the scope of week
work and unlikely to change, it might be worthy
to spend a little time, think about how to reach the
goal with small steps, and extract all the tickets**. The
benefit is that from now on, other people can just
take the first task and start working. Perhaps some of
the tasks are independent so you can prioritize them
with your customer and have a very clear path to
your goal. When all the tasks are visible, it is easy
for everyone to see the progress.

But this is often impossible and impractical for a really
big tasks that are going to take longer than a week. But before
we dive into another strategy, let's talk for a moment what
we want to actually achieve.

## Expectations and assumptions.

**We don't want to assign one programmer for 3 weeks to work on a
separate branch in a complete isolation from the
rest of the team**. Instead we believe that having multiple people
working on the feature is beneficial because they provide fresh
view and feedback about the code and feature. It also improves
_Collective Ownership_ which we care deeply about.

In the spirit of Agile **we don't want to deploy this feature after
long time of working on it. We want to build it iteratively and
deploy often**. We will seek the feedback from the customer and from
the users of our software. We want to continuously deliver value.
And if the customer decides to change the priorities and focus after
10 days of working on the feature to something new, that can possibly
bring greater value, then it shall remain her/his right. In such case
we would like everything that has been done and deployed so far
to be usable and beneficial to the users.

When the programmers implement small parts of the feature **we want
them to have a good overview of it**. Although when they work on a
small ticket, their responsibility is to implement the small part
enough to mark the story as done, it is also their responsibility
to make the solution friendly to next programmers implementing
further stories related to the feature. In other words, to implement
something small, but have in mind the big picture.

And that brings us to the second strategy. We call it _Documentation as
floating ticket_.

## Create the tickets as you go

You keep the big feature (specification) as a ticket in your backlog. But
whenever you reach it as part of _take the first task_ rule, instead of
starting to work on it as a developer, you put your project manager hat on.

You look into the specification and compare it to the current
state of project. The specification is also a document that
can be changed by everyone so you can see what parts
of it have already been extracted into tickets in the past
and what still needs to be done. Based on the priorities
mentioned in the ticket or based on your conversations
with the client it is now time for you to extract tickets.
How many of them? That’s up to many factors. Maybe
you can see clear path that can lead to having nice feature
from the documentation so want to extract few small tasks.
Maybe you know that the client want to keep working
slowly on these features so it is ok to only extract one story
from it. Whatever the reasons are, make sure the strategy
is discussed with the customer and your team and the rules
are clear for everyone.

<a href="/assets/images/floating-doc/documentation_as_floating_ticket.png" rel="lightbox[doc]"><img src="/assets/images/floating-doc/documentation_as_floating_ticket-fit.png" /></a>

So you decided to extract two task. You create them on top
of your backlog so that you or your team mates can start
working on them. Now based on similar factors described
in previous paragraph you need to decide how to reschedule
extracting next tasks from the spec. If the spec is very
important and everyone should be working on it, you can
leave it in place so that whenever currently extracted tasks
are finished, you will reach the document again and mine
new tasks from it, until the spec is fully implemented. If
however you want to work on multiple parts of the system
at the same time and customer expects progress also in
different parts of the app, you should move the spec down
in the backlog. The least important spec, the lower you
can move it down. You can have strict rule how much it
should be moved or you can do it based on your judgment
and knowledge about project priorities. If everything from
spec is done, mark it as done as you do with the rest of the
tickets. If you get the knowledge in the meantime that there are
more important issues and your team should stop working
on features listed in the spec, then it might be a good idea
to put it out of backlog, until the customer decides to bring
it back in the game.

You end up with extracted tickets, spec knowledge, updated
document about which parts are already moved into tickets
and which parts are still only covered in the spec. You can
go back to using _Take the first task_ strategy until you are
out of tickets, at which point you need to find your project
manager hat and wear it for at least a moment again.

## Get to know more

I hope reading this article was beneficial for you. If you want to
find out more about techniques that will

* help you improve _Collective Ownership_,
* deliver value to customers,
* have a nice and steady workflow,
* allow you to refactor more easily while working on the feature you were asked for.

please sign up now to the newsletter below. We will email you from time
to time about other techniques that work for us.
