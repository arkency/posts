---
title: "Private classes in Ruby"
created_at: 2016-01-29 11:49:07 +0100
kind: article
publish: false
author: anonymous
tags: [ 'ruby', 'private', 'class' ]
newsletter: :skip
newsletter_inside: :clean
---

One of the most common way to make some part of your code more understandable and explicit is to extract a class.
However, many times this class is **not intended for public usage**. It's an implementation detail of a bigger
unit. It should not be used be anyone else but the module in which it is defined.

So how do we hide such class
so that others are not tempted to use it? So that it is clear that it is an **implementation detail**?

<!-- more -->

I recently noticed that many people don't know that since Ruby 1.9.3 you can make a constant private. And that's
your answer to _how_.

```
#!ruby
class Person
  class Secret
    def to_s
      "1234vW74X&"
    end
  end
  private_constant :Secret

  def show_secret
    Secret.new.to_s
  end
end
```

The `Person` class can use `Secret` freely:


```
#!ruby
Person.new.show_secret
# => 1234vW74X&
```

But others cannot access it.

```
#!ruby
Person::Secret.new.to_s
# NameError: private constant Person::Secret referenced
```

So `Person` is the public API that you expose to other parts of the system and `Person::Secret` is just an
implementation detail.

You should probably not test `Person::Secret` directly as well but rather through the public `Person` API
that your clients are going to use. That way your tests won't be brittle and **depended on implementation**.

## Summary

That's it. That's the entire, small lesson. If you want more, subscribe to our mailing list below or [buy Fearless Refactoring](http://rails-refactoring.com).

<%= inner_newsletter(item[:newsletter_inside]) %>