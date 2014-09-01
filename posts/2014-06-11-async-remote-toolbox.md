---
title: "Async & remote - toolbox"
created_at: 2014-06-11 20:16:56 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :aar_newsletter
tags: [ 'foo', 'bar', 'baz' ]
stories: ['async-remote']
---

<p>
  <figure>
    <img src="/assets/images/remote-toolbox/toolbox-title.jpg" width="100%">
  </figure>
</p>

I've been speaking recently at a local IT entrepreneur meetup about remote work and about the ways a company can transition towards being more remote.

The part of the talk that seemed to be most interesting was the toolset that we're using at the moment. I thought I'd share this list here, as well.

Remember, that tools should just support your process and not replace it. If your goals are clear to you and your team, then the tools are just implementation details.

<!-- more -->

## Chat solution - Slack/Flowdock. IRC is dead

For 7 years we've been using IRC. It's a kind of a [old-school](http://royal.pingdom.com/2012/04/24/irc-is-dead-long-live-irc/) tool but it served us well.  We've been experimenting with alternatives, like Slack and I can't decide for the entire team, because we haven't made a decision yet, but I am pretty sure it's either Slack or Flowdock for us.

The tool itself is not that important, it's the goal it serves that is interesting.

We have one channel per project and several generic channels, like #lol, #arkency, #links, #coffee, #products, #blog, #social etc.

The project channels are often integrated with other tools and receive notifications from Trello, Github, Jenkins. This is like the headquarter. The integration with 3rd party tools works very well in both of them (slack and flowdock). The main difference is that on Slack you receive notification in the same window as your normal chat. Whereas on flowdock you receive the notifications in left window and the chat happens on the right window.

Flowdock has a very nice feature that every new chat message can start a new conversiation. If you click an icon near your message, then people can reply to in the the left window. In this mode the left window is used for conversion of one thread (flow) and the right window shows messages from all threads (like in a chat) for currently opened channel. The only problem is, that I almost never close my threads in the left window so I almost never see any notifications. They are hidden when you use left window for discussing one flow. If you know if it can be configured in some way to behave differently, please let me know.

Another nice thing in flowdock is that every notification is just a message and as I said every message can start a new thread. Because of that when you receive for example an exception notification from honeybadger you can ping your team members in thread and start chatting about potential fix or root source of the exception. So in flowdock, every discussion has a URL. And that's pretty important for me because, if you happen to have a conversation about scope of the ticket with product owner, you can later add it to trello or pivotal ticket for a fuller picture and put it in commit description so that anyone reviewing your commits can read it as well and have common mindset with the author of commit.

You can create a code snippet on Slack or upload a file and discuss it in comments, but that's it. If you have a 100 message-long discussion about something, you can't easily link to it. If you would like to discuss exception or failed build in a thread without the interference of other discussions happening in the same time on channel, well not on Slack. But, on the other hand you don't miss any notifications just because you happened to be in the middle of flow conversation

So if it was for me to design a chatting solution for developers I would go with 3 panes. One for notifications, one for current thread and one for chatting. We already have monitors > FullHD so place on screen is not a big issue ihmo.

As you can see on the screenshots Flowdock keeps the list of the channels on top which became problematic for some of us when there are a lot of channels you are subscribed to. Slack is displaying them in left panel and it handles them better visually ihmo.

One of the things that almost every tool is missing, is the ability to give +1 (or "like" or whatever you call it) without cluttering the interface. Facebook got it right and I belive it should be possible to just express your approval easily. Why are we having this feature in social networks only? We should have it in chats, story trackers and even emails.

TLDR: Every tools has its pros and cons. Give them a try in your entire team and make decision based on your real experience. Not based on screenshots or reviews like this one ;) I am pretty sure you are agile and you can switch to a different chatting solution for one week to evaluate it properly.

### Slack

Slack in normal mode

<a href="/assets/images/remote-toolbox/slack_normal.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/slack_normal-fit.png" />
</a>

Slack in compact mode

<a href="/assets/images/remote-toolbox/slack_compact.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/slack_compact-fit.png" />
</a>

Notifications on slack

<a href="/assets/images/remote-toolbox/slack_notifications.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/slack_notifications-fit.png" />
</a>

### Flowdock

<a href="/assets/images/remote-toolbox/flowdock.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/flowdock-fit.png" />
</a>

## Requirements/Tickets - Trello

This is our default project management tool. It works as a backlog. It contains many tickets/stories, prioritized and described. It helps detailing the requirements and seeing what's the status.

The tickets are also refactored - we extract new tickets, rename them, group them - whatever is needed.

One problem of trello is very limited number of tags that you can assign to ticket. Pivotal tags and epics works way better I think. However I find Trello visually more appealing than Pivotal, because ihmo it is easier to focus on current task and just see few next ones. Pivotal is great for showing a lot of information on one screen, but form it is just overwhelming.

And then there is the problem of every tool for managing backlog that I know. The don't show you changes in priorities. They don't notify you about them. Everything you do for one ticket, inside the ticket, every status change, every comment, assignment, checkbox crossed, they tell you nicely about.

But if someone moves task from bottom of the backlog to the top, thus changing its priority to being the most important one, silence. I really wish we could easily see the history of changes to priorities to the boards (backlogs). Something like "Task 'X' was moved 6 positions up. It is now more important than task 'A' and less important than task 'B'". If one of my colleagues makes such decision after talking to client about priorities, I would really like to know. For me that is way my important than anything else that is happening :)

In some projects we use Pivotal, Redmine or Asana for the same goal.


Living on the edge... Trello with one column only :)

<a href="/assets/images/remote-toolbox/trello_column.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/trello_column-fit.png" />
</a>

One ticket on trello

<a href="/assets/images/remote-toolbox/trello_one_ticket.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/trello_one_ticket-fit.png" />
</a>

Email notifications from trello

<a href="/assets/images/remote-toolbox/trello_email_notifications.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/trello_email_notifications-fit.png" />
</a>


## Documentation  - Hackpad

Hackpad - this is my favorite one. If you're not familiar with it already, it works similarly to Google Docs. In my opinion, it's a bit more interactive.

It's basically a wiki on steroids. It has support for collections, it notifies about changes via email. You clearly see who wrote what. You can comment sections of code and checkboxes.

Whatever interesting happens in our company, it gets an URL on Hackpad. Do I have an idea for a bigger refactoring in one project? I create a hackpad, paste some code and describe the plan. Others can join whenever they want (async!) and add their comments.

<a href="/assets/images/remote-toolbox/hackpad.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/hackpad-fit.png" />
</a>

The email notifications are very powerful tool to keep being updated in an asynchronous discussion about topics that you subscribed to. Here is a screenshot with notifications from our hackpad dedicated to our annual Arkency Camp event. As you can see the notifications are provide with a a bit of context for the changes, so sometimes you don't even have to open the pad, to know what's been changed or what is someone opinion about the topic. 

<a href="/assets/images/remote-toolbox/hackpad_email_notifications.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/hackpad_email_notifications-fit.png" />
</a>

### What hackpad is great for:

* documentation of every kind
    * notes from meetings and discussions
    * brainstorming
    * gathering ideas
    * describing problems
    * feature requirements
    * tribal knowledge
    * checklists, we have for example a checklist of things to do when new person joins Arkency
        * for the Arkency members
        * and for the new coworker
    * retrospections
    * list of links about particular topic, such as for example microservices
* async discussion
    * You write few paragraphs about a problem that is irritating or challenging for you. You describe current state of situation, what you tried and how it worked. You post the link to hackpad in online communication tool (irc, slack, flowdock). You can mention people that you would like to get feedback from directly on hackpad or in your favorite chatting tool. And you wait. If someone starts writing immediately in you document, you see the changes immediately and you play with it and you have a dialog. Or you can close the browser tab with hackpad and do it more async. You will get an email with changelog after someone finishes writing in your document.
* blog posts drafts

### What hackpad is not good at:

* being a chat ;)

## Voice communication - Mumble

Mumble is probably unknown to you. It's a tool very popular among gamers. They use it to communicate in a team, during a game. We started using it, as it was much more reliable than Skype. It's a very minimalistic tool. It has the concept of channels, so we designed it similarly to our communication tool (IRC). It also allows recording the conversations, so that people who were not able to attend (async!) can later listen to the most important fragments.

You can configure it to work in "Press button for talking mode" which is very convenient to use. I wish more software adopted this approach. Most of them transmit voice all the time which if you happen to be somewhere loud means that you need to click somewhere on the interface to constantly mute/unmute yourself. Other tools activate automatically when there is sound which also doesn't work great sometimes. But mumble configured in this mode works great because you just keep the button pressed as long as you are talking and this coupling feels very natural and it is easy to get such habit.

Our mumble server is self-hosted by us. Maybe that's one of the reasons that the sound quality is better than any other tool like skype or google hangout. Or maybe it's just mumble. I don't know, but it is a pleasure to use this tool for voice communication. Works on mac, linux, windows, ios and android.

<a href="/assets/images/remote-toolbox/mumble.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/mumble-fit.png" />
</a>

## Code reviews - Github

We use Github for hosting code and for making the micro-code reviews. I call it micro, as they only let us comment the deltas - commits or pull request. They don't let us comment the existing code base, which is a limitation many similar tools share. If there's one place, I'd like to see improvement for remote teams it would be a proper code review tool.

## Continuous Integration - Jenkins

We host the Jenkins instances to build our projects. I'm very far from liking it - it has many quirks, but overall we didn't find a good alternative to switch, yet. We had some problems with CircleCI and TravisCI running our biggest projects. But for smaller projects CircleCI worked great in our case. Maybe it's time for us to review these tools again. Maybe they matured and handle things better now.

## Remote pairing - tmux

I blogged about remote pair programming 6 years ago. At that time, I was using screen + vim and I still think it's a good combo (together with Skype or Mumble). Nowadays, we don't pair program too often, but when people in my team do that, they often use tmux to connect to each other (terminal-based). Another tool is tmate.io, which is also tmux-based.

On a good connection you can also use Google Hangouts and their Desktop Sharing feature.

## Video calls - Google Hangouts

We use video calls very rarely and mostly, when external teams are involved who prefer it. In that case, we use Google Hangouts.

## Screencasts - Arkency.tv & Youtube

We have our small self hosted app which just lists uploaded .webm files that every new browser can play without any plugin. And automatically create and embed hackpad below the video to have a place for discussion.

<a href="/assets/images/remote-toolbox/arkency_tv_listing.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/arkency_tv_listing-fit.png" />
</a>


<a href="/assets/images/remote-toolbox/arkency_tv.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/arkency_tv-fit.png" />
</a>

But recently we started to experiment with non-public videos on youtube and that also works great.

<a href="/assets/images/remote-toolbox/dopm_yt.png" rel="lightbox[picker]">
  <img src="/assets/images/remote-toolbox/dopm_yt-fit.png" />
</a>

## Summary

It's important to understand that those are only tools. They can change. I'm pretty sure, next year, we'll use a different toolset. What's important is the process around it - how you collaborate on projects, how you split stories, how you discuss, how you collaborate on the code, how do you spread the knowledge and achieve consensus.

What tools are you using? What would you recommend? What's your process?

## Update

Next part:

[Effective async communication](/2014/06/effective-async-communication/)
