---
title: "How to migrate large database tables without a headache"
created_at: 2020-01-08 12:12:12 +0100
kind: article
publish: true
author: Paweł Pacana
tags: ["rails_event_store", "mysql", "database"]
newsletter: arkency_form
---

This is the story how we once migrated an in-house event store, that reached its limits, to Rails Event Store.

<!-- more -->

My client used to say that the reward you get for achieving success is having to deal with even more complexity afterwards.

That couldn't be more true even if only applied to the ever-accumulating database tables when your venture gets traction. One very specific aspect of this success was reaching the count of several hundred millions domain events describing what happened in this business over time.

What do you do when you realize you made some mistakes in the past and have to change the schema of such humongous table? Do you know and trust your database engine well enough to let it handle it? Can you estimate the downtime cost of such operation and most importantly — can your business and clients accept it?

At that time we used MySQL and we had no other option than to deal with it. You may be in a more fortunate situation, i.e. on Postgres :)

There are a few problems with millions of rows and hundreds of gigabytes all in a single database table:

- some schema changes involve making a copy of existing table, i.e. when changing the type of used column and having to convert existing data

- some schema changes do not happen online, in-place and may lock your table making it inaccessible for some time, the longer the bigger this table is

- being aware of what happens when your database node runs out of free space while performing the operation you wanted and how does it reclaim that allocated space on failure

- being able to estimate how long the process will take and what is current progress of it — that is being in control

See more: [Online DDL operations on MySQL](https://dev.mysql.com/doc/refman/5.6/en/innodb-online-ddl-operations.html#online-ddl-column-operations).

We knew we'd not be able to stop the world, perform the migration and resume like nothing happened. Instead we settled on small steps performed on a living organism.

The plan was more or less as follows:

- create new, empty database table with the schema you wished to have

- add a database trigger which constantly copies new records to this new database table — this component is responsible for reshaping the inserted or updated data so that it fits new schema

- with the trigger handling new records, start backfilling old records in the background — there are several hacks to make this process fast

- once the copy is done — remove the trigger, switch the tables and the code operating on them, possibly within a short downtime to avoid race conditions

- after successful switch all that is left is removing the now-old database table (as one would expect that is not as easy as it sounds)

The devil is the details. We've learned a few by making the mistakes you can avoid.

Long story short — we moved from a single table storing domain events to the schema that consists of two. The exact code of the trigger that translated custom event store schema into RES:

```sql
BEGIN
    SET @event_id = uuid();
    SET @created_at = STR_TO_DATE(SUBSTR(new.metadata, LOCATE(':timestamp: ', new.metadata) + 12, 31), '%Y-%m-%d %H:%i:%s.%f');

    INSERT INTO event_store_events_res (id, event_id, event_type, metadata, data, stream, version, created_at) VALUES  (new.id, @event_id, new.event_type, new.metadata, new.data, new.stream, new.version, @created_at);

    IF new.stream = '$' THEN
        INSERT INTO event_store_events_in_streams (stream, event_id, created_at) VALUES ('all', @event_id, @created_at);
    ELSE
        INSERT INTO event_store_events_in_streams (stream, position, event_id, created_at) VALUES (new.stream, new.version, @event_id, @created_at);
        INSERT INTO event_store_events_in_streams (stream, event_id, created_at) VALUES ('all', @event_id, @created_at);
    END IF;
END
```

One thing to remember is that you wouldn't want a conflict between backfilled rows and the ones inserted by a trigger. So did we and set the auto increment to be large enough. Backfilled rows would get a value on an auto-incremented column set by us.

```sql
ALTER TABLE event_store_events_in_streams AUTO_INCREMENT = 210000000
```

Below is the script we have used initially to backfill existing records into new tables.

```ruby
require 'ruby-progressbar'
require 'activerecord-import'

MIN_ID     = ARGV[0].to_i
MAX_ID     = ARGV[1].to_i
BATCH_SIZE = (ARGV[2] || 1000).to_i

class EventV2 < ActiveRecord::Base
  self.primary_key = :id
  self.table_name  = 'event_store_events_res'
end

class StreamV2 < ActiveRecord::Base
  self.primary_key = :id
  self.table_name  = 'event_store_events_in_streams'
end

progress =
  ProgressBar.create(
    title: "event_store_events_res",
    format: "%a %b\u{15E7}%i %e %P% Processed: %c from %C",
    progress_mark: ' ',
    remainder_mark: "\u{FF65}",
    total: MAX_ID - MIN_ID,
  )

streams_with_position     = []
ignore_position_in_steams = []
stream_id = StreamV2.where('id < 340000000').order(:id).last&.id || 0


(MIN_ID...MAX_ID).each_slice(BATCH_SIZE) do |range|
  ActiveRecord::Base.transaction do
    events  = []
    streams = []
    EventStore::Repository::Event
      .where('id >= ? AND id <= ?', range.first, range.last)
      .each do |event|
           event_id = SecureRandom.uuid
           timestamp = YAML.load(event.metadata).fetch(:timestamp)

           events << EventV2.new(event.attributes.merge(event_id: event_id, created_at: timestamp))

           if event.stream == "$"
             stream_id += 1
             streams << StreamV2.new(id: stream_id, stream: 'all', position: nil, event_id: event_id, created_at: timestamp)
           else
             position = event.version if streams_with_position.any?{|s| event.stream.starts_with?(s)} && !ignore_position_in_steams.include?(event.stream)
             stream_id += 1
             streams << StreamV2.new(id: stream_id, stream: event.stream, position: position, event_id: event_id, created_at: timestamp)
             stream_id += 1
             streams << StreamV2.new(id: stream_id, stream: 'all', position: nil, event_id: event_id, created_at: timestamp)
           end
    end
    EventV2.import(events)
    StreamV2.import(streams)
    progress.progress += range.size
  end
end
```

Key takeaways:

- `find_in_batches` API has not been used deliberately

  Iterating with OFFSET and LIMIT on MySQL just does not meet any reasonable performance expectations on large tables. Scoping batches on `id` scaled pretty well on the other hand.  


- it is better to have fewer `INSERT` statements, which carry more rows to be added

  One `INSERT` adding 1000 rows works faster than 1000 inserts each with one row. It is also worth noting there is a point in which having larger inserts does not help. You have to find a value that works for you best.
  Using `activerecord-import` is one option. Another is the bulk import which arrived with [Rails 6](https://github.com/rails/rails/pull/35077).

- the less constrains and indexes during import, the faster it is

  Don't forget to finally add them though. You may find yourself in a situations where a query that does full table scan on a table with several hundreds millions of rows ;)

Plan how much disk space you will need to fit a copy of such a large table over an extended period of time. You may be surprised to actually need more than the old table due to different indexes. In case you run out if that precious disk space, be prepared to [reclaim](https://www.percona.com/blog/2013/09/25/how-to-reclaim-space-in-innodb-when-innodb_file_per_table-is-on/) [it](https://www.cyberciti.biz/faq/what-is-mysql-binary-log/) and it does not happen immediately.
  
With all events in the new tables we were able to do the switch. In order to avoid any race conditions we have decided on a deployment with barely noticeable downtime:

```ruby
class DropEventStoreEventsResTrigger < ActiveRecord::Migration[5.2]
  def change
    execute 'DROP TRIGGER migrate_bes'
  end
end
```

Last but not least — removing the leftovers. We've learned, the hard way, it [worked best with batches](http://mysql.rjweb.org/doc.php/deletebig).

Dealing with large database tables is definitely a different beast. Nevertheless this skill can be practiced and mastered like any else. Know your database engine better, execute in small steps and profit.

Have you been in a similar situation? What did you do and which tools made your task easier?
