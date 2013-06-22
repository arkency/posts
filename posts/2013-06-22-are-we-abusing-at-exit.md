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

## Usage

One of the best known example of using 
`at_exit` is [`minitest`](https://github.com/seattlerb/minitest).


