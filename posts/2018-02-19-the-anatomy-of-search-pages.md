---
title: "The anatomy of search pages"
created_at: 2018-02-19 16:16:01 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

FIXME: Place post lead here.

<!-- more -->

The anatomy of search pages

What kind of components do we need to use to make a great search page?

## Text Search

<%= img_original("ruby-rails-anatomy-search-page-algolia/text_search_box_component.png") %>

## Search results

<%= img_original("ruby-rails-anatomy-search-page-algolia/search_results_compoent.png") %>

<%= img_original("ruby-rails-anatomy-search-page-algolia/search_results_algolia_ikea_ruby_rails_react.png") %>

https://www.dropbox.com/s/bhtj1imn6qjj8z3/Screenshot%202018-01-07%2012.36.13.png?dl=0

Filters

https://www.dropbox.com/s/wxa5cyfzn5drv68/Screenshot%202018-01-07%2012.20.21.png?dl=0

https://www.dropbox.com/s/arggs2p8xwv1vec/Screenshot%202018-01-07%2012.21.29.png?dl=0

https://www.dropbox.com/s/wzo9j7zbd9zg496/Screenshot%202018-01-07%2012.22.04.png?dl=0

https://www.dropbox.com/s/n80nogsjwsr996h/Screenshot%202018-01-07%2012.29.17.png?dl=0

https://www.dropbox.com/s/jr6ycd0wih2i5wa/Screenshot%202018-01-07%2012.29.43.png?dl=0

https://www.dropbox.com/s/tjbzexep8ruohio/Screenshot%202018-01-07%2012.30.15.png?dl=0

https://www.dropbox.com/s/m06qtmctu2jzoub/Screenshot%202018-01-07%2012.33.44.png?dl=0

Custom components

https://www.dropbox.com/s/4nj2yjcorzvgsb4/Screenshot%202018-01-07%2012.27.10.png?dl=0

https://www.dropbox.com/s/q4p42gloixpi8ir/Screenshot%202018-01-07%2012.27.45.png?dl=0

https://www.dropbox.com/s/taqpeknqsjra5o6/Screenshot%202018-01-07%2012.38.00.png?dl=0

https://www.dropbox.com/s/q2lldzj2t4ujirq/Screenshot%202018-01-07%2012.55.38.png?dl=0

Sorting components

https://www.dropbox.com/s/nl0m5dis72o2kri/Screenshot%202018-01-07%2012.31.12.png?dl=0

https://www.dropbox.com/s/0ma57c0fofggh8t/Screenshot%202018-01-07%2012.32.05.png?dl=0

https://www.dropbox.com/s/nwe1c6put4p4lkc/Screenshot%202018-01-07%2012.33.01.png?dl=0

Pagination and results summary

https://www.dropbox.com/s/xsap9c00t9mvikt/Screenshot%202018-01-07%2012.23.08.png?dl=0

https://www.dropbox.com/s/54670bbr2rq378x/Screenshot%202018-01-07%2012.23.30.png?dl=0

I gathered some examples of the most typical components. How long do you think it would take your team to implement all of them. At the beginning, the task does not seem to be quite daunting. But the complexity comes from the fact that many of those components influence the search query, search results, and other components. As an example when a user keeps writing the search query, the list of categories (and their counters) is refreshed to reflect only those categories which contain search results limited to the query.

https://www.dropbox.com/s/lpqq0ktbdonz2l2/Screenshot%202018-01-07%2013.06.59.png?dl=0

When you search for “pillow”, the categories which don't contain pillows are not displayed anymore.

And that's where the complexity of implementing search pages comes from and often increases with every added component. It's not that there are many of them, it's not that you need to implement the backend to support that kind of filters. It's that you need to handle all the interactions between the components in any order and handle the state of every one of them.

But... Do you know what technology appeared some time ago to make handling frontend interactions and forms easier? React.js and...

to be continued...


