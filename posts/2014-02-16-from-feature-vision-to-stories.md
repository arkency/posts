---
title: "From feature vision to stories. How do you deal with big and complicated features?"
created_at: 2014-02-16 12:45:56 +0100
kind: article
publish: false
author: Robert Pankowecki
newsletter: :arkency_form
tags: [ 'foo', 'bar', 'baz' ]
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

One of the challenges of managing software projects is delivering big features.
We already told you that we prefer to work with [small](/2013/09/story-of-size-1/), 
[prioritized and unassigned](/2013/10/refactor-to-remote-leave-tasks-unassigned/)
stories that [anyone can take and finish](/2013/10/take-the-first-task/). But how
do any up there if what the customer comes to you with is a big document describing
the features that you must implement.

<!-- more -->

## Create tickets upfront

You can create all the tickets upfront based on the document
you received or vision of the customer.

This is sometimes possible. When the change or feature 
request by the customer is in the scope of week
work and unliekly to change, it might be worthy
to spend a little time, think about how to reach the
goal with small steps, and extract all the tickets. The
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

We don't want to assign one programmer for 3 weeks to work on a
separate branch in a complete isolation from the
rest of the team. Instead we believe that having multiple people
working on the feature is beneficial because they provide fresh
view and feedback about the code and feature. It also improves
_Collective Ownership_ which we care deeply about.

In the spirit of Agile we don't want to deploy this feature after
long time of working on it. We want to build it iteratively and
deploy often. We will seek the feedback from the customer and from
the users of our software. We want to continiously deliver value.
And if the customer decides to change the priorities and focus after
10 days of working on the feature to something new, that can possibily
bring greater value, then it shall remain her/his right. In such case
we would like everything that has been done and deployed so far
to be usable and beneficial to the users.

When the programmers implement small parts of the feature we want
them to have a good overview of it. Although when they work on a
small ticket, their responsibility is to implement the small part
enought to mark the story as done, it is also their responsibility
to make the solution friendly to next programmers implementing
further stories related to the feature. In other words, to implement
something small, but have in mind the big picture.

And that brings us to the second strategy.

## Create the tickets as you go

TODO: Finish it based on book.


