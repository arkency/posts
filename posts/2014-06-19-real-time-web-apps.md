---
title: "Real-time Web Apps"
created_at: 2014-06-19 22:04:18 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :arkency_form
tags: [ 'real-time', 'websockets', 'eventsource', 'web apps' ]
---

<p>
  <figure>
    <img src="<%= src_fit("real-time-web/notifications.jpg") %>" width="100%">
  </figure>
</p>

From the very beginning web pages were just static. Internet browsers received some HTML code to render and displayed it to user. When someone wanted to check if there are any news on our page, he had to refresh it and then some new data might appeared. Time to change it.

<!-- more -->

Nowadays, more and more often we'd like to have a **real-time experience** in our web applications. We are lazy and we want to be **notified** about changes without continuously clicking on refresh button in our browsers. Unfortunately HTTP protocol is based on request-response paradigm, so rather than being notified by a sever or listening on an open connection, we make some GETs or POSTs and receive data as an answer.

So far, to simulate this real-time behavior, we had to do some work-arounds such as a [interval-timeout JS pattern](http://stackoverflow.com/questions/3138756/jquery-repeat-function-every-60-seconds) or more sophisticated, but confusing [long pooling design concept](http://stackoverflow.com/questions/15724055/long-polling-really).
Luckily, things have changed. In the age of modern browsers, HTML5 API, smarter users and skilled developers we have (and _should_ use) great tools to build real real-time web applications.

## Let's start from WebSockets.
WebSockets establish **persistent connection** between user's browser and a server. Both of them can use it any time to **send messages** to each other. Every side of such connection listens on it to immediately receive incoming data. These messages can be primitives or even binary data. WebSockets allow to **cross-domain communication** so developers should pay attention on security issues on their own, because we aren't bound to same-origin policy anymore and can communicate across domains.

There's no special WebSocket opening method. After created, browser immediately tries to open a new connection. One of WebSocket property is `readyState` which is initialized with `WebSocket.CONNECTING`. Once connected, state changes to `WebSocket.OPEN`.

Client side:

```
#!coffeescript

ws = new WebSocket 'ws://arkency.com/notifications'
ws.onopen = -> ws.send 'connected!' # listen on state transition from WebSocket.CONNECTING to WebSocket.OPEN
ws.onmessage = (message) -> console.log message.data
```

Server side:

```
#!coffeescript

WebSocketServer = require('ws').Server
wss = new WebSocketServer(port: 8080)
wss.on 'connection', (ws) ->
  ws.on 'message', (message) ->
    console.log "received: #{message}"

  ws.send 'Connected!'

```

<p>
  <figure>
    <img src="/assets/images/real-time-web/web-sockets.png" width="100%">
    <details>
      Source: <a href="http://dsheiko.com/weblog/websockets-vs-sse-vs-long-polling/">dsheiko.com</a>
    </details>
  </figure>
</p>

### Note about websockets
Because establishing a `WebSocket` connection might be a little bit tricky, it is worth to describe here some more details about that.

A client connects with a server using so called _handshake_ process. The initial request should look like this:

```
Request URL:ws://echo.websocket.org/?encoding=text
Request Method:GET
Request Headers
	Connection:Upgrade
	Sec-WebSocket-Extensions:permessage-deflate; client_max_window_bits, x-webkit-deflate-frame
	Sec-WebSocket-Key:PmqLMA8neyQndMnwL4ptCg==
	Sec-WebSocket-Version:13
	Upgrade:websocket
```

And a server's response:

```
Response Headers
	Access-Control-Allow-Headers:x-websocket-protocol
	Access-Control-Allow-Headers:x-websocket-version
	Access-Control-Allow-Headers:x-websocket-extensions
	Connection:Upgrade
	Sec-WebSocket-Accept:s9nX9CIyg7mR+ZgzLBvFzYdIL+g=
	Upgrade:WebSocket
```

We can see here that client sends `Sec-WebSocket-Key` header with some `base64` value. Next, server append to it [`258EAFA5-E914-47DA-95CA-C5AB0DC85B11`](http://tools.ietf.org/html/rfc6455) string and return `base64` of `SHA-1` from this concatenation as a `Sec-WebSocket-Accept` header.
This handshake is supposed to replace initial `HTTP` protocol with WebSocket using the same `TCP/IP` connection under the hood. Provisioning process allows to get known both sides and be recognized in future messages. [Here is some nice demo.](http://codepen.io/squixy/full/jIECq/)

### A word about Event Machine

If you are reading us, there is a high chance that you are a Ruby developer. So naturally you might be tempted to use
ruby solution for you server side code such as `EventMachine` like that:

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

That might be great learning exercise to get
more familiar with **async** code and feel more confident. However we would advise against using EM on production (_speaking
from experience because we once did_).

Long story short. EM is quite OK, but the ecosystem around is unfortunately pretty small. And sometimes buggy in hard to
reproduce or notice way. There are a bunch of Ruby libraries that can help integrate your software with many
3rd party solutions and speed up the development process. However you can't use most of them in your EM-based
application because their behavior is blocking and it would block your event loop (and take away all the benefits from
using EM and its non-blocking approach). If you wanted to integrate such a blocking library into your EM application anyway
you would have to schedule calling the library by using [`EventMachine.defer`](http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine.defer).
That would lead to mixing non-blocking event based approach represented by EM and blocking behavior from your library.
The mental overhead of it is not small.

At first sight it might seem that EM-compatible libraries are existing and working. There are certainly some
`HTTP` libraries and database drivers. But once you start looking for those that will work properly
with more advanced options such as replication you might find your options limited. It's a shaky ground.

Another problem is that you won't probably find much commercial options available for deployment of EM-based
applications. So you will have to figure out the problem of deployment, rolling deploys, clean exit yourself.
 
So if you need non-blocking, server side solution for your application our recommendation would be to rather go with
[node.js](http://nodejs.org/) which is much more popular and battle tested solution compared to EM. We really enjoyed using EM and a few 
gem which were nicely designed and tested. But the more you move away from _get N-bytes from here and send them out there_
usecase and more towards application logic, flow and business processes, the more painful experience it becomes to keep
using EM.

TLDR: EM for fun? Yes. EM in production? You better consider twice your options.

## Now move on to Server-Sent Events.

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
    begin
      sse = SSE.new(response.stream, retry: 300, event: "event-name")
      loop do
        sse.write({ base: SecureRandom.urlsafe_base64 })
        sleep 5.second
      end
    rescue IOError # Raised when browser interrupts the connection
    ensure
      sse.close
    end
  end
end
```

<p>
  <figure>
    <img src="/assets/images/real-time-web/event-source.png" width="100%">
    <details>
      Source: <a href="http://dsheiko.com/weblog/websockets-vs-sse-vs-long-polling/">dsheiko.com</a>
    </details>
  </figure>
</p>

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