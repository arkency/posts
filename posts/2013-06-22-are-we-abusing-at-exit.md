---
title: "Are we abusing at_exit ?"
created_at: 2013-06-22 18:05:22 +0200
kind: article
publish: true
newsletter: :chillout
author: Robert Pankowecki
tags: [ 'ruby', 'at_exit', 'tempfile', 'webservers' ]
---

If you are deeply interested in Ruby, you probably already know about
[`Kernel#at_exit`](http://www.ruby-doc.org/core-2.0/Kernel.html#method-i-at_exit).
You might even use it daily, without knowing that it is there, in many gems, solving
many problems. Maybe even too many ?

<!-- more -->

## Basics

Let me remind you some basic facts about `at_exit`. You can skip this section if
you are already familiar with it.

```
#!ruby
puts "start"
at_exit do
  puts "inside at_exit"
end
puts "end"
```

The output of such little script is:

```
start
end
inside at_exit
```

Yeah. Obviously. You did not come to read what you can read in the documentation. So let's
go further.

## Intermediate

### at_exit and exit codes

[In ruby you can terminate a script in multiple ways](http://rubysource.com/exit-exit-abort-raise-get-me-outta-here/).
But what matters most at the for other programms is the exit status code. And `at_exit` block can change it.

```
#!ruby
puts "start"
at_exit do
  puts "inside at_exit"
  exit 7
end
puts "end"
exit 0
```

Let's see it in action.

```
> ruby exiting.rb; echo $?
start
end
inside at_exit
7
```

But exit code might get changed in implicit way due to an exception:

```
#!ruby
at_exit do
  raise "surprise, exception happend inside at_exit"
end
```

Output:

```
> ruby exiting.rb; echo $?
exiting.rb:2:in `block in <main>': surprise, exception happend inside at_exit (RuntimeError)
1
```

But there is a catch. It will not change if the exit code was already set:

```
#!ruby
at_exit do
  raise "surprise, exception happend inside at_exit"
end
exit 0
```

See for yourself:

```
> ruby exiting.rb; echo $?
exiting.rb:2:in `block in <main>': surprise, exception happend inside at_exit (RuntimeError)
0
```

But wait, there is even more:

### at_exit handlers order

The documentation says: [_If multiple handlers are registered, they are executed
in reverse order of registration_](http://www.ruby-doc.org/core-2.0/Kernel.html#method-i-at_exit).

So, can you predict the result of this code ?:

```
#!ruby
puts "start"

at_exit do
  puts "start of first at_exit"
  at_exit { puts "nested inside first at_exit" }
  at_exit { puts "another one nested inside first at_exit" }
  puts "end of first at_exit"
end

at_exit do
  puts "start of second at_exit"
  at_exit { puts "nested inside second at_exit" }
  at_exit { puts "another one nested inside second at_exit" }
  puts "end of second at_exit"
end

puts "end"
```

Here is my output:

```
start
end
start of second at_exit
end of second at_exit
another one nested inside second at_exit
nested inside second at_exit
start of first at_exit
end of first at_exit
another one nested inside first at_exit
nested inside first at_exit
```

So it is more like stack-based behaviour. There were even few bugs when this
behavior changed and things broke:

* http://bugs.ruby-lang.org/issues/5197
* https://github.com/seattlerb/minitest/issues/25

Which brings us to `minitest`

## minitest

One of the best known example of using 
`at_exit` is [`minitest`](https://github.com/seattlerb/minitest). Note: My little
examples are using `minitest-5.0.5` installed from rubygems.

Here is a simple minitest file:

```
#!ruby
# test.rb
require "minitest"
require "minitest/autorun"

class TestStruct < Minitest::Test
  def test_struct
    assert_equal "chillout", Struct.new(:name).new("chillout").name
  end
end
```

You can run it with `ruby test.rb`. As easy as that. But here is the issue:
_How can minitest run our test if the test is defined after we require `minitest`_ ?
You probably already know the answer:

* it uses [`at_exit` hook to trigger test running](https://github.com/seattlerb/minitest/blob/f771b23367dc698586f1e794eae83bcb905fa0d8/lib/minitest.rb#L36)
* and [`inherited` hook](http://www.ruby-doc.org/core-2.0/Class.html#method-i-inherited) [`to collect tests to run`](https://github.com/seattlerb/minitest/blob/f771b23367dc698586f1e794eae83bcb905fa0d8/lib/minitest.rb#L233)

You can see that [rspec is also using `at_exit`](https://github.com/rspec/rspec-core/blob/dee12fcb024d92505625f859462ece5aeb28f04a/lib/rspec/core/runner.rb#L8)

Minitest `at_exit` usage is a little complicated:

```
#!ruby
# Registers Minitest to run at process exit
def self.autorun
  at_exit {
    next if $! and not $!.kind_of? SystemExit

    exit_code = nil

    at_exit {
      @@after_run.reverse_each(&:call)
      exit exit_code || false
    }

    exit_code = Minitest.run ARGV
  } unless @@installed_at_exit
  @@installed_at_exit = true
end

# A simple hook allowing you to run a block of code after everything
# is done running. Eg:
#
#   Minitest.after_run { p $debugging_info }
def self.after_run &block
  @@after_run << block
end
```

But why does it need to use `at_exit` hook at all ? Is it not some kind of hack ?
Don't know about you, but it certainly feels a little hackish to me. Let's see
what we can do without `at_exit` ?

```
#!ruby
gem "minitest"
require "minitest"

class TestStruct < Minitest::Test
  def test_struct
    assert_equal "chillout", Struct.new(:name).new("chillout").name
  end
end

# Need to override it to do nothing
# because pride_plugin is loading
# minitest/autorun anyway:
# https://github.com/seattlerb/minitest/blob/f771b23367dc698586f1e794eae83bcb905fa0d8/lib/minitest/pride_plugin.rb#L1
def Minitest.autorun
end

Minitest.run
```

It works:

```
> ruby test.rb 
Run options: --seed 63193
# Running:
.
Finished in 0.000675s, 1481.4332 runs/s, 1481.4332 assertions/s.
1 runs, 1 assertions, 0 failures, 0 errors, 0 skip
```

So we can imagine that if the mentioned issue was not a problem, we could trigger
running specs at the end of file with one line and avoid using `at_exit`. But if we want to
run tests from multiple files situation gets more complicated. You can solve it
with a little helper:

```
#!ruby
gem "minitest"
require "minitest"

require "./test1"
require "./test2"

def Minitest.autorun
end
Minitest.run
```

But then you need to keep `Minitest.run` out of your test files (to avoid running
it multiple times), which make it impossible for us, to run tests from a single file, using
the old syntax that we are used to: `ruby single_file_test.rb`.

We could dynamically require needed files in our script based on its
arguments like `ruby helper.rb -- test.rb test2.rb`. So with time we are getting
closer to building our own binary for running the tests.

## Minitest binary

And I think that is what `minitest` is currently missing. Binary for running
tests that would let you specify where they are. The only difference would
be that we would have to run our tests using `minitest file_test.rb` instead
of `ruby file_test.rb`. Because the shipped binary would be starting and
ending point for our programs we would not have to use `at_exit` for
triggering our tests. After all it sounds way more logical to say
_program do something with file A_ by typing `program a.rb` instead of saying
_Ruby run file A and when you are finished do something completelly different
that is actually the main thing that I wanted to achieve_. I hope you agree.

We are starting our Rails apps with `rails` command or `unicorn` command or
`rackup` command (or whatever webserver you use ;) ).
We do not start them by typing `ruby config/environment.rb`
and running the web server in `at_exit` hook. So by analogy
`minitest file_test.rb` sounds natural to me.

## Capybara

But `minitest` is not the only one doing interesting things in `at_exit` hook.
Another very common example is `capybara`. [Capybara is using `at_exit` hook
to close a browser](https://github.com/jnicklas/capybara/blob/4772f509f88ba5f2dcd5841846d0347423e8c9ed/lib/capybara/selenium/driver.rb#L14) 
such as Firefox, when tests are finished. As you can see there is quite
complicated logic around it:

```
#!ruby
def browser
  unless @browser
    @browser = Selenium::WebDriver.for(options[:browser], options.reject { |key,val| SPECIAL_OPTIONS.include?(key) })

    main = Process.pid
    at_exit do
      # Store the exit status of the test run since it goes away after calling the at_exit proc...
      @exit_status = $!.status if $!.is_a?(SystemExit)
      quit if Process.pid == main
      exit @exit_status if @exit_status # Force exit with stored status
    end
  end
  @browser
end
```

What could `capybara` do to avoid using `at_exit` directly ? Perhaps a better way
would be to keep this kind of code dependent on test suite used underneath and
specify the hook via different gems such as `capybara-minitest`, `capybara-rspec`
etc. It is now possible in some major frameworks:

* in `minitest` you can use `Minitest.after_run`. currently it uses `at_exit` but you do not
need to worry if they ever decide to change the internal implementation to simply execute it manually
at the end of `minitest` binary. And it states your intention more explicitly.
* in `rspec` you can use [`after(:suite)`](http://rubydoc.info/gems/rspec-core/RSpec/Core/Hooks)
* [`cucumber` unfortunatelly recommends using `at_exit` directly](https://github.com/cucumber/cucumber/wiki/Hooks#global-hooks)

Of course `at_exit` is more universal, and capybara might be used outside of
testing environment. In such case I would simply leave the task of closing
the browser to the programmer.

## Sinatra

Sinatra is [using `at_exit` hook](https://github.com/sinatra/sinatra/blob/cd503e6c590cd48c2c9bb7869522494bfc62cb14/lib/sinatra/main.rb#L25)
to run itself (the application).

## Conclusion

I think it would be best if every long running and commonly used process such as
web servers or test frameworks provide there own binary and custom hooks for 
executing code at the end of a program. That way we could all forget about
`at_exit` and live happily ever after.

## Appendix

So much words said and I still gave you no reason for avoiding `at_exit` right?
Well it seems that every project using this feature is sooner or later being hit by bugs
related to its behavor and tries to find workarounds.
