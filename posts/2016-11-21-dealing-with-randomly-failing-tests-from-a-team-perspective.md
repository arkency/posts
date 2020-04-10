---
title: "Dealing with randomly failing tests from a team perspective"
created_at: 2016-11-21 00:12:37 +0100
kind: article
publish: true
author: Andrzej Krzywda
tags: ['testing']
---

One of the things that can negatively impact a team morale is random builds - builds where sometimes some tests are failing.
Inspired by Martin Fowler's article on [Quarantine](http://martinfowler.com/articles/nonDeterminism.html), in some of our projects we came up with a guideline how we can fix the problem as a team. 

<!-- more -->


1. If a test fails randomly for more than 1 time, add to it to quarantine (consult the list of existing failures)
2. never kick the build without doing some action (quarantine, test fix)
3. if the build is red after your session of work, it's your responsibility to fix it (feel free to ask for help if you have no time, but the initiative is yours). Whenever we say 'you are responsible', we mean that the whole team is responsible, but you're the tracker, you take the initiative. It's not your fault, but we need someone to track it and that seems to make most sense.
4. don't push into the repo if you have no time to handle the build problems 
5. never leave a red build after your session of work
6. if a build fails for not clear reason, find the reason and fix it
7. don't push the code if the build is red
8. if you start your working session and the build is red, talk to others and fix it first, then start your task
9. if there's really no other way to fix the build and no one to help, then at least kick the build
