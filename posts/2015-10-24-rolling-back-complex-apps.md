---
title: "Rolling back complex apps"
created_at: 2015-10-24 22:25:15 +0200
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

One of the customers of [Responsible Rails ebook](/responsible-rails) has
us about the topic of _Rolling back complex apps_ so I decided to share a
few small protips on this topic.

<!-- more -->

## Keep backward-forward compatibility

If you are afraid that your code might break something and you will have to
go back to previous version, then it is best to make your data structures
compatibile with previous versions of code.

You need to ask yourself what will happen if you:

* Deploy revision A and make it work for some time
* Deploy revision B with some updated and make it work for some time (even short)
* Go back to revision A which will have to work on data created by itself and by revision B

This is relevant to database structure, state columns, method arity and many aspects
of the system. Sometimes avoiding pitfalls is easy, sometimes it is harder.

Most of the time the answer how to do things more safely is to divide it into more steps.
Let's see some specifics.

## Don't use _not null_ initially

Say you want to add a _not null_ columns. Lovely. I hate _nulls_ in db. But if you add
_not null_ column without a default in revision B, and then you have to go to quickly go back
to revision A, then you are in trouble. Old code has no knowledge of the new column.
It doesn't know what to enter there. You can of course reverse the migration but that means
additional work in stressful circumstances. And chances are, you are doing it so rarely that
you won't be able to just run the proper command without hesitation. Hosting providers
usually don't come with good UI for rarely executed tasks as well. So nothing is on your side.

Solution? Break it into more steps:

* add _null_ column
* Wait enough time to make sure you won't roll back this revision.

    If you do roll back, then
    no problem. Old code can still insert new records and the will have _null_ in the newly added
    column. You don't have to revert the migration. The new column can be kept. Once you fix your
    code and deploy it again, it will start using the new column. Of course you will have to fill
    the value of the column for the records created when revision A was deployed for the second time.
* add null constraint

Adding a default is another way to circumvent the problem. But that's only posible if the
value is simple and not vary per record. You don't always have that comfort.

## Method arity

Say you have a background job that expects one argument in revision A.

```
#!ruby
class Job
  def self.perform(record_id)
  end
end

Job.enqueue(1)
```

And you want to add one more argument `perform(record_id, locale)` in your revision B.

```
#!ruby
class Job
  def self.perform(record_id, locale)
  end
end

Job.enqueue(1, "es")
```

To keep the code in revision B comptabile with jobs scheduled in revision A you
need to use a default:

```
#!ruby
class Job
  def self.perform(record_id, locale="en")
  end
end
```

Because when you deploy new version of background worker code, old jobs might still
be unprocessed.

Ok, but what happens if you roll back to revision A?

Jobs scheduled in revision B (and unprocessed) will fail on revision A. Too many arguments.

Solution? Break into more steps:

First, just add a default but don't change the method code and the code enqueuing.
Just the signature. This should be safe.

```
#!ruby
class Job
  def self.perform(record_id, locale="en")
  end
end

Job.enqueue(1)
```

And then in second step change the method so it depends on the additional argument
and the code that enqueues to pass that argument:


```
#!ruby
class Job
  def self.perform(record_id, locale="en")
  end
end

Job.enqueue(1, "es")
```

If you need to revert back, already enqueued jobs will continue to work on
previous code revision.

## Don't roll back, just deploy old code again


## Deploy as often as possible

## Use feature toggles

## No need to use those tools all the time


Note: Similar problem to zer-downtime-deploy but a bit more complicated
because instead of having 0 downtime going from A->B, you need to also
have 0 downtime going from B->A, which usually requires B to just be
smaller in size.
