---
title: 5 gems you no longer need with Rails
created_at: 2025-06-26T19:51:41.218Z
author: Paweł Pacana
tags: []
publish: false
---

In my line of work as a consultant I'm often reviewing Rails codebases. Most of the time they're not the greenfield apps — developed with latest and greatest Rails and Ruby releases. They power successful businesses though. To keep them running smoothly and securely they sometimes need a little push to stay within [framework maintenance window](https://endoflife.date/rails).

Upgrading the Rails itself is the easiest part of the upgrade process. It's well documented. The framework and its parts play well together. You can do it gradually, dealing with new framework defaults one by one. 

The trickier part is the non-framework dependencies. The ones that gave tremendous leg while bootstrapping the application. When upgrading, each of them adds some complexity:

 * how they interact with different framework versions — do you need to upgrade them as well

 * how they interact with other dependencies — do you need to upgrade them due to other dependencies changing

 * do they introduce breaking behaviour changes — if you have to upgrade them

 * can you upgrade them gradually in disconnect with framework changing on the same step

The more of them, the bigger the trouble. And eventually more changelogs to inspect each time. If we could remove some gems, it would be great help. There are many heuristics to detect dead gem dependencies. Here is the one that I use — *replace external gems with framework features*. Any my personal top 5 list of gems you no longer need with Rails.

### aasm

Easy kill. Rails has [enums](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html) since version 4.1. Yet it is not hard to find this gem still in use. When you find it — read more from Szymon on how to [replace aasm with enums](https://blog.arkency.com/replace-aasm-with-rails-enum-today/).

### activerecord-import

Wonderful gem that extended ActiveRecord with bulk operations. Not needed since Rails 6.0 and the introduction of [insert_all](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-insert_all), [upsert_all](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-upsert_all) and their bang counterparts.

One difference to keep in mind — different behaviour when applying bulk operations on empty collections. This has [harmonized](https://github.com/rails/rails/commit/cd3508607da073aaef190ac6a7479557eba121c4) with `activerecord-import` in Rails 7.1.

### timecop

[ActiveSupport::Testing::TimeHelpers](https://edgeapi.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html) are present since Rails 4.1. When included in a test class, they currently allow to both `freeze` and `travel` in time. There's even an `after_teardown` callback for added safety to isolate time changes within a dedicated test case.

### marginalia

What used to be a `marginalia` gem is now a part of [Rails 7.0 and newer](https://edgeapi.rubyonrails.org/classes/ActiveRecord/QueryLogs.html).

You have to explicitly enable it with `config.active_record.query_log_tags_enabled = true` in the application configuration. The `Marginalia::Comment.components` now becomes `config.active_record.query_log_tags`. Respectively `Marginalia::Comment.prepend_comment` is now `config.active_record.query_log_tags_prepend_comment` and that it is pretty much it.

### attr_encrypted

Rails introduced [encryption](https://guides.rubyonrails.org/active_record_encryption.html) to ActiveRecord attributes in version 7.0.

The differences in storage — number, naming and payload of stored, encrypted database columns make this replacement not quite straight-forward. Here's a [possible upgrade path](https://pagertree.gitbook.io/blog/migrate-attr_encrypted-to-rails-7-active-record-encrypts) as described by the PagerTree team.

I'm curious what are your top gems no longer needed with Rails. Happy upgrading!
