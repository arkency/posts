---
created_at: 2018-02-14 06:00:00 +0200
publish: true
author: Robert Pankowecki
tags: [ 'search', 'algolia', 'rails', 'react' ]
newsletter: arkency_form
---

# Building custom search is hard and boring

Have you ever had to implement a search page for your client? I did and I've gotta say it's often one of the most boring tasks. Not always, but often. There is a big list of features that the client usually expects other similar pages have. Especially when it comes to e-commerce websites. It needs to be fast, it needs to allow filtering, grouping and limiting by various attributes. On the backend side that usually means building sophisticated SQL queries, which is never a fun task when the search is highly dynamic and based on a variety of options available in the UI. Alternatively, you can use ElasticSearch or Lucene/Solr, but I've realized that while they are often super fast there is a lot of quirks that you need to learn when you would like them to just work.

<!-- more -->

So, on one hand, there is all this complexity and challenge which you might like as a developer. On the other hand, there is rarely anything novel about the task of building a search page and you might feel demotivated about doing it. Not to mention the deadlines. How can you build something sophisticated and have so many features (that are usually wanted and needed) in a week or two?

Let's try to list a few usual requirements:

* full-text search (often with the ability to handle some typos) that recognizes priority of the attributes in which a text is found
* various sort orders (date, price, popularity etc)
* filtering by brands or categories
* highlighting or displaying snippets of found text matches
* pagination or infinite scroll
* limiting by dates or price ranges or ratings
* responsiveness (refreshing results in milliseconds after changing options or providing new text query)

Now, separately these features are usually not that hard, but the challenge comes from the fact that our customers usually want all of that combined and working together. For every such feature/requirement, you need to implement it on the backend, implement a frontend component and connect them together. That's a lot of work. And this is just a start. After these basic requirements, there come new ones, those specific to the domain and application that you work on which require more custom logic and display. That's what interesting. That's what you would like to focus on. Here often lies the competitive advantage.

For quite some time I also struggled with this conundrum on how to build great search pages quickly and painlessly for our customers.

[to be continued...](/the-anatomy-of-search-pages/)

_Are you also feeling the pain of building search pages from scratch every time? Or maybe you just want to learn how to deal with it upfront? We have a [video course](https://blog.arkency.com/search-rails/) that can help :)_
