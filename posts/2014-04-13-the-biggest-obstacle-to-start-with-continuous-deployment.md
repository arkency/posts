---
title: "The biggest obstacle to start with Continuous Deployment - database migrations"
created_at: 2014-04-13 19:28:23 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'continuous', 'deployment', 'rails', 'database', 'migrations' ]
---

<p>
  <figure>
    <img src="/assets/images/continuous-deployment/continuous.jpg" width="100%">
    <details>
      <a href="https://www.flickr.com/photos/93751689@N04/9557470061/sizes/c/">Photo</a>
      remix available thanks to the courtesy of
      <a href="https://www.flickr.com/photos/93751689@N04/">Mark Engelbrecht</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

There are still startups which disable the website during deploys with database
migrations and believe that db migrations prevent them from going fully with CD.
They even have time window for triggering such activities (usually early in the
morning or late at night). However you must be aware of few things.

<!-- more -->

## Step by step

When you go with CD and do many deploys a day, most of them are not running db
migrations at all. You can save your developers time at least on these kinds of
activities. Your CD solution can easily detect (at least in case of Rails app)
that deploy would trigger new migration and notify your developer that in such
case the deploy should be done manually. Still better than nothing.
Still saving lots of people time.

Even if your deploy is containing migrations, in many cases they are
non-destructive. They are rather creating new tables, new columns and new indexes.
In such case you can for example follow a naming convention so that CI can easily know
that the migrations are indeed non-destructive and might be executed at any time because
it will not cause troubles to already running application. Still, you need to be a bit
cautious. If you add new column with `NOT NULL` constraint and without a default, it will
most likely cause troubles to you app if executed when new request are coming. Why? Because
the previous version of the app (the on running when migrations are executed) won't be
filling the column with proper data during new records creation. So whenever marking migration
as non-destructive, you should ask yourself a question _Will executing this migration when
system is online and serving requests cause any trouble when record from table X is added,
updated or deleted? If not, it means that your migration is non-interrupting for the system
and can be deployed automatically at any time._

In the worst case, when the deploy is containing destructive migrations you can fallback to the
old way of disabling the website during the deploy. But still your deployment script can be
triggered automatically and it can verify whether the migration procedure was triggered in the
allowed time window for turning off the application. So if a developer commits or merges
destructive migration to master branch during the time window, the app would be still deployed
automatically, saving your developers time.

In the last step you teach your team how to write code adapted for zero-downtime deploys triggered by
Continuous Deployment. So let's say you want to add new `not null` column. And you achieve it step by
step. Firstly you add new column with nulls allowed. Then you deploy code which is actually starting
to fill the column with some data from the app. Then you deploy code/migration which computes the data
for all old records containing nulls. Then you deploy code which marks that column as not null. All
step by step, without trying to achieve it in one giant commit or giant deploy. Notice how very well
this approach can work with [small stories](/2013/09/story-of-size-1/).

There is amazing presentation about how to do it: [Zero downtime deploys for rails apps](http://www.slideshare.net/pedrobelo/zero-downtime-deploys-for-rails-apps)

## Summary

As you can see you can achieve Continuous Deployment step by step. It does not have to be all or nothing. It can be:

* automatic deployment only for builds without database migrations, manual for the rest
* automatic deployment only for build without db migrations or with non-destructive migrations, manual for the rest
* automatic deployment for all builds, but those with destructive migration will temporarily disable the app and will be only allowed to be executed during selected time window.
* automatic deployment all the time, there are no interrupting migrations (your team does not write them), destroyed data are no longer used by application.

This post is a small extract from a chapter of our <%= landing_link %> ebook.
