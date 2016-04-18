---
title: "How I hunted the most odd ruby bug"
created_at: 2016-04-18 09:59:28 +0200
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

Every now and then there comes a bug in programmer's life that is different than anything
else you've encountered so far. Last time for me it was 3 days of debugging to find out that MySQL
was returning incorrect results. We didn't have to do much to fix it. We removed an index and created it again
from scratch. There, problem gone. But that was a few years ago.

Last week I was hunting an entirely different beast. But before we dive into details, let me tell
you a bit about the business story behind it.

<!-- more -->

We are working on a ticketing platform which sells tickets for big events, festivals but also for smaller gigs.
The nature of this industry is that from time to time there are spikes of sales when an organizer opens
sales for hot tickets. Early birds discounts and other promotions. You've probably attended some conferences
and concerts. You know how it works.

In our application there are tons of things that happen in the background. Especially after the sale. We want the
sale to be extremely quick so that we can handle the spikes nicely without hiccups. So when the purchase is finalized
we have 15 background jobs or maybe even more. Some are responsible for generating the PDFs of those tickets,
some are responsible for delivering emails with receipts. Other communicate with 3rd party APIs responsible for
delivering additional services for the buyers.

Let me show you how the sales spikes look like.

<%= img_fit("ruby-honeybadger-resque-slow/spike.jpg") %>

And their effect on the number of queued jobs that we had:

<%= img_original("ruby-honeybadger-resque-slow/spike.jpg") %>