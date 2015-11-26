---
title: "Rolling back complex apps"
created_at: 2015-10-24 22:25:15 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rollback', 'deployment' ]
newsletter: :arkency_form
---

One of the customers of [Responsible Rails ebook](/responsible-rails) has
asked us about the topic of _Rolling back complex apps_ so I decided to share a
few small protips on this topic.

<!-- more -->

## Keep backward-forward compatibility

If you are afraid that your code might break something and you will have to
go back to the previous version, then it is best to make your **data structures
compatible with the previous version** of the code.

You need to ask yourself what will happen if you:

* Deploy revision A and make it work for some time
* Deploy revision B with some updated and make it work for some time (even short)
* Go back to revision A which will have to work on data created by itself and by revision B

This is relevant to database structure, state columns, method arity and many aspects
of the system. Sometimes avoiding pitfalls is easy, sometimes it is harder.

Most of the time the answer how to do things more **safely is to divide them into more steps**.
Let's see some specifics.

## Don't use _not null_ initially

Say you want to add a _not null_ column. Lovely. I hate _nulls_ in db. But if you add
_not null_ column without a default in revision B, and then you must quickly go back
to revision A, then you are in trouble. Old code has no knowledge of the new column.
It doesn't know what to enter there. You can, of course, reverse the migration but that means
additional work in stressful circumstances. And chances are, you are doing it so rarely that
**you won't be able to just run the proper command without hesitation**. Hosting providers
usually don't come with good UI for rarely executed tasks as well. So nothing is on your side.

Solution? Break it into more steps:

* add _null_ column
* Wait enough time to make sure you won't roll back this revision.

    If you do roll back, then
    no problem. Old code can still insert new records and they will have _null_ in the newly added
    column. You don't have to revert the migration. The new column can be kept. Once you fix your
    code and deploy it again, it will start using the new column. Of course, you will have to fill
    the value of the column for the records created when revision A was deployed for the second time.
    But that's manageable.
* add _not null_ constraint

Adding a database default is another way to circumvent the problem. But that's only posible if the
value is simple and don't vary per record. You don't always have that comfort.

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

And you want to add one more argument `locale` in your revision B.

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

**Jobs scheduled in revision B (and unprocessed) will fail on revision A. Too many arguments.**

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

And then in a second step change the method so it depends on the additional argument
and the code that enqueues to pass that argument:


```
#!ruby
class Job
  def self.perform(record_id, locale="en")
  end
end

Job.enqueue(1, "es")
```

If you need to revert back, **already enqueued jobs will continue to work on
previous code revision.**

## Don't roll back, just deploy old code again

Some hosting providers offer the ability to roll back. However, we've seen
it been badly implemented. Maybe because it is not used too often. The way
I approach it, is to deploy again revision number A. I look into the history
of deploys, check out previously deployed revision number and keept it nearby.

Deployment is done so often that we know the procedure to be reliable and
verified. **The only difference is that I am deploying older revision instead
of newer one**.

Teoretically rolling back should be the same as deploying previous version
of the code. But for some providers it is not. So I mention it here
explicitly.

## Deploy as often as possible

Have you ever deployed a new feature that was living on a separate branch after
two or three weeks of developing? Despite all the tests I never feel
comfortable doing that.

So instead **I try to deploy once per day or two**. If you are adding new features
you can usually continue to add classes and methods and deploy them safely.
Often this path in code won't be reachable unless you display it on the UI.
And you can make it only available in development environment, staging or for admins. Which
brings us to our next technique.

## Use feature toggles

Usually when we land new big features for our biggest client they are protected
with [feature toggles](http://martinfowler.com/bliki/FeatureToggle.html) .
Often those toggles are not for entire system but rather they work per tenant or
per country. That means when the time comes and the feature is ready **you can
enable it in the biggest (if you feel brave) or the smallest (if not so brave)
market**. Or just in the market that is the targeted recipient of given feature.
The bigger the project the more often you need to adjust it
for local regulations, customers' habits and API providers.

When we add new payment gateway integration we usually try it first on certain
products, then on certain merchant accounts and then in certain countries. **Gradually
exposing it to more and more customers**.

Here is an example of such configuration. Settings for products take
precedence over settings for merchants which take precedence over
settings for countries.


```
#!ruby
class PaymentGatewaySetting < ActiveRecord::Base
  SettingNotFound = Class.new(StandardError)

  def self.fetch(country_id:, merchant_id:, product_id:)
    where(
      country_id:  country_id,
      merchant_id: [nil, merchant_id],
      product_id:  [nil, product_id],
    ).order("
      COALESCE(product_id, 0)  desc,
      COALESCE(merchant_id, 0) desc,
               country_id      desc
    ").first || raise SettingNotFound
  end
end
```

**Feature toggles make the easiest rollbacks**. Something is not right after enabling a feature?
No problem, just disable it, investigate, fix and re-enable.

You can read more about [programmer friendly workflow environment in our
Developers Oriented Project Management ebook](/developers-oriented-project-management) .
We describe there for example how to work on `master` branch without Pull Requests
and quote Google Chrome team which works the same way.

## Just tools

Of course these are just tools. No need to use them all the time. **Apply when in
need**. When you need to feel more safe and comfortable. There are core features
of the platform that must just work, for example, the checkout process in a shop.
And there are a lot of secondary features which are not as critical.

Going safer way means **deploying smaller chunks, deploying more often
and hiding features which are not ready yet**. So it is obvious that the cost
of shipping new features
is a little higher because of overhead. But if you already have Continuous Deployment
then it is not much bigger. **It's mostly your habits that need to change.**

## Zero downtime deploy but in a reversed direction

Easy rollbacks is a similar problem to zero-downtime-deploy but a bit more complicated.
Instead of having zero downtime going from **A → B**, you need to also
have zero downtime going (eventually) from **B → A**, which usually requires **B** to just be
smaller in size.

<iframe src="http://www.slideshare.net/slideshow/embed_code/12676486" width="427" height="356" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px 1px 0; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> <div style="margin-bottom:5px"> <strong> <a href="https://www.slideshare.net/pedrobelo/zero-downtime-deploys-for-rails-apps" title="Zero downtime deploys for Rails apps" target="_blank">Zero downtime deploys for Rails apps</a> </strong> from <strong><a href="http://www.slideshare.net/pedrobelo" target="_blank">pedrobelo</a></strong> </div>
