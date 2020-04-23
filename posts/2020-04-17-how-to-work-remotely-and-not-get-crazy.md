---
title: "How to work remotely and not get crazy"
created_at: 2020-04-20 13:22:48 +0200
author: Andrzej Krzywda
tags: ['async remote']
publish: true
---

Today I would like to talk about how to work remotely and how we do it at Arkency.  We’re living in crazy times right now, almost everyone seems to be working remotely, so I thought it would be a good idea to share some experiences we’ve had with remote (and asynchronous) work since we first started working like this around 15 years ago. I think some of the ideas I’m going to share are universal and can be applied to any profession, not just programming or software development. It is interesting to see how well the whole concept of remote work seems to be doing right now that everyone is embracing it. For some people, it’s a completely novel approach to going about their work, while others have been practicing it for some time. But even within one team, there can be people who have and who haven’t done it, which, of course, may create some difficulties.

<!-- more -->

## A few techniques

In this post I would like to discuss a few techniques that can be useful in organizing project work involving teams comprising of at least 2 people. And although these people might work from home, they don’t necessarily have to work at the same time. This is the big difference between asynchronous and remote work, the former meaning working from different locations, the latter - working at different times. Sometimes working times of the individual team members may overlap but very often they don’t. It’s important especially now, when few of us have the luxury of working six hours straight. While working remotely, we have to juggle work and family life, handling daily activities and running errands. There are intermittent periods of work and breaks. It’s a new situation which means, for example, that it is not so easy to set up a call or turn on a camera and talk to our co-workers. People can be interrupted or disconnected. The Internet connection is not that great nowadays because everybody goes online now.


## Easier

To make things easier for ourselves and our colleagues, it’s important that we divide our projects into smaller tasks, especially considering that people are less available or productive now. To avoid interruptions and unexpected stoppages, it is advisable to split tasks into the smallest possible units, or tickets, as we call them. A “size 1” ticket is an abstract concept, one that may represent e.g. 1 to 2 days of work. Ticketing makes our work more transparent and efficient, as it helps us to see the flow of work within a single task. During one week, for example, a developer might be expected to complete one or two tickets. This approach can give us a sense of closure and achievement. What’s more, there are some techniques that can be used to split tickets into even smaller units. This approach is especially useful in the remote and asynch environments as it creates an impression that everything is going well despite the difficult times.


## Sprint

Many programming teams apply the concept of “sprint” or “iteration”, which represent work units lasting from 1 to 2 weeks. These units have their start, end and scope. However, despite the advantages of such a solution, I think that  in the remote settings it is more efficient to gradually move towards the concept of the stream of work. Instead of thinking in terms of what can be done in one week, we just focus on organizing the work that needs to be done while someone else (project managers, product owners, etc.) organize the tickets somewhere in the backlog.

True, project managers still need to think of the calendar, timelines and deadlines, but from the perspective of developers the start and end of a sprint is not that important. It’s enough to focus on whichever ticket needs to be done - grab it, complete it and then move to another.  This is what the stream of work looks like from our perspective. As developers we will always have backlogs and there will always be more work than we can handle so it’s important from psychological and motivational point of view that we don’t look at everything that needs to be done but rather that we think in terms of timeboxes.

Now that the workflow has become so irregular and interrupted, it’s time to make the most of the time slots available to us any given day. This requires a mindshift in the way we perceive our project. For each such a slot of time, we should consider what kind of useful results we can deliver and what can we do to push our project forward.


## The first available ticket 

As for the backlog, it needs to be sorted in a way that allows team members to take the first ticket available. Tickets should be ordered (by product owners) according to their priority so that everyone knows which tasks have to be done first. It’s crucial that we try to understand the task and plan our work so that we can squeeze the most out of the time we have. For example, we may use a three-hour slot one day, and then finish a task the following day. Of course, it’s possible that we will be able to complete a small task within one work session. This approach requires something that is not common at all companies, i.e. that all developers are capable of doing all the tasks. It gives rise to many questions, e.g. how to split the backlog between developers. At Arkency we do mostly web development and API so we prefer that our developers to be full-stack, which means that one ticket represents something meaningful and functional, something that our client can actually use.

Although our clients have their own dedicated project managers, Arkency developers are capable of doing project management work on their own. We have enough business knowledge and are sufficiently familiar with their vision and priorities that we can access specifications and move tickets into the backlog, organizing the latter in a way that is useful to others. When a developer starts a PM session, they always make sure that they prepare at least 5 tickets so that other team members don’t have to change their context. In our backlog, we usually have 10 tickets which are sorted and prioritised and underneath them there is a separation line below which there are other random ideas and tickets. The line is serves as a border between what is prioritized and what is not.


## Customer meetings

Another important issue in the remote work settings are customer meetings. The big question is: how to organize meetings or calls with customers when these are required to agree on the next portion of work that needs to be completed? Although I try to avoid calls when possible, certain calls and meetings need to be held. Usually, the busiest of our clients are not accustomed to the async way of working, which also means they are not huge fans of writing things down and explaining themselves in writing. So sometimes, when we do make a call with businesspeople, we put in writing what they say, we agree on what and how needs to be done, we brainstorm ideas with them, etc. And then we try to summarize those meetings in terms of documentation or notes so that everyone can have access to them. Sometimes we also record such meetings but watching them may be too time consuming and reviewing notes proves to be more effective. Sometimes the notes and specifications we write down during meetings become part of the backlog and help us to create a specification ticket which is not ready to be worked on directly but can be used for extracting actual tickets. In such a situation project management work involves extracting work from specifications. Once we work with the tickets, it may be necessary to communicate certain things and to ask more questions. Comments are added to the tickets which are there for everyone to see. There is some integration between communication channels, so that a comment added to the backlog can also be seen e.g. on Slack.


## Over-communicate

When we work remotely, it’s very important that we over-communicate. This might be very difficult for developers because we tend to be introverted. Programmers have this rule: “Don’t repeat yourself” and this sometimes applies to real-life communications, too. And here we have to write a Git commit message to explain what we’ve done and then repeat it on Trello or Slack. Over-communication also means that when we see a problem that is related to the area we're working on, we don’t keep it to ourselves. At Arkency, for example, we have a special Slack channel for summarizing all our projects.



## Stand-ups

We don’t do daily stand-ups at Arkency, as this technique makes more sense in the office environment than in the remote settings. It’s easier to be done when everybody starts work at the same time. If you have this luxury and are able to keep discipline, then a kick-off meeting each day could be a good idea. But when people work asynchronously, it’s not easy to enforce the same time for a stand-up. Some companies enforce daily stand-ups on Slack channels before work, which is not a bad idea, but in case of async work, one don't really think in terms of days of work, but rather in terms of work sessions. There's more focus on the current session, what needs to be done now and what can be done later. Sometimes communicating during stand-ups every three days is enough and sometimes I post two times a day on our stand-up channel.



## Home office

Another important matter that needs to be considered in the context of remote work is the organisation of our home office. During the time of lockdown we are forced to work from the same house or apartment as the rest of our family. I have the luxury of having a separate room at my house but it wasn’t so when I first started. Right now I can enjoy some isolation and if necessary I can always use headphones. Still, working from home can make it more difficult to have a call or meeting as there is always some noise around you. And we’re not always comfortable turning our cameras on. I think that focusing on the techniques I mentioned above is useful because they reduce the need for calls while allowing us to have better communication than office-based teams.

Remote and async work is different than office-based work, more things are put in writing and more discipline is required. It's good to have a set of tools (e.g. Nozbe, Todoist), which allow us to record things that need to be done later. Also, asking questions in the async environment works a bit different than in the traditional office settings. We can’t expect that our questions will be answered straightaway, so we have to be respectful and let other people decide when to answer. Unfortunately, this sometimes may cause us to feel ignored within a team, as no one responds to our inquiries. If we feel frustrated because there is no one replying, it may mean that it’s time to review the techniques used. Although we shouldn’t expect an immediate answer, if our question is more or less valid, we have every right to expect that someone (be it another developer or a project manager), will finally provide us with an answer. There has to be a clear policy in place on how this problem will be dealt with. In healthy situations, however, the number of questions between team members should be reduced because more and more information is available - everyone has access to everything specification, documents, wireframes, etc.


## Check out more about [Async Remote here.](https://products.arkency.com/async-remote/)


Follow us on the [Arkency YouTube channel](https://www.youtube.com/channel/UCL8YpXFH1-y3AaELb0H7c3Q), thank you!


<iframe width="560" height="315" src="https://www.youtube.com/embed/RjSte_rP2Ew" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


