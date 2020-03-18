---
title: "Stream pagination in Greg's Event Store"
created_at: 2015-03-24 19:28:05 +0100
kind: article
publish: true
author: Tomasz Rybczyński
tags: [ 'event', 'eventstore', 'greg' ]
newsletter: arkency_form
img: "events/pages.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("events/pages.jpg") %>" width="100%">
  </figure>
</p>

Every stream in Event Store is represented as a paged feed. This is because reading from streams based on an AtomPub protocol. A paged feed is a set of feed documents where each document contains some part of a whole data. This is very useful solution when the number of information is very large. So basically in the ES reading a stream is a process of collecting events in small portions.
You can find some information about this feature in main Event Store’s [documentation](http://docs.geteventstore.com/http-api/3.0.3/reading-streams/) but in my opinion It is described very briefly. So this is why I decided to write this blog post.

<!-- more -->

## How It works

When you get stream data you receive information about links. Each link leads to different a feed page which contains specified number of events. For the purposes of this post I created `paginationtest` stream with 43 events inside.
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
      "updated": "2015-03-15T12:00:00.056484Z",
      "author": {
        "name": "EventStore"
      },
      "summary": "rybex",
      "links": [
        {
          "uri": "http://127.0.0.1:2113/streams/paginationtest/42",
          "relation": "edit"
        },
        {
          "uri": "http://127.0.0.1:2113/streams/paginationtest/42",
          "relation": "alternate"
        }
      ]
    },
    {
      "title": "41@paginationtest",
      "id": "http://127.0.0.1:2113/streams/paginationtest/41",
      "updated": "2015-03-15T11:49:02.709696Z",
      "author": {
        "name": "EventStore"
      },
      "summary": "rybex",
      "links": [
        {
          "uri": "http://127.0.0.1:2113/streams/paginationtest/41",
          "relation": "edit"
        },
        {
          "uri": "http://127.0.0.1:2113/streams/paginationtest/41",
          "relation": "alternate"
        }
      ]
    },
    (…) #OTHER EVENTS
   {
     "title": "23@paginationtest",
     "id": "http://127.0.0.1:2113/streams/paginationtest/23",
     "updated": "2015-03-15T11:41:17.481024Z",
     "author": {
       "name": "EventStore"
     },
     "summary": "rybex",
     "links": [
       {
         "uri": "http://127.0.0.1:2113/streams/paginationtest/23",
         "relation": "edit"
       },
       {
         "uri": "http://127.0.0.1:2113/streams/paginationtest/23",
         "relation": "alternate"
       }
     ]
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

I think about feed paging as a pagination on a website. It is more intuitive for me and it allows to understand the whole concept easier.
If we would like to get all entries from newest we have to iterate **backward** over the stream. In the case of my example iterating will looks following:

First step:

<a href="/assets/images/events/backward_first.png" rel="lightbox[picker]">
  <img src="<%= src_fit("events/backward_first.png") %>" />
</a>

Second step:

<a href="/assets/images/events/backward_second.png" rel="lightbox[picker]">
  <img src="<%= src_fit("events/backward_second.png") %>" />
</a>

Third step:

<a href="/assets/images/events/backward_third.png" rel="lightbox[picker]">
  <img src="<%= src_fit("events/backward_third.png") %>" />
</a>

To get all events starting from the begin we have to walk **forward** over whole stream:

First step:

<a href="/assets/images/events/forward_first.png" rel="lightbox[picker]">
  <img src="<%= src_fit("events/forward_first.png") %>" />
</a>

Second step:

<a href="/assets/images/events/forward_second.png" rel="lightbox[picker]">
  <img src="<%= src_fit("events/forward_second.png") %>" />
</a>

Third step:

<a href="/assets/images/events/forward_third.png" rel="lightbox[picker]">
  <img src="<%= src_fit("events/forward_third.png") %>" />
</a>

This is only a simple example of iteration over whole stream. But using ES's streams is more flexible. You can easily modify url parameters to get more entries per page or you can start from different place in your stream.
If you modify the number of events on a page that Event Store will calculate for you links in response. This solution is very useful in case of parallel pagination. For example
if various users start paginate in different places on stream that the structure of pages is different. Despite the move through the same stream. This is very useful to easier cache user's events.

## Summary

Important things to remember:

1. Events are always sorted descending on a page.
2. You can specify the number of events on a page by modifying appropriate url. There are twenty events per page by default.
3. Event is always added to the beginning (head) of the stream.


