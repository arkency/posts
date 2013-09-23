---
title: "Throw away Sprockets, use UNIX!"
created_at: 2013-09-23 12:49:29 +0200
kind: article
publish: true
newsletter: :spabook
author: 'Mateusz Lenik'
tags: [ 'sprockets', 'unix', 'coffeescript', 'javascript' ]
---

The Sprockets gem is the standard way to combine asset files in Rails, but it
wasn't very straightforward to use in stand-alone projects, like Single Page
Applications without backend, before the `sprockets` command was added.

Few weeks ago I realized that Sprockets solve the problem that has been
already solved, but in a different language and in different era of computing.

Later I wanted to check whether my idea would actually work and started
hacking. You can see the results below.

<!-- more -->

### The C Preprocessor

The designers of C language had to solve a similar problem, so they came up
with a preprocessor that understands directives that allow concatenating
multiple files into one. Additionally, it offers some macros and other stuff,
but it isn't really important in this application.

In most UNIX-like systems there exists a separate binary, called `cpp`, that
can be used to invoke the preprocessor.

Its key feature here is that it can be used with any programming language, not
necessarily C, C++ or Objective-C.

### Let's give it a try

Say I have two files, one called `deep_thought.coffee` and the other one called
`answer.coffee`. They're listed below.

__answer.coffee__:

    #!coffeescript
    answer = 42

I'd like to use the `answer` in the other module of my application. It's really
simple with the `#import` directive, which includes the dependency only once.

__deep_thought.coffee__:

    #!coffeescript
    #import "answer.coffee"

    console.log "The answer to the Ultimate Question is #{answer}"

Now let's run the preprocessor and see what happens.

    #!coffeescript
    $ cpp -P deep_thought.coffee
    answer = 42
    console.log "The answer to the Ultimate Question is #{answer}"

Looks like it's what we need. The only thing that's left to do is to compile
the file.

    #!javascript
    $ cpp -P deep_thought.coffee | coffee -s -p
    (function() {
      var answer;
      answer = 42;
      console.log("The answer to the Ultimate Question is " + answer);
    }).call(this);

As you can see from the above, there is no magic and even old UNIX tools can
get this work done properly.

### Is it any good in practice?

The short answer is yes. To prove this I resurrected the [hexagonal.js
implementation of TodoMVC](https://github.com/hexagonaljs/todomvc) and replaced
`coffee-toaster` with a `Makefile` listed below.

    MAIN=src/todo_app.coffee
    RELEASE_DIR=release
    RELEASE_MAIN="$(RELEASE_DIR)/todo_app.js"

    debug:
        cpp $(MAIN) | coffee -s -p > $(RELEASE_MAIN)

    release:
        cpp $(MAIN) | coffee -s -p | uglifyjs > $(RELEASE_MAIN)

    clean:
        rm -f $(RELEASE_DIR)/*

    .PHONY: debug release clean

That's it. There are three targets defined: `debug`, `release` and `clean`. The
default one is `debug`. `.PHONY` just means that there are no dependencies for
these targets and they should be executed every time.

You can see [all the relevant changes in this
commit](https://github.com/mlen/todomvc/commit/69c3c8495f3c07d40bbeb46ab5a4460ce61a1eb2).
To compile it, just run `make` from the command line and given you have
`coffee` and `cpp` command line utilities installed, it just works!

### But is it faster?

To check it I modified the `Makefile` to run Sprockets and performed simple
benchmark. I ran both versions in the clean environment 50 times and took an
average. The run time for Sprockets doesn't include the time of running `bundle
exec`. You can [see the modifications on a separate
branch](https://github.com/mlen/todomvc/commit/35442c8da443ce075eccf963c3387859355fea9a).

The `cpp` took 0.23 seconds to compile the assets, while for Sprockets it was
1.57 seconds, which is almost seven times slower! Looks like it is doing a lot
more work than is needed to just compile few CoffeeScript files.

You can easily perform similar benchmark using the `time` command if you don't
believe the results.

### When not to use it

You may have noticed some differences in the output file produced by the `cpp`
solution. There is only one wrapping anonymous function on the top level. This
is because it first concatenates all CoffeeScript files and then it compiles
one big file.  Sprockets work the other way around - the files are compiled and
then they are concatenated. That allows mixing JavaScript and CoffeeScript
files.

Comments in CoffeeScript files don't work either, because they are treated as
directives for the preprocessor and are reported as errors. At Arkency we
rarely use comments in the code - we believe that the code should be always
readable without needing additional explanation in the comment. It isn't an
issue if you do the same.

The performance may be also a problem, even though the benchmarks show that
`cpp` is clearly faster. However, when a single file is modified in the large
project, Sprockets recompile only that file, whereas in this solution all
imported files need to be recompiled.

### Conclusion

The problem with Sprockets is that they are responsible for doing lot of tasks.
They have to manage the dependencies, run the compiler and then concatenate all
the resulting files. It is clearly, against the UNIX way. There should be one
component for each task. The `make` command can be used to schedule the
compilation, compiler should only do the compilation, another tool should
create the dependency map and yet another one should put the resulting files
together using the compiled results and the dependency map. That'd be the UNIX
way to solve this problem!
