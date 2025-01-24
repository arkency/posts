---
created_at: 2025-01-10 23:55:51 +0100
author: Maciek Korsan
tags: ['frontend', 'css', 'hotwire', 'turbo', 'rails' ] 
publish: true
---

# Turbo Frames and the Extra DOM Node – How to Handle It?

I come from the React world, I've spent years working with it, and I've been a fan of it ever since. Recently, I started working with Hotwire, and  I quickly fell in love with it – the simplicity and efficiency of this approach are impressive. However, along the way, I encountered a few surprises.  

One of those surprises was how **Turbo Frames** work in the DOM. In React, we can use `<Fragment>` or a shorthand `<>` to avoid adding an extra node to the DOM structure. In contrast, when using `<turbo-frame>` tag, it's being physically embedded in the DOM, which can sometimes lead to unexpected display and styling issues.  

<!-- more -->

Let's start with a simple example.

We have a record collection browser and we want to display a list of records, but first element is an add new record button.

That's the basic markup:

```html
  <ul class="grid grid-cols-4 gap-8">
    <li>
      <div class="w-full bg-black aspect-square">
        <%%= link_to new_record_path, :class => "bg-blue-500 text-white px-2 py-1 rounded-md size-full flex items-center justify-center" do %>
          <span class="text-2xl text-center"><span class="text-4xl">+</span><br/> New Record</span>
        <%% end %>
      </div>
    </li>
    <%% @records.each do |record| %>
      <li class="relative">
        <%%= link_to  record_path(record) do %>
          <div class="w-full bg-black aspect-square">
            <%%= image_tag record.cover, class: "size-full object-contain" if record.cover.present? %>
          </div>
        <%% end %>
      </li>
    <%% end %>
  </ul>
```

and it should look like this:

<img src="<%= src_fit("turbo-extra-node/turbo-extra-node.webp") %>" width="100%">

Now we want to wrap the records in a turbo frame, without including the add new record button in it.


```html
  <ul class="grid grid-cols-4 gap-8">
    <li>
      <div class="w-full bg-black aspect-square">
        <%%= link_to  new_record_path, :class => "bg-blue-500 text-white px-2 py-1 rounded-md size-full flex items-center justify-center" do %>
          <span class="text-2xl text-center"><span class="text-4xl">+</span><br/> New Record</span>
        <%% end %>
      </div>
    </li>
    <%%= turbo_frame_tag "records" do %>
      <%% @records.each do |record| %>
        <li class="relative">
          <%%= link_to  record_path(record) do %>
            <div class="w-full bg-black aspect-square">
              <%%= image_tag record.cover, class: "size-full object-contain" if record.cover.present? %>
            </div>
          <%% end %>
        </li>
      <%% end %>
    <%% end %>
  </ul>
```

But the result is not what we expected:

<img src="<%= src_fit("turbo-extra-node/turbo-extra-node-2.webp") %>" width="100%">

### So what's the problem?

Turbo Frames are inserted into the DOM as a new element, which can break the layout. Frame is inserted into the second column of the grid, and so are all the records.

<img src="<%= src_fit("turbo-extra-node/turbo-extra-node-3.webp") %>" width="100%">

###Can we fix it? 

Yes! One of the solutions is to use good old CSS to make the frame "transparent". The property we need is `display`, and we need to set it to `contents`. 

```css
turbo-frame {
  display: contents;
}
```

This will make the frame transparent and the records will be displayed correctly 🎉

<img src="<%= src_fit("turbo-extra-node/turbo-extra-node-4.webp") %>" width="100%">

## Webinar: My Journey from React to Hotwire

If you’re interested in similar topics, join my [webinar - From React to Hotwire](https://arkency.com/webinars/from-react-to-hotwire), where I’ll talk about my experiences I had along the way! 

The webinar will take place on January 30th at 17:00 Warsaw time.

See you there!




