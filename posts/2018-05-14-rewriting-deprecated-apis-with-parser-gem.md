---
title: "Rewriting deprecated APIs with parser gem"
created_at: 2018-05-14 23:35:00 +0200
kind: article
publish: false
author: Paweł Pacana
tags: ['ruby', 'parser', 'AST', 'rails_event_store' ]
newsletter: :arkency_form
img: "rewriting_deprecated_apis_with_parser_gem/rewriting_deprecated_apis_with_parser_gem.jpg"
---

<%= img_fit("rewriting_deprecated_apis_with_parser_gem/rewriting_deprecated_apis_with_parser_gem.jpg") %>

In upcoming [Rails Event Store](https://railsevenstore.org) release we're going to deprecate existing reader methods. They'll be replaced in favor of fluent query interface — popularized by ActiveRecord. In order to make this transition a bit easier, we've prepared a script to transform given codebase to utilize new APIs.

<!-- more -->

Long story short: we had six different query methods that allowed reading streams of events forward or backward, up to certain limit of events or not and finally starting from beginning or given position in a stream. Example:

```ruby
client.read_events_backward('Order$1', limit: 5, start: :head).each do |event|
  # do something with up-to 5 events from Order$1 stream read backwards
end
```

We've [decided to change it](https://github.com/RailsEventStore/rails_event_store/issues/184) to something like this:

```ruby

spec = client.read.stream('Order$1').from(:head).limit(5).backward
spec.each do |event|
  # do something with up-to 5 events from Order$1 stream read backwards
end
```

Deprecating APIs seems easy — issue warning on old method call, maybe suggest new usage:

```ruby
specify do
  expect { client.read_events_backward('some_stream') }.to output(<<~EOS).to_stderr
    RubyEventStore::Client#read_events_backward has been deprecated.

    Use following fluent API to receive exact results:
    client.read.stream(stream_name).limit(count).from(start).backward.each.to_a
  EOS
end
```

It is however more burdensome for the end-user than it looks on first sight:

* more often it several usages over codebase
* you'd have to exercise all involved code paths to get that deprecation warnings
* not all usages are equal (different keyword arguments to reader methods) and you'd have to account for default values (like limit being 100 implicitly)

Digging though codebase for usage and manual replace or maybe some `sed` trickery would help, sure. The thing is we can do better. We can rewrite Ruby, using Ruby. Enter excellent `parser` gem:

```
gem ins parser
```

It all begins with analyzing how the code we want to replace looks like in AST. Consider the aforementioned example:

```ruby
$ ruby-parse -e "client.read_events_backward('Order$1', limit: 5, start: :head)"         

(send
 (send nil :client) :read_events_backward
 (str "Order$1")
 (hash
   (pair
     (sym :limit)
     (int 5))
   (pair
     (sym :start)
     (sym :head))))
```

Here we've learned that `:read_events_backward` is a message sent to what appears to be a client receiver. We can also see how arguments, positional and keyword, are represented as AST nodes.

Next piece of the puzzle is a thing called `Parser::Rewriter` (or `Parser::TreeRewriter` in latest `parser` releases). It let's you modify AST node in following ways:

```ruby
insert_after(range, content)
insert_before(range, content)
remove(range)
replace(range, content)
```

What are its arguments? Content stands for string with code. In our case that would be `client.read.stream('Order$1').from(:head).limit(5).backward.each.to_a`. With `range` it's a bit more complicated. Let's use `ruby-parse -L` to reveal more secrets:

```ruby
ruby-parse -L -e 'client.read_events_backward(\'Order$1\', limit: 5, start: :head)'

s(:send,
  s(:send, nil, :client), :read_events_backward,
  s(:str, "Order$1"),
  s(:hash,
    s(:pair,
      s(:sym, :limit),
      s(:int, 5)),
    s(:pair,
      s(:sym, :start),
      s(:sym, :head))))
client.read_events_backward('Order$1', limit: 5, start: :head)
      ~ dot                         
       ~~~~~~~~~~~~~~~~~~~~ selector                         ~ end
                           ~ begin                                       
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ expression
s(:send, nil, :client)
client.read_events_backward('Order$1', limit: 5, start: :head)
~~~~~~ selector  
~~~~~~ expression
s(:str, "Order$1")
client.read_events_backward('Order$1', limit: 5, start: :head)
                            ~ begin ~ end       
                            ~~~~~~~~~ expression
s(:hash,
  s(:pair,
    s(:sym, :limit),
    s(:int, 5)),
  s(:pair,
    s(:sym, :start),
    s(:sym, :head)))
client.read_events_backward('Order$1', limit: 5, start: :head)
                                       ~~~~~~~~~~~~~~~~~~~~~~ expression
s(:pair,
  s(:sym, :limit),
  s(:int, 5))
client.read_events_backward('Order$1', limit: 5, start: :head)
                                            ~ operator    
                                       ~~~~~~~~ expression
s(:sym, :limit)
client.read_events_backward('Order$1', limit: 5, start: :head)
                                       ~~~~~ expression
s(:int, 5)
client.read_events_backward('Order$1', limit: 5, start: :head)
                                              ~ expression
s(:pair,
  s(:sym, :start),
  s(:sym, :head))
client.read_events_backward('Order$1', limit: 5, start: :head)
                                                      ~ operator        
                                                 ~~~~~~~~~~~~ expression
s(:sym, :start)
client.read_events_backward('Order$1', limit: 5, start: :head)
                                                 ~~~~~ expression
s(:sym, :head)
client.read_events_backward('Order$1', limit: 5, start: :head)
                                                        ~ begin         
                                                        ~~~~~ expression
```

With `-L` switch `ruby-parse` was kind enough to describe to us those ranges in each AST node. We can use them to refer to particular locations in parsed code.

For example following description teaches us that `node.location.selector` refers to area between `client.` and `('Order$1', limit: 5, start: :head)`.

```ruby
s(:send,
  s(:send, nil, :client), :read_events_backward,
  s(:str, "Order$1"),
  s(:hash,
    s(:pair,
      s(:sym, :limit),
      s(:int, 5)),
    s(:pair,
      s(:sym, :start),
      s(:sym, :head))))
client.read_events_backward('Order$1', limit: 5, start: :head)
      ~ dot                         
       ~~~~~~~~~~~~~~~~~~~~ selector                         ~ end
                           ~ begin                                       
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ expression
```

What's more, ranges can be joined. Calling `node.location.selector.join(node.location.end)` would get you range for `read_events_backward('Order$1', limit: 5, start: :head)`. Exactly what we're looking for!

All good so far, but how exactly you'd get that `node` for `replace`?
This `Parser::Rewriter` class is a descendant of `Parser::AST::Processor`. Given parsed AST and source buffer, it will call our method handlers as soon as a matching tree is found:


```ruby
class DeprecatedReadAPIRewriter < ::Parser::Rewriter
  def on_send(node)
    _, method_name, *args = node.children
    replace_range = replace_range.join(node.location.end)

    case method_name
    when :read_events_backward
      replace(replace_range, "read.stream('Order$1').from(:head).limit(5).backward.each.to_a")
    end
  end
end
```

In the example above we totally disregard arguments passed to the `read_events_backward` method. This is fine since we're focusing on first example in TDD flow and giving more specific test examples would drive this code to become more generic.

Full infrastructure to get it going:

```ruby
RSpec.describe DeprecatedReadAPIRewriter do
  def rewrite(string)
    parser   = Parser::CurrentRuby.new
    rewriter = DeprecatedReadAPIRewriter.new
    buffer   = Parser::Source::Buffer.new('(string)')
    buffer.source = string

    rewriter.rewrite(buffer, parser.parse(buffer))
  end

  specify 'take it easy' do
    expect(rewrite("client.read_events_backward('Order$1', limit: 5, start: :head)"))
      .to eq("read.stream('Order$1').from(:head).limit(5).backward.each.to_a")
  end
end
```

To recap, we've learned how to read parsed Ruby code in AST and how to use this knowledge in order to transform it to something new. And that's just the tip of the iceberg!

Full `DeprecatedReadAPIRewriter` [script](https://github.com/RailsEventStore/rails_event_store/blob/master/ruby_event_store/lib/ruby_event_store/deprecated_read_api_rewriter.rb) with [specs](https://github.com/RailsEventStore/rails_event_store/blob/540d1822d29017d0010562e1f1a112a2adc0fc72/ruby_event_store/spec/deprecated_spec_api_rewriter_spec.rb) to study in Rails Event Store [repository]().


### Hungry for more?

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our every day struggles and solutions for building maintainable Rails apps which don't surprise you.

You might enjoy reading:

* [Using Ruby parser and the AST tree to find deprecated syntax](/using-ruby-parser-and-ast-tree-to-find-deprecated-syntax/) — when `grep` is just not good enough

* [One simple trick to make Event Sourcing click](/one-simple-trick-to-make-event-sourcing-click/) — the curious case of explaining Event Sourcing with Aggregate Root

* [Process Managers revisited](/process-managers-revisited/) — how coordinate events over time and put a barrier that breaks as soon as they all happened

**Also, make sure to check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.**
