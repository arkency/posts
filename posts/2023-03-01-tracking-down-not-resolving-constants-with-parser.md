---
created_at: 2023-03-01 14:00:31 +0100
author: Piotr Jurewicz
tags: []
publish: false
---

# Tracking down not resolving constants with parser

Lately, we have been working on upgrading an obsolete stack of one Ruby app. This application was running on Ruby 2.4.
After dropping dozens of unused gems, performing security updates, and eliminating deprecation warnings, we decided it's time for a Ruby upgrade.
This is where the story REALLY begins.

<!-- more -->

## Top-level constant lookup

One of the major changes introduced in Ruby 2.5 was [removing top-level constant lookup](https://github.com/ruby/ruby/commit/44a2576f79).
It means a breaking change of how Ruby resolves constants. Let me explain it with an example.
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

If we tried to do the same in Ruby 2.5 and later, we would get an error.
```
[1] pry(main)> RUBY_VERSION
=> "2.5.9"
[2] pry(main)> A::B::C
NameError: uninitialized constant A::B::C
from (pry):8:in `<main>'
```

As the codebase was huge and poorly tested, we had to find a smart way to track down all the places where this change would break the app.

## Parser gem

Paweł came up with the idea to use a [parser tool](https://github.com/whitequark/parser) for this purpose.
Examples of using this powerful gem have already been described by us [on the blog](https://blog.arkency.com/tags/parser/).

```ruby
require "parser/runner"
require "rubocop"
require "unparser"
require "set"

require_relative "config/environment"

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
      return if namespace.lvar_type? # products_klazz::RENTERS
      return if namespace.send_type? # obj.rating_namespace::Settings
      return if namespace.self_type? # self::ENCRYPTED_ID_PREFIX
      break if namespace.cbase_type?
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