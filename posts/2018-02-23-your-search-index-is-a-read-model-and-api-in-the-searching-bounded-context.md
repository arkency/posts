---
title: "Your search index is a read model (and API 😉) in the Searching bounded context"
created_at: 2018-02-23 16:00:00 +0200
publish: true
author: Robert Pankowecki
tags: [ 'search', 'algolia', 'rails', 'react' ]
newsletter: arkency_form
---

For me, one of the biggest revelation from adopting [DDD](https://martinfowler.com/tags/domain%20driven%20design.html) was the discovery that one model of your data is often not sufficient. That with bigger and more complex applications you might need to have multiple, slightly (or hugely) different models which take a different perspective to look at the data. For years, I've been modeling thinking that there is one way I can organize my classes and my data. One way, which would be convenient for all parts of the application. Only years later I realized that requirements usually diverge over time and trying to have a single model to cover for the requirements coming from different people, different parts of the organization, from admins, customer service, merchants, customers, board, etc might be doomed from the beginning. I realized that it might be simpler to duplicate some data, but organize them differently, in a way which makes it easier to answer the needs of a certain stakeholder or certain class of features.

<!-- more -->

The same argument goes for data stores, but I think with data stores it is more embraced in certain circles. We understand that there is no single DB good at everything and at some point, we just need to add a different one. It's never an easy decision (at least for skeptical guys like me). And it requires careful judgment whether the benefits outweigh the additional operational cost.

If there is one place where it turned out to be a good choice many times, I would say it's when you need to implement fast full-text search in your app.

In DDD, a derived model that you build based on what's happening in your canonical model is called a read model. Read model as the name implies is read-optimized. Usually, a read model will contain data from multiple tables and there will be duplication. Also, a good read model is tailor-made for a single purpose, ie. a single screen. That means when you design the search index it is good to think about:

* what data needs to be displayed, that way you don't need to contact your primary model and you can just use the search result directly
* what data needs to be used for filtering, that way you don't need to contact your primary model as well

I think about search indexes (as in Elasticsearch or Algolia) as my read models optimized for searching and displaying search results. Those indexes are often built asynchronously in a reaction to what's happening to the write model stored in a primary data-store. If you use domain events then often you are going to update the index within a handler reacting to published events.

Here is an interesting idea. What if the data in the index could be exposed via an automatically provided API directly to your frontend (JS and/or mobile) clients for direct consumption. That would mean you don't need to implement the search API on your own and you could save the time for building it.

It means that the frontend team working on the search would probably need very little API from the backend team. You would communicate via the data in the indexes. Sometimes that's not good enough. When it is not, the frontend can communicate with the backend to run a query using the index. Then the backend could further limit the results based on some criteria or enhance the returned data with attributes from the database.

You can even decide on the index schema up front, fill a test index with some fake data and start working separately on it. The frontend team on building a wonderful search experience and a pretty design. The backend team on reacting to data changes in your app which should lead to updating the index. As a result, both teams can work in parallel.

And that's what you get out of the box when using Algolia. Your mobile or JS client (written in React.js or React Native) can use an API token to obtain search results from allowed search indexes and it does not even need to communicate with the backend. It can talk directly to Algolia, which is hosting your search data in their data-centers.

_Are you also feeling the pain of building search pages from scratch every time? Or maybe you just want to learn how to deal with it upfront? We have a [video course](https://blog.arkency.com/search-rails/) that can help :)_
