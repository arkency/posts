---
title: "Remote collaborative modelling"
created_at: 2020-03-23 14:11:18 +0100
author: Mirosław Pragłowski
tags: [ 'ddd', 'remote', 'modelling' ]
newsletter: skip
kind: article
publish: false
---

Being remote means you do not always have a face to face contact with your customers, with the domain experts or with the right people who really know you the business you try to model works.

This must not be an excuse to skip the modelling part. Actually it is even more important to have good shared understanding of the domain and the problem you try to solve, to build & use the ubiquitous language.

<!-- more -->

## Start with shared document

You don't need any special knowledge, you don't need to read books, you don't need to take courses, just start collaborating with the right people, the people who know the business or the people who have experience with old systems.

Start by just asking questions and by actually listening the answers, and then note them down.

Use shared document & if possible shared screen to collaboratively create the description of the domain problem. The tools here are not important - anything that is capable to show changes history and add comments/ handle discussions would fit. The online documents shared & editable by whole team would be a good start.
From my experience the tools to manage project (Trello, Basecamp, Jira etc) are not the best ones here. The discussion should be close to the text where problem is described. This tools allows to comment under the main section and that is adding unnecessary friction when you want to understand whole thing, with all different opinions.
BTW if your collaborators are familiar with Github a Pull Request with a markdown file should work - you will get traceability of changes and PR conversations will allow for easy clarifications of misunderstandings.

Shared screen will work only if you work at the same time, what not always will be possible, that's why is it important to have a way to track changes & have discussions in the edited document. Use shared screen to build trust, to help others to focus on the current part and to make user everything is described in a way all of you understand and being consistent with ubiquitous language.

Good idea might be use techniques & tools used in Mob Programming - especially when you work in larger group, with several domain experts. Put yourself in a driver role and let them guide you, follow their words and make notes - build the model based on shared understanding. And ask questions if you have any doubts.

But we could do better than that. Some modellers have already tried that and worked on some techniques how to make the gathering requirements better, how to have better, easier conversations with domain experts. We could learn from them and try which technique works best for us.

## Event Storming

Th Event Storming hits the DDD community a few years ago. It has changed the way we think about modelling session. It has introduced the visual collaborative modelling techniques and has made us to embrace use of it.

But the Event Storming is the hardest one to use online. According to [Alberto Brandolini](https://twitter.com/ziobrando) there is no good way to do it online, the same way you do not organise "toga party" online.

There have been some attempts to make remote/virtual Event Storming but my feeling is all of them miss some important energy we get when standing together under an unlimited modelling space, working in chaotic way. The remote Event Sourcing miss the chaos, and in this case it's a bad thing.

However things changes... maybe you will find a good way to use it, maybe you could think of some new tools that will "embrace chaos" and allow you to get back that energy.
I've tried... but I've failed. Some said that it was a success.   Try it for yourself. Share the experiences. Let's learn from each other, because you know... "we're learners"!

## Domain StoryTelling

Domain StoryTellings is a collaborative modelling method developed by [Henning Schwentner](https://twitter.com/hschwentner) & [Stefan Hofer](https://twitter.com/hofstef).
It relies on a fact that telling stories is a fundamental way of human communication and business experts are the storytellers (at least most of them). It uses a simple pictographic language with three essential types of symbols:
actors (usually named with a role identifier), work objects & activities to visualise the stories told by domain experts.
Domain Stories are told from the perspective of actors, which play an active role in the Domain Story. Actors create, work with, and exchange work objects such as documents, physical items, and digital objects.

The modeller should focus on true stories, no abstract generalisations, no hypotheticals, just concrete examples of what is actually happening in a domain.

> Sometimes three good examples are more helpful to understand the requirements than a bad abstraction.

Start with default/happy case, model important variations and error cases as separate Domain Stories.

Telling the stories are natural for humans so this method is easy to explain to your collaborators. It's easy to understand, easy to follow and very easy to do it remotely. There is a dedicated online tool where you could draw Domain Stories [https://www.wps.de/modeler/](https://www.wps.de/modeler/) but this is not the only one option.\
You could read [more about Domain Storytelling here](https://domainstorytelling.org/#dst-explained).

## Story Storming

Another technique is the Story Storming. It is influenced by Domain StoryTelling & Event Storming but also by other ways to map business requirements like Event Modelling, User Story Mapping. It starts with very simple, easy to explain notation. You use tree kinds of post-its: Subject, Verb & Object. And like in any language you build simple sentences. You describe the domain story with this simple sentences, using very specific, concrete examples. As a modeller you have to focus on language, the simplicity of the sentences enable domain experts to tell their stories in a natural manner. No need to learn new technique, no barriers to start using it, no need for technical background.
Learn [more about Story Storming here.](https://medium.com/plexiti/story-storming-191756f57387)

## Sync vs Async

Remote work gives you an opportunity to avoid sync meetings. Yes, sometimes this is much easier to just have a shared screen and work together - especially when your domain expert is not very technically savvy. It would work better also on the beginning of the modelling when you need to establish basics of the language (ubiquitous language is not defined from the begging - this is something you need to build together) and gain trust from the business. So start with sync, and then it depends on you & your collaborators how you want to continue.

Embracing async is not easy, it will cause some friction and misunderstandings but don't let it to stop you. With time your understanding of domain will grow, also you will learn how to work better with your domain experts and also them will learn how to share the domain knowledge with you.

Async modelling has also some advantages. It's is slower. And that is a good thing. You actually have a time to think about your model, about what really is important and about examples you are working with.

## There is more, give it a try!

I've shown you only a few techniques here, but there is more. To name a few:

* Event Modelling
* User story mapping
* Impact Mapping
* Business Model Canvas
* Example mapping
* Specification by Example

Go check them. Find the one suitable for your needs. Start using it. Share your experiences. Help others to understand good and bad parts of the techniques, but remember your mileage may vary :)
