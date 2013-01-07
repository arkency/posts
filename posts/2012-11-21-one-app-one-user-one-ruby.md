---
title: "One app, one user, one ruby"
created_at: 2012-11-21 12:40:51 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :chillout
tags: [ 'ruby', 'deployment', 'chef', 'littlechef', 'ruby-build', 'cookbooks' ]
---

There are many ways to install and manage ruby installation in your
infrastructure. Some people like `rvm`, others prefer `rbenv`, some pack
their ruby installation into `deb` packages. We like nothing.

<!-- more -->

## You ain't need it in production.

Yes, you read it well. Using no tool is better than using some tool if we can
simply avoid it. Let me state it clearly: RVM is a great tool for *development*
environment however we do not see much use for it in production. Even in
development some of us started to separate projects on higher level using
Vagrant or LXC containers but that is another story.

A little background: Our customers usually host their applications using our
infrastructure or their own. These solution are based on LXC, XEN, or KVM.
Every project has its own container/VM .

## Simplest thing that can possibly work

We do not have a globally installed ruby except for ruby coming from system
package that is used mostly by [littlechef](https://github.com/tobami/littlechef) to
setup the virtual machine according to our conventions and application requirements.
For *every application* that is a part of bigger project *separate user is created*
and *separate ruby is installed* in its *home directory*. If we end up having five
users using same ruby version but different ruby installation then fine. Storage
is cheap. Easy upgrades are more important.

## Running ruby

### bash

You might wonder how to execute your scripts and run applications with that ruby.
We just add the ruby bin path to user `$PATH` via `.bashrc` and voilà.
Whenever you run something inside bash it just works. And gem binaries are
installed into the same directory so they also work properly.

### not bash ?

If your software is not directly executed inside bash you have two options:

* run it in bash anyway.
* just use the full path to your ruby.

#### Example 1

Here is an example. [Runit](http://smarden.org/runit/) by default executes
supervised processes as `root`. We use `su` to switch to user with no
special abilities. The `-c` switch allows you to execute a command that will
be invoked in a shell. You can use `-s, --shell SHELL` specify which shell
is going to be used. Thanks to such behavior `.bashrc` is used and `$PATH`
variable is set up properly.

Note: We use `exec` twice here so that runit ends up monitoring our
`application-name` binary instead of monitoring `su` or `bash` shell.

```
#!bash
exec su - application-name -c "cd /var/lib/application-name/current/ \
&& exec bundle exec ruby -Ilib ./bin/application-name"
```

#### Example 2

And the second mentioned solution is to use full ruby binary (or gem)
path in a script:

```
#!bash
/var/lib/application-name/1.9.3-p286/bin/rackup path/to/the/app
```

## Cookbook

You can see our open-sourced cookbook for ruby installation on
github [arkency/ruby-build-cookbook](https://github.com/arkency/ruby-build-cookbook).
This is first thing that we open sourced as a company (we do have lot
of open source experience as individuals) and we hope
that in the future you can expect even more from us.

And if you are not that much into cooking (with chef) you can
see for yourself how simple the whole
[ruby installation process](https://github.com/arkency/ruby-build-cookbook/blob/master/definitions/ruby.rb)
just is.

## Benefits

* No need to use rvm wrappers in every possible place such as
cron, capistrano recipes etc.
* No need to switch ruby versions because you just log in as
proper user associated with the application and there is just
the right ruby that you should be using with this app.

## TL;DR

* Every application has its own user
* Every user has its own ruby
