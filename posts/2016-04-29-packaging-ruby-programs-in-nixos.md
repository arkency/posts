---
title: "Packaging ruby programs in NixOS"
created_at: 2016-04-29 00:28:12 +0200
kind: article
publish: false
author: Rafał Łasocha
tags: [ 'nix', 'nixos', 'ruby', 'devops' ]
newsletter: :arkency_form
img: "packaging-ruby-programs-in-nixos/hammer-sledgehammer-mallet-tool.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("packaging-ruby-programs-in-nixos/hammer-sledgehammer-mallet-tool.jpg") %> alt="" width="100%" />
  </figure>
</p>

Recently at Arkency we're exploring how [NixOS](https://nixos.org/) could fit our infrastructure.
From a few weeks we've switched most of our projects CI systems from CircleCI to [Buildkite](https://buildkite.com/).
Buildkite offers unique offer in which it is us who provide infrastructure and containers to test our applications so we've decided to setup these containers with NixOS and we are by far happy with this solution.

However in this post I would like to describe how to package a simple ruby program, based on simple password manager CLI utility - [pws](https://github.com/janlelis/pws).

<!-- more -->

## Nix & NixOS

Firstly, we should get to know how (without details) packaging process in NixOS looks like.
Typical package in NixOS is a directory with a `default.nix` file (and maybe others).
`*.nix` files are files written in [Nix](http://nixos.org/nix/), which is functional programming language and package manager.
A `default.nix` file is a function which takes configuration options and dependencies as an input and creates package as an output.

Just to recap the syntax of nix language, you should know a few things:

* in nix we're using records extensively. Records are what we know as Hash in ruby world and they look like this: `{ foo = "some value"; bar = 3; }`
* function application is very haskell-ish, and looks like this: `name_of_the_function argument`. Most often, argument is a record with many fields.
* definition of function usually looks like this: `{arg1, arg2, arg3}: body_of_the_function` - which is essentialy a function with one record argument destructured into `arg1`, `arg2`, `arg3`. Think about ruby's `def my_function(**args)`.
* nix is lazily evaluated
 
## Simplest ruby package

Our program is distributed as a gem, so we can take an advantage of the fact that NixOS has a built-in `bundlerEnv` function for creating Bundler environments as packages.
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

As you can see, it's a simple function. It's argument, a record, has two fields: `bundlerEnv` and `ruby`. Body of this function does only one thing: it calls `bundlerEnv` function, with record as an argument. This record has fields: `name`, `ruby`, gemfile`, `lockfile` and `gemset`.

About fields from the arguments' record: `bundlerEnv` is aforementioned function creating Bundler environment and `ruby` is... Ruby, a program. You've to get use to the fact that the programs are just values passed in as arguments to other functions.

There are few important things right here:

* `gemfile`, `lockfile` and `gemset` are references to the files we haven't defined yet. We'll create them in a second.
* `ruby = ruby` may firstly look funny, but think about scopes: it is a definition of the field `ruby`, which value is `ruby` program. Think about `{ ruby: ruby }` Hash in ruby - it's perfectly valid.

`bundlerEnv` function requires a few things to work: a `Gemfile` and `Gemfile.lock` files of the bundler environment it needs to build and a `gemset.nix` file.

The easy part is to create `Gemfile` and `Gemfile.lock`.
Let's create simplest possible `Gemfile` containing `pws` gem:

```
#!ruby
source 'https://rubygems.org'
gem 'pws'
```

Let's generate `Gemfile.lock` file by running `bundle install` command.

Now, if we have both `Gemfile` and `Gemfile.lock` in one directory, you can generate `gemset.nix` using Bundix tool. `gemset.nix` is basically a `Gemfile.lock` but written in nix language. Bundix is not yet finished, thus it is not able to translate less used `Gemfile` features like `path:` attribute.

Examplary gemset.nix looks like this:

```
{
  clipboard = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11r5xi1fhll4qxna2sg83vmnphjzqc4pzwdnmc5qwvdps5jbz7cq";
      type = "gem";
    };
    version = "1.0.6";
  };
  paint = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1z1fqyyc2jiv6yabv467h652cxr2lmxl5gqqg7p14y28kdqf0nhj";
      type = "gem";
    };
    version = "1.0.1";
  };
  pbkdf2-ruby = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "014vb5k8klvh192idqrda2571dxsp7ai2v72hj265zd2awy0zyg1";
      type = "gem";
    };
    version = "0.2.1";
  };
  pws = {
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1brn123mmrw09ji60sa13ylgfjjp7aicz07hm9h0dc3162zlw5wn";
      type = "gem";
    };
    version = "1.0.6";
  };
}
```


Currently our function is generating a bundler environment and if we would release it this way, `pws` program would be able to run. However current `default.nix` has two major disadvantages:

* it doesn't include runtime dependencies. On Linux, `pws` needs `xsel` command to run and if user won't install this program by himself, `pws` will be useless
* as it's bundler environment, it expose following binaries: `pws`, `bundle` and `bundler`. You probably don't want to surprise someone with providing `bundler` binary by installing your package.

## Wrapper package

Thus, let's create a wrapper package which will just use generated bundler environment and provide only pws as a binary.

Our wrapper package can be achieved by the following code:

```
{ bundlerEnv, ruby, stdenv, makeWrapper }:

stdenv.mkDerivation rec {
  name = "pws-1.0.6";

  env = bundlerEnv {
    name = "pws-1.0.6-gems";

    ruby = ruby;

    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
  };

  buildInputs = [ makeWrapper ];

  phases = ["installPhase"];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${env}/bin/pws $out/bin/pws
  '';
}
```

`mkDerivation` from `stdenv` is a function which is usually used to create packages (the simple ones) written for example in C or Bash. 

As you can see `env` field is pretty much our bundler environment which we've used before but now it's only part of our package.

`phases` field is an array which keeps list of phases needed to build this package. It's mostly convention-driven and in the end we can use arbitrary names there. We declare that the process of building our package consists of only one phase (named `installPhase`).

`installPhase` itself is just a simple 2-line bash script. It uses a [makeWrapper](https://nixos.org/wiki/Nix_Runtime_Environment_Wrapper) function provided by NixOS just for situation like this - it generates a simple script which does only one thing - call an exec given as an argument.

If we check the source of such generated file, it looks like this:

```
#!bash
#! /nix/store/1qg54rgrk0sm04fqjixm64hn94kxhvzk-bash-4.3-p42/bin/bash -e
exec /nix/store/slxvwr8zgl2ajzjhb8692kp7mch978v7-pws-1.0.6-gems/bin/pws "${extraFlagsArray[@]}" "$@"
```

## Runtime dependency

There's only one issue left with our current package which I've mentioned before. `pws` to run properly needs `xsel` (a clipboard utility). However it's only _run-time dependency_. _Run-time dependency_ (as opposed to _build-time dependency_) means that we can successfully build a package without this dependency, but our program will misbehave when this run-time dependency is not present.

That's why we want to modify our package a little bit:

```
#!nix
{ bundlerEnv, ruby, stdenv, makeWrapper, xsel }:

stdenv.mkDerivation rec {
  name = "pws-1.0.6";

  env = bundlerEnv {
    name = "pws-1.0.6-gems";

    ruby = ruby;

    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
  };

  buildInputs = [ makeWrapper ];

  phases = ["installPhase"];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${env}/bin/pws $out/bin/pws \
      --set PATH '"${xsel}/bin/:$PATH"'
  '';
}
```

We've added `xsel` as dependency. We've also modified the `installPhase` script (`makeWrapper` call, to be specific) to prepend location of `xsel` (which is something like `/nix/store/...-xsel/bin`) to our `PATH` environment variable.

Now our package is done. You could follow [Chapter 10. Submitting changes](https://nixos.org/nixpkgs/manual/#chap-submitting-changes) of nixpkgs manual to release your package to the public. [Based on my experience, it's very simple process](https://github.com/NixOS/nixpkgs/pull/14963). If you're a ruby developer I hope this guide got you closer to the nix ecosystem and let me know if there are topics you would like to get coveraged.
