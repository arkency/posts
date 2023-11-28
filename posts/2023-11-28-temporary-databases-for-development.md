---
created_at: 2023-11-28 12:00:00 +0100
author: Paweł Pacana
tags: []
publish: false
---

# Temporary databases for development

At RailsEventStore we have quite an extensive test suite to ensure that it runs smoothly on all supported database engines. That includes PostgreSQL, MySQL and Sqlite in several versions — not only newest but also the oldest-supported releases.

Setting up this many one-time databases and versions is now a mostly solved problem on CI, where each test run gets its own isolated environment. In development, at least on MacOS things are a bit more ambiguous.

Let's scope this problem a bit — you need to run a test suite for the database adapter on PostgreSQL 11 as well as PostgreSQL 15:

1. With `brew` that's a lot of gymnastics. First getting both versions installed at desired major versions. Then perhaps linking to switch currently chosen version, starting database service in the background, ensuring header files are in path to compile `pg` gem and so on. In the end you also have to babysit any accumulated state.

2. An obvious solution seems to be introducing `docker`, right? Having many separate `Dockerfile` files describing database services in desired versions. Or just one starting many databases at different external ports from one `Dockerfile`. Any database state being discarded on container exit is a plus too. That already brings much needed convenience over plain `brew`. The only drawback is probably the performance — not great, not terrible.

What if I told you there's a third option? And that database engines on UNIX-like systems already have that built-in?

## The UNIX way

Before revealing the solution let's briefly present the ingredients:

1. Temporary files and directories. Convenience `mktemp` mechanism to generate unique, non-conflicting paths on disk. If these are created on `/tmp` partitions there's an additional benefit of operating system performing the cleanup periodically.

2. UNIX socket — an inter-process data exchange mechanism, where the address is on the file system. With TCP sockets one would address it by host:port and go through IP stack and routing. Here we connect to the path on disk and the access is controlled by its permissions. For example `/tmp/tmp.iML7fAcubU`.

3. Operating system process — our smallest unit of isolation. Such processes are identified by PID numbers. Knowing such identifier lets us control the process after we send it into the background.

Knowing all this, here's the raw solution:

```sh
TMP=$(mktemp -d)
DB=$TMP/db
SOCKET=$TMP

initdb -D $DB
pg_ctl -D $DB \
  -l $TMP/logfile \
  -o "--unix_socket_directories='$SOCKET'" \
  -o "--listen_addresses=''\'''\'" \
  start

createdb -h $SOCKET rails_event_store
export DATABASE_URL="postgresql:///rails_event_store?host=$SOCKET"
```

First we create a temporary base directory with `mktemp -d`. What we get from it is some random and unique path, i.e. `/tmp/tmp.iML7fAcubU`. This is the base directory under which we'll host UNIX socket, database storage files and logs that database process produces when running in the background.

Next the database storage has to be seeded with `initdb` at the designated directory. Then a postgres process is started via `pg_ctl` in the background. It is just enough to configure with command line switches. These tell, in order — where the logs should live, that we communicate with other process via UNIX socket at given path and that no TCP socket is needed. Thus there will be no conflict of different processes competing for the same `host:port` pair.

Once our isolated database engine unit is running, it would be useful to prepare application environment. Creating the database with `createdb` PostgreSQL CLI which understands UNIX sockets too. Finally letting the application know where its database is by exporting `DATABSE_URL` environment variable. The URL completely describing a particular database run by a database engine of chosen version may look like this — `postgresql:///rails_event_store?host=/tmp/tmp.iML7fAcubU`.

Once we're done with testing it is time to nuke our temporary database. Killing the process in the background first. Then removing temporary directory root it operated in.

```sh
pg_ctl -D $DB stop
rm -rf $TMP
```

That's it.

## Little automation goes a long way

It would be such a nice thing to have a shell function that spawns a temporary database engine in the background, leaving us in the shell with `DATABASE_URL` already set and cleaning up automatically when we exit.

The only missing ingredient is an exit hook for the shell. One can be implemented with `trap` and stack-like behaviour built on top of it. Borrowed from [modernish](https://github.com/modernish/modernish#user-content-use-varstacktrap):

```sh
pushtrap () {
  test "$traps" || trap 'set +eu; eval $traps' 0;
  traps="$*; $traps"
}
```

The automation in its full shape:

```sh
pushtrap () {
  test "$traps" || trap 'set +eu; eval $traps' 0;
  traps="$*; $traps"
}

mk_pg_15() {
  TMP=$(mktemp -d)
  DB=$TMP/db
  SOCKET=$TMP

  /path_to_pg_15/initdb -D $DB
  /path_to_pg_15/pg_ctl -D $DB \
    -l $TMP/logfile \
    -o "--unix_socket_directories='$SOCKET'" \
    -o "--listen_addresses=''\'''\'" \
    start

  /path_to_pg_15/createdb -h $SOCKET rails_event_store
  export DATABASE_URL="postgresql:///rails_event_store?host=$SOCKET"

  pushtrap "/path_to_pg_15/pg_ctl -D $DB stop; rm -rf $TMP" EXIT

  sh
}
```

Whenever I need to be dropped into a shell with Postgres 15 running, executing `mk_pg_15` fulfils it.

## The nix dessert

One may argue that using `Docker` is familiar and temporary databases is a solved problem there. I agree with that sentiment at large.

I've found my peace with `nix` long time ago. Thanks to numerous contributions and initiatives using `nix` on MacOS is as simple as `brew`.

With `nix` and I'm currently spawning the databases with one command, that is:

```sh
nix-shell ~/Code/rails_event_store/support/nix/postgres_15.nix
```

As an added bonus this will fetch PostgreSQL binaries from nix repository when they're not already on my system in given version. All the convenience of Docker without any of its drawbacks in a tailor-made use case.

```nix
with import <nixpkgs> {};

mkShell {
  buildInputs = [ postgresql_14 ];

  shellHook = ''
    ${builtins.readFile ./pushtrap.sh}

    TMP=$(mktemp -d)
    DB=$TMP/db
    SOCKET=$TMP

    initdb -D $DB
    pg_ctl -D $DB \
      -l $TMP/logfile \
      -o "--unix_socket_directories='$SOCKET'" \
      -o "--listen_addresses=''\'''\'" \
      start

    createdb -h $SOCKET rails_event_store
    export DATABASE_URL="postgresql:///rails_event_store?host=$SOCKET"

    pushtrap "pg_ctl -D $DB stop; rm -rf $TMP" EXIT
  '';
}
```

In RailsEventStore we've prepared such [evaluations for numerous PostgreSQL, MySQL and Redis versions](https://github.com/RailsEventStore/rails_event_store/tree/master/support/nix).

Happy experimenting!
