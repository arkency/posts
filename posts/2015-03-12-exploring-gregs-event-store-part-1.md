---
title: "Exploring Greg's Event Store. Part 1"
created_at: 2015-03-12 13:58:01 +0100
kind: article
publish: false
author: Tomasz Rybczyński
tags: [ 'event', 'eventstore', 'greg' ]
newsletter: :arkency_form
img: "/assets/images/events/store-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/events/store-fit.jpg" width="100%">
  </figure>
</p>

Event Store is a domain specific database for people who use the Event Sourcing pattern in their apps. It is a functional database which based on a publish-subscribe messages pattern. Why functional? 
It uses a functional language as its query language. In ES It is the Javascript. I will say something more about this later. The lead architect and designer of Event Store is Greg Young who provides commercial support for the database.
I decided to create this two-part tutorial to bring the idea closer to you. I will describe issues related to Event Store in the first part and I will present some simple examples of the ES usage in the second one.

<!-- more -->

## How to get it?

All you have to do is download the latest release from here and run one command. That is all. The Event Store runs as a server and you can connect to it over HTTP or using one of the client APIs.  
If It run you can access to the dashboard on http://127.0.0.1:2113 (default credentials login: admin, pass: changeit). You will find a lot of useful information there but it is material for another post ;).

<img src="/assets/images/events/eventstore-dashboard-fit.png">

## Communication with ES
 
You can connect to an Event Store over TCP or HTTP. Which one is better? Of course it depends on your needs. TCP is strongly recommended for a high-performance environment. There is also a latency increase when using HTTP. We will push events to the subscribers in TCP variant. 
Using HTTP subscribers will pool to check events availability what is less effective. Additionally the number of supported writes is higher in case of TCP. In Event Store documentation we can find following comparison:

`„At the time of writing, standard Event Store appliances can service around 2000 writes/second over HTTP compared to 15,000-20,000/second over TCP!”`

The Event Store provides a native interface of AtomPub over HTTP. The AtomPub is more scalable for many subscribers and it becomes easy to use the Event Store in heterogeneous environments. It is easier to use if we have to integrate with different teams from different platforms. It may seem like HTTP is less efficient at the outset. 
However It offer intermediary caching of Atom feeds. It will be useful for replaying streams.

## Types of Subscribers

**Live-only** - This kind of subscription allows you to get every event from the point of subscribing until the subscription is dropped. If you start subscribing from event number 200 you will get every event starting from 201 to the end of subscription. 

**Catch-up** - A catch-up subscription works in a very similar way to a live-only subscription. There is one difference. You can specify the starting point of your subscribing. For example if your stream has 200 events you can specify starting point at 50. You will get every event starting from 51 to the end of subscription.

## Projections in Event Store

Projection is very interesting feature. It allows as to query over our streams using Javascript’s functions. This is why we call the Event Store functional database. I am interested in using projections as a method of building View Models, for example collecting repartitioned data for some reports. I will show you some example of usage in next part but if you look for some more sophisticated examples you can check Rob Ashton’s series. 

