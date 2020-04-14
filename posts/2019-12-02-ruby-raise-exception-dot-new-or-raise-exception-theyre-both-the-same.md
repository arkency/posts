---
title: "Ruby's raise Exception.new or raise Exception — they're both the same"
created_at: 2019-12-02 18:45:01 +0100
publish: true
author: Andrzej Krzywda
tags: ['ruby', 'exceptions']
---

TLDR: You can use `raise Exception` and `raise Exception.new` - they’re identical as a result and it’s 4 characters less.


<!-- more -->

In my previous post ([OOP Refactoring: from a god class to smaller objects | Arkency Blog](https://blog.arkency.com/oop-refactoring-from-a-god-class-to-smaller-objects/) I’ve used some code with raising exceptions:

```ruby
  def add_task(task)
    raise Duplicate if @tasks.include?(task)
    @tasks << task
  end
```

or

```ruby
  def assign_task(task, developer)
    raise AlreadyAssigned if task.assigned?
    task.assign_developer
  end
```

The way I’m raising the exception here is that I raise it without calling `.new`. This may look as if I’m raising a class, not an object.

Some people asked me if this actually works and if it's the same.

We already know the short answer, so let’s dig into why it's the same. Is there some kind of magic involved?

One place to go is to check the [raise (Kernel) - APIdock](https://apidock.com/ruby/v2_6_3/Kernel/raise) documentation. 

```
raise(*args) public

With no arguments, raises the exception in $! or raises a RuntimeError if $! is nil. With a single String argument, raises a RuntimeError with the string as a message. Otherwise, the first parameter should be the name of an Exception class (or an object that returns an Exception object when sent an exception message). The optional second parameter sets the message associated with the exception, and the third parameter is an array of callback information. Exceptions are caught by the rescue clause of begin…end blocks.
```

OK, this gives some answer, but I prefer to check the code - let's look at the Ruby implementation (in C…)

```C
static VALUE
rb_f_raise(int argc, VALUE *argv)
{
    VALUE err;
    VALUE opts[raise_max_opt], *const cause = &opts[raise_opt_cause];

    argc = extract_raise_opts(argc, argv, opts);
    if (argc == 0) {
        if (*cause != Qundef) {
            rb_raise(rb_eArgError, "only cause is given with no arguments");
        }
        err = get_errinfo();
        if (!NIL_P(err)) {
            argc = 1;
            argv = &err;
        }
    }
    rb_raise_jump(rb_make_exception(argc, argv), *cause);

    UNREACHABLE_RETURN(Qnil);
}
```

BTW I’m wondering if it's the first time, we've posted some C code on the Arkency materials.

In order to actually get the answer, I started exploring the C code, but my C reading is not the biggest skill I have. I prefer reading Ruby.

Let’s look at Rubinius - the Ruby implementation of Ruby.

```ruby
  def raise(exc=undefined, msg=nil, trace=nil)
    Rubinius.synchronize(self) do
      return self unless @alive

      if undefined.equal? exc
        no_argument = true
        exc = active_exception
      end

      if exc.respond_to? :exception
        exc = exc.exception msg
        Kernel.raise TypeError, 'exception class/object expected' unless Exception === exc
        exc.set_backtrace trace if trace
      elsif no_argument
        exc = RuntimeError.exception nil
      elsif exc.kind_of? String
        exc = RuntimeError.exception exc
      else
        Kernel.raise TypeError, 'exception class/object expected'
      end

      if $DEBUG
        STDERR.puts "Exception: #{exc.message} (#{exc.class})"
      end

      if self == Thread.current
        Kernel.raise exc
      else
        Rubinius.invoke_primitive :thread_raise, self, exc
      end
    end
  end
```

[rubinius/thread.rb at 75086f2b2cc92302b54176db0250ec6635adfcc8 · rubinius/rubinius · GitHub](https://github.com/rubinius/rubinius/blob/75086f2b2cc92302b54176db0250ec6635adfcc8/core/thread.rb#L224)

The main thing here is `if exc.respond_to? :exception`. Does that mean that both the Exception class and the Exception instances have this method?

Let’s find out!

```ruby
class Exception
  class << self
    alias_method :exception, :new
  end

  def exception(message=nil)
    if message
      unless message.equal? self
        # As strange as this might seem, this IS actually the protocol
        # that MRI implements for this. The explicit call to
        # Exception#initialize (via __initialize__) is exactly what MRI
        # does.
        e = clone
        Rubinius.privately { e.__initialize__(message) }
        return e
      end
    end

    self
  end
end
```

[rubinius/exception.rb at 0296620da5ce252266cccf3574ae3e756ab144e6 · rubinius/rubinius · GitHub](https://github.com/rubinius/rubinius/blob/0296620da5ce252266cccf3574ae3e756ab144e6/core/exception.rb#L148)

This part is the main answer:
```ruby
  class << self
    alias_method :exception, :new
  end
```

So, `exception` is just an alias to `new`, at the class level. At the object level it just returns `self`.

Thanks to Rubinius, for making it easier to explore such things!

