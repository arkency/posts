---
title: "One year of React.js in Arkency"
created_at: 2015-05-10 20:11:11 +0200
kind: article
publish: true
author: Marcin Grzywaczewski 
tags: [ 'react', 'frontend', 'book' ]
newsletter: :react_book
img: "/assets/images/one-year-of-react/head-fit.png"
---

<p>
  <figure align="center">
    <img src="/assets/images/one-year-of-react/head-fit.png">
  </figure>
</p>

What always makes me **happy** with new technologies are **hidden positive side-effects** I’ve never expected to happen. When I first introduced React in Arkency, which was on 4th of March 2014 I never expected it’ll become so popular in our team. But should I be surprised? **Let me tell you a story** of how React allowed us to re-think our frontend architecture and make us a lot more **productive**.

<!-- more -->

I worked on a big application and one of client requirements was a **fully dynamic UI**. Our client sells that SaaS to big companies - all employees are accustomed to working with desktop apps, like Excel. It was a very important goal to provide a familiar **experience** to them.

We prepared a list of tickets and started working with our standard practices. And that was a hell lot of work! **Demos for end-users were very often**. With those demos **priorities changed** - and it was a matter of **hours**, not days. *“Hey, I got a VERY IMPORTANT CLIENT and demo for him will be the next monday - can you provide me a fully-working UI of &lt;insert your big feature name here&gt;?”* - client asked such questions very **often**. On Thursday…

Clients are usually happy with our productiveness but such tight **deadlines were exhausting**, even for us. But we worked. **Worked hard.** Cutting the niceties out, leaving only the most necessary elements for demo purposes, even shipping the frontend-only prototypes which were good enough since our client was in charge of making a proper presentation - we can consult him and tell what he should avoid to show.

But **code started to slow us down**. We designed our frontend code as a set of specialized ‘micro-apps’, each in a similar fashion - there was an use case object with domain logic and adapters which provided the so-called external world - backend communication, GUI and more. Then we’ve used 'Glue' objects which wired things together using using advice mechanism to wire an use case and adapters together (that is called aspect-oriented programming - [look at this library](https://github.com/gameboxed/YouAreDaBomb) if you are interested in this topic). This architecture was fine in a situation where such apps are not designed to communicate between themselves. But **the more we dived into a domain the more we understood** that some apps will communicate between themselves. **A lot.**

The next problem was a GUI adapter. That was the part of every app then - we just needed a UI for performing our business. **And it was the most fragile and the hardest part to get right.** We’ve used Handlebars + jQuery stack to deal with UI then. And this part took us like **80% time of shipping a feature**.

Now imagine: You’re working hard to build features for your client with a tight deadline. You are crunching your data, **trying to understand a hard domain this project has**. You carefully design your use case object to reflect a domain language of the project and wire in adapters. Then you write a set of tests to make sure everything works. After 8 hours of work you managed to finish tickets needed for an upcoming demo. Hooray! You contact your client that everything is done and close the lid of your laptop. Enjoy your weekend!

**Monday comes. Your client is super-angry since his demo went wrong.**

Ouch. What happened? You enter Airbrake and investigate. That click handler you set on jQuery was not properly instantiated after a mutation of the DOM. And confirmation works, yeah. But it has an undefined variable inside and you did not check it in your tests since it was such a small thing… since **testing is such a PITA in the jQuery-Handlebars stack**.

**And your business logic code was fine. Your Rails code was awesome. But fragility of your GUI adapter punched you (and your embarrassed client) in the face.**

Atmosphere was dense. And we still had big architectural changes to be done… HOW CAN WE FIND TIME FOR THAT?

**Then I decided something had to be done about it.** I went on a camp with some fellow developers and a friend of mine had a presentation about React. I had a laptop opened and was looking at UI code of this project.

The React presentation was good. I imagined how declarativeness of React will **help me with avoiding such embarrassments** we had before. I needed to talk with my co-workers about it.

**After I got back from a camp, this was my first commit:**

```
Author: Marcin Grzywaczewski <marcin.grzywaczewski@arkency.com>
Date:   Tue Mar 4 22:07:13 2014 +0100

   Added React.js
```

I rewrote this nasty part that destroyed the demo of my client in React. **It took me 4 hours with a deep dive to React docs** since I had no experience with React before. **Previous version took me 6 hours of writing and debugging a code.** In a technology I understood well and had experience with.

And it worked. It worked without a debug… I then talked with my co-workers and showed them the code. **They decided to give React a try.**

First two weeks were **tough**. Unfamiliarity of React was slowing us down. But in this additional time we were thinking about answers to questions like *“how to split this UI into components?”* or *“how to pass data to this component in a sane way?”*. There was less time to make all this *write code-refresh browser-fix error* cycles we had before. Declarativeness of React allowed us to think about code easier and took all nasty corner-cases of handling user interactions and changing page away.

And ultimately we **spent less and less time of writing our UI code**. Next demos went fine. **React gave us more time to think about more important problems.** We finally found time to change our architecture - we replaced advice approach with event buses as a first step. As the project grew, we needed to overcome performance problems - we loaded the same data many times from different API endpoints. We fixed this problem with introducing stores, highly influenced by a similar idea from **Flux** architecture which is also a part of the React ecosystem.

**But I'll be honest here: it was not React that fixed our problems. Not directly. What helped us is that writing UI code became easy - and fun!**

**Fun is a big thing here.** What unlocked our full potential is that **we stopped thinking about writing UI code as an unpleasant task.** We started to experiment freely. We had more time to think about more important problems - writing UI was faster with React. We spent less time in ‘failure state’. We had a more organised way to think about UI elements - components abstraction helped us to produce tiny pieces fast and without failures. Our **frontend tests were much easier to write, so we improved our code coverage** a lot. All those **tiny side-effects** React gave to us made us successful.

Now we got React in many projects. In many states - some apps have the UI fully managed by React (like the project I am writing about here), some got both Rails views and React-managed parts. Some got parts in other technologies like Angular.

We write blogposts about React and other front-end technologies we started to love. **More and more people in Arkency that used to dislike frontend tasks became happy with them. You can be too!**

Since React was so successful for us we decided to write a book about it. You can [buy the beta version now for $49](https://arkency.dpdcart.com/cart/view?referer=http%3A%2F%2Fblog.arkency.com%2Frails-react%2F&product_id=106660-rails-meets-react-js&_ga=1.119508879.764295944.1430244356&__dpd_cart=b33e1b79-0c92-4882-a3e1-f37aa18ab989). We took an effort to make it friendly for Rails developers. It consists of:

* Practical tutorial showing form with a few dynamic features that you can do step by step to learn react
* Theoretical chapters about react API and best practices
* Examples on testing react components
* Around 150 pages right now filled with knowledge and examples plus bonus chapters.

We had fun writing it. We put our best practices to this book - and we experimented a lot to examine those practices. Me and my co-workers worked to improve quality of its content. 

**The side effects of React helped us with our projects. You have an occasion to bring fun to your front-end code too!**

