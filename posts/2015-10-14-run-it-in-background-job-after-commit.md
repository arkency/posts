---
title: "Run it in background job, after commit"
created_at: 2015-10-14 21:05:24 +0200
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

There is this problem that when you schedule a background job from inside of a running
database transaction, the background job can kick in before the transaction is commited.
Then the job can't find the data that it expects to already be there, in database.
How do we solve this issue? Let's schedule a job after db commit.

<!-- more -->

## The story behind it

The easiest way to do it, would be to move all the code responsible for scheduling
after the transaction is finished. But in big codebase, you might not have the ability
to do it easily. And it is not that trivial with nested dependencies.

You might know that your ActiveRecord class have `after_commit` callback that can be
triggered when the transaction is commited. However, I didn't want to couple my solution
with an ActiveRecord class. I didn't want to save something in database just for the sake
of using `after_commit` callback. I wanted the callback without ActiveRecord class.
Here is how it can be achieved and how I figured it out.

## `after_commit` - where are you.

Let's see [`after_commit`](http://api.rubyonrails.org/v4.1.0/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_commit)
documentation and implementation in Rails.

```ruby
# File activerecord/lib/active_record/transactions.rb, line 225
def after_commit(*args, &block)
  set_options_for_callbacks!(args)
  set_callback(:commit, :after, *args, &block)
end
```

Well, this doesn't tell me much on what and how is calling this callback.

So I looked into [`set_callback`](https://github.com/rails/rails/blob/10ac0155b19ea5b457417244f4f327404b997935/activesupport/lib/active_support/callbacks.rb#L34)
and there I found that such callbacks should be executed with `run_callbacks :commit do`.

## What calls you?

The next step was to investigate what part of ActiveRecord calls this hook. A simple grep told me the truth.
Only [one place in code](https://github.com/rails/rails/blob/10ac0155b19ea5b457417244f4f327404b997935/activerecord/lib/active_record/transactions.rb#L295) calling it

```ruby
# Call the +after_commit+ callbacks.
#
# Ensure that it is not called if the object was never persisted (failed create),
# but call it after the commit of a destroyed object.
def committed! #:nodoc:
  run_callbacks :commit if destroyed? || persisted?
ensure
  @_start_transaction_state.clear
end
```

Ok, so what calls the method `commited!` ?


