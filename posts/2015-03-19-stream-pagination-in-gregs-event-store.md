---
title: "Stream pagination in Greg's Event Store"
created_at: 2015-03-19 22:35:05 +0100
kind: article
publish: false
author: Tomasz Rybczyński
tags: [ 'event', 'eventstore', 'greg' ]
newsletter: :arkency_form
img: "/assets/images/events/pages-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/events/pages-fit.jpg" width="100%">
  </figure>
</p>

Every stream in Event Store is represented as a paged feed. This is because reading from streams based on an AtomPub protocol. A paged feed is a set of feed documents where each document contains some part of a whole data. This is very useful solution when the number of information is very large. So basically in the ES reading a stream is a process of collecting events in small portions.
You can find some information about this feature in main Event Store’s [documentation](http://docs.geteventstore.com/http-api/3.0.3/reading-streams/) but in my opinion It is described very briefly. So this is why I decided to write this blog post.

<!-- more -->

## How It works

When you get stream data you receive information about links. Each link leads to different a feed page which contains specified number of events. For the purposes of this post I created `paginationtest' stream with 43 events inside. 
(Creation of events I described in this [post](/2015/03/your-solid-tool-for-event-sourcing-eventstore-examples/)). Lets make a fast request to get some data:

```
curl 'http://127.0.0.1:2113/streams/paginationtest' -H 'Accept: application/json'

{
  "title": "Event stream 'paginationtest'",
  "id": "http://127.0.0.1:2113/streams/paginationtest",
  "updated": "2015-03-15T12:00:00.056484Z",
  "streamId": "paginationtest",
  "author": {
    "name": "EventStore"
  },
  "headOfStream": true,
  "selfUrl": "http://127.0.0.1:2113/streams/paginationtest",
  "eTag": "42;248368668",
  "links": [
    {
      "uri": "http://127.0.0.1:2113/streams/paginationtest",
      "relation": "self"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/paginationtest/head/backward/20",
      "relation": "first"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/paginationtest/0/forward/20",
      "relation": "last"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/paginationtest/22/backward/20",
      "relation": "next"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/paginationtest/43/forward/20",
      "relation": "previous"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/paginationtest/metadata",
      "relation": "metadata"
    }
  ],
  "entries": [
    {
      "title": "42@paginationtest",
      "id": "http://127.0.0.1:2113/streams/paginationtest/42",
      #OTHER ATTRIBUTES
    },
    {
      "title": "41@paginationtest",
      "id": "http://127.0.0.1:2113/streams/paginationtest/41",
      #OTHER ATTRIBUTES
    },
    (…) #OTHER EVENTS
   {
      "title": "23@paginationtest",
      "id": "http://127.0.0.1:2113/streams/paginationtest/23",
      #OTHER ATTRIBUTES
    }
]
}
```

Ok what we have here? I called here the stream’s **head**. Head page contains the latest stream's events. As you can see events (aka entries) are sorted **descending**. It is very important information that entries are always sorted desc on an every page. 
There are twenty entries on each page by default. You can modify the number of events per page changing specified link. We do have also the above-mentioned links. I will try to describe them al little bit:

1. `self` and `first` - both links point the head of stream. The difference between them is that in the second version you are able to define the number of entries per page.
2. `last` -  direct to a last page where we have oldest entries
3. `next` - leads to a next page with older events
4. `previous` - leads to a next page with newer events
5. `metadata` - this url allows us to read the metadata associated to stream

I think about feed paging as a pagination on a website. It is more intuitive for me and It allows to understand the whole concept easier. 
In the case of my example iterating **backward** it will looks following:

<img src="/assets/images/events/backward-fit.png"  width="100%">

The situation where we walk **forward** over whole stream:

<img src="/assets/images/events/forward-fit.png"  width="100%">

## Summary

Important things to remember:

1. Events are always sorted descending on a page.
2. You can specify the number of events on a page modifying appropriate url. There is twenty events per page by default.
3. Event is always added to the beginning (head) of the stream.


