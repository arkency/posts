---
title: Multitenancy with Postgres schemas: key concepts explained
created_at: 2020-10-07T14:59:25.990Z
author: Tomasz Wróbel
tags: ['postgresql', 'multitenancy']
publish: true
---

# Multitenancy with Postgres schemas: key concepts explained

PostgreSQL _schemas_ let you hold multiple instances of the same set of tables inside a single database. They're essentially **namespaces for tables**. Sounds like a compelling way to implement multitenancy — [at least in specific cases](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/). But if you're like me, you'd rather know exactly how it works before you rush to implement it. Let's explain some basic concepts first: _schema_ itself, _search_path_ and _session_.

## PostgreSQL schema

As I said before _schema_ is basically a collection of tables (and other db "objects"). _Schema_ is not the most fortunate name for it, as it can be confused with db schema in the sense of db structure. _Namespace_ would be a more adequate name. Actually _namespace_ is how PG calls it in some contexts - e.g. in `pg_namespace` catalog.

Let's open `psql` and play a little.

Even before you create any schemas yourself, there's already one schema there - the default schema, named `public`. You can see it by listing all schemas with the psql command `\dn`.

Alternatively, if you run `select * from pg_namespace;` you'll also see all schemas — along with some internal ones.

`public` schema is where all your tables live by default - if you don't specify any specific schema. So if you create a table `CREATE TABLE things (name text)` it just ends up in the public schema, which you'll see when listing all the tables with `\dt` (of course provided you haven't changed the `search_path` - see next section).

```
my-db::DATABASE=> \dt
            List of relations
 Schema |  Name  | Type  |     Owner
--------+--------+-------+----------------
 public | things | table | ydhtoowbnonxqk
(1 row)
```

Now let's create a new schema: `CREATE SCHEMA tenant_1`. You should now see another entry if you list all existing schemas with `\dn`:

```
my-db::DATABASE=> \dn
     List of schemas
   Name   |     Owner
----------+----------------
 public   | ydhtoowbnonxqk
 tenant_1 | ydhtoowbnonxqk
```

Now we can create a table inside this schema. You can do it by prefixing the table name with the schema name and a dot: `CREATE TABLE tenant_1.things (name text)`.

You won't see it when listing all tables with `\dt` (again, provided you haven't yet changed the `search_path`). To list the table, run `\dt` with an additional param:

```
my-db::DATABASE=> \dt tenant_1.*
             List of relations
  Schema  |  Name  | Type  |     Owner
----------+--------+-------+----------------
 tenant_1 | things | table | ydhtoowbnonxqk
```

So at this moment we should have two tables named `things` which live in separate namespaces (schemas). To interact with them, you just prefix the table name with the schema name and a dot:

```sql
SELECT * FROM tenant_1.things;
SELECT * FROM public.things;
SELECT * FROM things;  -- will query the default schema
```

To get rid of the schema, run `DROP SCHEMA tenant_1;`. It'll fail in this situation though, because there are tables in it. To remove it together with the tables, run `DROP SCHEMA tenant_1 CASCADE;`.

## PostgreSQL search_path

So far we accessed other schemas by using their fully qualified name: `schema_name.table_name`. If we skip the schema name, the default schema is used — `public`. Now, `search_path` is a Postgres session variable that determines which schema is the default one. Let's check its value:

```
my-db::DATABASE=> SHOW search_path;                                                                                                                        search_path
-----------------
 "$user", public
```

As you can see, it has a couple comma-separated values. It works similarly to `PATH` in a shell — if you try to access a table, Postgres first looks for it in the first schema listed in the `search_path` — which is `"$user"`. If it cannot find it there, it looks in the second one — `public`. If it's not there, then we get an error. 

Now `"$user"` is a special value that makes it actually look for a schema named after the user. Personally I've never used it. It's just there by default. The ability to use multiple schemas also looks like a feature I'd rather not use, but sometimes you have to - e.g. to handle Postgres extensions - [more here](https://blog.arkency.com/what-surprised-us-in-postgres-schema-multitenancy/).

To change the search path, run: `SET search_path = tenant_1`. If you now run `SELECT * FROM things`, it will access `tenant_1.things`.

To get back, you typically do `SET search_path = public` — or whatever is your default. Sidenote: in Rails you can set your default schema via `schema_search_path` option in `database.yml`.

A good question to ask: what is the scope and lifetime of this variable. This is a _session_ variable, i.e. it affects the current Postgres session and is discarded when the session closes.

Sidenote: there's a variant — `SET LOCAL` which works for a transaction instead of a session, but personally I've never had to use it. Another sidenote: `search_path` resolution is actually more complex — apart from aforementioned session variable, it can be also permanently set for the whole DB or role.

## PostgreSQL session

Now it makes sense to explain what exactly a Postgres session is — when it's initiated and closed.

Postgres session, depending on context, might be referred to as _Postgres connection_ or _backend_.  

Under normal circumstances, whenever you establish a new connection to Postgres (e.g. via `psql` or from Rails), a new Postgres session is instantiated. It's closed when the connection closes. That perhaps explains the interchangeable usage of _session_ and _connection_. 

Actually when you get hold of a DB connection in Rails, you don't always get a new DB connection — because there's a _connection pool_ ([read more here](https://blog.arkency.com/rails-connections-pools-and-handlers/)). Connection pool is there to limit the number of DB connections Rails app can make. From the perspective of Postgres sessions, a **crucial fact** is that the DB connection is not necessarily closed if a Rails request releases it — it stays in the pool and might be used by a different request later. The consequence is that if you `SET` a Postgress session variable in one request, it'll be set in the next one — if it happens to run on the same DB connection. That's why you have to make sure you always SET the desired search_path before you do any DB work in a request or background job. 

Every session gets a separate OS process on the DB server, which you can check yourself by running e.g. `ps aux | grep postgres`. You can also see the sessions by querying `SELECT * FROM pg_stat_activity` — there's a lot of useful data in it.

Now it's worth saying that even if Rails makes an actual new connection to the DB, it usually means a new connection on the DB server, but not always — it depends on what stands inbetween the Rails app and the DB server. If you happen to have **PgBouncer** in your stack, sessions are managed by it. If PgBouncer runs in any mode different than _session mode_, you can even end up **mixing tenant's data**.  — [read more here](https://blog.arkency.com/what-surprised-us-in-postgres-schema-multitenancy/).

If you want to know what session you're currently on, you may use `pg_backend_pid()`. It's basically the PID of this session's _backend_ (OS process).

```ruby
p ActiveRecord::Base.connection.execute("select pg_backend_pid()").first
```

<!-- ## Rails DB connection -->
<!-- not always 1-1 with pg connections -->

<!--  **Rails DB connection pool** — in short: _Connection Handler_ has many _Connection Pools_ has many _Connections_. [More here](https://blog.arkency.com/rails-connections-pools-and-handlers/). -->

<!-- ## Questions you might have -->

<!-- **How do you typically switch to a different tenant in a Rails app?** -->

<!-- **How do you do it in ActiveRecord?** -->
