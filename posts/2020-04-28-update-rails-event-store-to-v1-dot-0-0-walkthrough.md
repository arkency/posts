---
title: "Update Rails Event Store to v1.0.0 - walkthrough"
created_at: 2020-04-28 11:59:46 +0200
author: Mirosław Pragłowski
tags: ['rails event store']
publish: false
---

Recently I've posted a tweet:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">We are updating <a href="https://twitter.com/RailsEventStore?ref_src=twsrc%5Etfw">@RailsEventStore</a> in our workshop reference app (and a base for exercises for Domain-Driven Rails book). Who knows what&#39;s coming next :) <br><br>You could purchase the book &amp; get access here <a href="https://t.co/cKiPFfMio0">https://t.co/cKiPFfMio0</a> <a href="https://t.co/o60o8CyoMC">pic.twitter.com/o60o8CyoMC</a></p>&mdash; Arkency (@arkency) <a href="https://twitter.com/arkency/status/1250130514603839489?ref_src=twsrc%5Etfw">April 14, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Since then we have published 2 more Rails Event Store versions. And we have finally reached a 1.0.0 milestone!

The process of the upgrade between versions is always described in [release notes](https://github.com/RailsEventStore/rails_event_store/releases), but here I've decided to summarise all changes required and to emphasize the most important ones.

<!-- more -->

## The Ancient Era - versions: .. 0.1.0

Here is nothing to update. No known (public) historical sources. No changelog. The origins of Rails Event Store are hidden in a private repository of one of our customers. It was born as a small tool to help to integrate with 3rd party systems. We've started publishing domain events, have some subscribers that have been reacting to the published events. And most important we have started to store the published domain events. All in only 283 lines of code.


## The Medieval Period - versions: 0.1.1 .. 0.14.5

This was a violent time, with separate repositories and frequent API changes. No prisoners have been kept, no deprecations warnings have been issued. Also licensing has not yet been clarified. Thankfully I do not need to update these versions.



The strategy I have used to update Rails Event Store in our workshop application was simple: step by step, and prefer small steps. I've always updated only to the next version, run bundler, and run all tests to check if all are green all the time.


## The Age of Discovery - versions: 0.15.0 .. 0.18.2

The update started here. The version of the `rails_event_store` in Gemfile was `0.14.3`.


After cloning the application repository and make `bundle install` I've needed to start with making test passing. The problem was the `ClassyHash` gem we are using in the application to define the schema of domain events. The version in Gemfile has not been specified. And in the meantime, the API of the `ClassyHash.validate` method has changed. It needs to be fixed.


Having all test green I've moved to update Rails Event Store. But this time it has been a piece of cake. Just update version in GemFile, bundle install & run the tests. Additionally, I've added a `rails_event_store-rspec` gem and started using [RSpec matchers provided by Rails Event Store](https://railseventstore.org/docs/rspec/) in tests. Without issues and in ~2 hours I've reached the `0.18.2` version.


The biggest discovery in this Age Of Discovery was that there are no surprises here ;)


## The Modern Times - versions: 0.19.0 .. 1.0.0

The Modern Times has started with a big milestone - change of database schema (a.k.a V2 schema). The process of generating migration and running it is well described in [v0.19.0 release notes](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.19.0) but there are additional things to be beware of:

* The workshop app (this is only a reference application, not production-ready code) uses SQLite as a database (no dependencies, no problems). Before Rails 5.2 the migration created by Rails Event Store migration generator has tried to an create additional index, which was a duplicate of PK index created by SQLite. The solution is [described here](https://github.com/RailsEventStore/rails_event_store/blob/fceb501dc8d20224e1b8051851650e3abeaa358d/railseventstore.org/source/docs/install.html.md#setup-data-model).
* I've gone straight to `0.20.0` version because missing specification of minimum working `activerecord-import` gem version.

After solving these issues the first version of the workshop application with the "modern" version of Rails Event Store was ready.


The next noticeable difference (remember I update versions one by one) was `0.26.0`. With this version, I've to change how subscriptions to events are defined because API has been changed. Also, I've started using a new API that allows passing a proc/lambda as a subscriber.

    * Replaced deprecated use of `subscribe(handler, array_of_event_types)`
      with `subscribe(handler, to: event_types)`
    * Use new API that allows passing a subscriber as proc

I've replaced:

```ruby
# ./config/initializers/rails_event_store.rb

es.subscribe(OrderList::OrderSubmittedHandler,
	[Orders::OrderSubmitted])

es.subscribe(
	->(event){ Discounts::Process.perform_later(YAML.dump(event)) },
 [Orders::OrderShipped])
```

with updated code:

```ruby
# ./config/initializers/rails_event_store.rb

es.subscribe(OrderList::OrderSubmittedHandler,
	to: [Orders::OrderSubmitted])

es.subscribe(to: [Orders::OrderShipped]) do |event|
  Discounts::Process.perform_later(YAML.dump(event))
end
```


The `0.27.1` version allowed me to use Arkency's `command_bus` gem, which it is from this version included in Rails Event Store. Also here you could no longer compare generated & stored domain event's metadata because of [change in metadata enrichment](https://github.com/RailsEventStore/rails_event_store/commit/d261be7e13bbe6cc5bc14dd7b5ef682888bc463f).


With a `0.29.0` version, I was able to start correlating events using `with_metadata` method of `RailsEventStore::Client`. See more [how to use it in the documentation](https://railseventstore.org/docs/request_metadata/). Also the `RubyEventStore::Specification::Result` has replaced previous reader API methods. All usages of:

```ruby
client = Rails.configuration.event_store

client.read_all_streams_forward(count:  count, start: start)
client.read_all_streams_backward(count:  count, start: start)
client.read_events_forward(stream_name, count:  count, start: start)
client.read_events_backward(stream_name, count:  count, start: start)
client.read_stream_events_forward(stream_name)
client.read_stream_events_backward(stream_name)
```

need to be replaced with [new read API](https://railseventstore.org/docs/read/):

```ruby
client = Rails.configuration.event_store

client.read.from(start).limit(count).each.to_a
client.read.from(start).limit(count).backward.each.to_a
client.read.stream(stream_name).from(start).limit(count).each.to_a
client.read.stream(stream_name).from(start).limit(count).backward.each.to_a
client.read.stream(stream_name).each.to_a
client.read.stream(stream_name).backward.each.to_a
```

This change could be done using provided migrator:

```bash
bundle exec res-deprecated-read-api-migrator -m FILE_OR_DIRECTORY
```

Check the [release notes](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.30.0) for details.



Another API change has been allowed by `0.31.1`. But this was just a rename, replacing `append_to_stream` with `append` and `publish_event` with `publish`. If you use `link_to_stream` it can be also changed here to `link`. The old deprecated here method names have been removed in `0.33.0`.


With `0.34.0` a database migration was needed to add indexes for searching by event type & limit length of `event_id` field. And `0.35.0` comes with next data migration - to change `data` & `metadata` fields to `binary`


The Rails Event Store `0.37.0` comes with redesigned `aggregate_root` gem. The aggregate objects should no longer have `load` and `store` methods but you should use `AggregateRoot:Repository` implement aggregate persistence.

Instead of:

```ruby
order = Order.new.load("OrderStreamHere")
order.do_something
order.store
```

you need to:

```ruby
repository = AggregateRoot::Repository.new
order = repository.load(Order.new, "OrderStreamHere")
order.do_something
repository.store(order, "OrderStreamHere")
```

or even better:

```ruby
repository = AggregateRoot::Repository.new
repository.with_aggregate(Order.new, "OrderStreamHere") do |order|
	order.do_something
end
```


All other versions up to `1.0.0` it's just updating gem versions (remember to update also `rails_event_store-rspec`) and checking if everything is ok by running tests.


## Other noticeable changes - not covered here

Version `0.40.0`:

* Introduced `PipelineMapper` that allows composing transformations to build customized mapping solution.

Version `0.31.0`:

* Breaking: `RailsEventStore::Client#initialize` signature. Out is `event_broker:`, in `subscriptions:` and `dispatcher:`. A dispatcher is no longer an event broker dependency.

Version `0.28.0`:
* Change: Mappers (and serializers) now operate above the repository layer. If you have a custom mapper or serializer move its configuration.
* Breaking: Metadata keys are limited to symbols. Metadata values are limited to `[String, Integer, Float, Date, Time, TrueClass, FalseClass]`. Using `Hash`, `Array`, or custom objects is no longer supported.
* Breaking: Using protobuf mapper requires adding `protobuf_nested_struct` gem.

Version `0.27.0`:

* Breaking: Dropped support for `Ruby 2.2`. It might continue to work, but we no longer test it and we don't guarantee it anymore.
* Breaking: `RailsEventStore.event_repository` global configuration option was removed. Pass a repository as a dependency when initializing the client.

Version `0.19.0`:

* Breaking: `delete_stream` no longer removes events.



## Ruby & Rails versions

The issue with the additional index for SQLite goes away with the update to Rails 5.2. The support for this Rails version has been added in `0.28.0`.

Currently Rails Event Store is tested with Ruby `2.4`, `2.5` & `2.6` (it works with `2.7` but there are issues with mutation testing) and with Rails `4.2`, `5.0`, `5.1`, `5.2` (it works with `6.0` but it is not yet included in test matrix).

## When in doubts

Read the [... manual](https://github.com/RailsEventStore/rails_event_store/releases) or call the [developer's](https://arkency.com) police 🤣
