---
title: "Which ruby version am I using? - how to check"
created_at: 2017-09-29 11:22:09 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'version', 'check' ]
newsletter: :arkency_form
---

Are you not sure which Ruby version you are using right now? Wondering how to check it? Say no more. Here are two simple ways to check for it.

<!-- more -->

## In irb

Run `irb` and type:

```ruby
RUBY_VERSION
# => "2.4.1"
```

## from command line

Just type `ruby -v`

```
$ ruby -v
ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-linux]
```

## in `rvm`

Are you using RVM?

Run `rvm current` and get the answer

```
$ rvm current
ruby-2.4.1
```

## in `rbenv`

Are you using rbenv? Just run `rbenv version`

```
$ rbenv version
2.4.1p111 (set by /Users/rupert/.rbenv/version)
```

## using `which`

Do you want to know where your `ruby` binary is installed? It can also sometimes reveal the version you are using as it is usually part of directory structure. Just run `which ruby`.

```
$ which ruby
/home/rupert/.rvm/rubies/ruby-2.4.1/bin/ruby
```

