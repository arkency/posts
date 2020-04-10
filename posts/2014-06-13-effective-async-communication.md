---
title: "Effective async communication"
created_at: 2014-06-13 18:39:02 +0200
publish: true
author: Robert Pankowecki
newsletter: async_remote_main
tags: [ 'async remote', 'communication' ]
stories: ['async-remote']
---

<p>
  <figure>
    <img src="<%= src_fit("async-communication/async.jpg") %>" width="100%">
  </figure>
</p>

What we mean by working asynchronously is not to always work async, to avoid meetings and video calls at all cost. But to rather **prefer async way of communicating when it is favorable**, when you are sure that sync discussion wouldn't bring you much more. At first you might think that it is almost never but if you keep pushing yourself a little bit you will soon start to realize that you are getting better at it. In fact now we have much more async discussions than sync discussions.

<!-- more -->

## Why should you try to lean towards more async communication?

Because that means less disruptive interruptions for you and your team. In sync mode developers try to keep writing code and reply to everything that happens in the surrounding environment (just like your CPU does). It's hard to keep focused that way and write a good code. **That's why you see so many developers sitting with headphones in the office**. They are trying to communicate to the world that they are busy and now it's not a good time to be asked of any favor.

In teams which embraced async communication and discussion (especially remote teams) it looks a little different. Developers don't receive notifications that needs to be answered immediately. Instead they go seek them when they are ok processing them. So I might **schedule 60-120 minutes of time for myself purely for coding**. I set myself away on chat and turn of notifications fur that time. In that time I am fully in developers mindset. Coding, TDD, Architecture is what I breath at that time. When I am done with some part of the problem that I wanted to implement I get out of zone. I check my email, chat, answer peoples questions, send my own questions to people. I might take a break to grab a lunch or stretch a neck, send something nice to my wife. When I am done, I can schedule next uninterruptible part of time for myself to code.

This is great for a daily work when you know what to work on, tasks are already discussed and properly prioritized or assigned. It's a casual day of asynchronous programmer. It might look similar to you to Pomodoro technique except that Pomodoro default is usually very small (25min) and I found that for serious programming you usually need more time than that to get all the necessary concepts into my head. So I usually **try to organize my day around 4 or 5 sessions that are about 90 minutes long**.

I don't focus that much on time, but rather on my task and moving it forward. When I am happy about the results and feel good about it, **when my attention starts to diminish, that's about a good time to take a break and figure out what happened in the project in the meantime**. If I finished something meaningful in 60 minutes, good for me, I can take a break earlier. If it took me loner, like 105 minutes, that's still ok. I usually keep around myself nuts, seeds and almonds to be able to keep coding without feeling hungry. The time for bigger meals is between those scheduled sessions of work.

## When sync

However we don't always have a nice, prioritized backlog of well understood tasks. In that moment it might be a good time to schedule longer, sync communication with your boss, PM or product owner. Remember, _5 hours of coding can save you 1 hour of research_ ;). **Sync communication is good to discuss poorly defined, or not well understood requirements** for next tasks if we are going to start working on them soon like today or tomorrow.

## When async again

But sometimes we have more time, the deadline is not even on horizon, so we can still discuss the details asynchronously and without rush. In such case we usually go with document (hackpad or google doc). We start by **defining problem and proposing initial solution** (sometimes even a dummy one in the spirit of [McDonalds theory](https://medium.com/what-i-learned-building/9216e1c9da7d)). Sometimes we trigger the beginning of discussion on our weekly meeting and continue in the document. Sometimes the sparkling comes from screencast describing the problem. It doesn't matter.

The idea is that **all discussion happen async because the problem to solve is not threatening us immediately**. You can even add a task to your backlog to have people express their opinion on the subject. But usually you don't have to. People will just jump on board and start discussing because they will receive mentions or notifications that someone else expressed their opinion in the document. That's how it works.

The nice side effect is that at the end **you have everything nicely documented**. All your options, all pros and cons, yays and nays in one place to make your final decision. Of course you can record voice and video communication (and we sometimes do) but the problem with them is that it takes way longer get something out them when you come back later. Recordings are great for sharing what happened with someone who were absent, but they are not great as documentation.

# Knowledge sharing

**Sharing knowledge in remote, async teams might look challenging at first**. In the office, you usually have someone walk to your desk and either talk a bit about bunch of code or even practice pair programming for a moment. In Arkency we went different way. There are few tools and solutions that we use to share knowledge about code, good solutions, practices etc.

### Screencasts

This if my favorite one. Did you do something cool in your company? Did you just understand nice concept in your domain? Were you enlighten about new way to use an old tool? Is there a problem that you are struggling with? Record a screencast. **It scales very nicely because you can use it to communicate with multiple people**. It's awesome for people who joined your company or team later. It can be useful for other teams in your company working on different projects. If you get accustomed to this way of sharing knowledge you can even start recording them professionally and sell online (something still on my todo list).

**It's one of the most single effective technique that we adopted** in our company. At first it was just an experiment. Instead of sharing screen and having conversation with someone who could potentially help you, we started to record screencast. Usually because someone was absent or working different hours or simply because we wanted to know the opinion from everyone involved in our team. We used to put them in Drobox and send each other link on our chat.

Then it became so popular that we decided to standardize on .webm format and created a small app for serving them over our VPN. Now **we are in the phase of experimenting of uploading them to Youtube** (but not publicly). So we don't need VPN, hosting, and if you link it in discussion you will get nice thumbnail of the video. And that works nicely as well. When we feel strongly that the video is good and does not contain any secret information, we can just publish it on YT and involve the community in our discussion. This helps our branding and shows to potential candidates how we work internally. It is also a nice training before presenting on Ruby User Groups meetups or on conferences.

When recording screencast we usually just open browser with github commits or text editor to show the code we would like to discuss. We **try to keep the videos short (5m)** because it turns out more people are willing to watch them in such case but even the longer ones (some take half an hour) are welcomed nicely. In many cases it is good to break whatever larget topic you have in mind into few smaller things. People will more likely watch three 5-minute-long videos (in their small break or over multiple days) than one that takes 15 minutes. The pressure to have short videos also makes people think more deeply about the structure and cut the crap out of it. Just dive into the video topic and avoid unnecessary digressions. Leave them to the comments of the video.

Example screencast:

<iframe width="640" height="480" src="//www.youtube.com/embed/xEoMKmjy1Zg" frameborder="0" allowfullscreen></iframe>

### Hackpad

We [discuss Hackpad more deeply in blogpost about tools that we use](/2014/06/async-remote-toolbox/) so I won't go into much details here. I just wanted to mention that since it is a very nice mix of wiki&google-docs with **very minimal friction**, we use it for almost everything. But more for documenting decisions, requirements, discussing ideas, having checklists than for discussing code. You can paste code to hackpad and format it nicely but it just doesn't feel right most of the time to discuss code outside of its context and surroundings. **In some projects our customers collaborate with us on hackpad to properly distill the domain knowledge and establish [ubiquitous language](http://martinfowler.com/bliki/UbiquitousLanguage.html)**.

### Ad-hoc mumble or hangouts

When it happens that you and your coworker in need work at the same time (despite being async and remote, most people have similar schedule and start somewhere in the morning, usually between 7am and 10am) you are not in the zone, but in communication mode, switching to voice communication might be very efficient. I only wish that we recorded some of those spontaneous conversations more often. **It happened many times that what started as typical conversation turned out be really interesting evaluation of potential options to solve a problem** and very interesting discussion between two individuals. But you usually realize this after fact and wish you started recording 20 minutes ago so you could have share this talk with the rest of the team. So it might be a good habit to **record every conversation** and just not put it online if it happened to be a casual one with no shareable output. Or we should switch to a tool that would record everything for us just like chatting tools keep to remember everything in the history ;)

In case when we want to share screen (usually because of the code) we jump to Google Hangout. But Mumble with better voice quality and lower broadband requirements seems to be less disruptive so for now this is our default ad-hoc communication channel. Whatever tool you use for recording your desktop (screencasts) it will probably let you record Google Hangout discussion as well. Our Mac users tend to use **Screenflow** app for this purpose.

### Weekly meeting - sharing what we learnt

A small (usually last) part of our company weekly meeting is dedicated to sharing knowledge. Everyone has a chance to express something interesting about what they learnt, did or failed at this week. You can hear **people success stories and their small, everyday failures**. It is our time to share the knowledge in cross-project manner. To have it flow even between people who don't cooperate together right now. We find it to be very valuable.

# Standups and meetings

Every company tries to balance the number of meetings (the lower the better) with knowledge flowing through the company (the more the better). And I won't lie to you that this is hard and I am pretty sure we don't have a silver bullet for that. But one of the things we found interesting after applying all those tools and techniques mentioned before is that **we don't have that much need for daily, sync standup in our projects**.

Audio/Video **Standups are great at the beginning of the project** when teams are forming and requirements might change of often. But over the time standup starts to become more boring, repetitious, less interactive and generally bringing less value. From a discussing tool they tend to change into status updates. I believe this is mostly due to a pressure to keep them short. So after every of your team member speaks their voice there is not much time for a discussion on bigger issues.

**No time seems to be a good one for standups in big teams**. You make them in the morning, someone is not gonna be there because they wake up later. You make them before lunch, everybody is there but people are hungry and want to finish early. You put them after lunch, again might be problem to have everyone on board because some people eat at different hours and it takes them different amount of time to finish.

If you have a scheduled meeting every day at the same hour, people will organize their schedule around it. They know that **standup is going to interrupt their flow and they must finish coding something before the standup starts**. Otherwise they will have to get into the zone again to finish the task and that takes time. And if you finish something 15-5 minutes before standup, you know there is no point in starting new task right now because you are going to be interrupted in a moment anyway.

So we dropped the daily audio standup routine in favor of other techniques:

* **text-based, asynchronous standups**
    * written on our chat in #standup channel accessible for everyone
    * cross-project in other words
    * focused on readers
    * mostly for status updates
* **one weekly project meeting**
    * without taking the time to update everyone who is working on what because you already know that from textual standups
    * so we can jump straight into interesting conversations around problems, priorities, business domain, refactoring ideas, knowledge crunching etc
    * we asynchronously generate the list of topics to talk about through the entire week
    * when we start we are prepared and have agenda already present
    * recorded for those who are not present
* **topic based meetings**
    * contrary to the weekly meeting they are scheduled for one topic only
the discussion usually starts on hackpad earlier
    * the meeting mostly happen after people already expressed their concerns and opinion in a document
    * the number of participants might be limited to those interested in that particular topic, so it doesn't have to be entire project team
    * recorded as well

As you can see we try to keep number of enforced discussion very low. Too many mandatory meetings are considered harmful. Instead we prefer smaller talks including only interested participants that mostly happen in text before they are evaluated on a synchronous audio/video meeting. In other words: _a lot of async before we sync_.

In next blogpost we are going to show you how to take most out of async, textual standups so that they are truly a masterpiece :)
