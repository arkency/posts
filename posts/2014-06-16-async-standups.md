---
title: "Take most out of async textual standups"
created_at: 2014-06-16 19:04:36 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :arkency_form
tags: [ 'remote', 'async', 'communication', 'standups' ]
stories: ['async-remote']
---

<p>
  <figure>
    <img src="/assets/images/async-standup/async-standup-smaller.jpg" width="100%">
  </figure>
</p>

When you work remotely, you want to have some kind of a standup meeting regularly. In our team, after experimenting with many different approaches, we settled with **text-based, asynchronous standups every day**. Additionally, every project has a weekly 'sync' meeting.

<!-- more -->

Whatever tool we currently use for remote communication (irc in the past, now Slack), we create a channel that is dedicated to #standup. **We don't have a specific time to post there, usually we do it, when we begin our work session** - so, in the spirit of async - different people at different times.

I consider #standup to be a very good opportunity **to communicate cross-project, to educate, to learn, to help**. Short standup messages are not bad, but they miss this opportunity.

When writing the standup message, **think more about the others, than about yourself** - what can they get from it by reading your status?

### Example

_Yesterday I finished the "fix the price calculator" feature, which was mostly about removing the Coffee code and rely on the value retrieved from the backend, via ajax. The nice thing was that the backend code was already covered with tests, while the Coffee one wasn't. After that I helped Jack with the "allow logging in with email" feature (we need it now because we have a batch import of users from system X soon). After that I did a small ticket, where I block buying licences for special periods of time. This was nicely TDD'ed, thanks to the concept of aggregate, introduced by Robert recently - all the tests pass < 1s. Here is a commit worth looking at. Today I'm going to start with foreman'ing the recent commits and after that I want to work the XYZ system to allow a better editing of entries. I'm not sure how to start it, so all help is welcome._

### What's good?

* many details, 
* letting other people jump in and help me, 
* some opinions about the code that I saw, 
* some details about practices I applied (TDD, foreman'ing)
* reminds about some business information - import of users from the X system, happening soon
* links to the commit (potential education)

### Format

1. yesterday 
2. today 
3. good things 
4. bad things 
5. challenges 
6. call for help 
7. reminder about good practices (tdd, foreman, help colleagues) 
8. code examples (link)
9. business-related info
