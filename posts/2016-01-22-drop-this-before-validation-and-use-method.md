---
title: "Drop this before validation and just use a setter method"
created_at: 2016-01-29 10:02:10 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'validations', 'aspects', 'ruby' ]
newsletter: :skip
newsletter_inside: :clean
---

In many projects you can see code such as:

```
#!ruby

class Something
  before_validation :strip_title

  def strip_title
    self.title = title.strip
  end
end
```

However there is **different way** to write this requirement.

<!-- more -->

```
#!ruby

class Something
  def title=(val)
    @title = val.strip
  end
end
```

...or...

```
#!ruby
class Something
  def title=(val)
    self['title'] = val.strip
  end
end
```

...or...

```
#!ruby
class Something
  def title=(val)
    super(val.strip)
  end
end
```

...depending on the way you keep the data inside the class. Various gems use various ways.

Here is why I like it that way:

* it **explodes** when `val` is `nil`. Yes, I consider it to be **a good thing**. Rarely my frontend can send `nil` as title
so when it happens most likely something would be broken and exception is OK. It won't happen anyway. It's just my
programmer lizard brain telling me all corner cases. I like this part of the brain. But sometimes it deceives us and
makes us focus on cases which won't happen.
* It's **less magic**. Rails validation callbacks are cool and I've used them many times. That said, I don't need them to
strip fuckin' spaces.
* It **works** in more cases. It works when you read the field after setting it, without doing save in between. Or if you
save without running the validations (for whatever reasons).

```
#!ruby
something.code = " 123 "
something.code
# => 123

something.save(validate: false)
```

I especially like to impose such cleaning rules on objects used for crossing boundaries such as **Command** or **Form objects**.

## Summary

That's it. That's the entire, small lesson. If you want more, subscribe to our mailing list below or [buy Fearless Refactoring](http://controllers.rails-refactoring.com).

<%= show_product_inline(item[:newsletter_inside]) %>
