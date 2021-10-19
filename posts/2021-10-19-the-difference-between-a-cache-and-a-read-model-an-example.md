---
title: The difference between a cache and a read model, an example
created_at: 2021-10-19T10:25:04.939Z
author: Tomasz Wróbel
tags: []
publish: false
---

Let's say you have a fairly complicated view: a calendar-like table with apartments to rent as rows and availability dates as columns.

<!-- TODO: image -->

Of course you want to be able to

* filter by availability, by location
* sort
* paginate the list of properties
* paginate the dates (look at a different date range)

The server gives you a JSON which is then consumed by a client like a SPA frontend.

You need to join data from a couple different tables:

* `apartments`
* `addresses`
* `bookings`
* a sequence of dates

At the beginning you just query your tables, do some joins. Later you optimize the queries and perhaps write some of them by hand.

Developers keep extending this view over the years by adding more and more data.

Clients grow their datasets and soon they start complaing about the page being too slow.

You start to think about...

## Caching

In this case you want to cache the JSON responses.

* You need to cache a response for every combination of filters/pages/sorting
* You will probably cache on first request, so some of the requests can still be slow, no predictable performance 
* Warming up a cache can be cumbersome and feels dirty
* Now comes the second hardest problem of computer science: _cache expiration_ (the first one being _naming things_)

Is a cache the only option?

Let's look at...

## Read models

In this solution you'd do something different.

* Build a new DB table which is totally optimized for the queries that the client wants to do.
* Let's have a single table (as opposed to multiple cached variants per page/sorting/filters). This table should contain all the data for further pagination/sorting/filtering.
* Have all the fields as client-ready as possible. If you need to show the address, instead of joining with `addresses` table, put this data into the read model table, so that now the 
* Need to filter or sort - have a plain field dedicated for it


Now how you're going to maintain current data in this table?
Update the 



