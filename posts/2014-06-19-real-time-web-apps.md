---
title: "Real-time Web Apps"
created_at: 2014-06-19 22:04:18 +0200
kind: article
publish: true
author: Kamil Lelonek
tags: [ 'real-time', 'websockets', 'eventsource', 'web apps' ]
---

<p>
  <figure>
    <img src="/assets/images/real-time-web/notifications.jpg" width="100%">
  </figure>
</p>

From the very beginning web pages were just static. Internet browsers received some HTML code to render and displayed it to user. When someone wanted to check if there are any news on our page, he had to refresh it and then some new data might appeared. Time to change it.

<!-- more -->

Nowadays, more and more often we'd like to have a **real-time experience** in our web applications. We are lazy and we want to be **notified** about changes without continuously clicking on refresh button in our browsers. Unfortunately HTTP protocol is based on request-response paradigm, so rather than being notified by a sever or listening on an open connection, we make some GETs or POSTs and receive data as an answer.

So far, to simulate this real-time behavior, we had to do some work-arounds such as a [interval-timeout JS pattern](http://stackoverflow.com/questions/3138756/jquery-repeat-function-every-60-seconds) or more sophisticated, butt confusing [long pooling design concept](http://stackoverflow.com/questions/15724055/long-polling-really).
Luckily, things have changed. In the age of modern browsers, HTML5 API, smarter users and skilled developers we have (and _should_ use) great tools to build real real-time web applications.

### Let's start from WebSockets.
WebSockets establish **persistent connection** between user's browser and a server. Both of them can use it any time to **send messages** to each other. Every side of this connection listens on it to immediately receive incoming data. These messages can be primitives or even binary data. WebSockets allow to **cross-domain communication** so developer should pay attention on security issues on his own, because he isn't bound to same-origin policy any more and can communicate across domains.

There's no special WebSocket opening method. As soon as it is created it is opened too and ready for communication.

Client side:

```
#!coffeescript

ws = new WebSocket 'ws://arkency.com/notifications'
ws.onopen = -> ws.send 'connected!'
ws.onmessage = (message) -> console.log message.data
```

Server side:

```
#!ruby

EM.run {
  EM::WebSocket.run(host: "0.0.0.0", port: 8080) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"
      ws.send "Hello Client, you connected to #{handshake.path}"
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Recieved message: #{msg}"
      ws.send "Pong: #{msg}"
    }
  end
```

![ES](/assets/images/real-time-web/web-sockets.png)

### Now move on to Server-Sent Events.
Server-Sent Events intended for **streaming text-based event data from server directly to client**. There are two requirements to use this mechanism: browser interface for **EventSource** and server `'text/event-stream'` content type. SSE are used to **push notifications** into your web application, which makes it more **interactive with user** and provides **dynamic content** at the time it appears.

Client side:

```
#!coffeescript

es = new EventSource '/notifications'
es.onopen = -> es.send 'connected!'
es.onmessage = (event) -> console.log event.data
```

Server side:

```
#!ruby

class NotificationsController < ApplicationController
  include ActionController::Live
 
  def index
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 300, event: "event-name")
    sse.write({ name: 'John'}, id: 10, event: "other-event", retry: 500)
  ensure
    sse.close
  end
end
```

![ES](/assets/images/real-time-web/event-source.png)

### Basic differences:

#### [WebSockets](http://caniuse.com/websockets)
- Supported in all major modern browsers (IE+10)
- Two-directional communication
- Siutable for chats or online gaming
- Based on custom protocol (`ws://` and encrypted `wss://`)

#### [Server-Send Events](http://caniuse.com/eventsource)
- Require [Polyfill](https://github.com/remy/polyfills/blob/master/EventSource.js) as they are still _candidate recommendation_ and have no IE support
- One-way messaging (server -> browser)
- Best for push notifications and status updates
- Leverages HTTP protocol

### Similarities:
- Both can provide real-time web application experience in area of notifications and updates
- JavaScript API
- Both are pretty new and may not be supported in every environment 

##### References:
1. https://developer.mozilla.org/en-US/docs/Server-sent_events/Using_server-sent_events
2. https://developer.mozilla.org/en-US/docs/WebSockets/Writing_WebSocket_client_applications
3. http://dev.w3.org/html5/eventsource/
4. http://dev.w3.org/html5/websockets/

##### Resources:
1. http://dsheiko.com/weblog/websockets-vs-sse-vs-long-polling/
2. http://html5doctor.com/methods-of-communication/