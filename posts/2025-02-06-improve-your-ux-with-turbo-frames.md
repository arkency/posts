---
created_at: 2025-02-06 18:52:04 +0100
author: Maciek Korsan
tags: [hotwire, turbo, rails, frontend]
publish: false
---

# Improve your user experience with Turbo Frames

I’ve spent a good chunk of my career optimizing performance in web apps — mostly from the frontend perspective. Recently, I stumbled upon a simple trick with Turbo Frames that can improve the user experience when a particular part of the page is painfully slow to load. 

## The Slow Page Dilemma

Imagine you have a view that shows a giant, complex list of data. Maybe it involves heavy database queries, advanced filtering, or complicated logic that can take a couple of seconds to finish. Traditionally, the user is stuck watching a blank page until everything completes.

That’s obviously subpar for UX. The user might think the page is broken or slow, and they might leave before the content even shows up.

<img src="<%= src_fit("improve-ux-turbo-frames/improve-ux-frame-1.avif") %>" width="100%">

## Splitting Out the Slow Section

One way to tackle this is to give the slow list its own route. Your main view then serves everything else right away — like a quick summary or basic info — while the heavy query is executed in a separate request.

You drop a `<turbo-frame>` in your main view, pointing its `src` to the new endpoint that returns just the slow data. Turbo automatically fetches that data and replaces the frame’s content once it’s ready. Meanwhile, the user can already see and interact with the rest of the page.

```html
<h1>My super page</h1>
<turbo-frame id="slow-section" src="<%%= slow_data_path %>">
  <!-- This can be empty or show a spinner / loading text -->
</turbo-frame>
```

<img src="<%= src_fit("improve-ux-turbo-frames/improve-ux-frame-2.avif") %>" width="100%">

## Preventing Frame Navigation

If you place links inside that frame, you might run into a second surprise: clicking a link will keep you “trapped” in the frame, rendering all subsequent pages inside it. That’s obviously not always what you want.

The fix is straightforward: add `data-turbo-frame="_top"` to any link that you want to break out of the frame and load as a full page.

```html
<%%= link_to "Go Full Page", some_full_page_path, data: { turbo_frame: "_top" } %>
```

Or you can use the `target="_top"` on the frame itself to make all links open in the top frame.

That way, your users aren’t stuck inside a sub-view forever.

## Conclusion

This approach is nothing fancy or revolutionary — it’s more like a practical shortcut that lets you tackle performance bottlenecks on any given page. By moving the slow part behind a `<turbo-frame>` with its own endpoint, you keep the rest of the page fast and interactive. Your users (and your patience) will thank you.