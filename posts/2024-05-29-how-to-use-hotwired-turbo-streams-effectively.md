---
created_at: 2024-05-29 07:33:30 +0200
author: Łukasz Reszke
tags: [ 'hotwired', 'turbo', 'turbo streams' ]
publish: false
---

# How to use Hotwired Turbo Streams effectively?

Have you ever wondered which approach to take?
Should you always redirect? Or should you always use Turbo Streams?

Take a look at the following functionality. It moves tasks between tables representing states in a Kanban board.

<div class="not-prose">
<img src="https://arkency-images.s3.eu-central-1.amazonaws.com/hotwired-turbo-redirect-vs-turbo-stream/demo.gif" alt="demo of kanban example"></img>
</div>

The two approaches that can be used to implement this functionality are the Redirect approach and the Turbo Streams approach.

<%= img_fit("hotwired-turbo-redirect-vs-turbo-stream/redirect_vs_turbo_stream.jpg") %>

## Let's take a look at the redirect approach first.

For developers, it is easy, testable, and last but not least, productive.
These are solid advantages that make it very tempting to use. And I don't think it's a bad idea to use it in some cases.
Also, what I really like is this little detail that my colleague Tomek noticed. If you stop at Server Side Rendering
and didn't join the SPA hype, all you need to do now is update your Rails application and you'd get nice UX
improvements without any (or much) additional effort.

## The problem

The problem starts when the `kanban' endpoint slows down. Why would it slow down?

Well... why wouldn't it? ;)

It may not be true for all pages in
in our applications, but functionality tends to pile up and grow. The feature gets added here and there. It turns out
that for this one particular page, it is important to include it. Live goes on, and we wake up with the page loading a lot of data and taking a lot of
tons of data and takes a long time to render.

Then, when the redirect happens after a successful operation that should be quick and short,
the server has to perform all the queries and retrieve all the data that would be needed to
to render the entire page. The user experience is bad. And it could be better!

What is desired from the user's perspective is to simply
move the row from one table to another and change the state.

If you find yourself in this situation, it is a perfect moment to use Turbo Streams instead.

## What are the other aspects between two that are worth noticing?

In addition to the performance, there are other aspects that are worth noting.

### Amount of the data sent over the wire

With the redirect approach, the entire page is sent over the wire. This is not a big deal for some pages, but as I mentioned in the
mentioned in the beginning, pages have a tendency to grow in functionality, data, complexity, etc.
If you notice that you're sending too much data over the wire, it's a good time to take a look and
and consider using Turbo Streams.

### Maintaining the scroll position (if you don't use morph)

If you haven't upgraded to the latest version of Turbo, you won't have access to the Morph feature.
Therefore, whenever you perform an operation similar to what happened in our little gif, the page would scroll to the top.
This may not be visible to your users, but if it is, it could be solved by using Turbo Streams.

### Explicitness and control

Some of us just want to control exactly how the server responds. Then the Turbo Streams approach is the way to go.

## Conclusion

Personally, I prefer the Turbo Streams approach for the applications I work with. But that mostly has to do with the fact that
that these are legacy applications. For the greenfield, I would consider the redirect approach. Here is what I wrote
😉.

I also like how the developer happiness is mentioned when it comes to the redirect approach, and generally the
direction of Turbo and Rails.

For me, the biggest boost to developer happiness is that I don't have to use JavaScript to make my application
interactive 😂.

I mean, besides some Stimulus here and there. It's a great win!
