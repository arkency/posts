---
title: "I was a CRUDoholic"
created_at: 2018-11-20 17:41:40 +0100
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :skip
tags: ['ddd', 'rails']
img: rescon_andrzej_thinking.jpg
---

Imagine one of your non-IT friends. Yeah, the “normal”.

Think about what they do for a living.

Try to construct a few sentences describing their daily work.
 
This is my take:

Rafal runs a big chess school. He hires chess instructors and assigns them to specific regions where they educate the kids on the beauty of the game of chess. They invent new plays and they use them to simulate chess pieces. Thanks to this, the kids love the game and they practice strategic thinking while playing.
 
OK.

Now, the next part, let’s translate it into a language, which is basically English, but with just 4 verbs: **create**, **read**, **update**, **destroy**.

<!-- more -->
 
Rafal **created** a big chess school. He **updates** the team with instructors and **creates** new instructor/reader assignments where they **update** kids education on the beauty of the game of chess. They **create** new plays and they **create** a simulation of those plays to **create** chess pieces simulations. Thanks to this, the kids **update** their love to the game and they **update** their strategic thinking while **creating** new chess games.
 
It sounds awfully weird, right? Now, imagine your friend reads this second job description. Imagine how they would look like.
You know what I’m getting at, right?
 
**CRUD**

The translated text is how CRUD programmers sound to the “normal” people.
 
Who are CRUD programmers? Unfortunately, Rails, kind of makes us all CRUD programmers. The controller actions are usually CRUDish. The ActiveRecord classes are basically wrappers around CRUD actions. The migrations use CRUD language. Heck, even the views are CRUD’ish. Our UI looks CRUD’ish.

Rails doesn’t force us to do it, but it feels right to do CRUD with Rails.

**My relationship with Rails is complicated.**
 
When I first met Rails, I was a Java developer. I haven't known Ruby yet. I loved Java (yes, kill me). I wrote Plain Old Java Objects. I studied “Refactoring” by Martin Fowler. I was fighting the language to make it look more elegant, less verbose, more like ... Ruby.
And then I found Rails. And then I found Ruby. And I've fallen in love.

I loved the syntax, I loved the perfect OOP model (messages!). Because I found Ruby through Rails, I adopted the Rails Way of thinking. Somehow I accepted this as part of Ruby. Slowly, all my OOP rules that I sticked to in Java, became obsolete.
 
Who cares about too many responsibilities in that object, when it’s still just 80 lines of code, less than this smallest Java class I ever created?
 
Who cares about breaking the Law of Demeter, when Ruby has those nice delegates “macros” and it’s so short and easy to do so?
 
Then it hit me - the Rails projects I worked on became bigger and bigger. The testing became painful (hard to unit test the monolith, so let’s go for browser tests). The build was slow and unreliable. My communication with the clients became robot-like, where the robot is limited to just four verbs.
 
<%= img_fit("rescon_andrzej_thinking.jpg") %> 
 
**Yep, I became the CRUD-oholic.**
 
Even though, I knew it was wrong, it was so hard to get out of the CRUD addiction.
But I knew that I had to.
 
Slowly, I was coming back to the world of design patterns. It wasn’t easy, though. It’s not easy to talk about OOP, where you don’t even have control over how the objects are instantiated. Good luck having constructors for ActiveRecord classes or the controllers. Good luck having objects always in the valid state - where Rails encourages you to have objects in the wrong state - because you can always call .valid? right?
 
Hexagonal architecture was one area where I found inspiration - this inspired me to simplify at least one part of the app - the application layer.

Then I found out about **Domain-Driven Design**, but it didn’t fully click on its own.
Then I learnt about **CQRS** - Command Query Responsibility Segregation (awful name, right?) but it didn’t make sense to me.
Then I learnt about **Event Sourcing** and it felt just wrong.
 
It took one person, whom I grateful all the time, a few beers and one evening of drawing diagrams. After one programming meetup, Mirek Praglowski (now part of Arkency!) explained those 3 things together to me.
 
And then it clicked.
 
**CQRS + DDD + Event Sourcing**
 
Each of us has a different style of learning. Each of us needs different “click” moments. To me, it was seeing how those 3 techniques can work together. This solved so many of my problems.
 
Fast-forward about 6 years. All Arkency projects now use RailsEventStore, the tool we created to support CQRS/DDD/ES in Rails projects. We became the experts of applying those techniques in the Rails world. 6 weeks ago, we have organized the first REScon - a conference dedicated to RailsEventStore. We have organized Rails/DDD workshops in Poland, Ukraine, Germany, UK.
 
I’m so grateful that we found this way. I’m grateful for the people I met who were patient to explain this to me. I’m grateful to the Arkenciers - we went through the hard learning phases as one team, helping each other all the time. I’m grateful to our clients who trusted us and let us choose the techniques we recommended. I’m grateful to all the people who attended our workshops, trainings, conferences - this motivated us to create RES.
 
**Thank you!**
 
Thursday, this week (US friends - yes now I know it’s Thanksgiving, I’m sorry, it wasn’t intentional), I will be running a free webinar called **“From Rails Architect to Rails Programmer”** during which I explain how CQRS/DDD/ES help us shape the architecture of our apps, based on 6 examples. During the webinar, we will have a big announcement. I’m super-excited, but also scared. I hope you can be there with me.
 
Hopefully, we can all create a better programming world where there are more than 4 verbs available.

[https://arkency.com/webinar](https://arkency.com/webinar)
 
See you!
Andrzej
