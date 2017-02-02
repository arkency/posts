---
title: "yield default object"
created_at: 2017-02-02 10:23:01 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'yield', 'default' ]
newsletter: :arkency_form
---

There is one programming pattern that I sometimes use
which I wanted to tell you about today. I called this technique
_yield default object_. I am pretty sure it was already presented
somewhere, by someone, but I could not find any good reference.

<!-- more -->

Imagine code like this:

```
#!ruby
def start_till_cash_register_session
  cmd = Till::StartNewSession.new(
    uuid: SecureRandom.uuid,
    terminal_name: "2nd floor, nr 2103",
    employee_name: "Jurgen Klinsman",
    organizer_id: user_id,
    currency: currency,
    starting_cash_balance: "0.00",
  )
  command_bus.call(cmd)
end
```

It doesn't matter where it is located (TestActor btw), what it does,
or what's the full context (selling in a boutique/box office/museum).
We will be looking at it from a mechanical perspective.
 
So the code is all good, and provides some nice defaults that we can
use in our tests. However, sometimes we would like to override those
defaults. What options do we have?

## default named arguments

We could use default named arguments:

```
#!ruby
def start_till_cash_register_session(
    uuid: SecureRandom.uuid,
    terminal_name: "2nd floor, nr 2103",
    employee_name: "Jurgen Klinsman",
    starting_cash_balance: "0.00",
  )
  
  cmd = Till::StartNewSession.new(
    uuid: uuid,
    terminal_name: terminal_name,
    employee_name: employee_name,
    organizer_id: user_id,
    currency: currency,
    starting_cash_balance: starting_cash_balance,
  )
  command_bus.call(cmd)
end
```

```
#!ruby
start_till_cash_register_session(employee_name: "Batman")
```

I don't know about you, but that feels a little verbose to me.
On the other hand the code is very grep-able and if you later
want to rename something it should be pretty straight-forward
to rename any argument and find where they are being used.

After years of using Ruby and Rails, that's something that I
value highly.

It would also work very nice with code-editors that will be
capable of showing nicely all arguments that you can pass to
the method.

## merge / reverse_merge

We can use the double splat operator and handle any named arguments.

```
#!ruby
def start_till_cash_register_session(**attributes)
  defaults = {
    uuid: SecureRandom.uuid,
    terminal_name: "2nd floor, nr 2103",
    employee_name: "Jurgen Klinsman",
    organizer_id: user_id,
    currency: currency,
    starting_cash_balance: "0.00",
  }
  cmd = Till::StartNewSession.new(defaults.merge(attributes))
  command_bus.call(cmd)
end
```

```
#!ruby
start_till_cash_register_session(employee_name: "Batman")
```

It's definitely less verbose, but you might not get any errors
in case of typos (depends on how the `StartNewSession` constructor
is implemented, whether it will silently ignore additional
attributes or not). And you won't get autocomplete.

## yield default object

Here is another approach. One that I wanted to show you.

```
#!ruby
def start_till_cash_register_session
  cmd = Till::StartNewSession.new(
    uuid: SecureRandom.uuid,
    terminal_name: "2nd floor, nr 2103",
    employee_name: "Jurgen Klinsman",
    organizer_id: user_id,
    currency: currency,
    starting_cash_balance: "0.00",
  )
  yield cmd
  command_bus.call(cmd)
end
```

Instead of passing the attributes around we are passing the whole
command object built with defaults by `yield`-ing it to the caller. 

```
#!ruby
start_till_cash_register_session{|cmd| cmd.employee_name = "Batman" }
```

For me there is certain appeal to this solution.

And if you use the [fluent interface](/2017/01/fluent-interfaces-in-ruby-ecosystem/)
as well you could have:

```
#!ruby
start_till_cash_register_session do |cmd| 
  cmd.employee_name("Batman").starting_cash_balance("200.00")
end
```

Of course the number of solutions to this problem is infinite and
you could mix and match those approaches (for example by yielding attributes
instead of the object).

Which approach do you use in your test?

P.S. Yes, I know about `factory_girl`, you don't need to mention it.

## Want to know more?

Check out our video course [Hands-on Ruby, TDD, DDD - a simulation of a real project](https://vimeo.com/ondemand/arkencyruby)
which contains 51 short videos, each one discussing a small refactoring or technique.

Use discount code `YIELD_DEFAULT` to [purchase](https://vimeo.com/r/1R9K/LkRzRUpkZX) with 50% discount.
The offer expires on Fed 10, 2017.