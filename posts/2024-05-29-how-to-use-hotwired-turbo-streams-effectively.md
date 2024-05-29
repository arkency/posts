---
created_at: 2024-05-29 07:33:30 +0200
author: Łukasz Reszke
tags: [ 'hotwired', 'turbo', 'turbo streams' ]
publish: false
---

# How to use hotwired turbo streams effectively?

Have you ever wondered which approach you should follow?
Should it always be redirect? Or maybe you should always use Turbo Streams?

## Let's take a look at the redirect approach first.

For the developers it is simple, testable and last but not least, productive.
Those are solid pros that make it very tempting to use. And I don't think it is bad idea to use it in some cases.
Also, what I really like is that small detail that my coworker Tomek noticed. If you stopped at Server Side Rendering
and you didn't join the SPA hype, all you need to do now is upgrade your Rails application and you'd get nice UX
improvements without any (or much) additional effort.

## The problem

The problem starts when the `kanban` endpoint slows down. Why would it slow down?

Well.. why wouldn't it? ;) 

It might not be true for all pages
in our applications, but the functionality usually stacks and grows. The feature is added here and there. It turns out,
that for this one specific page, it is important to contain it. Live goes on and we wake up with the page that loads
tons of data and takes a lot of time to render.

Then, when after successful operation that is supposed to be quick and short, the redirect happens,
the server has to execute all the queries and get all the data that would be required for
rendering the whole page. The user experience becomes bad. And it could be better!

What is desired for the user's perspective is to simply
move the row from one table to another and change the status.

Once you find yourself in that situation, it is a perfect moment to use Turbo Streams instead.

## What are the other aspects between two that are worth noticing?

Besides the performance there are also other aspects worth noticing.

### Amount of the data sent over the wire 

With the redirect approach, the whole page is sent over the wire. It is not a big deal for some pages, but as I mentioned
in the beginning, the pages have a tendency to grow in functionality, data, complexity, etc. Once you notice that you're
sending too much data over the write, it is a good moment to take a look and consider using Turbo Streams.

### Maintaining the scroll position (if you don't use morph)

If you haven't upgraded to the latest version of the Turbo, you don't have access to the Morph feature.
Therefore, whenever you perform operation similar to what happened in our little gif, the page would scroll to the top.
It might not be visible for your users, but if it is, it could be solved by using Turbo Streams.

### Explicitness and control

Some of us just like to control what exactly will be the servers response. Then, the Turbo Streams approach is the way.

## Conclusion

Personally, I prefer the Turbo Streams approach for the apps that I work with. But it mostly has to do with the
fact that those are legacy applications. For the green field, I would consider the redirect approach. Here, I wrote that 😉.

I also like how the developer happiness is mentioned when it comes to the redirect approach, and generally, the direction of 
Turbo and Rails. To me, the biggest boost of developer happiness is that I don't have to use JavaScript to make my app
interactive 😂. I mean, besides some Stimulus here and there. It's a great win!
