---
title: "Your solid tool for event sourcing - EventStore examples"
created_at: 2015-03-12 14:01:17 +0100
kind: article
publish: true
author: Tomasz Rybczyński
tags: [ 'event', 'eventstore', 'greg' ]
newsletter: :arkency_form
img: "/assets/images/events/warehouse-fit.jpg"
---

In this part I will show you basic operations on the Event Store. 

<!-- more -->

## Creating events

```
#test.txt
{
    Test: "Hello world",
    Count: 1
}
```

```
curl -i -d @/Users/tomek/test.txt "http://127.0.0.1:2113/streams/helloworld" -H "Content-Type:application/json" -H "ES-EventType:HelloCreated" -H "ES-EventId: 8f5ff3e6-0e26-4510-96c4-7e61a270e6f6”
```

```
HTTP/1.1 201 Created
Access-Control-Allow-Methods: POST, DELETE, GET, OPTIONS
Access-Control-Allow-Headers: Content-Type, X-Requested-With, X-PINGOTHER, Authorization, ES-LongPoll, ES-ExpectedVersion, ES-EventId, ES-EventType, 
ES-RequiresMaster, ES-HardDelete, ES-ResolveLinkTo, ES-ExpectedVersion
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: Location, ES-Position
Location: http://127.0.0.1:2113/streams/helloworld/0
Content-Type: text/plain; charset=utf-8
Server: Mono-HTTPAPI/1.0
Date: Wed, 11 Mar 2015 10:51:51 GMT
Content-Length: 0
Keep-Alive: timeout=15,max=100
```

I sent simple event to a new stream called `helloworld`. You don’t have to create a new stream separately. The Event Store creates it automatically during creation of the first event. Using `application.json` Content Type you have to add the `ES-EventType` header. 
If you forget to include the header you will be given an error. It is also recommended to include the `ES-EventId`. If you leave off that header Event Store reply with a 301 redirect. Than you can post events without the `ES-EventId` to returned URI.
If you don’t want to add information about event’s id and type into header you can use `application/vnd.eventstore.events` Content Type. It allows you to specify event’s id and type in your request body. 

```
#test.txt
[{
  "eventId": "cdf601b8-874f-47d6-a1fc-624f4aa4b0a0",
  "eventType": "HelloCreated",
  "data": {
      "Test": "Hello world",
      "Count": 2
    }
}]
```

```
curl -i -d @/Users/tomek/test.txt "http://127.0.0.1:2113/streams/hello" -H „Content-Type:application/vnd.eventstore.events+json"
```

```
HTTP/1.1 201 Created
Access-Control-Allow-Methods: POST, DELETE, GET, OPTIONS
Access-Control-Allow-Headers: Content-Type, X-Requested-With, X-PINGOTHER, Authorization, ES-LongPoll, ES-ExpectedVersion, ES-EventId, 
ES-EventType, ES-RequiresMaster, ES-HardDelete, ES-ResolveLinkTo, ES-ExpectedVersion
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: Location, ES-Position
Location: http://127.0.0.1:2113/streams/helloworld/1
Content-Type: text/plain; charset=utf-8
Server: Mono-HTTPAPI/1.0
Date: Wed, 11 Mar 2015 11:56:54 GMT
Content-Length: 0
Keep-Alive: timeout=15,max=100
```

## Reading streams

To get information about your stream you have to call at http://domain:port/stream/#{stream_name}. I will do simple GET to this resource:

```
curl 'http://127.0.0.1:2113/streams/helloworld' -H 'Accept: application/json'
{
  "title": "Event stream 'helloworld'",
  "id": "http://127.0.0.1:2113/streams/helloworld",
  "updated": "2015-03-11T10:56:54.797339Z",
  "streamId": "helloworld",
  "author": {
    "name": "EventStore"
  },
  "headOfStream": true,
  "selfUrl": "http://127.0.0.1:2113/streams/helloworld",
  "eTag": "1;248368668",
  "links": [
    {
      "uri": "http://127.0.0.1:2113/streams/helloworld",
      "relation": "self"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/helloworld/head/backward/20",
      "relation": "first"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/helloworld/2/forward/20",
      "relation": "previous"
    },
    {
      "uri": "http://127.0.0.1:2113/streams/helloworld/metadata",
      "relation": "metadata"
    }
  ],
  "entries": [
    {
      "title": "1@helloworld",
      "id": "http://127.0.0.1:2113/streams/helloworld/1",
      "updated": "2015-03-11T10:56:54.797339Z",
      "author": {
        "name": "EventStore"
      },
      "summary": "HelloCreated",
      "links": [
        {
          "uri": "http://127.0.0.1:2113/streams/helloworld/1",
          "relation": "edit"
        },
        {
          "uri": "http://127.0.0.1:2113/streams/helloworld/1",
          "relation": "alternate"
        }
      ]
    },
    {
      "title": "0@helloworld",
      "id": "http://127.0.0.1:2113/streams/helloworld/0",
      "updated": "2015-03-11T09:51:51.261217Z",
      "author": {
        "name": "EventStore"
      },
      "summary": "HelloCreated",
      "links": [
        {
          "uri": "http://127.0.0.1:2113/streams/helloworld/0",
          "relation": "edit"
        },
        {
          "uri": "http://127.0.0.1:2113/streams/helloworld/0",
          "relation": "alternate"
        }
      ]
    }
  ]
} 
```

You can notice here couple interesting things. You get here all basic information about the stream like id, author, update date and unique uri. The stream is also pageable. You get links to pages. You also don’t get information about events, only links to each event. 
If you want to get event's details you have to go over each entry and follow link. In my case It will be:

```
curl 'http://127.0.0.1:2113/streams/helloworld/1' -H 'Accept: application/json'
{
  "Test": "Hello world",
  "Count": 1
}
```

## Using projections

Projections allow us to run functions over streams. It is interesting method to collect data from different streams to build data models for our app. There is Web UI to manage projection available at `127.0.0.1:2113/projections`. You can create there projection with specific name and source code. After all you can call it using unique URL. Lets check following examples.
At the beginning we have to prepare some sample events. I’ve added following events to stream:

```
[{
  "eventId": "ebc744bb-c50d-451f-b1d7-b385c49b1087",
  "eventType": "OrderCreated",
  "data": {
    Description: "Order has been created"
  }
},
{
  "eventId": "adaa388c-18c1-4be6-9670-6064bfd9f3dd",
  "eventType": "OrderUpdated",
  "data": {
    Description: "Order has been updated"
  }
},
{
  "eventId": "4674d7df-4d3e-49eb-80fc-e5494d89a1bd",
  "eventType": "OrderUpdated",
  "data": {
    Description: "Order has been updated"
  }
}]
```

I also created simple projection to count every type of event in my stream. I called it `$counter`. It is important to start name of projection from $. If you don’t do that projection won’t start.

```
fromStream("orders")
  .when({
    $init: function() {
      return { createsCount: 0, updatesCount: 0, deletesCount: 0 }
    },
    "OrderCreated": function(state, event) {
      state.createsCount += 1
    },
    "OrderUpdated": function(state, event) {
      state.updatesCount += 1
    },
    "OrderDeleted": function(state, event) {
      state.deletedCount += 1
    }
  })
```

Now you can call above projection using HTTP request:

```
curl 'http://127.0.0.1:2113/projection/$counter/state' -H 'Accept: application/json’

{„createsCount”:1,"updatesCount":2,"deletesCount":0}
```

We can do the same with multiple streams. I modified the previous projection to iterate over two separate streams and I added a listener on one more event type. 

```
fromStreams([ "orders", "olderlines" ])
  .when({
    $init: function() {
      return { createsCount: 0, updatesCount: 0, deletesCount: 0, linesCreated: 0 }
    },
    "OrderCreated": function(state, event) {
      state.createsCount += 1
    },
    "OrderUpdated": function(state, event) {
      state.updatesCount += 1
    },
    "OrderDeleted": function(state, event) {
      state.deletedCount += 1
    },
    "OrderLineCreated": function(state, event) {
      state.linesCreated += 1
    }
  })
```

I've added new event to `orderlines` stream:

```
{
  "eventId": "4674d7df-4d3e-49eb-80fc-asd78fdd76dsf",
  "eventType": "OrderLineCreated",
  "data": {
    Description: „Order line has been updated"
  }
}]
```

The result of the modification:

```
curl 'http://127.0.0.1:2113/projection/$counter/state' -H 'Accept: application/json’

{„createsCount”:1,”updatesCount”:2,”deletesCount":0,"linesCreated": 1}
```

## Conclusion

It was great experience to work with Greg's Event Store. Although using cURL isn't the best method to experience the ES. We have to create own ruby tool to work with Greg's Event Store. After all we are rubyists, right?



