---
title: "Using singleton objects as default arguments in Ruby"
created_at: 2018-04-23 16:33:02 +0200
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'rails' ]
newsletter: arkency_form
---

Sometimes you would like to define a method which takes an optional argument, but the programmer might pass `nil`. And your code needs to distinguish between the value not being provided (default value) and `nil`. How can it be achieved?

<!-- more -->

The usual solution for default value is to define them as `nil` or other empty/zero values which makes sense such as 0 or a string, an empty array, etc. 

```ruby
class Foo
  def bar(one, two: nil)
    # ...
  end
end
```

But what if you need to distinguish between `nil` and no value being provided? What if you want to distinguish between:

```ruby
foo.bar(:something, two: nil)
```

and

```ruby
foo.bar(:something)
```

Here is the solution. Define a single, unique object and use it as a default. And instead of checking if the passed argument is `nil` check if that's the singleton object or not.

```ruby
class Foo
  NOT_PROVIDED = Object.new
  
  def bar(one, two: NOT_PROVIDED)
    puts one.inspect
    if two == NOT_PROVIDED
      puts "not provided"
    else
      puts two.inspect
    end
  end
  
  private_constant :NOT_PROVIDED
end
```

using `private_constant` is not necessary but [I like to remind Ruby devs that we can use it for ages](https://blog.arkency.com/2016/02/private-classes-in-ruby/) and that we can have private classes that way as well. 

```
Foo.new.bar(1)
1
not provided

Foo.new.bar(1, two: 2)
1
2
```

You could use a symbol (`:not_provided`) or number or anything else that's unique in ruby, but in general methods (such as `assert_changes` described below) they could be valid objects to be provided as an argument. So the best way to solve it, is to use a unique object that nobody can pass as an argument. 

Here is how Rails is using it to implement `assert_changes`:

```ruby
assert_changes :@object, from: nil, to: :foo do
  @object = :foo
end

assert_changes -> { object.counter }, from: 0, to: 1 do
  object.increment
end
```

```ruby
UNTRACKED = Object.new
def assert_changes(expression, message = nil, from: UNTRACKED, to: UNTRACKED, &block)
  exp = if expression.respond_to?(:call)
    expression
  else
   -> { eval(expression.to_s, block.binding) }
  end

  before = exp.call
  retval = yield

  unless from == UNTRACKED
    error = "#{expression.inspect} isn't #{from.inspect}"
    error = "#{message}.\n#{error}" if message
    assert from === before, error
  end

  after = exp.call

  if to == UNTRACKED
    error = "#{expression.inspect} didn't changed"
    error = "#{message}.\n#{error}" if message
    assert_not_equal before, after, error
  else
    error = "#{expression.inspect} didn't change to #{to}"
    error = "#{message}.\n#{error}" if message
    assert to === after, error
  end

  retval
end
```

I guess I prefer the rspec approach

```ruby
expect do
  object.increment
end.to change{ object.counter }.from(0).to(1)
```

but I admire the `assert_changes` implementation which uses `UNTRACKED` object.

Although, it's kind of similar to using boolean arguments, which often is an indicator that 2 separate methods should be defined. So instead of `foo(1, true)` and `foo(1, false)`, it is often argued it's better to just have `foo(1)` and `bar(1)` and I usually agree with this guideline. However, in case of `assert_changes` the usage of named arguments and singleton object seems OK to me.

### Would you like to continue learning more?

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our every day struggles and solutions for building maintainable Rails apps which don't surprise you.

You might enjoy reading:

* [Composable RSpec matchers](/composable-rspec-matchers/) - how to implement nice RSpec matchers `expect(domain_event).to be_an_event(OrderPlaced).with_data(order_id: 42).strict`
* [inject vs each_with_object](/inject-vs-each-with-object/) - 2 very popular ruby methods, what's the difference between them
* [The === (case equality) operator in Ruby explained](/the-equals-equals-equals-case-equality-operator-in-ruby/) - Meet the power of `===` operator
* [Relative Testing vs Absolute Testing](/relative-testing-vs-absolute-testing/) - 2 modes of testing that you can switch between to make writing tests easier.
* [Using ruby parser and AST tree to find deprecated syntax](/using-ruby-parser-and-ast-tree-to-find-deprecated-syntax/) - when grep is not enough for your refactorings.


**Also, make sure to check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.**
