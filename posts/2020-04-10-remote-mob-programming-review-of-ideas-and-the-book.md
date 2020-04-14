---
title: "Remote Mob Programming — review of ideas and the book"
created_at: 2020-04-10 15:50:12 +0200
author: Andrzej Krzywda
tags: [ 'async remote', 'mob programming' ]
publish: true
---


At Arkency, we subscribe mostly to the remote and asynchronous approach to software development. I described this method in detail in “Async Remote. The guide to Build a Self-Organizing Team”, a book I co-wrote with Robert Pankowecki. Most of the insights and views expressed in the publication were based on our own experience but we also drew on some ideas borrowed from other companies. Truth be told, when we first started, there weren’t really that many remote companies to be influenced or inspired by. We learned a lot from open-source projects, the way they build their teams and how they collaborated asynchronously.

In this post, however, I would like share and review some ideas from a book called  “Remote Mob Programming” written by Jochen Christ, Simon Harrer and Martin Huber, senior programmers at Innoq, which is dedicated to… you guessed it… mob programming and how it can be done remotely. I like this publication a lot although, to be honest, it’s super short - only 30 pages, including some additional resources. If you, however, like quick and concise reading that lets you focus on a number of key ideas, you should certainly grab it. There are some lessons to be learned from the book - It has certainly inspired me to look at the things we do at Arkency from a different angle. 

For those of you who don’t know - mob programming is a software development approach based on a whole team working together on a single task at the same time and at the same place. Some of you may be familiar with pair programming - it’s a situation when two people sit together in front of one computer and they program together, with one person typing and the other one navigating. It’s a very unique way of working, certainly not for everybody. I used to work this way at a London company, before I started Arkency. We paired all the time, it was a very exhausting and intense process but quite rewarding. I personally think it’s not a bad approach to creating software. 

Then there’s mob programming. It usually means working in front of one screen, but, unlike in pair programming, there are more than two people involved. The main idea behind  this method is that it can be done in the office. We have tried this approach a few times at Arkency, including one time when we had a co-working session at my house. There were five of us working on a big TV screen, moving around the keyboard. We were working on a sample application for our Domain Driven Design workshops, creating the initial design, adding tests, etc. As a method consisting in many people working at a single workstation, mob programming has some consequences, both positive and negative. Intuition may tell us that working like this could be a waste of time - what with five people working concurrently on the same task. But this approach has some benefits as well.

We came to realize that mob programming is superior to anything we’ve ever tried before, claim the authors of *“Remote Mob Programming”* in the introduction to the book. That’s quite a bold claim to make and it’s interesting to see that comparing office work to some other ideas, including remote work without mob programming, didn’t change the writers’ minds.

The three senior programmers did full-time mob programming every day for a year, which to me seems like enough time to draw conclusions. An interesting consequence of the approach was that for one year the team **didn’t have to rely on daily stand-ups**. They were not needed, as everybody already knew what had been done and everyone was on the same page all the time. Moreover, there were **no code reviews**.

At Arkency, we don’t really do mandatory code reviews anyway. I know, it’s quite controversial. A lot of other companies, however, seem to construct their processes around code reviews so there is always some waiting involved. When developers create code, they are not allowed to push it into production before it gets reviewed.

The one-year “mob programming experiment” also meant **no hand-overs before holidays**. Normally, when one of the developers takes some time off, for example, to go on holiday, someone else has to step in and take over their task. At Arkency we do this through collective ownership but this is not a solve-it-all approach so I can understand why the method suggested by the writers makes sense. Finally, the authors address the problem of working in isolation - using remote mob programming approach can prevent programmes working at home from feeling alone. Right now many of us in the industry are working remotely full-time for the first time in our lives and there are lots of things that we can learn from this experience.

 Christ, Harrer and Hubethe give us a number of rules to follow when working remotely. Here are some I found most interesting:
 - **Remote everybody.** This idea was also important for us when we wrote our “Remote Async” book. We didn’t claim that remoting every team member was absolutely  needed or required but we agreed it was something to consider. As the writers rightly point out, when one group of people is working remotely and another one in the office, there is information asymmetry that may lead to problems. 
 
 - **Camera always on.** I think this one is a controversial rule. Personally, I wouldn’t like to work in an environment where you are constantly monitored. It’s not that I have anything to hide but I don’t think it is important for programming activities. According to the authors, the cameras were on all the time and although it felt strange at first, after a few days it started feeling natural. It gave them a sense of presence in the team, almost like working together. I think that what they aimed at was to “simulate” the office. I would, however, avoid this, there are better metaphors with which to describe our work right now, for example open-source projects. 

 - **Regular on-site meetings.** According to the authors, they work together on-site once a month. That’s not something that we do at Arkency. We don’t do mobs, we do remote. On-site meetings may take place once in a while, but definitely not as often as once a month. Some projects never involve on-site meetings. Interesting as it may seem, I’m not a huge fan of this idea. I don’t think this is necessary but if there is the luxury of living not far from each other, it’s definitely worth giving a try. At Arkency, we have clients from the US, Denmark, Germany, which makes working on-site practically impossible.

 - **Same time.** Innoq developers work six times a day and everybody is required to work at the same time. It’s not something that would be easy to do at Arkency. For us, the async part of the job is crucial. Our processes are based on the fact that we can work at different times. A short digression: we have tried mob programming. What I would like to explore after reading the book, is the concept of async mob programming where people can “checking in and out” at their own scheduled time. We’ve been trying this approach with one project and it was very interesting. All the benefits mentioned in the book (no stand-ups, no coach reviews) were working to our advantage. I don’t think, however, it would be feasible to work six hours a day in the present situation, during the lockdown when we’re constantly interrupted by some external factors. 

 - **Same shared screen.** This rule makes sense, as it helps people to focus on their work. When one person is typing, another one is the navigator. The team mates rotate every 10 minutes. I think it’s a similar approach to the one we used for our mob sessions except that we were rotating every five minutes. It helped to keep the dynamics of the work. 

 - **Small team.** This rule aligns with my view that there is a number above which a team stops being productive. I don’t believe in teams comprising of 20 programmers - at some point adding more team members make communication more difficult and slows down a project. I think this also depends to a certain degree on the culture of the organisation. 

 - **Group decisions.** *In software engineering you constantly compare different alternatives and decide for one. (...) Group decisions are superior over individual decisions. (...) In remote programming all decisions are group decisions and this way we minimize technical debt. As bold as this claim may be, I think that group decisions do reduce technical debt.* At some point most software projects slow down and almost come to a halt because there is technical debt, there are some workarounds, morale goes down. In the case of pair working, which we practice a lot at Arkency, it helps a lot that there are two people, and they help each other to understand code bases, problems and solutions.

 - **Constant momentum.** The authors claim that this approach often allows them to get into a rewarding flow. Working in a group helps to avoid procrastination and random activity online. There’s less temptation to stop working, which may be a big time saver. 

 - **Learning from the team.** This idea was huge when I was pairing at the London company. We got better by learning from each other. With mob programming, on-boarding only took weeks rather than years as the knowledge transfer was much faster. In half a year I became quite fluent at VIM or Python...and all of the team members were able to quickly learn new things.

 - **Trust.** According to the authors trust is built by communicating actively. When we work remotely, the client doesn’t see us working and the management may be afraid of losing control over their team. If all members work at the same time, we can’t be sure about the productivity. Of course, when there are five people working on the same task, there can be some waste. This is similar to what we call over-communication in Async. 

 - **Save the planet. Working remotely is environmentally-friendly.** We don’t travel so there’s zero emission. We can observe this currently, as the climate change has slowed down during the epidemic, as we all have to stay at home. 

 - **Enjoy more quality time with our families.** This one is more about the remote aspect of work than mob programming but is still worth mentioning. 

Mob programming is certainly an idea to consider. At Arkency we might combine the different modes of working and try to mix some of the ideas of remote async work, mob programming and even live streaming. There’s definitely a lot to explore in this area. The lockdown has forced us to seek new effective ways of working and enhanced our creativity.

Check out more and follow us on the Arkency YouTube channel, thank you!

<iframe width="560" height="315" src="https://www.youtube.com/embed/HizKk3M7AdA" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
