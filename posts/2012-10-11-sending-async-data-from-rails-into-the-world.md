---
title: "Sending async data from Rails into the world"
created_at: 2012-10-11 10:56:22 +0200
kind: article
publish: true
author: "Robert Pankowecki"
newsletter: :arkency
tags: [ 'foo', 'bar', 'baz' ]
---

## The problem

Exceptions and business metrics. These are two common usecases involving
delivery of data from our Rails application (or any other web application)
to external services that are
not so crucial and probably we would like to send them asynchronously instead
of waiting for the response, blocking the thread. We will try to balance
speed and certainty here, which is always a hard thing to achieve.

This is a series of posts which describe what techniques can be used in such
situation. The first solution that I would like to desribe (or discredit) is
ZMQ.

<!-- more -->

## ZMQ - the holy grail of messaging

What is ZMQ ? According to the
[lenghty and funny ZMQ guide](http://zguide.zeromq.org/page:all):

_ØMQ (ZeroMQ, 0MQ, zmq) looks like an embeddable networking library but acts
like a concurrency framework. It gives you sockets that carry atomic messages
across various transports like in-process, inter-process, TCP, and multicast.
You can connect sockets N-to-N with patterns like fanout, pub-sub, task
distribution, and request-reply. It's fast enough to be the fabric for
clustered products. Its asynchronous I/O model gives you scalable multicore
applications, built as asynchronous message-processing tasks. It has a score
of language APIs and runs on most operating systems. ØMQ is from iMatix
and is LGPLv3 open source._

You can also watch an introduction to ZMQ delivered by one of the creators of
this library: [Matrin Sustrik: ØMQ - A way towards fully distributed architectures](http://www.youtube.com/watch?v=RcfT3b79UYM)

It seems like a perfect candidate at first sight, so let's dive into this topic a little bit.

### How would that work ?

I belive that we could use diagram here.

<a href="/assets/images/async-zmq/Async-ZMQ.png" rel="lightbox"><img src="/assets/images/async-zmq/Async-ZMQ-fit.png" class="fit" /></a>

Every rails thread (I assume multithreading app here, but it does not matter
a lot) would have a ZMQ socket for sending exceptions and business metrics. Sending
a message with such socket means only that it was delivered to ZMQ thread
which will try to deliver it further.

### The good parts

* Async. The Rails app can use async interface to ZMQ and never block for sending message.
However it means that some messages might be droppend in case of special condition like
lack of connection or overflow. It might also use sync interface and block when there
is a problem but this is not what we are trying to achieve now. We want exactly
the contrary :)
* ZMQ is capable of dropping messages when one of the side is not performing well enoughm
* ZMQ can be configured to try to deliver unsent messages in X seconds when
process is being closed. That could be useful but it would require your webserver to
expose hook for such event, so that you can tell ZMQ to shut down when
webserver is shutting down. I am not sure if every popular webserver used in Ruby community
exposes such API.
* Capable of using exponential backoff strategy for reconnectes (although by default
uses static intervals).

### Problem ?

* ZMQ probably works best when compiled from source. We had problems with the
version provided in debian packages. People generally do not like doing that
and for some reason are scared of it.
* Although ZMQ is getting more and more popular, people are still not
familiar with it. And we tend to avoid what we don't know. But I encourage
you to get out of your comfort zone and meet ZMQ.
* ZMQ will not retry sending undelivered messages.
* ZMQ was not designed to be exposed to wild world. It would probably require
the external service to provide a separate endpoint (meaning at least different
port for tcp connection) for every client.
* [Asymetric encryption is not straightforward](http://www.riskcompletefailure.com/2012/09/tls-and-zeromq.html)

### Summary

* Seems like a really good fit for non-critical data that might rarely get dropped.
* Fantastic for internal usage, terrible for external.
* Not for newbies.
* Lack of simple encrypted transport for ZMQ.

### So ...

If you are building a solution and would like your customers to
send you some data from their applications, ZMQ is probably not the way to go.
