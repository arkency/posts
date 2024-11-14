---
created_at: 2024-11-13 20:22:19 +0100
author: Tomasz Stolarczyk
tags: [ 'hotwire', 'turbo', 'turbo streams', 'turbo frames', 'rails' ]
publish: false
---

# The difference between Turbo Streams and Turbo Frames

The first point of the Rails Doctrine is "Optimize for programmer happiness", and I personally
consider this one as the one that is responsible for the huge popularity and success of RoR. I would even go one better
and say that it's optimized for non-programmer happiness, too, as we know stories of "non-technical" people starting
their online businesses with Rails. A considerable part of that is possible due to Rails' convention over configuration,
and we may have different views on this one, but that's the way the cookie crumbles.

"Optimize for programmer happiness" is finally described as: "Optimizing for happiness is perhaps the most formative
key to Ruby on Rails. It shall remain such going forward." And this is so true, as you can spot the idea even now with
Hotwire. You can start with Turbo Drive, which will not require changes and will give you out-of-the-box `<body>`
replacement without page reload. Getting things for free will for sure impact your happiness. But then you also get
tools that will be like sharp knives, and I mean turbo frames and turbo streams. I really like the below chart from
[one of 37signals' articles](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/):

<img src="<%= src_original("the-difference-between-turbo-streams-and-turbo-frames/responsiveness-to-happiness.jpg") %>" width="100%">

_Source: https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/_

But I think this chart is somehow "broken" for me, as even though the chart says I should be less happy using frames
and streams than just body replacement, I'm still quite excited when working with them. I actually prefer them, as
thanks to them, I can make exact changes on pages, which at the same time implies smaller calculations on the backend
and smaller response sizes. Nevertheless, they differ, and here I would like to show you the main differences so you
can use them mindfully, depending on the specific case.

## Turbo Frames

Let's start with Turbo Frames. They help you split your page into parts. The most important thing here is that you can
only replace a single frame, and by default, it's a frame from which you make an HTTP request. So when your button is
in the Turbo Frame called `projects` after submitting, if the server responds with more than one frame, only the
`projects` frame will be updated. When you look into the Turbo-Frame request header, you will see the name of the frame
that would be replaced:

<img src="<%= src_original("the-difference-between-turbo-streams-and-turbo-frames/turb-frame-header.png") %>" width="100%">

It is also possible that a button outside of the specific frame can trigger an update of the frame's content, but then
you have to explicitly point to that frame:

```html
<%= button_to "Delete", @projects.first, method: :delete, data: {turbo_frame: "projects"} %>
```

Above, in general, means that when working with frames, you always only "replace" the existing frame with new content.

## Turbo Streams

Now, the most confusing part is Turbo Streams. First, you don't need WebSockets to work with them. Turbo Streams work
with regular requests, WebSockets, and SSE (Server Sent Events). Second of all, we can think about turbo streaming as
broadcasting the data over the WebSocket, but it is also a format used in `Accept` and `Content-Type` headers
(`text/vnd.turbo-stream.html` MIME type), so you can rely on it when serving the content on the server side:

```ruby
respond_to do |format| 
  format.html { redirect_to projects_url }
  format.turbo_stream do
    render turbo_stream: turbo_stream.remove(dom_id_for(@project))
  end
end
```

Unlike Trubo Frames, the Turbo Stream type of response allows you to manipulate multiple DOM elements in a single
response. Besides that, you are allowed to do more than just replace, as you can, for example, `append`, `prepend`,
`update`, or `remove`:

```ruby
format.turbo_stream do
  render turbo_stream: [
    turbo_stream.prepend('ongoing_projects', partial: 'projects/kanban/ongoing_project'),
    turbo_stream.remove(dom_id_for(@project))
  ]
end
```

## Turbo Frames vs. Turbo Streams

Now, to sum the most important things up:

* Turbo Frames:
  * You can only replace a single frame, so responding with multiple frames will have no effect.
  * By default, it replaces a frame from which you are making an HTTP request, and if you are targeting the frame outside of the frame, it has to be pointed.
  * By its nature, it supports only the replacement operation.
* Turbo Streams:
  * You don't need WebSockets to work with them, but using WebSockets allows you to broadcast real-time updates to all interested parties.
  * Have `text/vnd.turbo-stream.html` MIME-type.
  * Unlike Turbo Frames, it allows the manipulation of multiple unrelated page elements in a single response.
  * It supports more than just replacing, i.e., appending, prepending, removing, etc.

And just to compare them side by side:

| Feature           | Turbo Frames   | Turbo Streams                                                    |
|-------------------|----------------|------------------------------------------------------------------|
| Scope of updates  | Single element | Multiple elements                                                |
| Update types      | replace only   | append, prepend, replace, update, remove, before, after, refresh |
| Real-time updates | No             | Yes, possible via WebSockets, but that's just a bonus.           |

This will help you next time you have concerns about which of those should be used in specific cases. If you have any 
questions, don't hesitate to contact [us](mailto:dev@arkency.com).

See you!

PS. If you find a Hotwire topic interesting, you may want to check few other resources that we prepared:

* [YT] [Hotwire, Turbo Drive, Frames and Streaming. Long Live Server Side Rendering with SPA experience](https://www.youtube.com/watch?v=C8I8l5nlWIk)
* [YT] [Turbo Streaming AKA Broadcasting over Web Socket explained. DON'T DO THAT MISTAKE!!!](https://www.youtube.com/watch?v=4iCuPB3dhsM)
* [YT] [How to implement infinite scroll pagination for a table using Rails Hotwire Turbo](https://www.youtube.com/watch?v=khnKX5lqSdE)
* [YT] [Make your tables alive with turbo streams. Redirect vs Turbo Streaming. Which one to choose?](https://www.youtube.com/watch?v=hc1C0r4a1J4)
* [Blog] [How to use Hotwire Turbo Streams effectively?](https://blog.arkency.com/how-to-use-hotwire-turbo-streams-effectively/)
* [Blog] [How to add a loading animation to your turbo frame with TailwindCSS](https://blog.arkency.com/how-to-add-a-loading-animation-to-your-turbo-frame-with-tailwindcss/)
* [Blog] [Take advantage of Turbo Streams in event handlers](https://blog.arkency.com/take-advantage-of-turbo-streams-in-event-handlers/)
* [Blog] [Be careful with turbo and view components](https://blog.arkency.com/be-careful-with-turbo-and-view-components/)
