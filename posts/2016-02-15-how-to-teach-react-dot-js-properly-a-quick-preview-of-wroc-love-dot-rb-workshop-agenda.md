---
created_at: 2016-02-15 18:47:24 +0100
publish: true
author: Marcin Grzywaczewski
tags: [ 'react', 'redux', 'wroc_love.rb' ]
newsletter: react_books
img: "reactjs-workshop-blogpost-agenda/header.jpg"
---

# How to teach React.js properly? A quick preview of wroc_love.rb workshop agenda

<p>
  <figure>
    <img src="<%= src_fit("reactjs-workshop-blogpost-agenda/header.jpg") %>" width="100%">
  </figure>
</p>

Hey there! My name is Marcin and I'm a co-author of two Arkency books you propably already know - [Rails meets React.js](http://blog.arkency.com/rails-react/) and [React.js by Example](http://reactkungfu.com/react-by-example/). In this short blogpost I'd like to invite you to learn React.js with me - and this is quite a journey!

**Long story short, Arkency fell in love in React.js.** And when we fell in love in something, we're always sharing this love with others. We [made a lot](http://blog.arkency.com/2015/11/arkency-react-dot-js-resources/) resources about the topic. All because we want to teach you how to write React.js applications.

Workshop is a natural step further to achieve this goal. But how to teach React.js in a better way? How to take an advantage a stationary workshop gives to learn you in an optimal way? **What can you expect from React.js workshops from Arkency?**

<!-- more -->

## Why you should learn React.js?

There are many reasons. First of all, React.js helps you write even the most complicated dynamic interfaces. Facebook uses it, your clients will demand it soon (if not demanding it today). **React.js makes easy things easy and hard things achievable.** The programming model of React.js scales very well with the growth of your application. From small projects to big ones it is always applicable.

The second thing is that **React.js can be introduced gradually in your codebase.** This is extremely important when you work on an existing code. You can take a tiny piece of your interface and transform it into the React.js component. It works well with frameworks. And speaking of frameworks - it is often way harder to introduce a JavaScript framework in such workflow-friendly way. [Ryan Florence has a great talk about why React.js is well suited for legacy codebases](https://www.youtube.com/watch?v=BF58ZJ1ZQxY). For us it is also very important - inside the team we're working with legacy codebases all the time. It is inherent to the work of a consulting agency.

React.js is also a great _gateway drug_ to an interesting world of modern JavaScript. You may hate JS - but it is one of the most developing communities nowadays. The new standard of JavaScript polishes a lot flaws the old JS had. Node.js tools can be great drop-in replacements even in your Rails apps. It is really worth giving it a try - and in my opinion there is no better way to enter this world than learning React.js.

Last, but not least - the learning curve of React.js is very smooth. You need to learn only a few concepts to start working. It only makes one job - managing your views. This is the biggest advantage and the biggest flaw the same time - especially for Rails people, who get accustomed to benefits the framework provides.

But as always there are things which are harder than other. Let me talk a bit about those "hairy" parts.

## What is hard to learn in React.js?

Basically, there are three things that are needed to understand in order to master React.js:

* What is a component, what are its basic parts - `render` method, lifecycle methods and so on.
* What are properties and what is their role in React components.
* What is state and its role in the whole lifecycle of a component.

The third part is usually the hardest to grasp for React.js beginners. What you put into state? What you put into props? Aren't they interchangeable? If you don't get it right, you [can get into some nasty trouble](http://reactkungfu.com/2015/09/common-react-dot-js-mistakes-unneeded-state/). Not to mention you can nullify all benefits React provides to you.

There is also a problem of React.js being just a library. People can learn creating even the most complicated component, but they can still struggle in a certain field frameworks give you for free - data management. Building the user interface is very important but it is nothing if you can't manage the data coming out from using it.

What if you could get rid of both problems at the same time? That would certainly help you with getting into a right direction with your React.js learning. And you know what is the best part?

In fact, you can.

## React.js and Redux is the solution

Initially React.js was published by Facebook and there was no opinionated way to solve problems of data management, nor cumbersome state management. After a short while Facebook proposed its own solution - a so-called [_Flux architecture_](http://facebook.github.io/flux/).

The community went crazy. There was a massive EXPLOSION of libraries that were foundations to implement your app in a _Fluxy_ way. Those libraries was often focused on different goals - there were type-checked-flux libaries, isomorphic flux libraries, immutable-flux libraries and so on. It was a headache to choose wisely among all of those! Not to mention the hype over Flux caused some damage - this is not a silver bullet and people followed the idea blindly.

Today this situation is more or less settled. Many libraries from this time just died, replaced by better solutions. **It can be observed that this "flux libraries war" has a one clear winner - [Redux](https://github.com/reactjs/redux) library.**

Redux won because many things. One is the most important - it is extremely simple. The second one - it needs a minimal amount of boilerplate. Third - it does only one job - and makes it right. The dreaded problem of most React.js and frontend beginners in general - data management.

Let's make a thought experiment. Let's take three main parts of React.js:

* Component
* Props
* State

This is how React component works (in a great simplification):

* You render a component by giving it properties and a place to render. The result is a piece of an user interface (a `widget` if that kind of naming is your thing).
* A component has state. It is internal to it. User interaction (or an external world, generally) can modify state by calling component methods.
* State changes, component gets re-rendered. The change is possible because a `render` method which produces HTML uses `state` and `props` to determine what is the output.

**So state is something persisting within your component - hidden, yet important.** This is a problem because to know exactly what is rendered on the screen you need to dive into the React component.

And what if there'd be no state?

* You render a component by giving it props and a place to render. The result is a piece of an user interface.
* To make change you need to render the component with different props.

Let's rephrase it a little:

* You get a result of a function by giving it arguments and a place to store the result.
* To get another result you call a function with different arguments.

**So, basically, without state React.js is just a pure function (that is: a function which return value is determined only by their arguments).** This makes things even simpler than they are with _standard_ way of doing React. It also takes away the last learning obstacle - state management.

**Combo React + Redux is extremely efficient in working with components in a stateless fashion.** That's why it is my preferred way to learn people React.js on the upcoming workshop.

## What you'll do during the workshop?

I'm honored to make a workshop as a part of the wonderful [wroc_love.rb conference](http://www.wrocloverb.com/) in Wrocław, Poland. This is my little _thank you_ to the community, as well as an another occasion to share my knowledge about React.js.

I wanted to make this workshop as Arkency-like as possible. You may know that we're working remotely and we're following async principles. You can learn more about it in [Async Remote: The Guide to Building a Self-Organizing Team](http://blog.arkency.com/async-remote/) book which is our 'manifest' of workflow, culture and techniques. While a workshop form is not _remote_ at all, I wanted to make it as _async_ as possible.

In the workshop we'll be developing an app. A real one - it'll be an application to manage Call-for-Papers process which takes place before a conference. You'll be presented with a working API, static mockups and working environment where you can just start writing React.js-Redux code. Your goal will be to develop an user interface for this application.

You can enter or leave anytime. During the workshop the questions & answers will be accumulated and available for you all time. Everything you'd need to jump in and code will be written on a blackboard. You can take only a first task and do it. You can just watch. I'll be here to help you, answer your questions and make a quick introduction to React.js and Redux basics.

That's all. You don't need any prior React.js knowledge. It'd be great if you saw JavaScript code before - but not necessary.

Do you think it is a crazy idea? Or maybe it's impossible to make a working app this way in such short time? This is why because you haven't seen React.js+Redux combo in action ;).

**You can enter the workshop free of charge** (although the conference is a paid event). **The event takes place in a lovely city of Wrocław, Poland - 11th of March at 11:00.** Mark your calendars - I'll be happy to see you there!

Oh, and don't hesitate to reach me through [an e-mail](mailto:dev@arkency.com), [Twitter](https://twitter.com/Killavus) if you have any further questions. Or maybe you have your story to share - for example what is the hardest part of learning React.js? I'll be happy to hear them!
