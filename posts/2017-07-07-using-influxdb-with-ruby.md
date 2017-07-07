---
title: "Using influxdb with ruby"
created_at: 2017-07-07 15:12:05 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'chillout', 'influxdb' ]
img: ruby-influxdb-chillout/pdfs_orders2.png
---

InfluxDB is an open-source time series database, written in Go. It is optimized for fast, high-availability storage and retrieval of time series data in fields such as operations monitoring, application metrics and real-time analytics.

We use it in [chillout](https://get.chillout.io) for storing business and performance metrics sent by our [collector](https://github.com/chilloutio/chillout).

<!-- more -->

> InfluxDB storage engine looks very similar to a LSM Tree. It has a write ahead log and a collection of read-only data files which are similar in concept to SSTables in an LSM Tree. TSM files contain sorted, compressed series data.

If you wonder how it works I can provide you a very quick tour based on the [The InfluxDB Storage Engine documentation](http://docs.influxdata.com/influxdb/v1.2/concepts/storage_engine/) and what I've learnt from a _Data Structures that Power your DB_ part in [Designing Data Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems](https://www.amazon.com/gp/product/1449373321/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1449373321&linkCode=as2&tag=arkency-20&linkId=2d9f6564fa4056f6f6966bf3400049b0)

1. First, arriving data is written to a WAL (Write Ahead Log). The WAL is a write-optimized storage format that allows for writes to be durable, but not easily queryable. Writes to the WAL are appended to segments of a fixed size.

  The WAL is organized as a bunch of files that look like _000001.wal. The file numbers are monotonically increasing and referred to as WAL segments. When a segment reaches certain size, it is closed and a new one is opened.

2. The database has an in-memory cache of all the data written to WAL. In case of crash and restart this cache is recreated from scratch based on the data written to WAL file.

  When a write comes it is written to a WAL file, synced and added to an in-memory index.

3. From time to time (based on both size and time interval) the cache of latest data is snapshotted to disc (as Time-Structured Merge Tree File).

  The DB also needs to clear the in-memory cache and can clear WAL file.

  The structure of these TSM files looks very similar to an SSTable in LevelDB or other LSM Tree variants.

4. In the background these files can be compacted and merged together to form bigger files.

[The documentation](http://docs.influxdata.com/influxdb/v1.2/concepts/storage_engine/) has a nice historical overview how previous version of InfluxDB tried to use LevelDB and BoltDB as underlying engines but it was not enough for most demanding scenarios.

I must admin that I never really understood very deeply how DBs work under the hood and what are the differences between them (from the point of underlying technology and design, not from the point of APIs, query languages and features).

The book that I mentioned [Designing Data Intensive Applications](https://www.amazon.com/gp/product/1449373321/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1449373321&linkCode=as2&tag=arkency-20&linkId=2d9f6564fa4056f6f6966bf3400049b0) really helped me understand it.

Let's go back to using InfluxDB in Ruby.

## influxdb-ruby gem

For me personally, [influxdb-ruby](https://github.com/influxdata/influxdb-ruby) gem seems to just work.

### writes

```
require 'influxdb'
influxdb = InfluxDB::Client.new
influxdb.write_point(, {
  series: 'orders',
  values: {
    started: 1,
    number_of_products: 4,
    total_amount: 55.70,
    tax: 5.70,
  },
  tags:   {
    country: "USA",
    terminal: "KATE-123",
  }
})
```

The difference between tags and values is that tags are always automatically indexed.

> Queries that use field values as filters must scan all values that match the other conditions in the query. As a result, those queries are not performant relative to queries on tags.


## reads

However InfluxQL query language (similar to SQL but not really it) really shines when it comes to returning data grouped by time periods, which is great for metrics.

#### raw data using influxdb console

```
SELECT
  sum(completed)/sum(started) AS ratio
FROM orders
WHERE time >= '2017-07-05T00:00:00Z'

GROUP BY time(1d)
```

```
name: orders
time                ratio
----                -----
1499212800000000000 0.8
1499299200000000000 0.7
1499385600000000000 0.6
```

where `Time.at(1499212800).utc` is `2017-07-05 00:00:00 UTC` and
`Time.at(1499299200).utc` is `2017-07-06 00:00:00 UTC`.

#### influxdb-ruby

Using the gem you can easily query for the data using InfluxQL and get these values nicely formatted.

```
#!ruby
influxdb.query "select sum(completed)/sum(created) as ratio FROM orders WHERE time >= '2017-07-05T00:00:00Z' group by time(1d)"

[{
  "name"=>"orders",
  "tags"=>nil,
  "values"=>[
    {"time"=>"2017-07-05T00:00:00Z", "ratio"=>0.8},
    {"time"=>"2017-07-06T00:00:00Z", "ratio"=>0.7},
    {"time"=>"2017-07-07T00:00:00Z", "ratio"=>0.6}
  ]
}]
```

## What for?

For dashboards and graphs, monitoring and alerting. For business metrics:

<%= img_fit("ruby-influxdb-chillout/pdfs_orders2.png") %>
<%= img_fit("ruby-influxdb-chillout/trainings_games2.png") %>

And performance metrics (monitoring http and sidekiq):

<%= img_fit("ruby-influxdb-chillout/average_response_time_rails_chillout2.png") %>