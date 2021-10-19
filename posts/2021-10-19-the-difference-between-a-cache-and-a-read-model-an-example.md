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

You want to cache the JSON responses.



