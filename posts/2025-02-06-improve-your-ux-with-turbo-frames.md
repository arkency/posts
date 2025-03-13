---
created_at: 2025-02-06 18:52:04 +0100
author: Maciej Korsan
tags: [hotwire, turbo, rails, frontend]
publish: true
---

# Improve your user experience with Turbo Frames

I’ve spent a good chunk of my career optimizing performance in web apps — mostly from the frontend perspective. Recently, I stumbled upon a simple trick with Turbo Frames that can improve the user experience when a particular part of the page is painfully slow to load. 

## When Slow Pages Hurt UX

Imagine you have a view that shows a giant, complex list of data. Maybe it involves heavy database queries, advanced filtering, or complicated logic that can take a couple of seconds to finish. Traditionally, the user is stuck watching a blank or previous page until everything completes.

That’s obviously subpar for UX. The user might think the page is broken or slow, and they might leave before the content even shows up.

<img src="<%= src_fit("improve-ux-turbo-frames/improve-ux-frame-2.avif") %>" width="100%">

## Splitting Out the Slow Section

One way to tackle this is to give the slow list its own route. Your main view then serves everything else right away — like a quick summary or basic info — while the heavy query is executed in a separate request.

You drop a `<turbo-frame>` in your main view, pointing its `src` to the new endpoint that returns just the slow data. Turbo automatically fetches that data and replaces the frame’s content once it’s ready. Meanwhile, the user can already see and interact with the rest of the page.

```html
<h1>My super page</h1>
<turbo-frame id="slow-section" src="<%%= slow_data_path %>">
  <!-- This can be empty or show a spinner / loading text -->
</turbo-frame>
```

<img src="<%= src_fit("improve-ux-turbo-frames/improve-ux-frame-1.avif") %>" width="100%">

## Preventing In-Frame Navigation

If you place links inside that frame, you might run into a second surprise: clicking a link will keep you “trapped” in the frame, rendering all subsequent pages inside it. That’s obviously not always what you want.

The fix is straightforward: add `data-turbo-frame="_top"` to any link that you want to break out of the frame and load as a full page.

```html
<%%= link_to "Go Full Page", some_full_page_path, data: { turbo_frame: "_top" } %>
```

Or you can use the `target="_top"` on the frame itself to make all links open in the top frame.

That way, your users aren’t stuck inside a sub-view forever.

## Final Thoughts

This approach may not be groundbreaking, but it’s a handy shortcut for dealing with performance bottlenecks on any page. It won't make your slow query faster - you still should think about optimizing it. By isolating the slow portion behind a `<turbo-frame>` that points to a separate endpoint, you keep the rest of the page quick and responsive. The overall perception of speed increases — and your users will appreciate the difference.