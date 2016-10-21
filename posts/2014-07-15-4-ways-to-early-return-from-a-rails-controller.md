---
title: "4 ways to early return from a rails controller"
created_at: 2014-07-15 12:53:01 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter: :skip
newsletter_inside: :fearless_refactoring_1
tags: [ 'controllers', 'rails' ]
---

<p>
  <figure align="center">
    <img src="<%= src_fit("exit-controller/return.jpg") %>" width="100%">
  </figure>
</p>

When [refactoring rails controllers](http://rails-refactoring.com/) you can stumble upon one gottcha. It's hard to
easily extract code into methods when it escapes flow from the controller method (usually
after redirecting and sometimes after rendering). Here is an example:

## 1. redirect_to and return (classic)

```
#!ruby
class Controller
  def show
    unless @order.awaiting_payment? || @order.failed?
      redirect_to edit_order_path(@order) and return
    end

    if invalid_order?
      redirect_to tickets_path(@order) and return
    end

    # even more code over there ...
  end
end
```

So that was our first classic `redirect_to and return` way.

Let's not think for a moment what we are going to do later with this code, whether some of it should landed
in models or services. Let's just tackle the problem of extracting it into a controller method.

<!-- more -->

## 2. extracted_method and return

```
#!ruby
class Controller
  def show
    verify_order and return
    # even more code over there ...
  end

  private

  def verify_order
    unless @order.awaiting_payment? || @order.failed?
      redirect_to edit_order_path(@order) and return true
    end

    if invalid_order?
      redirect_to tickets_path(@order) and return true
    end
  end
end
```

The problem with this technique is that after extracting the code into method you
also need to fix all the _returns_ so that they end with `return true` (instead of just `return`).
If you forget about it you are going to introduce a new bug.

The other thing is that `verify_order and return` does not feel natural. When this method
returns `true` I would rather expect the order to be positively verified so escaping early
from controller action does not seem to make sense here.

So here is the alternative variant of it

## 2.b extracted_method or return

```
#!ruby
class Controller
  def show
    verify_order or return
    # even more code over there ...
  end

  private

  def verify_order
    unless @order.awaiting_payment? || @order.failed?
      redirect_to edit_order_path(@order) and return
    end

    if invalid_order?
      redirect_to tickets_path(@order) and return
    end

    return true
  end
end
```

Now it sounds better `verify_order or return`. Either the order is verified or we return early.
If you decide to go with this type of refactoring you must remember to add `return true` at the
end of the extracted method. However the good side is that all your `redirect_to and return` lines
can remain unchanged.

## 3. extracted_method{ return }

```
#!ruby
class Controller
  def show
    verify_order{ return }
    # even more code over there ...
  end

  private

  def verify_order
    unless @order.awaiting_payment? || @order.failed?
      redirect_to edit_order_path(@order) and yield
    end

    if invalid_order?
      redirect_to tickets_path(@order) and yield
    end
  end
end
```

If we wanna return early from the top level method, why not be explicit about what we
try to achieve. You can do that in Ruby if your callback block contains `return`. That
way inner function can call the block and actually escape the outer function.

But when you look at `verify_order` method in isolation you won't know that this `yield` is
actually stopping the flow in `verify_order` as well. Next lines are not reached.

I don't
like when you need to look at outer function to understand the behavior of inner
function. That's completely contrary to what we usually try to achieve in programming
by splliting code into methods that can be understood on their own and provide us with
less cognitive burden.

## 4. extracted_method; return if performed?

```
#!ruby
class Controller
  def show
    verify_order; return if performed?
    # even more code over there ...
  end

  private

  def verify_order
    unless @order.awaiting_payment? || @order.failed?
      redirect_to edit_order_path(@order) and return
    end

    if invalid_order?
      redirect_to tickets_path(@order) and return
    end
  end
end
```

With [`ActionController::Metal#performed?`](http://api.rubyonrails.org/v4.1.4/classes/ActionController/Metal.html#method-i-performed-3F)
you can test whether render or redirect already happended. This seems to be a good solution for cases when you extract code into method
solely responsible for breaking the flow after render or redirect. I like it because in such case as shown, I don't need to tweak the
extracted method at all. The code can remain as it was and we don't care about returned values from the subroutine.

## throw :halt (sinatra bonus)

In [sinatra you could use `throw :halt`](http://patshaughnessy.net/2012/3/7/learning-from-the-masters-sinatra-internals)
for that purpose ([don't confuse `throw` (flow-control) with `raise` (exceptions)](http://rubylearning.com/blog/2011/07/12/throw-catch-raise-rescue-im-so-confused/)).

There was a [discussion about having such construction in Rails a few years ago](https://groups.google.com/forum/#!topic/rubyonrails-core/EW7C5GoEZxw)
happening automagically for rendering and redirecting but the discussion is inconclusive and looks like it was not implemented
in the end in rails.

It might be interesting for you to know that expecting `render` and `redirect` to break the flow of the method and exit it immediately
is one of the most common mistake experienced by some Rails developers at the beginning of their career.

<%= show_product_inline(item[:newsletter_inside]) %>

## throw :halt (rails?)

As Avdi wrote and [his blogpost](http://rubylearning.com/blog/2011/07/12/throw-catch-raise-rescue-im-so-confused/)
Rack is also internally using `throw :halt`. However I am not sure if using this directly from Rails, deep, deep in
your own controller code is approved and tesed. Write me a comment if you ever used it and it works correctly.

## why not before filter?

Because in the end you probably want to put this code into service anyway and separate checking
pre-conditions from http concerns.

## More

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
