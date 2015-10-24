---
title: "Run it in background job, after commit, from Service Object"
created_at: 2015-10-24 21:05:24 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'active_record', 'background', 'job', 'after commit' ]
newsletter: :skip
newsletter_inside: :clean
---

There is this problem that when you schedule a background job from inside of a running
database transaction, the background job can kick in before the transaction is commited.
**Then the job can't find the data that it expects to already be there, in database**.
How do we solve this issue? Let's schedule a job after db commit.

<!-- more -->

## The story behind it

The easiest way to do it, would be to move all the code responsible for scheduling
after the transaction is finished. But in big codebase, you might not have the ability
to do it easily. And it is not that trivial with nested dependencies.

You might know that your ActiveRecord class have `after_commit` callback that can be
triggered when the transaction is commited. However, I didn't want to couple enqueuing
with an existing ActiveRecord class. I think that
**integrations with such 3rd party systems as for example background queues are more the responsibility
of Service Objects** rather then ActiveRecord models.
And I didn't want to introduce a new AR class just for the sake
of using `after_commit` callback. **I wanted the callback without ActiveRecord class**.

Here is how it can be achieved and how I figured it out.

## `after_commit` - where are you.

Let's see [`after_commit`](http://api.rubyonrails.org/v4.1.0/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_commit)
implementation in Rails.

```
#!ruby
# File activerecord/lib/active_record/transactions.rb, line 225
def after_commit(*args, &block)
  set_options_for_callbacks!(args)
  set_callback(:commit, :after, *args, &block)
end
```

Well, this doesn't tell me much on what and how is calling this callback.

So I looked into [`set_callback`](https://github.com/rails/rails/blob/10ac0155b19ea5b457417244f4f327404b997935/activesupport/lib/active_support/callbacks.rb#L34)
and there I found in a documentation that such callbacks should be executed with `run_callbacks :commit do`.

```
#!ruby
# Example from documentation
class Record
  include ActiveSupport::Callbacks
  define_callbacks :save

  def save
    run_callbacks :save do
      puts "- save"
    end
  end
end
```

## What calls you?

The next step was to investigate what part of ActiveRecord calls `:commit` hook. A simple grep told me the truth.
Only [one place in code](https://github.com/rails/rails/blob/10ac0155b19ea5b457417244f4f327404b997935/activerecord/lib/active_record/transactions.rb#L295) calling it

```
#!ruby
# Call the +after_commit+ callbacks.
#
# Ensure that it is not called if the
# object was never persisted (failed create),
# but call it after the commit of a destroyed object.
def committed! #:nodoc:
  run_callbacks :commit if destroyed? || persisted?
ensure
  @_start_transaction_state.clear
end
```

Ok, so what calls the method `commited!` ? It is used in
[`ActiveRecord::ConnectionAdapters::OpenTransaction`](https://github.com/rails/rails/blob/10ac0155b19ea5b457417244f4f327404b997935/activerecord/lib/active_record/connection_adapters/abstract/transaction.rb#L147):

```
#!ruby
def commit_records
  @state.set_state(:committed)
  records.uniq.each do |record|
    begin
      record.committed!
    rescue => e
      record.logger.error(e) if record.respond_to?(:logger) && record.logger
    end
  end
end
```

It is called on every `record` from `records` collection. But how are they added there?

```
#!ruby
def add_record(record)
  if record.has_transactional_callbacks?
    records << record
  else
    record.set_transaction_state(@state)
  end
end
```

So I turns out, all we need to do, is add an object which quacks like an ActiveRecord one, to the collection
of `records` tracked by currently open transaction (if there is one).

## This... is... Ruby! (quack)

Here is a class which mimics the small API necessary for things to work correctly:

```
#!ruby
class AsyncRecord
  def initialize(*args)
    @args = args
  end

  def has_transactional_callbacks?
    true
  end

  def committed!(*_, **__)
    Resque.enqueue(*@args)
  rescue => e
    logger.warn("Transaction commited - async scheduling failed")
    Honeybadger.notify(e, { context: { args: @args } } )
  end

  def rolledback!(*_, **__)
    logger.warn("Transaction rolledback! - async scheduling skipped")
  end

  def logger
    Rails.logger
  end
end
```

And here is a piece of code which checks if we are in the middle of an open transaction.
If so, we add our `AsyncRecord` to the collection of tracked `records`. When the transaction
is commited, the new job will be queued in Resque.

```
#!ruby
def enqueue(*args)
  if ActiveRecord::Base.connection.transaction_open? && !transaction_test
    ActiveRecord::Base.
      connection.
      current_transaction.
      add_record( AsyncRecord.new(*args) )
  else
    Resque.enqueue(*args)
  end
end
```

One more thing is important. You might be running some (all?) of your tests inside a database transaction
that is rolledback at the end of each test. I excluded such tests from this behavior:

```
#!ruby
def transaction_test
  Rails.env.test? && 
  defined?(DatabaseCleaner) && 
  DatabaseCleaner::ActiveRecord::Transaction === DatabaseCleaner.connections.first.strategy
end
```

This is dependent on your testing infrastructure so it might differ in your project.

If enjoyed this article and would like to **keep getting free Rails tips** in the future, subscribe
to our mailing list below:

<%= inner_newsletter(item[:newsletter_inside]) %>
