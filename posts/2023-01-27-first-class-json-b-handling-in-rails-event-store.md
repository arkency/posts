---
created_at: 2023-01-27 18:54:42 +0100
author: Szymon Fiedler
tags: ['rails event store', 'json', 'jsonb', 'time']
publish: true
---

# First class json(b) handling in Rails Event Store

Recently, in _Rails Event Store_ [v2.8.0](https://github.com/RailsEventStore/rails_event_store/releases/tag/v2.8.0) `PreserveTypes` transformation has been introduced. [v2.9.0](https://github.com/RailsEventStore/rails_event_store/releases/tag/v2.9.0) release brought `RailsEventStore::JSONClient`. It's a set of great improvements for RES users who plan to or already use PostgreSQL with `jsonb` data type for keeping events' `data` and `metadata`.

<!-- more -->
## Back to the primitive

According to [RFC 4627](https://www.ietf.org/rfc/rfc4627.txt) JSON can represent four primitive types:
- strings
- numbers
- booleans
- null

and two structured types:
- objects
- arrays

When `data` is serialised to JSON format with `JSON.dump` or `ActiveSupport::JSON.encode`, which happens implicitly when persisting event, the `data` need to be converted to primitives or structured types.

Given event `data`:

```ruby
{
    boolean: true,
    nothing: nil,
    string: "hello",
    symbol: :baz,
    int: 123,
    float: 1.23,
    big_decimal: BigDecimal("1.23"),
    array: [1, 2, 3],
    hash: { foo: :bar },
    date: Date.current,
    time: Time.now,
    active_support_time_with_zone: Time.current,
}
```

becomes in the database:

```json
{ 
  "boolean": true,
  "nothing: null,
  "string": "hello",
  "symbol": "baz",
  "int": 123,
  "float": 1.23,
  "big_decimal": "1.23",
  "array": [1,2,3],
  "hash": {"foo":"bar"},
  "date": "2023-01-27",
  "time": "2023-01-27 16:11:04 +0100",
  "active_support_time_with_zone": "2023-01-27 15:11:04 UTC"
}
```

As expected, everything was converted to JSON's primitives. There are slight difference between `JSON.dump` and `ActiveSupport::JSON.encode` when it comes to time serialization (it's more precise), but it doesn't matter for this example.

## We will get our data types back... Right?

What happens when we want to read the event and access it's `data`?

```ruby
{
  "boolean" => true,
  "nothing" => nil,
  "string" => "hello",
  "symbol" => "baz",
  "int" => 123,
  "float" => 1.23,
  "big_decimal" => "1.23",
  "array"=> [1, 2, 3],
  "hash"=> {"foo"=>"bar"},
  "date"=> "2023-01-27",
  "time"=> "2023-01-27 16:17:13 +0100",
  "active_support_time_with_zone"=> "2023-01-27 15:17:13 UTC"
}
```

Short list of problems that will occur:

1. Keys in the hash are no longer symbols, if your code used to access event's data values by the symbol, you'll get `nil` or `KeyError` when using `.fetch` method. The same goes with symbols in values, they will become strings.
2. `BigDecimal` remained a string.
3. `Date` is as string.
4. `Time` and `ActiveSupport::TimeWithZone` are strings either
5. Information about time precision (fraction of seconds) is also lost.

## How we resolved those problems in Rails Event Store and why we even face them?

For a long time, our recommended setup was `binary` column type for storing events `data` and `metadata` and [YAML serializer](https://railseventstore.org/docs/v2/mapping_serialization/):

> The reason is that YAML is available out of box and can serialize and deserialize data types which are not easily handled in other formats.

However, we had found out that if you're on PostgreSQL, it's good to use its native _jsonb_ type for storing `data` and `metadata`. Using [JSON types in postgres](https://www.postgresql.org/docs/current/datatype-json.html) has a lot of benefits, e.g. you can query event data or metadata using SQL and find events of your interest based on their payload. We would love to expose API for that in Rails Event Store one day. 

There are numerous ways to solve the problems mentioned above your Rails Event Store events. Implementing custom event class with schema is one solution, the other would be to implement a custom transformation and a mapper.


## JSONClient and PreserveTypes transformation to the rescue

We decided to provide sane defaults not to bother users with advanced configuration. Newly introduced [RailsEventStore::JSONClient](https://railseventstore.org/docs/v2/install/#client-for-jsonb-data-type) incorporates mapper containing `PreserveTypes` transformation.

`PreserveTypes` allows registering serializer and deserializer for any type of data you wish to put in your event's `data` or `metadata`. Meaning that event published with `data`: 

```ruby
{
    boolean: true,
    nothing: nil,
    string: "hello",
    symbol: :baz,
    int: 123,
    float: 1.23,
    big_decimal: BigDecimal("1.23"),
    array: [1, 2, 3],
    hash: { foo: :bar },
    date: Date.current,
    time: Time.now,
    active_support_time_with_zone: Time.current,
}
```

after persisting and reading it again will represent originally intended data types:

```ruby
{
    boolean: true,
    nothing: nil,
    string: "hello",
    symbol: :baz,
    int: 123,
    float: 1.23,
    big_decimal: 0.123e1,
    array: [1, 2, 3],
    hash: { foo: :bar },
    date: Fri, 27 Jan 2023,
    time: 2023-01-27 18:06:32.647146 +0100,
    active_support_time_with_zone: Fri, 27 Jan 2023 17:06:46.914852000 UTC +00:00,
}
```

Here's `PreserveTypes` configuration extracted from [`RailsEventStore::JSONClient`](https://github.com/RailsEventStore/rails_event_store/blob/2e5c3ab33e60696f207d52f690ae06cc6bb44fdc/rails_event_store/lib/rails_event_store/json_client.rb)

```ruby
RubyEventStore::Mappers::Transformation::PreserveTypes
  .new
  .register(
    Symbol,
    serializer: ->(v) { v.to_s },
    deserializer: ->(v) { v.to_sym }
  )
  .register(
    Time,
    serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
    deserializer: ->(v) { Time.iso8601(v) }
  )
  .register(
    ActiveSupport::TimeWithZone,
    serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
    deserializer: ->(v) { Time.iso8601(v).in_time_zone },
    stored_type: ->(*) { "ActiveSupport::TimeWithZone" }
  )
  .register(
    Date,
    serializer: ->(v) { v.iso8601 },
    deserializer: ->(v) { Date.iso8601(v) }
  )
  .register(
    DateTime,
    serializer: ->(v) { v.iso8601 },
    deserializer: ->(v) { DateTime.iso8601(v) }
  )
  .register(
    BigDecimal,
    serializer: ->(v) { v.to_s },
    deserializer: ->(v) { BigDecimal(v) }
  )
```

As you noticed, the configuration is pretty simple, we expect both serializer and deserializer to respond to `call` and accept single argument with value. 

Primitive types like `String` or `Integer` require no serialization, original value will be passed. It also won't be deserialized on read.

If you're curious how `PreserveTypes` transformation is implemented, feel free to look at the [source code](https://github.com/RailsEventStore/rails_event_store/blob/2e5c3ab33e60696f207d52f690ae06cc6bb44fdc/ruby_event_store/lib/ruby_event_store/mappers/transformation/preserve_types.rb#L6).

## Quirks

### Look at me, I'm `Time` now

During implementation, we figured out that there's a quirk around `ActiveSupport::TimeWithZone`. We rely on on [Module#name](https://ruby-doc.org/3.2.0/Module.html#method-i-name) to recognize object class name. It turned out that `ActiveSupport::TimeWithZone.name` [for unknown reason](https://github.com/rails/rails/blob/f86a5295595517a557d17800a538c7a34113b083/activesupport/lib/active_support/time_with_zone.rb#L44-L53) will return `Time`. Obviously this broke deserialization of this particular type, since the wrong one was picked by transformation. For this reason we introduced another parameter called `stored_type` which expects object responding to `call`, returning a string containing class name.

### Additional metadata is persisted

Yes, it will take additional space in your database, but it's the sacrifice we're ready for. Event's `metadata` along with standard information will store information about `types`:

```json
{
  "types": {
    "data": {
      "boolean": ["Symbol","TrueClass"],
      "nothing": ["Symbol","NilClass"],
      "string": ["Symbol","String"],
      "symbol": ["Symbol","Symbol"],
      "int": ["Symbol","Integer"],
      "float": ["Symbol","Float"],
      "big_decimal": ["Symbol","BigDecimal"],
      "array": ["Symbol",["Integer","Integer","Integer"]],
      "hash": ["Symbol",{"foo":["Symbol","Symbol"]}],
      "date": ["Symbol","Date"],
      "time" :["Symbol","Time"],
      "active_support_time_with_zone": ["Symbol","ActiveSupport::TimeWithZone"]
   },
   "metadata":{
     "correlation_id":["Symbol","String"]
   }
}
```

First element in the array represents type of the key, the other one — value's.

This is completely transparent operation, you won't see this data when reading event in your console:

```ruby
irb(main):021:0> event_store.read.last
  RubyEventStore::ActiveRecord::Event Load (1.3ms)  SELECT "event_store_events".* FROM "event_store_events" ORDER BY "event_store_events"."id" DESC LIMIT $1  [["LIMIT", 1]]
=>
#<OopsIDidItAgain:0x000000011265f7d0
 @data=
  {:int=>123,
   :date=>Fri, 27 Jan 2023,
   :hash=>{:foo=>:bar},
   :time=>2023-01-27 18:23:58.607724 +0100,
   :array=>[1, 2, 3],
   :float=>1.23,
   :string=>"hello",
   :symbol=>:baz,
   :boolean=>true,
   :nothing=>nil,
   :big_decimal=>0.123e1,
   :active_support_time_with_zone=>Fri, 27 Jan 2023 17:23:58.607731000 UTC +00:00},
 @event_id="df6c5c48-06da-47ff-90ae-1b76eb6ceeaf",
 @metadata=
  #<RubyEventStore::Metadata:0x000000011265f780
   @h=
    {:correlation_id=>"d55c851d-97e8-4dc4-880c-cafcea3e9c49",
     :timestamp=>2023-01-27 17:24:29.831713 UTC,
     :valid_at=>2023-01-27 17:24:29.831713 UTC}>>
```

nor in the [Browser](https://railseventstore.org/docs/v2/browser/).

## Summary

Running on `JSONClient` with `PreserveTypes` provides seamless type handling. It removes all the disadvantages which using _JSON_ brought as compared to _YAML_ serialization within binary column. It opens new possibilities like ability to query events' `data` and `metadata` via SQL interface and RES interface in the future. It's also a nice alternative to event schemas used solely for type casting which can be sometimes [slow](https://github.com/pawelpacana/res-event-schema-comparison). 

