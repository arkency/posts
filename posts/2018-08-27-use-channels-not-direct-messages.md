---
title: "Use channels, not direct messages - 9 tips"
created_at: 2018-09-02 12:59:52 +0200
publish: true
author: Andrzej Krzywda
tags: [ 'async remote' ]
---

There's something about using direct messages (project related) that developers find uncomfortable. At Arkency, we avoid them at all costs, but we also see how hard is to change our client teams habits, sometimes. 

I thought it would be nice to describe the problem and find some solutions. I talk about it from the perspective of a remote/async/distributed team, but I suppose some problems are similar to in-office teams.

My criticism towards direct messages doesn't assume bad intents from the initiatiors of such conversation. I believe it's mostly about not being aware of the consequences.

In this post, I'm focusing mostly on project-related communication - where I believe all the team should be up to date. There are other types of conversations which might be fine keeping secret and hidden from others, if really required.

<!-- more -->

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">remote teams rule nr 1<br><br>no direct/private messages related to work, use channels</p>&mdash; Andrzej Krzywda (@andrzejkrzywda) <a href="https://twitter.com/andrzejkrzywda/status/1033053721905831936?ref_src=twsrc%5Etfw">August 24, 2018</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

# Why is this a problem?

The main thing is the problem with **transparent communication**. 

Whatever happens in direct/private messages is not visible to others in the team. Sooner or later, it will leak that some people talk about a project in direct messages - others will fell left out of the conversation. If the conversation is about some work to do then others in the team are excluded of knowing what are the current priorities. Also, it implicitly creates a pressure on the receiver of the message, that from now on, only she/he is familar with the details provided here. The context (even if it's not a clear task) is kind of assigned to her. Also, it's not always clear - if I received a direct message instead of communicating on a public channel, does it mean I should keep it secret? Not clear.

The second problem is **the ASAP nature of DM** which make them feel like requests. We talk a lot about the reasons for going async in [Async Remote](https://blog.arkency.com/async-remote/) but to TLDR it here - async allows choosing the most effective time for a developer to work on difficult tasks. By allowing async work we send a clear message to the team that we trust them. Obviously not all kind of messages need to be treated as bad/sync, but the way they're presented by default (notifications) is often making it sound like something to react to ASAP. Direct messages are the evolutionary kids of phone calls. Which developers usually also hate, by the way.

# The types of direct messages

One type is asking for the **status update**. "Hey, how is it going with X feature?". 

The second type is the **"just" tasks**, "Hey, could you **just** fix the sorting in the financial report UI, thanks!"

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Please repeat after me:<br><br>Slack DMs do not replace GitHub issues/google docs<br>Slack DMs shouldn&#39;t be for private tasklists from other folks nor should it be a place for feature requests.<br><br>Thanks for coming to my TED talk.</p>&mdash; corey hobbs (@chobberoni) <a href="https://twitter.com/chobberoni/status/1034502969969000448?ref_src=twsrc%5Etfw">August 28, 2018</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

The third type, I'm aware of is **when a developer is clearly assigned to a part of the application** and it's only him dealing with it. In this case, the communication is usually specifying the details of the next bugfixes/features. The problems here are quite subtle - other people don't know what is going on in this area. They are not able to participate. The whole project doesn't feel like a collaboration anymore.

# How to reduce the number of direct messages

The basic tips are the following:

### 1. Be the role model - Never initiate work conversations on direct message

Instead, initiate the conversation on channel - even if it's clear that for now only you and 1 other person would be involved. It helps to have dedicated channels (open to everybody) where certain topics are discused. General channels are not a good place for that

### 2. When asked on direct message - ask if it's something that you can reply on channel, as others may benefit from it

If it's a status question - you can take the 2 minutes to reply on the #standup channel and just link in the DM saying "Hey, I thought others would benefit from knowing my status, so I posted there, I hope it's fine".

### 3. Don't open Slack when your current task requires deep focus

I recently listened to the audiobook ["Deep Work"](http://calnewport.com/books/deep-work/). There are more such async-friendly advices. In short, the author recommends approach where you schedule "internet-time" instead of the more popular  (reversed) approach of scheduling "offline-time". 

### 4. Disable notifications for direct messages

Instead, you can schedule in your own backlog/plan when you review your messages. Others would learn quickly that grabbing your attention this way is not effective. It's important thought that you do reply to questions (ideally on channels) systematically.

### 5. Keep your own Inbox/Backlog

Your project has a backlog, but you can have one too. Schedule and prioritize your tasks, so that you have time for deep work, but also for communication. I use Nozbe for that. Todoist was also a good experience. 

### 6. Over-communicate your work so that others don't need to query your status

The simplest way is to post to #standup frequently. But sometimes if your current task goes slowly - keep overcommunicating on the channel about what problems you're encountering. It's a varation of the rubber duck as we all know  it.

### 7. Make quick progress with the backlog, small stories, so that managers/product owners can trust that they can add something important to the top.

This is the big one. Project managers need to trust your process. If you ask them to always add tasks to the backlog, show they would be handled quickly. Otherwise, they would look for tricks and they would be right. Our developers freedom to have a deep work should be accompanied by quick progress. The best way to do it is to improve the skill of extracting smaller stories and the "start from the middle" techniques. At Arkency we promote the idea of 1-size user stories. It's a bit idealistic and sometimes hard to achieve but that's the goal worth aspiring to.

### 8. Avoid assigning tasks/silos to specific developers.

Our culture of work assumes that each developer can work on any part of the application. This is sometimes called collective ownership. It's especially important for the kind of projects we work on - projects where we're involved for several years (we almost never work on 3-months projects).
If you're the developer who gets assigned to one part only, try to explain why it's risky for the team and what implications it has on you (big pressure, hard to go for vacation?).
Even if you're not that developer - look around. Is someone in the team always assigned to one part? Do they enjoy it? Do you both think it's healthy for the project? Reach out to them and ask if you can help them. BTW, this is the kind of conversation where I would find it OK to do on direct message, even though it's project-related. Just don't keep it secret for too long. Aim for actions/discussions how to resolve the issue and move on.

### 9. Create more channels with clear topic/name

Maybe it's #projectfoo-UI, #projectfoo-invoices or #projectfoo-performance - you name it, whatever makes sense in your context. This helps deciding where to start the conversation.


<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">(Using email)<br><br>You have one inbox.<br><br>(Sign up for Slack)<br><br>You have 30 inboxes.<br><br>(Slack adds threads feature)<br><br>Your inboxes have inboxes.</p>&mdash; Henning Koch (@triskweline) <a href="https://twitter.com/triskweline/status/1035073193550249984?ref_src=twsrc%5Etfw">August 30, 2018</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

Do you know other techniques how to deal with the problem? Feel free to share in the comments.

If you like the way of thinkng behind those advices, you will like our [**Async/Remote**](https://blog.arkency.com/async-remote/) book too. 

<img src="https://blog-arkency.imgix.net/aar/async-remote-ver13-0.77proportion.png?w=300&h=300&fit=max"</img>
