---
title: "Using anonymous modules and prepend to work with generated code"
created_at: 2016-02-29 11:41:56 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'metaprogramming', 'prepend', 'anonymous-modules' ]
newsletter_inside: clean
---

In my previous blog-post [about using setters](/2016/01/drop-this-before-validation-and-use-method/)
one of the commenter mentioned a case in which **the setter methods are created by a gem. How can we
overwrite the setters in such situation?**

<!-- more -->

Imagine a gem `awesome` which gives you `Awesome` module that you could use in your class
to get  `awesome` getter and `awesome=(val)` setter with an interesting logic.
You would use it like that:

```ruby
class Foo
  extend Awesome
  attribute :awesome
end

f = Foo.new
f.awesome = "hello"
f.awesome
# => "Awesome hello"
```

and here is a silly `Awesome` implementation which uses meta programming to
generate the methods like some gems do.

Be aware that it is a bit contrived example.

```ruby
module Awesome
  def attribute(name)
    define_method("#{name}=") do |val|
      instance_variable_set("@#{name}", "Awesome #{val}")
    end
    attr_reader(name)
  end
end
```

Nothing new here. But here is something that the authors of `Awesome` forgot. They forgot to strip the `val`
and remove the leading and trailing whitespaces. For example. Or any other thing that the authors of gems forget about
because they don't know about your usecases.

Ideally we would like to do what we normally do:

```ruby
class Foo
  extend Awesome
  attribute :awesome

  def awesome=(val)
    super(val.strip)
  end
end
```

But this time we can't. Because the gem relies on meta-programming and adds setter method directly to our class.
We would simply overwrite it.

```ruby
Foo.new.awesome = "bar"
# => NoMethodError: super: no superclass method `awesome=' for #<Foo:0x000000012ff0e8>
```

If the gem did not rely on meta programming and followed a simple convention:

```ruby
module Awesome
  def awesome=(val)
    @awesome = "Awesome #{val}"
  end

  attr_reader :awesome
end

class Foo
  include Awesome

  def awesome=(val)
    super(val.strip)
  end
end
```

you would be able to achieve it simply. But gems which need the field names to be provided
by the programmers don't have such comfort.

## Solution for gem users

Here is what you can do if the gem authors add methods directly to your class:

```ruby
class Foo
  extend Awesome
  attribute :awesome

  prepend(Module.new do
    def awesome=(val)
      super(val.strip)
    end
  end)
end
```

Use `prepend` with anonymous module. That way `awesome=` setter defined in the module is higher in the hierarchy.

```ruby
Foo.ancestors
# => [#<Module:0x00000002d0d660>, Foo, Object, Kernel, BasicObject]
```

## Solution for gem authors

You can make the life of users of your gem easier. Instead of directly defining methods in the class, you can
include an anonymous module with those methods. With such solution the programmer will be able to use `super``.

```ruby
module Awesome
  def awesome_module
    @awesome_module ||= Module.new().tap{|m| include(m) }
  end

  def attribute(name)
    awesome_module.send(:define_method, "#{name}=") do |val|
      instance_variable_set("@#{name}", "Awesome #{val}")
    end
    awesome_module.send(:attr_reader, name)
  end
end
```

That way the module, with methods generated using meta-programming techniques, is lower
in the hierarchy than the class itself.

```ruby
Foo.ancestors
# => [Foo, #<Module:0x000000018062a8>, Object, Kernel, BasicObject]
```

Which makes it possible for the users of your gem to just use old school `super` ...

```ruby
class Foo
  extend Awesome
  attribute :awesome

  def awesome=(val)
    super(val.strip)
  end
end
```

...without resort to using the `prepend` trick that I showed.

## Summary

That's it. That's the entire lesson. If you want more, subscribe to our mailing list below or [buy Fearless Refactoring](http://rails-refactoring.com).

<%= show_product_inline(item[:newsletter_inside]) %>

## More

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="<%= src_fit("rbe/rbe-cover.png") %>" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="/blogging"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
