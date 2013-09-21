---
title: "Throw away Sprockets, use UNIX!"
created_at: 2013-09-21 21:59:29 +0200
kind: article
publish: false
author: 'Mateusz Lenik'
tags: [ 'sprockets', 'unix', 'coffeescript', 'javascript' ]
---

# Throw away Sprockets, use UNIX!

The Sprockets gem is the standard way to combine asset files in Rails, but it
isn't very straight forward to use in stand-alone projects, like Single Page
Applications without backend.

Later the `sprockets` binary was added to address this issue.
Unfortunately at the time I tried to use them with Nanoc, that command wasn't
available, so I had to hack a bit to get the thing working.

Few weeks before I realized that Sprockers solve the problem that has been
already solved, but in a different language and in different era of computing.

<!-- more -->

## The C PreProcessor

The designers of C language had to solve a similar problem, so they came up
with a preprocessor that understands directives that allow concatenating
multiple files into one. Additionally it offers some macros and other stuff,
but it isn't really important in this application.

In most UNIX-like systems there exists a separate binary, called `cpp`, that
can be used to invoke the preprocessor.

It's key feature here is that it can be used with any programming language, not
necessarily C, C++ or Objective-C.

## Let's give it a try

Say I have two files, one called `deep_thought.coffee` and the other one called
`answer.coffee`. They're listed below.

    # answer.coffee
    answer = 42

I'd like to use the `answer` in the other module of my application. It's really
simple with the `#import` directive.

    # deep_thought.coffee
    #import "answer.coffee"

    console.log "The answer to the Ultimate Question of Universe, Life and Everything is #{answer}"

Now let's run the preprocessor and see what happens (blank lines removed).

    $ cpp -P deep_thought.coffee
    answer = 42
    console.log "The answer to the Ultimate Question of Universe, Life and Everything is #{answer}"

Looks like it's what we need. The only thing that's left to do is to compile
the file. Lets use some pipes then.

    $ cpp -P deep_thought.coffee | coffee -s -p
    (function() {
      var answer;
      answer = 42;
      console.log("The answer to the Ultimate Question of Universe, Life and Everything is " + answer);
    }).call(this);

As you can see from the above, there is no magic and even old UNIX tools can
get this work done properly.

## Is it any good in practice?

The short answer is yes. To prove this I resurrected the [hexagonal.js
implementation of TodoMVC](https://github.com/hexagonaljs/todomvc) and replaced
`coffee-toaster` with a `Makefile` (and removed lots of crap committed to the
repository in the meantime). You can see [all the relevant changes in this
commit](https://github.com/mlen/todomvc/commit/69c3c8495f3c07d40bbeb46ab5a4460ce61a1eb2).
To compile it, just run `make` from the command line and given you have
`coffee` and `cpp` command line utilities installed, it just works!

## Yet still it isn't good enough to replace Sprockets

You may have noticed some differences in the output file produced by the
commands in the `Makefile`. There is only one wrapping anonymous function. This
is because it first concatenates all CoffeeScript files and then it compiles
one big file. Sprockets work the other way around - the files are compiled and
then they are concatenated. That allows mixing JavaScript and CoffeeScript
files.

This can be also achieved using `cpp`, but that would require extending
CoffeeScript compiler to support preserving the `#import` directive in the
output files. That would allow to create a `Makefile` that'd support parallel
compilation. How cool would that be?

## One more thing

Some of you'd probably say that `#import` is deprecated. I know that. My
solution is already hackish, so I don't care about deprecations.

The other way would be to use `#include` statements and few `#define`s combined
with `#ifndef`s. That would be a proper way, but it is also the ugly way. After
all, readability matters.
