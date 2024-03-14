---
created_at: 2024-03-13 19:51:22 +0100
author: Maciek Korsan
tags: ['frontend', 'css', 'hotwire', 'tailwindcss', 'rails' ]
publish: false
---

# How to add a loading animation to your turbo frame with TailwindCSS

Ever been working on a project and hit a snag? That's what happened to me recently. I came across a turbo frame that was slow to load and didn't show any signs of loading. Talk about confusing!

<!-- more -->

<div>
<video src="https://arkency-images.s3.eu-central-1.amazonaws.com/how-to-add-a-loading-animation-to-your-turbo-frame-with-tailwindcss/loader-off.mp4" class="w-full not-prose" autoplay muted playsinline loop></video>
<span class="font-italic text-sm not-prose">Waiting a few eternities for the historic transactions tab to load.</span>
</div>

## The `busy` attribute of the turbo frame

The easiest way to add a loading state to the turbo frame is to insert the loader inside the frame tag. Problem is that it only works on the very first load, after that you'll see the old content until the new one fully loads.

I did some digging and found out that [turbo frames actually have states](https://turbo.hotwired.dev/reference/frames#html-attributes), which can be useful: one when they're loading `busy` and one when they're done `complete`. They're represented by an HTML attribute and can be used to create the proper CSS selector.


## The handful sibling selector

To make my animation I've wrapped the frame with an additional container:

```erb
<div class="relative min-h-96">
    <%%= turbo_frame_tag 'transactions', src: dashboard_transactions_historic_path do %>
    <%% end %>
</div>
```

I've added `relative` class to create a possibility of making overlay, and `min-h-96` - to make it at least 24rems height. As I've mentioned above,the `Loading...` part will show on the initial load. In this project we're switching between different transaction types, and each of them has its own path, so after switching to another one (which takes a while to load) we're left with the old view and no reaction from the UI. Let's change it!

To create the overlay we need another element, which will change its behaviour based on turbo frame's state. We'll place it underneath the frame:

```erb
<div class="relative min-h-96">
    <%%= turbo_frame_tag 'transactions', src: dashboard_transactions_historic_path do %>
        Loading...
    <%% end %>
    <div class="pointer-events-none absolute inset-0 z-20 flex items-center justify-center bg-gray-50 bg-opacity-25 backdrop-blur-sm transition-opacity">
      <%%= image_tag "loading.svg", class: "animate-pulse" %>
    </div>
</div>
```

Right now we have a pulsating loading image with an overlay covering the frame's content. We need to create a selector to change it's opacity, to do it we'll use the sibling `~` selector, and combine it with the tailwind's arbitrary variant: `[[busy]~&]:`. In this puzzle `[busy]` refers to our frame, `&` represents the loader element, so when the frame get's the `busy` attribute `[[busy]~&]:` variant will work. We'll use it with the opacity property - default value will be `0`, and `100` for the active variant. We can also get rid of the `Loading...` text.


```erb
<div class="relative min-h-96">
    <%%= turbo_frame_tag 'transactions', src: dashboard_transactions_historic_path do %>
    <%% end %>
    <div class="pointer-events-none absolute inset-0 z-20 flex items-center justify-center bg-gray-50 bg-opacity-25 opacity-0 [[busy]~&]:opacity-100 backdrop-blur-sm transition-opacity">
      <%%= image_tag "loading.svg", class: "animate-pulse" %>
    </div>
</div>
```

<video src="https://arkency-images.s3.eu-central-1.amazonaws.com/how-to-add-a-loading-animation-to-your-turbo-frame-with-tailwindcss/loader-on.mp4" class="w-full" autoplay muted playsinline loop></video>

Now everytime we reload the frame's content we'll get a visual confirmation that something is going on. Everything done with a plain CSS selector and not a single line of JavaScript!


