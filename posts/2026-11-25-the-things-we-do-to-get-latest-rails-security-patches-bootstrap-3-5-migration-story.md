---
created_at: 2026-11-25 16:28:29 +0100
author: Łukasz Reszke
tags: ['rails', 'bootstrap', 'ai', 'legacy']
publish: true
---

# The things we do to get latest Rails security patches: Bootstrap 3 -> 5 migration story

In order to get Rails security upgrades we, sometimes, must do nasty things. One of nasty things I participated in lately was bootstrap 3 -> 5 upgrade to ged rid of a blocker – bootstrap-sass gem used together with Sprockets. A project that has been stretching its timeline way too long, until it became clear that it has to be done. Especially after recent security attacks and exposed vulnerabilities. Everywhere.

<!-- more -->

So together with our client’s team we gathered up and figured out how to speed up the migration. The migration plan was there. It was already under execution. The problem was that… the user tests lagged behind. And it shouldn’t really surprise you. That’s mundane work that takes hours to get through. However… decision’s decision, to quote a famous rapper. I decided to help with verification. Execution was simple enough. Verification was the bottleneck.

## Verification

Let’s focus on verification. What do you need to check during verification of bootstrap upgrade migration?

1. Of course the page should render
2. It should look mostly the same. There should be no crazy elements drift but a little is accepted
3. Requests should reach backend endpoints

1 and 3 are quite simple to verify. With or without an AI agent we can check whether page finished rendering with 200 HTTP Status code. Button or link clicks should reach desired URL with expected HTTP method.

But how to verify bullet number two?

I think the answer will not surprise you. Use an AI Agent to do the verification. Yea fine, make no mistakes, end of story.

Except it’s not. Because relying on an AI agent, especially in production system that supports people working 24/7, requires proper evaluation of its work. And also managing cost to stay under certain threshold. Last but not least, time to execute the project is important too. My goal was also to stay involved as little as possible. Let me show you how I approached this problem and eventually was able to speed up the work and reduce cost significantly while keeping high outcome quality.

## How to verify things look mostly the same without having a full agent trust?

I am trusting agents’ code output more and more each day. However our codebase is a little bit of limitation. 12-year-old codebase. Mixed approaches. Unfinished projects. Deprecated approaches. Therefore I decided to stay in the loop and use a little bit of my time to help with verification.

I initially started with model Opus 5.5, reasoning medium to perform the verification. After each iteration I improved the bootstrap migration verification skill.
Among other things, the skill compared rendered layout – computed styles, bounding boxes and hover states, flagged visual regressions by running two dev servers – before and after change. It also turned every real drift into a failing Playwright check before fixing it. To prove the fact that before and after state is the same. Last but not least, it took side by side screenshots and turned all of this into brief report, highlighting the differences. The screenshots step was most important for me – the human in the loop. It allowed me to scan every page visually and quickly spot possible issues without merely relying on the word (or rather output token) from an agent doing the job.

Sounds good, right? I was happy with that setup for a while. We were able to speed up verification. But I was hoping for better speed gains and less feedback from my side. First good call was to reduce the scope of the project. That was one of valuable lessons – doing something just because you can doesn’t mean you should do it. At least not in one step. Let me explain…

During bootstrap upgrade it was also tempting to rewrite haml format to erb. The reason for that was simple. Some of the old pages were written in HAML since the good old days. It seemed almost harmless to include this small addition. However once this step was removed, the verification provided better results. I think that the reason for improvement was better usage of context window during single execution of bootstrap 3 -> 5 migration. However no speed gain.

### The breakthrough

Then I figured something out. For other small tasks in this project I was using Haiku 5.5 and it provided really good results, waaaaaaaaaaay faster than opus or sonnet. The better prompt I wrote, the better results I had. So I thought – I already have a good workflow defined (via skill) instructing an agent how to perform verification – let’s try to use cheaper, less smart but faster model and compare the results.

Needless to say, I was stunned. Same results, after fraction of time and for fraction of cost. Compared side by side both reports. Issues were reported with different words, but basically the same outcome. I decided to switch to Haiku 5.5 with high level of reasoning to finish this project. And there it was. I was satisfied with how quickly the amount of PRs I had to verify was shrinking.

There it was. David beat Goliath. We managed to finish migration before Rails 8.0 stopped getting security patches. Migrated to Rails 8.1.

My main lesson there is: you gotta experiment. If you are not able to execute task that should be possible to execute with cheaper model then maybe the time is not right yet. But do not assume (or follow X-tech-bros-advice) to only use best models all the time. Even if you can afford it, imo it’s not worth it. Execution time is important as well. And it turns out even mundane work such as bootstrap migration can get exciting because of how you can execute it. And boy I think it’s beautiful.
