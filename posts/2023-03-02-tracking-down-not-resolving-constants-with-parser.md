---
created_at: 2023-03-02 14:00:31 +0100
author: Piotr Jurewicz
tags: []
publish: true
---

# Tracking down not resolving constants with parser

Lately, we have been working on upgrading an obsolete stack of one Ruby app.
This application was running on Ruby 2.4.
After dropping 50 unused gems, performing security updates, and eliminating deprecation warnings, we decided it was time for a Ruby upgrade.

This is where the story REALLY begins, and I encourage you to keep reading even if you are not interested in the old Ruby version's internals.
In the end, I will give you a powerful tool to help you track down not resolving constants in your codebase.
<!-- more -->

## Top-level constant lookup

One of the major changes introduced in Ruby 2.5 was [removing top-level constant lookup](https://github.com/ruby/ruby/commit/44a2576f79).
It means a breaking change in how Ruby resolves constants. Let me explain it with an example.
```ruby
class A
  class B
  end
end

class C
end
```

In Ruby 2.4 and earlier, the output of calling `A::B::C` is `C`. Are you surprised? I was.
```
[1] pry(main)> RUBY_VERSION
=> "2.4.5"
[2] pry(main)> A::B::C
(pry):20: warning: toplevel constant C referenced by A::B::C
=> C
```

The warning message suggests that we are doing something that may have unexpected results.

If we tried to do the same in Ruby 2.5 and later, we would get an error.
```
[1] pry(main)> RUBY_VERSION
=> "2.5.9"
[2] pry(main)> A::B::C
NameError: uninitialized constant A::B::C
from (pry):8:in `<main>'
```

As the codebase was huge and poorly tested, we had to find a smart way to track down all the places where this change would break the app.

It would be relatively easy to grep with regexp all the constants used in the codebase, but then we had to find out if they resolved correctly from the context they are being used.

## Parser gem

Paweł came up with the idea to use a [parser tool](https://github.com/whitequark/parser) for this purpose.
Examples of using this powerful gem have already been described by us [on the blog](https://blog.arkency.com/tags/parser/).

In short, it allows parsing Ruby code into an AST (abstract syntax tree) and then traversing it.

### Processor
We started with extending the `Parser::AST::Processor` class and overriding the `on_const` method which gets trigerred for every constant found in the code.
```ruby
class Collector < Parser::AST::Processor
  include AST::Sexp

  def initialize
    @store = Set.new
    @root_path = Rails.root
  end

  def suspicious_consts
    @store.to_a
  end

  def on_const(node)
    return if node.parent.module_definition?
    return if node.parent.class_definition?

    namespace = node.namespace
    while namespace
      return if namespace.lvar_type? # local_variable::SOME_CONSTANT
      return if namespace.send_type? # obj.method::SomeClass
      return if namespace.self_type? # self::SOME_CONSTANT
      break if namespace.cbase_type? # we reached the top level
      namespace = namespace.namespace
    end
    const_string = Unparser.unparse(node)

    if node.namespace&.cbase_type?
      return if validate_const(const_string)
    else
      namespace_const_names =
        node
          .each_ancestor
          .select { |n| n.class_type? || n.module_type? }
          .map { |mod| mod.children.first.const_name }
          .reverse

      (namespace_const_names.size + 1).times do |i|
        concated = (namespace_const_names[0...namespace_const_names.size - i] + [node.const_name]).join("::")
        return if validate_const(concated)
      end
    end
    store(const_string, node.location)
  end

  def store(const_string, location)
    @store << [
      File.join(@root_path, location.name.to_s),
      const_string
    ]
  end

  def validate_const(namespaced_const_string)
    eval(namespaced_const_string)
    true
  rescue NameError, LoadError
    false
  end
end
```

Guards in the `on_const` method are there to skip constants that are part of the class/module definition. We look for usages only.
```ruby
return if node.parent.module_definition?
return if node.parent.class_definition?
```

Than, we drop all the dynamic usages which are hard to validate and need special handling.
```ruby
namespace = node.namespace
while namespace
  return if namespace.lvar_type? # local_variable::SOME_CONSTANT 
  return if namespace.send_type? # obj.method::SomeClass
  return if namespace.self_type? # self::SOME_CONSTANT
  break if namespace.cbase_type? # we reached the top level
  namespace = namespace.namespace
end
```

After that, we check if the filtered-out constants resolve correctly.
If the constant is explicitly referenced from the top-level, we just try to evaluate it.
In other cases, we must consider the namespace in which the constant is used and try to call it with the full namespace prepended, and then with one level less, and so on, until we reach the top level binding.
```ruby
if node.namespace&.cbase_type?
  return if validate_const(const_string)
else
  namespace_const_names =
    node
      .each_ancestor
      .select { |n| n.class_type? || n.module_type? }
      .map { |mod| mod.children.first.const_name }
      .reverse

  (namespace_const_names.size + 1).times do |i|
    concated = (namespace_const_names[0...namespace_const_names.size - i] + [node.const_name]).join("::")
    return if validate_const(concated)
  end
end
```
Finally, we store constants that failed to resolve with their location in the codebase.

### Runner
Another class to extend is `Parser::Runner` which is responsible for parsing the files and passing them to the processor.
```ruby
runner =
  Class.new(Parser::Runner) do
    def runner_name
      "dudu"
    end

    def process(buffer)
      parser = @parser_class.new(RuboCop::AST::Builder.new)
      collector = Collector.new
      collector.process(parser.parse(buffer))
      show(collector.suspicious_consts)
    end

    def show(collection)
      return if collection.empty?
      puts
      collection.each { |pair| puts pair.join("\t") }
    end
  end

runner.go(ARGV)
```

## Results
We ensured that eager loading is enabled and invoked the script on Ruby 2.4 and 2.5 to compare the results.
```bash
bundle exec ruby collector.rb app/ lib/
```
It turned out that there were 52 constants that were not resolving correctly in Ruby 2.5 and only 7 fewer in Ruby 2.4.
**It means there were already 45 possible sources of run-time errors in the codebase which were not detectable by existing tests!** 🤯

Fortunately, some of them were located in the code that was not used anymore, so we could just safely remove those methods.

## Bonus
We published the script within the context of the example app on GitHub.

Check it out at: [https://github.com/arkency/constants-resolver](https://github.com/arkency/constants-resolver). 
Copy and run `collector.rb` against your codebase and see if your app is free of not resolving constants. If you find something, share this solution with your friends to help them avoid problems too.