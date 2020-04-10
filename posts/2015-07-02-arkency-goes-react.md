---
title: "Arkency goes React"
created_at: 2015-07-02 09:19:01 +0200
publish: true
author: Andrzej Krzywda
tags: ['react']
newsletter: kung_fu
---

From its beginnings in 2007, Arkency was connected to Ruby and Rails. We’re still most active in those technologies.
However, over time there’s another R-named technology that quickly won our hearts - React.js.

<!-- more -->

Our journey with JavaScript was quite long already and sometimes even painful. We’ve started with pure JavaScript, then went all CoffeeScript. Nowadays we introduce ES 6.

We’ve experimented with Backbone (some parts are OK), we’ve had painful experiences with Angular (don’t ask…). We’ve been proudly following the no-framework JS way, while being very hexagonal-influenced ( [http://hexagonaljs.com](http://hexagonaljs.com) is alive and fine).

From the hexagonal point of view, the views and the DOM are just adapters. They’re not especially interesting architecturally. In practice, rendering the views is one of the hardest tasks, thanks browsers.

At the beginning of our hexagonal journey we went with just jQuery. We were careful not to use outside of the adapters. This was just an implementation detail. It wasn’t bad. It wasn’t really declarative, though. For richer UIs, this was visibly problematic.

When we learnt about React.js it felt like the missing piece in our toolbox. Thanks to our architectures, it was easy to introduce React.js gradually. Suddenly, all Arkency projects were switching to React based views.

React is a small library. It doesn’t offer that many features. That’s why it’s so great. It does one thing and it does it well - handles the DOM rendering. What’s also important, it does it very fast. If you worked on big JS frontends, you know how difficult it was.

We started sharing our React.js knowledge with our Ruby community, with which we feel strongly connected. We wrote many blog posts. At some point, we also started writing [a React.js book for Rails developers](http://blog.arkency.com/rails-react/). That’s where we felt the best - switching to React views from the Rails perspective.

If you want to read the whole story (and more reasons) why we switched to React.js, then go here: [1 year of React.js in Arkency](http://blog.arkency.com/2015/05/one-year-of-react-dot-js-in-arkency/)

Over time, we started to do more. More blog posts, more chapters in the book. We added a Rails repo which goes with the book.

At the same time, [we were contacted](http://arkency.com) by more and more clients who were mostly interested in our React.js experience and needed help with rebuilding their frontends.

Then we came up with [React.js koans](https://github.com/arkency/reactjs_koans). The idea was simple - let people learn React.js. Despite our Rails roots, we didn’t see any sense to couple this idea with Rails. The koans use ES6 and they run on node-based tooling. With koans, there was nothing Ruby-related, so it wasn’t targeted only to our beloved Ruby community.

The popularity of the React.js koans was bigger than we ever expected. Within one day we went to over 1000 GitHub stars. The repo was trending and Arkency was the second trending developer on GitHub for a moment (ahead of Facebook and Google).

When we worked on Koans, before the launching day - we were often discussing internally whether we need to extend “our audience” to more than Ruby developers. It felt out of our comfort zone. It’s nice to feel that we are surrounded with like-minded Ruby devs. We have *some* recognition in the Ruby market. Outside of that, we’re not really known. At that time, we called the potential new audience, “the JavaScript developers”.

Long story short - we’re opening a new chapter in the Arkency history. We’re announcing the React.js Kung Fu. We’re going to teach more and educate even more, about React.js. We’re no longer limiting ourselves to the Ruby audience with this message. We’ll be releasing a new book about React.js very soon. This time, the book doesn’t require any Rails background. We’ll be releasing more screencasts and blogposts. We’re also opening a new mailing list, that will be mostly about React.js and JS frontends.

<%= show_product_inline(item[:newsletter]) %>

We’re still in the Ruby community, though. We are working on a new update to the [Rails Refactoring book](http://rails-refactoring.com).

BTW, this book is at the moment part of the [Ruby Book Bundle](http://rubybookbundle.com).  The bundle contains 6 advanced Ruby books for a great price.

I just presented a [webinar about Rails and RubyMine](http://blog.jetbrains.com/ruby/2015/06/webinar-recording-refactoring-rails-applications-with-rubymine/). More stuff is coming here. We’re not leaving the Ruby community, we’re just broadening the React.js communication channel to more developers.

Let me repeat - Arkency is still a mostly Ruby company. We love Ruby. However, we have a great team of developers and this allows us to do more things. One of those new things is React.js.

Keep in mind, that Ruby and React.js are just technologies. They change, over the years. What is not changing is the set of practices. We’re doing TDD, despite the technology choice. We believe in small, decoupled modules. We understand the importance of higher-level architecture. We keep improving at understanding the domains of our clients. We translate the domain to code using the DDD techniques. We create bounded contexts. We let the bounded contexts communicate via events and we often consider CQRS and Event Sourcing. We measure the production applications. [We believe in the importance of async and remote cooperation](http://blog.arkency.com/async-remote/). We split features into smaller tasks.
The practices define us - not the specific technologies or syntaxes.

React.js deserves to be listed as one of the R-technologies in our toolbox. Open this new chapter with us - subscribe to the new mailing list and stay up to date with what we’re cooking.

<%= show_product_inline(item[:newsletter]) %>

Thanks for being with us!
