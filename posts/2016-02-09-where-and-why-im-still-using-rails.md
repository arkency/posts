---
title: "Where and why I'm still using Rails"
created_at: 2016-02-09 11:50:16 +0100
kind: article
publish: true
tags: [ 'rails', 'wrocloverb' ]
author: Andrzej Krzywda
---

I've had many interesting conversations with experienced Ruby/Rails programmers recently. One of the topics that often pops up is when it makes sense (for us) to still use Rails, given the variety of other choices. This blogpost aims to summarize some of the views here. 

<!-- more -->

## Ruby conferences

Some of the conversations started when we talked about Ruby conferences and when I was explaining the mission behind the [wroc_love.rb](http://www.wrocloverb.com) conference. The mission is to serve the *experienced* Ruby programmers.

According to Uncle Bob [estimates](http://www.infoq.com/presentations/history-future-programming-languages), we double the number of programmers in the world every 5 years. It means that at any point of time, we have half of the programmers having less than 5 years of experience. That's a lot of people. 

Many conferences, rightfully, aim to educate those new people. They do it either by making the whole conference newbie-friendly or they try to find the balance mixing the "easy" and "hard" talks.

It's also a visible trend at Ruby conferences to present more and more non-Ruby talks. Some of them are the typical "soft" talks, while others are focusing on some other technologies (Elixir, React.js, Clojure, Rust, Go).

With wroc_love.rb we try to stay with experienced-only content. Even when we introduce some non-Ruby topics (this year it's React/Redux and the R language) we try to make it "deep" so that it's intellectually interesting to experienced programmers.

## Can you surprise an experienced Ruby programmer?

It's not easy to "surprise" a Ruby dev, if just look at the language. But language is well, just a language. It's the syntax. We're with one of the most elegant and happiness-oriented languages in the world.

I still find excitement while doing Ruby.
Some examples:

What [mutant](https://github.com/mbj/mutant) does while testing your test coverage is pretty amazing. Parsing the codebase, mutating the abstract syntax tree, unparsing and then running the tests again, how cool is that? BTW, the mutant tool [has](https://github.com/mbj/vanguard) a nice [ecosystem](https://github.com/mbj/anima) of [tooling](https://github.com/mbj/concord) around it.

In one of the larger projects we were working, we decided to get rid of FactoryGirl (mostly [because the tests using it were creating a state that was not the right one](http://blog.arkency.com/2014/06/setup-your-tests-with-services/)). My friend used the parser to find most of the calls to FactoryGirl and [replaced](https://twitter.com/pawelpacana/status/684427725457719296) (again, using Abstract Syntax Tree) them with the other ways of preparing the test state (test actors).

Have you looked at what's possible with [Opal.rb](http://opalrb.org) - the Ruby to JavaScript transpiler? Many people use it in production to write Ruby code for the browser. There's a whole framework ([Volt](https://github.com/voltrb/volt)) behind it, which allows you to reuse backend/frontend code. BTW, [Elia](https://twitter.com/elia), one of the Opal.rb creators will be presenting at wroc_love.rb this year.

[I'm deep into DDD/CQRS/ES recently](http://blog.arkency.com/2016/01/from-legacy-to-ddd-start-with-publishing-events/) (Domain-Driven Design, Command Query Responsibility Segregation, Event Sourcing). Those techniques are not ruby-related. But, they changed the way I write Ruby/Rails code. I'm giving this example, as it's good to know that we can bring ideas from other programming worlds and bring them to Ruby.

I know there are some cool things around the [dry-*](https://github.com/dryrb)/ROM ecosystem. This is something still on my TODO list to discover, so I keep being excited about some new things.

I recently blogged about the idea of [having a single Rails API endpoint to accept all changes to the app state](http://blog.arkency.com/2015/12/a-single-rails-api-endpoint-to-accept-all-changes-to-the-app-state/). I didn't have time to go further with this crazy idea.

Look at what we're (Arkency) doing around the [RailsEventStore project](https://github.com/arkency/rails_event_store).

Many of those things do appear at [Ruby Weekly](http://rubyweekly.com) or [/r/ruby](https://www.reddit.com/r/ruby/) or [/r/rails](https://www.reddit.com/r/rails/). However they get lost among other more newbie-oriented content.

If you don't find new exciting things it's because it's now hidden in smaller Ruby communities. Those ideas and discussions take place on their related Gitter channels, Slack communities or Github-issues related to the relevant languages.

I didn't even mention [what's happening with JRuby](https://github.com/jruby/jruby/wiki/Truffle) and that's like a whole world of innovations which are possible because we can use the whole JVM platform!

Did I mention the [Hanami](http://hanamirb.org) project (old name: Lotus)?

Did you look at apotonick's Trailblazer? [Have you read his book?](http://trailblazer.to)

## But Rails makes developers stupid

It's now more popular to criticize Rails than it was before. Once you get past the things that are possible with Rails you see the problems with some of its patterns - the active record pattern being the main one.

Suddenly, we realize that Rails teaches new developers bad habits. [We're worried that Rails makes other developers stupid](http://andrzejonsoftware.blogspot.com/2014/04/be-careful-with-rails-way.html). We try to show that [there's a world beyond The Rails Way](http://blog.arkency.com/2014/12/beyond-the-rails-way/).

## Why use Rails when you want to just use the routing/http layer?

This is the clue of the blogpost. Once you know the Rails limitations you try to find alternatives. You go with Hanami or you go with smaller tools like [roda](https://github.com/jeremyevans/roda). You may go with [Sinatra](http://www.sinatrarb.com). Or you go with rich Single Page Applications and you find yourself writing more JS code than Ruby.

Here's my approach, based on my skills and on my experience:

I still use Rails for the first version of the application. Me (and other people who were doing Rails for years) have the Rails-skills in our blood. Our muscle memory is based on Rails tricks. Most of the things you need for a typical web app is already there in Rails. You can build a full app within hours/days/weeks. This is what Rails is optimized for. 

I'm yet to find an alternative to Rails which is so productivity-oriented.

There's the whole issue with the rails-dependent gems. There are some which are more easy to remove/replace when needed - like [Devise](https://github.com/plataformatec/devise). While, there are some crazy gems which introduce huge coupling and are harder to replace (in my experience). This is the border for me. If I'm tempted to introduce some heavily-coupled gems then it's time to slow down and do it the non-rails way.

Yes, the Rails patterns make the code difficult to maintain in the long run. But in the shorter perspective they're just hard to replicate in other environments. I can't be faster with other tooling. There's obviously the skills bias here - I'm fast with Rails, so I'm going to stick with what I know. But that's the point of this post - to show you that if you're fast with Rails then you can enjoy staying with Rails for longer.

**My approach of starting with Rails is based on the understanding that code is not set in stone**. You can change it later.

You can decouple your app from the framework step by step and [I wrote a whole book about it](http://rails-refactoring.com).

You can gradually separate the frontend and go into React.js (recommended!) and/or Redux. We wrote a book how to use [React.js with Rails](http://blog.arkency.com/rails-react/), but we also wrote a book full of examples (and +10 repos!) [how to start with React.js](http://blog.arkency.com/rails-react/). We have [a huge list of Arkency React.js resources](http://blog.arkency.com/2015/11/arkency-react-dot-js-resources/). I see the React/Redux movement as my frontend future.

Heck, you can even move to DDD from a typical Rails codebase, if that's your kind of thing (it is for me).

OK, so that was the first reason when to use Rails - when you want to start quickly and you know how to gradually improve the code later on.

If you want to go with Roda or Sinatra, but later you actually follow the active record pattern of just using the same object from the db layer to the view, then I don't understand how this is different from just using Rails. I'd go with Rails.

If I'm about to start a Rails app, the time-to-market is not a major factor, then I'd consider things like roda or sinatra. But in that case, I'd go with architecture like DDD, where I take care of the object design on my own.

Rails is actually very good for the http layer - I don't see the need to replace it with other libs.
ActiveRecord as a persistence library is also good enough. As long as the AR object don't leak to your domain, then it's cool. It is overcomplicated, but if you just use in limited ways, creating your own private API for it - then you have the persistence problem solved.

## The future of Rails

I see a bright future for Rails. The Rails 5 release is controversial to many, mainly due to [ActionCable](https://github.com/rails/actioncable). I'm not criticizing it. Without going into details of the ActionCable infrastructure (there are parts worth some critique), the whole idea is making Rails even more attractive for the typical backend+frontend setups. You will be able to do cooler things faster.

Rails is a cool marketing product for many programmers. Yes, we live in times, where frameworks are products and require marketing. 

We have a charismatic and smart leader - [DHH](https://twitter.com/dhh). I often disagree with him on some details, but he's probably the best salesman in the whole programming community. That's one of the reasons why Rails will thrive. Rails is a product where out of the box you have everything and everything is just working. It's like the Apple products. 

Happy Rails coding!
