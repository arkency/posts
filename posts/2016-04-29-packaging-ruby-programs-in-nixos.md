---
title: "Packaging ruby programs in NixOS"
created_at: 2016-04-29 00:28:12 +0200
kind: article
publish: false
author: Rafał Łasocha
tags: [ 'nix', 'nixos', 'ruby', 'devops' ]
newsletter: :arkency_form
---

Recently at Arkency we're exploring how NixOS could fit our infrastructure.
From a few weeks we've switched most of our projects CI systems from CircleCI to Buildkite.
Buildkite offers unique offer in which it is us who provide infrastructure and containers to test our applications, so we've decided to setup these containers with NixOS and we are by far happy with this solution.
In this post however, I would like to describe how to package a simple ruby program, based on simple password manager CLI utility - `pws`.

<!-- more -->

## Nix & NixOS

I assume some knowledge about NixOS, but I assume you didn't (dokonczyc)

Firstly, we should get to know how (without details) packaging process in NixOS looks like.
Packages in NixOS are files written in Nix, which is functional programming language.
These packages contain `default.nix` file, which is a function which takes configuration options and dependencies as an input and creates package as an output.

Just to recap the syntax of nix language, you should know 3 things:
* in nix we're using records extensively and records are what we know as Hash in ruby world and look like this: `{ foo = "some value"; bar = 3; }`
* function application is very haskell-ish, and looks like this: `name_of_the_function argument`. Most often, argument is a record.
* definition of function usually looks like this: `{arg1, arg2, arg3}: body_of_the_function` - which is essentialy a function with one argument, but accepting a record with many values. Think about ruby's `def my_function(**args)`.
* nix is lazily evaluated
 
## Simplest ruby package

Our program is distributed as a gem, so we can take an advantage of the fact, that NixOS has a built-in `bundlerEnv` function for creating Bundler environments as packages.
After checking out how other ruby programs' packages look like, we can write following function:

```
{ bundlerEnv, ruby }:

bundlerEnv {
  name = "pws-1.0.6";

  ruby = ruby;

  gemfile  = ./Gemfile;
  lockfile = ./Gemfile.lock;
  gemset   = ./gemset.nix;
}
```

As you can see, it's a simple function. It's argument, a record, has two fields: `bundlerEnv` and `ruby`. Body of this function does only one thing: it calls `bundlerEnv` function, with record as an argument. This record has fields: `name`, `gemfile`, `lockfile` and `gemset`.

About fields from the arguments' record: `bundlerEnv` is aforementioned function creating Bundler environment and `ruby` is... Ruby, a program. You've to get use to the fact that the programs are just values passed in as arguments to other functions.

There are few important things right here:
* `gemfile`, `lockfile` and `gemset` are references to the files we weren't defined yet. We'll create them in a second.
* `ruby = ruby` may firstly look funny, but think about scopes: it is a definition of the field `ruby`, which value is `ruby` program. Think about `{ ruby: ruby }` Hash in ruby - it's perfectly valid.

`bundlerEnv` function requires a few things to work: a `Gemfile` and `Gemfile.lock` files of the bundler environment it needs to build and a `gemset.nix` file.

### Gemfile & Gemfile.lock

That's the easy part. 
Let's create simplest possible `Gemfile` containing `pws` gem:











As I've told before, NixOS package is a function. So let's make a simple function which returns a new package:

We've added another field called `env` which calls `bundlerEnv` function.
```
{ stdenv }:

stdenv.mkDerivation rec {
  name = "pws-1.0.6";
}
```

As you can see, it's a simple function - it takes a record with one field (`stdenv`) as an input and in the body we're just calling `mkDerivation` function declared in `stdenv` (which is, in the end, a record - I've told you that in nix you're using records very often!) passing a simple record with one field (`name`). `rec` keyword before a record means that it is recursive - definition of fields may use other fields defined in the same record.


```
{ stdenv, bundlerEnv, ruby }:

stdenv.mkDerivation rec {
  name = "pws-1.0.6";

  env = bundlerEnv {
    name = "${name}-gems";

    ruby = ruby;

    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
  };
}
```


















TODO: Link do Nixos, buildkite

