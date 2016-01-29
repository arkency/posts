---
title: "Using anonymous modules and prepend to work with generated code"
created_at: 2016-01-29 12:41:56 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby', 'meta-programming', 'prepend' ]
newsletter: :skip
newsletter_inside: :clean
---

In my previous blog-post [about using setters](/2016/01/drop-this-before-validation-and-use-method/)
one of the commenter mentioned a case in which the setter methods are created by a gem. How can we
overwrite the setters in such situation?

<!-- more -->

Imagine a gem `awesome-bar` which gives you `AwesomeBar` module that you could include in your class
to get  `awesome_bar` getter and `awesome_bar=()` setter with an interesting logic.
You would use it like that:

```
#!ruby
class Foo
  include AwesomeBar
end

f = Foo.new
f.awesome_bar = "hello"
f.awesome_bar
# => "Awesome hello"
```

and here is silly `AwesomeBar` implementation which uses meta programming to
generate the methods like some gems do.

Be aware that it is a contrived example.
Gems are adding methods using various Ruby API methods. Such simple example in real would not use `included`
callback. But it will fit us to demonstrate the problem. Methods added directly to a class via meta-programming.

```
#!ruby
module AwesomeBar
  def self.included(klass)
    klass.send(:define_method, :awesome_bar=) do |val|
      @awesome_bar = "Awesome #{val}"
    end
    klass.send(:attr_reader, :awesome_bar)
  end
end
```

Nothing new here. But here is something that the authors of `AwesomeBar` forgot. They forgot to strip the `val`
and remove the leading and trailing whitespaces. For example. Or any other thing that the authors of gems forget about
because they don't know about your usecases.

Ideally we would like to do what we normally do:

```
#!ruby
class Foo
  include AwesomeBar
  def awesome_bar=(val)
    super(val.strip)
  end
end
```

But this time we can't. Because the gem relies on meta-programming and adds setter method directly to our class.
We would simply overwrite it.

If the gem did not rely on meta programming and followed a simple convention :

```
#!ruby
module AwesomeBar
  def awesome_bar=(val)
    @awesome_bar = "Awesome #{val}"
  end

  attr_reader :awesome_bar
end
```

you would be able to achieve it simply.

## Solution for gem users

Here is what you can do if the gem authors add methods directly to your class:

```
#!ruby
class Foo
  include AwesomeBar

  prepend(Module.new do
    def awesome_bar=(val)
      super(val.strip)
    end
  end)
end
```

Use `prepend` with anonymous module. That way `awesome_bar=` setter defined in the module is higher in the hierarchy.

```
#!ruby
Foo.ancestors
# => [#<Module:0x00000002d0d660>, Foo, AwesomeBar, Object, Kernel, BasicObject]
```

## Solution for gem authors

You can make the life of users of your gem easier. Instead of directly defining methods in the class, you can
include an anonymous module with those methods. With such solution the programmer will be able to use `super``.

```
#!ruby
module AwesomeBar
  def self.included(klass)
    m = Module.new do
      define_method(:awesome_bar=) do |val|
        @awesome_bar = "Awesome #{val}"
      end
      attr_reader :awesome_bar
    end
    klass.include(m)
  end
end
```

That way the module with methods generated using meta-programming techniques are lower in the hierarchy than the class itself.

```
#!ruby
Foo.ancestors
# => [Foo, #<Module:0x000000018062a8>, AwesomeBar, Object, Kernel, BasicObject]
```

Which makes it possible for the users of your gem to just use old school `super`...

```
#!ruby
class Foo
  include AwesomeBar
  def awesome_bar=(val)
    super(val.strip)
  end
end
```

...without resort to using the `prepend` trick that I showed.

## Summary

That's it. That's the entire lesson. If you want more, subscribe to our mailing list below or [buy Fearless Refactoring](http://rails-refactoring.com).

<%= inner_newsletter(item[:newsletter_inside]) %>