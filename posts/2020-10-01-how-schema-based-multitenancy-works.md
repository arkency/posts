---
title: How schema-based multitenancy works
created_at: 2020-10-01T09:29:21.528Z
author: Tomasz Wróbel
tags: ['postgresql', 'multitenancy']
publish: false
---

# How Postgres-schema based multitenancy works

PostgreSQL _schemas_ let you hold multiple instances of the same set of tables inside a single database. They're essentially namespaces for tables. Sounds like a simple way to implement multitenancy — at least in [specific cases](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/). But if you're like me, you'd rather know exactly how it works before you rush to implement it. Let's explain basic concepts first.

## PostgreSQL schema

As I said before _schema_ is basically a collection of tables (and other db objects). _Schema_ is not the most fortunate name for it, as it can be confused with db schema in the sense of db structure. _Namespace_ would be a more adequate name. Actually _namespace_ is how PG calls it in some contexts - e.g. in `pg_namespace` catalog.

Let's open `psql` and play a little.

Even before you create any schemas yourself, there's already one schema there - the default schema, named `public`. You can see it by listing all schemas with the psql command `\dn`:

```
protos-eschatos::DATABASE=> \dn
     List of schemas
  Name  |     Owner
--------+----------------
 public | ydhtoowbnonxqk
(1 row)
```

If you run `select * from pg_namespace;` you'll also see all schemas — along with some internal ones.

`public` schema is where all your tables live by default - if you don't specify any specific schema. So if you create a table `CREATE TABLE things (name text);` it just ends up in the public schema, which you'll see when listing all the tables with `\dt` (of course provided you haven't changed the `search_path` - see next section).

```
protos-eschatos::DATABASE=> \dt
            List of relations
 Schema |  Name  | Type  |     Owner
--------+--------+-------+----------------
 public | things | table | ydhtoowbnonxqk
(1 row)
```

Now let's create a new schema:

```
CREATE SCHEMA tenant_1;
```

You should now see another entry if you list all existing schemas with `\dn`:

```
      List of schemas
   Name   |     Owner
----------+----------------
 public   | ydhtoowbnonxqk
 tenant_1 | ydhtoowbnonxqk
(2 rows)
```

Now we can create a table inside this schema. You can do it by prefixing the table name with the schema name and a dot:

```
CREATE TABLE tenant_1.things (name text);
```

You won't see it when listing all tables with `\dt` (again, provided you haven't yet changed the `search_path`). To list the table, run `\dt` with an additional param:

```
protos-eschatos::DATABASE=> \dt tenant_1.*
             List of relations
  Schema  |  Name  | Type  |     Owner
----------+--------+-------+----------------
 tenant_1 | things | table | ydhtoowbnonxqk
(1 row)
```

So at this moment we should have two tables named `things` which live in separate namespaces (schemas). To interact with them, you just prefix the table name with the schema name and a dot:

```
SELECT * FROM tenant_1.things;
SELECT * FROM public.things;
SELECT * FROM things;             -- will query the default schema
```

To get rid of the schema, run `DROP SCHEMA tenant_1;`. It'll fail in this situation though, because there are tables in it. To remove it together with the tables, run `DROP SCHEMA tenant_1 CASCADE;`.

## PostgreSQL search_path

current schema

session based (but not only)

```
protos-eschatos::DATABASE=> show search_path;                                                                                                                        search_path
-----------------
 "$user", public
(1 row)
```

## PostgreSQL session

(sometimes referred to as _connection_ or _backend_).

```
protos-eschatos::DATABASE=> select * from pg_stat_activity;
```

pid, `ps aux`.

pg "session features"

## Rails DB connection

not always 1-1 with pg connections

**Rails DB connection pool** — in short: _Connection Handler_ has many _Connection Pools_ has many _Connections_. [More here](https://blog.arkency.com/rails-connections-pools-and-handlers/).

## Questions you might have

**How do you typically switch to a different tenant in a Rails app?**

**How do you do it in ActiveRecord?**

