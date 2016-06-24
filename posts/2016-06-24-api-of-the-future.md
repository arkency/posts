---
title: "API of the future"
created_at: 2016-06-24 15:42:00 +0200
kind: article
publish: false
newsletter: :skip
author: Marcin Grzywaczewski
tags: ["frontend-friendly-rails"]
img: "frontend-friendly-rails/ffr-cover.png"
---

_The "Frontend-friendly Rails" book is now live!_ 

Here is what Ryan Platte (one of the readers) wrote after reading the book:

> I'm very experienced with Rails, and I've built production apps in React. But faced with starting a new Rails+React integration, I didn't look forward to arguing with Sprockets or undoing other Rails "opinions". Frontend Ready Rails pointed me to a clean setup with easy-to-follow steps to do it right the first time. And every step is explained thoroughly so I understand the reasoning behind each part of the advice.

> With this book, I basically got an experienced pair to step through this setup with me. I recommend it to anyone who wants to integrate React into their Rails app the right way.

<p><a href="https://arkency.dpdcart.com/cart/add?product_id=133328&amp;method_id=142386&amp;_ga=1.91543644.719304756.1458753187" style="display: block; margin: 1em 0; text-align: center; font-size: 2em;">Click here to buy the book!</a>
<p style="text-align: center; font-weight: bold">Use the <code>FF_RAILS_BLOG</code> coupon to get 40% off!</p>

API is a constantly evolving topic. Today, the most of APIs we’re all using are REST, JSON-based APIs. That was not the case a few years ago, when XML was a king in terms of response formats and techniques like XML RPC was quite popular.

But is the current state of API is here to stay? Do REST-based APIs scale well? Do they provide an optimal experience for integrated clients?

I don’t know the answer to this question. What I know is that there are companies that are challenging this idea - and you can  try out their solutions today. Maybe those solutions will be a better fit for your project?

<!-- more -->

## Netflix - Falcor & JSONGraph

<iframe width="560" height="315" src="https://www.youtube.com/embed/nxQweyTUj5s" frameborder="0" allowfullscreen></iframe>

Relatively recently open sourced [Falcor](http://netflix.github.io/falcor/) is a technology Netflix uses to build their backend solutions. Results for them are spectacular - they claim that they were able to remove 90% of their networking backend code by using it. It’s a pretty impressive result!

As every approach in this list, Falcor is using an underlying language for its inner workings - in case of Falcor it’s the most non-intrusive choice which is [JSONGraph](http://netflix.github.io/falcor/documentation/jsongraph.html). The advantage of this choice is that you don’t need to incorporate another technology - JSONGraph is just JSON.

The aim of Falcor is to provide the same experience regardless of the technical means needed to fetch the data. As quoted in the main page:

  You code the same way no matter where the data is, whether in memory on the client or over the network on the server.

Falcor works different than a typical REST API - while in REST you have a resource per endpoint, in Falcor you have just one endpoint. This is what [Andrzej was advocating too](http://blog.arkency.com/2015/12/a-single-rails-api-endpoint-to-accept-all-changes-to-the-app-state/) in a slightly different context.  The main reason for that is to reduce network latency inherent to an every request - with Falcor the client can hit the endpoint just _once_ due to flexibility it provides. Falcor was an internal Netflix solution and it’s blatantly visible - it provides the biggest gains if you happen to host an infrastructure with many small services being the separate apps - just like Netflix does.

What’s more, you get many application-level features that you would need to implement by yourself in case of the REST API, like caching, batching requests or request deducing.

I find Falcor very interesting in topologies with many small apps - because it provides a way to provide a coherent way of fetch data regardless of its source. Unfortunately, you can’t use Falcor together with Rails - you need to build your Falcor solution on top of Rails, instead on integrating it together within the same app.

## Facebook - Relay & GraphQL

<iframe width="560" height="315" src="https://www.youtube.com/embed/9sc8Pyc51uU" frameborder="0" allowfullscreen></iframe>

Before Netflix released Falcor, Facebook came up and open sourced their own technology for building APIs. What’s more, it’s not only a technology, but an architecture/framework as well. It’s called [Relay](http://facebook.github.io/relay/), it is intended to be used with [React.js](http://facebook.github.io/react) and it allows you to fetch your data in a more controlled way than a typical REST API connection looks like.

In a typical REST API application, your client can only _assume_ the structure of the data - of course you can make your API configurable, so the client can ask only for a specific fields from the response and so on. But still, client is just issues the AJAX request, hoping that what comes back is the response format it expects.

Relay takes a different approach. There is a concept of _schema_  in your backend which you define. A client can issue a _query_, defining what expects from the server to be returned. A server validates whether the query is valid (so it can be processed) and returns the response expected by the client.

The main difference is that now client not assumes how response should look like, but defines it by itself. This way you can avoid variety of very hard to test situations like breaking API changes not reflected on the client, and so on.

The language used to describe your queries is a custom Facebook solution and is called [GraphQL](http://facebook.github.io/relay/docs/thinking-in-graphql.html#content). It works very well for queries which can be easily shaped as a graph. And (surprise!) Facebook has the ideal data for it - relationships are natural because those are people relationships.

As Falcor, since it is a solution tailored for applications with an extreme performance needs you have many performance improvements, like built-in caching. Unfortunately, while performant, it also introduces a lot of code if you’d like to mutate your data through it. There is a concept of _mutations_ which encapsulates the logic of mutating your data, as well as invalidating all necessary caches - and you need to write it by yourself. Ouch!

It also provides very nifty features like optimistic updates (your view gets updated instantly, and if error on the server occurs it gets rolled back), retrying failed requests, queuing mutations… it’s really sophisticated.

I’d recommend this solution if you happen to have data suitable to be represented as a graph - so rather small ‘data nodes’ with many relationships between them. Relay has a rather steep learning curve and entry cost - but it pays off in terms maintainability, performance and elasticity it provides.

What’s fortunate, you can use GraphQL and Relay together in Ruby - there are libraries like [graphql-ruby](https://github.com/rmosolgo/graphql-ruby) and [graphql-relay-ruby](https://github.com/rmosolgo/graphql-relay-ruby) that can help you with building a solution, using Rails.

## The change keyword is _Graph_

There are many other new approaches to build an API ([Flux over the wire](https://codepen.io/elierotenberg/post/flux-over-the-wire), the big come back of [Datalog thanks to Clojure/Datomic](http://docs.datomic.com/query.html)…), but what is very clear from most of them is that those solutions are relying heavily on the cornerstone of the computer science - which is a graph.

Graph is a very simple structure, consisting of _nodes_ and _edges_. Under the hood, a RDBMS like MySQL and PostgreSQL can be represented by a graph, too. There are [graph databases](http://cassandra.apache.org/) which are optimised to store and query data that way.

It’s nothing new. But right now topologies of our systems, as well as processing power enables us to revise this idea again. I’m looking forward to more ideas like this - it’s always beneficial to provide new, interesting solutions.

The wind of change is also visible because majority of those solutions are based on just a single API endpoint. It’s cool because you can just add it as a separate endpoint and continue serving your old REST API without major problems.

Are they better than plain old REST APIs? Of course it’s complicated. They work wonders for both Facebook and Netflix - but it is because those are developed with their needs in mind. What is the best choice for your applications? There are rules of thumb, but the definite answer is unknown for your project. You know the best!

## But what if you’re still working with REST API?

<a href="https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386">
  <%= img_fit("frontend-friendly-rails/ffr-cover.png") %>
</a>
<a href="http://blog.arkency.com/assets/misc/frontend-friendly-rails/ff-rails-sample.pdf" style="display: block; margin: 1em 0; text-align: center; font-size: 1.5em">Download the free chapter</a>

I’d recommend going for those techniques if you happen to be quite happy with your current REST API solution and want to upgrade your experience. 

Unfortunately, I find people struggling with creating robust APIs in Rails tailored for their rich UI needs. No wonder Rails has some to do with this - it is a framework designed for request-response cycle applications with HTML views served by the backend. To use it better, you may need to upgrade Rails defaults to something better.

In our new *Frontend-friendly Rails* book we describe the process of such upgrade. You can learn from it a set of independent techniques that are beneficial for API-based Rails projects, without resorting to new technologies like Grape, Rails-API or Swagger. You can build great APIs using just standard Rails - something that I want to emphasize.

Those techniques serves me well to this day. I implement them in my projects and they’ve got a status of being *battle-tested* - they served thousands of users and made my code just more maintainable and allowed my frontend to blossom. Not to mention you’ll see how easy you can improve your backend-frontend communication even more by adding real-time to it or knowing and distinguishing patterns you can use to write integrations around them. It’s all about making Rails more *friendly* for your sophisticated frontend application written in JavaScript (knowledge applies to mobile clients too).

The book consists of 99 pages of an exclusive content. With bonus chapters (which are hand-picked selection of blogposts we’ve written during years about the topic) it’s 154 pages. The book is a set of techniques - you can treat chapters as complete solutions or summaries of a particular topic/technique. There are also benefits and all necessary theory explained, as well as step-by-step descriptions of a process - perfect for convincing your boss/teammates to improve your codebase.

From this book you’ll learn:

* **Switch your Rails application to frontend-generated UUIDs** - a step-by-step, database-agnostic, test-driven solution you can use with legacy applications too. It’ll allow you to free your frontend code from being tightly coupled to the backend with every data change.
* **Setup the Cross-Origin Sharing (CORS**) - the description of the problem as well as the solution described. Useful if you want to host frontend on a different host than your backend.
Prepare JSON API endpoints for your API - JSON API allows you to have very robust response format for your endpoints which will serve you well and you won’t need to think about it. That’ll allow you to focus what’s more important - which is doing your business logic right.
* **Create a living API** - beyond request-response cycle - this is a chapter about adding real-time support to make your frontend even more user friendly. The solution presented is made using the Pusher library, but the way of doing it is tool-agnostic. I also present cool technique to make the real-time support as maintainable as possible.
* **Consequences of frontend decisions** - level up your knowledge and understanding of shaping your frontend, knowing consequences of your decision. More theoretical (but code-based) chapter which will improve your thinking about designing frontend code.
* **A complete overview of creating modern assets pipeline** - the last chapters are about creating the assets pipeline from scratch. You’ll learn what tools you’ll use, what their responsibilities are and how to configure it in a step-by-step manner. After you finish, you’ll have the stack with ES2015 support, CoffeeScript support for legacy compatibility, testing stack and production builds.

<a href="https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386" style="display: block; margin: 1em 0; text-align: center; font-size: 2em;">Click here to buy the book!</a>
<p style="text-align: center; font-weight: bold">Use the `FF_RAILS_BLOG` coupon to get 40% off!</p>

I found a ton of value in applying these techniques in projects I’ve been working on. I hope this book will be as handy for you as those techniques are for me - to this day!

## Summary

Graph-based solutions are great opportunities to think about redesigning your API. While powerful and backed by big companies, you still need to consider they’ll be a good fit for your data and your kind of topology. Netflix’ Falcor works best in micro services world where Netflix sits. Facebook’ Relay works best in graph-based scenarios where fetching data related in a complicated way is a common use case. Choose your technology wisely and think above REST API!
