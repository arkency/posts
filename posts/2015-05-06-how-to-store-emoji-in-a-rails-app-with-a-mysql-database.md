---
title: "How to store emoji in a Rails app with a MySQL database"
created_at: 2015-05-06 14:34:08 +0200
kind: article
publish: true
author: Jakub Kosiński
tags: [ 'mysql', 'unicode', 'emoji', 'rails', 'utf8mb4' ]
newsletter: :arkency_form
img: "how-to-store-emoji-in-a-rails-app-with-a-mysql-database/emoji.png"
---

<p>
  <figure align="center">
    <img src="<%= src_fit("how-to-store-emoji-in-a-rails-app-with-a-mysql-database/emoji.png") %>">
  </figure>
</p>

Suppose you have a Rails app and you are storing your data in a MySQL database. You were requested to add emoji support to your application. Probably you are thinking:

> Oh, that's simple, it's just unicode, isn't it?

The answer is: **no**. Unfortunately, MySQL's `utf8` character set allows to store only a subset of Unicode characters - only those characters that consist of one to three bytes. Inserting characters that require 4 bytes would result in corrupted data in your database.

<!-- more -->

# Problems with `utf8` character set

Look at this example:

```
mysql> SET NAMES utf8;
Query OK, 0 rows affected (0,00 sec)

mysql> INSERT INTO messages (message) VALUES ('What a nice emoji😀!');
Query OK, 1 row affected, 1 warning (0,00 sec)

mysql> SHOW WARNINGS;
+---------+------+---------------------------------------------------------------------------+
| Level   | Code | Message                                                                   |
+---------+------+---------------------------------------------------------------------------+
| Warning | 1366 | Incorrect string value: '\xF0\x9F\x98\x80!' for column 'message' at row 1 |
+---------+------+---------------------------------------------------------------------------+
1 row in set (0,00 sec)

mysql> SELECT message FROM messages;
+-------------------+
| message           |
+-------------------+
| What a nice emoji |
+-------------------+
1 row in set (0,00 sec)
```

As you can see, using `utf8` character set is not enough. You are getting a warning and your data is truncated at the first 4-bytes unicode character.

# `utf8mb4` to the rescue

[MySQL 5.5.3](https://dev.mysql.com/doc/relnotes/mysql/5.5/en/news-5-5-3.html) introduced new character set - `utf8mb4` that maps to _real_ UTF-8 and fully support all Unicode characters, including 4-bytes emoji. It is fully backward compatible, so there should be no data loss during migrating your database. You just need to convert your tables to the new character set and change your connection's settings. You can do it in migration:

```
#!ruby
class ConvertDatabaseToUtf8mb4 < ActiveRecord::Migration
  def change
    # for each table that will store unicode execute:
    execute "ALTER TABLE table_name CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
    # for each string/text column with unicode content execute:
    execute "ALTER TABLE table_name CHANGE column_name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end
end
```

Please notice the `VARCHAR(191)` fragment. There is one important thing you should know - when switching to `utf8mb4` charset, the maximum length of a column or index key is the same as in `utf8` charset in terms of bytes. This means it is smaller in terms of characters, since the maximum length of a character in `utf8mb4` is four bytes, instead of three in `utf8`. The maximum index length of InnoDB storage engine is 767 bytes, so if you are indexing your `VARCHAR` columns, you would need to change their length to 191 instead of 255.

You should also change your `database.yml` and add encoding and (optionally) collation keys:

```
production:
  # ...
  encoding: utf8mb4
  collation: utf8mb4_bin
```

Now you are ready to handle emoji 👍

# Rails, why you don't like `utf8mb4`?

After changing character set, you may experience the `Mysql2::Error: Specified key was too long; max key length is 767 bytes: CREATE UNIQUE INDEX` error when performing `rake db:migrate` task. It is related to the InnoDB maximum index length described in previous section. There is [a fix](https://github.com/rails/rails/commit/8744632fb5649cf26cdcd1518a3554ece95a401b) for `schema_migrations` table in Rails 4+, however you still can experience this error on tables created by yourself. As far as I am concerned this is still not fixed in Rails 4.2. You can resolve this issue in two ways:

* You can monkey patch `ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES` using the following initializer:

  ```
  #!ruby
  # config/initializers/mysql_utf8mb4_fix.rb
  require 'active_record/connection_adapters/abstract_mysql_adapter'

  module ActiveRecord
    module ConnectionAdapters
      class AbstractMysqlAdapter
        NATIVE_DATABASE_TYPES[:string] = { :name => "varchar", :limit => 191 }
      end
    end
  end
  ```

* You can also switch to [`DYNAMIC` MySQL table format](http://dev.mysql.com/doc/refman/5.6/en/innodb-parameters.html#sysvar_innodb_large_prefix) add add `ROW_FORMAT=DYNAMIC` to your `CREATE TABLE` calls when creating new tables in migrations (that would increase the maximum key length from 767 bytes to 3072 bytes):

  ```
  #!ruby
  create_table :table_name, options: 'ROW_FORMAT=DYNAMIC' do |t|
    # ...
  end
  ```

You wouldn't experience this issues when using PostgreSQL, but sometimes you just have to support legacy application that uses MySQL and migrating data to other RDBMS may not be an option.

## More

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
