---
title: Overcome 10k rows database limit on Heroku by upgrading the plan
created_at: 2020-05-05T11:20:37.601Z
author: Andrzej Krzywda
tags: []
publish: false
---

Over time I have collected quite a number of small Rails heroku apps. They usually start small, but overtime they hit the limit of 10k rows and it's time to upgrade the database plan. Every time I do it, I hit the heroku documentation just to realize that their way of explaining doesn't fit me well.

This usually means that I then google a lot and only after 10 minutes I find what I look for.

This blogpost is my attempt to make myself a quick summary of what needs to be done:

And yes, Andrzej, if you read it in the future - you do need to provision a new database to overcome the 10k limit. There's no way of just upgrading this limit on the UI with one button.


Before I start I make sure that I don't need to append the name of the app to each command, by:

`heroku git:remote -a myapp`

* create new postgres add-on (choose Hobby Basic) in UI
* `heroku maintenance:on`
* `heroku pg:copy HEROKU_POSTGRESQL_COPPER_URL HEROKU_POSTGRESQL_CHARCOAL` 
* `heroku pg:promote HEROKU_POSTGRESQL_CHARCOAL`
* `heroku maintenance:off`
* remove old Postgres add-on
