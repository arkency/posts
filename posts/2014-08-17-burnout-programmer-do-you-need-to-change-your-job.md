---
title: "Burnout - do you need to change your job?"
created_at: 2014-08-17 15:07:31 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter: :async_remote_main
tags: [ '' ]
stories: ['async-remote']
---

<p>
  <figure>
    <img src="<%= src_fit("burnout-programmer-fire/programmer_burnout_fire.jpg") %>" width="100%">
  </figure>
</p>

I've been reading recently a story on Hacker News about a programmer who
(depending on who you ask for a diagnose in the thread) was **suffering from
burnout**. Some commenters even suggested depression. There were many
advices recommended (unfortunatelly I can't find a link to the discussion
right now) but one certainly spot my attention.

<!-- more -->

## Change technology - completely

The advice was to **completely change the technology and start again with something new**.
_If you are Rails backend developer, switch to frontend or even go with gaming_. People
said the money doesn't matter, it's your mental health that is the most important and
earning 2x or even 4x less is not the thing to focus and not the most crucial factor.

Well, I don't know if that's going to help, if that's a good advice. I'm not a
psychologist nor psychiatrist. Although I am guilty of dreaming occasionaly about
switching to gaming and releasing my own 2D platform game based on _Unity_ probably.
However, that is not the most important here. What got me thinking is **_Do we really
need to change a job to try out new things?_**

## Does it mean I need to change my job?

If we do need to change the job, how did it happen? **How is that despite being well paid,
having a sophisticated job, that many would like to have, we still suffer from burnout?**
Well, we might start as _let's say_ C++ programmers, but do we wanna die as C++
programmers? I don't think so. So ask yourself, do you sometimes have a feeling that you
are doing the same thing over and over? That you were categorized (_internally by yourself_
or _externally by your agency, boss, coworkers, head hunters..._) as
**X technology-developer** and you can't escape this? My guess is, that you are probably
not alone, feeling like that.

If you want to switch from Ruby or Java or .NET to gaming (which i guess is prefering
C++ and C#) then yeah, you probably need to switch company. Even using the same language
might not be enough because of the customer that your company has, the nature of the business
and the tribal knowledge that you need to finish project. I guess web companies don't take
much gaming gigs.

But when you are already a web developer (probably strongly oriented towards either backend
or frontend) then **why the hell would you need to change a job to try out something else?**
Can't backend developers help with frontend, learn Angular or React, have fun and help
with the project? Can't frontend developers learn node.js and finish backend features as well?
I don't get it. And maybe we all can do mobile just fine as well, especially when we have
background in desktop apps?

Could it be that way?

## Could it be different?

I don't think there is a silver bullett for burnouts but _excuse me_ **I think we can
as industry do way more to minimize the scale of the problem**. Here are few ideas:

* Small stories
* Team Rotations
* Products
* Microservices

Let me elaborate a bit about each one of them.

### Small stories

You know one reason why people get stressed and tired? Because bosses give them huge stories,
huge features to work on alone. People got something to do for a week or a month or even longer
(i know, speaking from experience and from hearing from others) and **they have no reason to talk
and discuss and cooperate on it inside the team**. Technically, you are part of a team. In
practice, you are on your own doing the feature. And don't think someone is going to help you.
**Everyone is _busy_**.

**And you know why your backend developers never asked for a frontend story. Because they know it
would too big for them and they are scared. And they don't want to overpromise. They are not yet
confident.**

**What could help? Small stories**. Split everything into small stories. Get people to track bigger
topics/features (but not implement them alone) and let everyone do frontend and backend stories.
Of course we will be afraid and a bit slower at first. But then, we will get more confident. We
will better understand what our coworkers do and how much time it takes. We will have plenty of
reasons to talk about code and how to write it so that everyone understands each others
intentions. We will have better **collective ownership**.

### Team Rotations

**Ever joined a company and got stuck in a project for _like... how about... forever?_ Yeah... That
sucks**. If you are a member of a company which has more than 10 people, chances are, you could
theoretically switch to another project. Of course your boss would have to let you do it. And it would
have to be approved by the client. But switching the project and getting to know new domain,
new people, new client, new problems and new challenges is refreshing. Problem is (as almost
always) the _inertia_. **Sometimes customers even fall in love with their developers** (not
literally, but you probably know what I mean) and don't want to let them go. They fear that
the replacment won't be as good. It's _understandable_. But that shouldn't be the major
factor for the decision.

**Team rotations are easier if your company is having fewer projects** but of
bigger size. If there are 20 of you, then it is easier to convince customer to let developer go
when you are working on 3 projects with about 7 ppl each one. Or 4 projects with 5 people. If you
have 6-7 projects with 2-3 people working on them, you customer might not be willing to let
one of the developers go. After all, that one developer is 50 or 33% of the entire team. So they
tend to worry a lot about consequences. If one developer is 14% of a team, then there is high
chance that domain knowledge will still remain in the team and can be passed completely until
next person leaves a team.

### Products

**Consulting can be exhausting**. As everyone who ever did knows. One thing that can help is letting
**people work on their own projects**. They don't necesarly need to be open source ones (although
that is nice as well). But that can be products that your consulting company intends to sell.
As [Amy Hoy said](http://unicornfree.com/2011/5-big-nasty-fears-keeping-you-on-the-hamster-wheel-of-hourly-work)
 _When you get paid to do a thing, you’ve already got three built-in markets to tap_:

* _People who would want to hire you — including those who want to, but can’t_
* _People who are like you & do what you do_
* _People who want to be like you & do what you do_

Why not let developers target those people as well? That can be challenging and as
refreshing as getting another project or another technology. **Except that instead of learning
new tech, you need to learn research, marketing, prioritizing and much more**. With your own products
you always want to do so much but your time is so limited. And sometimes our ideas fail. Just
like our clients. Getting better with skills in those areas can help us be better in consulting
and prevent our customers from making mistakes. When you launch at least one of your project
suddenly you are well more aware of many limitations. And you can question and challenge the
tasks way better. You are inclined to ask customer for reasons and goals behind doing the tasks.
You are not just building _feature X_, you are _improving retention_. You get the sense of all
of it.

### Microservices

There is so much hype recently for microservices. A lot of people mention that with microservices
you can write components more easily in the languages better suited for the task. But have you
ever considered that with microservices you can give people some playground for their ideas
without much risk. It's not that you need to rewrite entire app in Haskell. But one, well isolated
component with clear responsibility. If they want to? Why not? **_Uncle Bob_ says we should learn
at least one new programming language every year to expand our horizons. And if we do? And if
we expanded our horizons, where are we to apply that knowledge? In a new job?**

## Last word

**Let your people work and learn** at the same time. You might not know it
but **you probably hired geeks who would like to know everything there is in the world**. They are
never going to stop learning, whether you let them or not. If they need to, they will change a job for
it. But it doesn't mean they want to do it. It's just, you might not leave them much choice.