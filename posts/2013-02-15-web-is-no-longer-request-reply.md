---
title: "Web is no longer request-reply"
created_at: 2013-02-15 10:30:12 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: react_books
tags: [ 'rails', 'web', 'servers', 'patterns' ]
---

In the old times everything was simple. You received a request, did some computation (or not in case of static page)
and sent a reply. However what we do now is no longer that easy.

<!-- more -->


<a href="/assets/images/req-repl/old.png" rel="lightbox"><img src="<%= src_fit("req-repl/old.png") %>" class="fit" /></a>

## Social web

With the rise of rich, usually social applications almost every action triggers immediate chain of notifications.
You click a "Like" button and all of your friends should know this fact. Same way with Twitter, Gmail, Hackpad, Trello
and soon probably almost every app.

<a href="/assets/images/req-repl/new.png" rel="lightbox"><img src="<%= src_fit("req-repl/new.png") %>" class="fit" /></a>

## But don't we still live in the old times ?

For years our tools was built and improved around request-reply pattern. Proxies, load balancers, benchmarks.
Tons of software which basically _think_ in this model. But it was not always like that. Earlier we used to embrace
the connection. Yep, you heard me right. Because under this powerful pattern that we took to the edge there is still
plain, old TCP connection. A stream of bytes. Not messages but merely bytes.

## The future (or perhaps the current state)

But web no longer is HTTP. Nor request-reply. We have now Websockets, SSE, and SPDY. The web is now realtime.
Streaming data both ways. Servers usually stream music and video and clients usually stream their location
(especially if you develop modern, urban city game).

## Tools

So the question is: Do our current tools help us to develop applications with such requirements ? What I dream about are
frameworks and libraries which would make it simple to think about the new part of the web, about notifications.
I do not want to just respond to a request anymore. I want to do something additional. Like:

```ruby
# pseudo-rails code
class CommentsController
  def create
    comment = post.comments.create!(params[:post])
    respond_with(comment)
    notify(comment.author.friends).with(comment)
  end
end
```

And I want it to be a first-class citizen of my new framework. Not something that I hacked around.

All you need to have is a webserver and technology stack which does not limit you to processing the request but makes
it possible for you to send any data at any time to any other connection. A webserver that supports more than HTTP.
And there is an increasing number of solutions which let you do it, for example:

* [Reel](https://github.com/celluloid/reel)
* [Mongrel2](http://mongrel2.org/)

Of course, all of that can still be achieved with current technologies. A lot of existing applications prove it to be
possible. However, what I dream of is that it is not only possible, but simple. So I could have it working in
a few minutes. Rails was a revolution, I am still waiting for the next revolution.

The first step is to have it working on one server. The next step would be a distributed environment which would let
me deliver notifications to user friends even when they are connected to a different server.

On one server I would probably have to stick to evented frameworks such as EventMachine or node.js. But I have so many
bad experiences with EM that I do not even want to think about it. And none of those evented frameworks give you any
advantage when it comes to developing and maintenance of a distributed solution.

## So ...

What do you think about current state of the web and our tools? Is req-repl now becomming a burden in the development?
Which of our frameworks and tools are ready for the future of the web? Or perhaps I delude myself that all of that can be solved
with one tool. Maybe the usage of multiple tools for solving such problems is good because you can tweak them according
to their needs and the needs of HTTP connection are different than those of long running, mostly inactive Websocket or
SSE connections? I am very curious of your opinion ...
