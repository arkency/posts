---
title: "Using ruby parser and AST tree to find deprecated syntax"
created_at: 2017-12-22 11:32:22 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby', 'parser', 'AST', 'rails', 'upgrade' ]
newsletter: :arkency_form
---

Sometimes we doing large refactoring or upgrades we would like to find places in the code for which `grep` or Rubymine search is not good enough. These are usually cases where you would like to use something more powerful. And we can do that.

<!-- more -->

I am upgrading this old app to Rails 4.1 and the [official guide mentions this case](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#usage-of-return-within-inline-callback-blocks):

> Previously, Rails allowed inline callback blocks to use return this way:

```ruby
class Model < ActiveRecord::Base
  before_save { return false }
end
```

> This behavior was never intentionally supported. Due to a change in the internals of `ActiveSupport::Callbacks`, this is no longer allowed in Rails 4.1. Using a return statement in an inline callback block causes a `LocalJumpError` to be raised when the callback is executed.

Of course, the same code could look like:

```ruby
class Model < ActiveRecord::Base
  before_save do
    return false if something?
  end
end
```

or be even more complex/nested.

I did not want to look at all possible files and callbacks to figure out whether there is a statement like that or not. I decided to use [a ruby parser](https://github.com/whitequark/parser) and check the AST for blocks which have a return statement.

I am not super skilled in using this gem or its binaries. I know it can be used for [rewriting Ruby in Ruby](https://whitequark.org/blog/2013/04/26/lets-play-with-ruby-code/) because my coworkers used it for doing big rewrites across big Rails apps. But I've never played with it before myself. This was my first approach. And I think it went fine :)

## Easy beginning

I started by having a small ruby example showing more or less that kind of code I was trying to detect and parsing it to see what it looks like.

```ruby
require 'parser/current'

code = <<-RUBY
  class Model < ActiveRecord::Base
    before_save do
      if something
        return 5
      end
    end
    before_update { return 6 if false }
  end
RUBY

ast = Parser::CurrentRuby.parse(code)
```

and it gives us:

```
s(:class,
  s(:const, nil, :Model),
  s(:const,
    s(:const, nil, :ActiveRecord), :Base),
  s(:begin,
    s(:block,
      s(:send, nil, :before_save),
      s(:args),
      s(:if,
        s(:send, nil, :something),
        s(:return,
          s(:int, 5)), nil)),
    s(:block,
      s(:send, nil, :before_update),
      s(:args),
      s(:if,
        s(:false),
        s(:return,
          s(:int, 6)), nil))))
```

the result has overwritten `inspect` method so the output looks a bit unusual. But here is what it is.

```ruby
ast.type
# => :class

ast.class
# => Parser::AST::Node

ast.children.size
# => 3
ast.children.first.type
 => :const
```

## in the deep

And that's all I needed to know. I can read a node's `type` and it can be for example `:block` or `:return` symbols. I can iterate over children (1st level) with `children`. There is probably much more you can. I wanted to iterate over all `descendants` but I couldn't find an easy way to do it. Nevertheless, `children` was good enough for me. I decided to write a recursive algorithm which will look for `:block` nodes and inside them for `:return` nodes.

```ruby
def look_for_block(ast)
  return unless Parser::AST::Node === ast
  if ast.type == :block          # when we found block
    ast.children.map do |child|
      look_for_return(child)     # let's look for returns in it
    end.any?
  else
    ast.children.map do |child|  # otherwise let's look for blocks
      look_for_block(child)      # deeper in the AST
    end.any?
  end
end

def look_for_return(ast)
  return false unless Parser::AST::Node === ast
  if ast.type == :return
    return true
  else                            # if this is not a return
    ast.children.map do |child|
      look_for_return(child)      # maybe it is somewhere deeper
    end.any?
  end
end
```

Since this was quite a simple query I didn't mind writing it by hand. Looking for X inside Y when Z is something would be less trivial. When I was writing it my first thought was that XPath queries could be an interesting way of expressing such queries. After all that would be just `//block//return` query, I believe. Maybe there is a gem for that. I don't know, if you do, let me know.

Anyway, it seemed to work on my artificial example so I was hopeful :)

```ruby
code = <<-RUBY
  class Model < ActiveRecord::Base
    before_save do
      if something
        return 5
      end
    end
    before_update { return 6 if false }
  end
RUBY
ast = Parser::CurrentRuby.parse(code)
look_for_block(ast)
# => true
```

The only thing left for me to do was checking it out on all files in my Rails project.

```ruby
Dir.glob("app/**/*.rb").select do |file|
  ast = Parser::CurrentRuby.parse(File.read(file))
  look_for_block(ast)
end
# => [
#  "app/controllers/cart_controller.rb",
#  "app/models/package.rb",
#  "app/models/rule.rb",
#  "app/services/products/service.rb"
# ]
```

And it worked! It found usages such as:

```ruby
FileUtils.cd(working_directory) do
  cmd = "..."
  return system(cmd)
```

or

```ruby
module Products
  class Service
    def bulk_destroy(cmd)
      Product.transaction do
        # ...
        return BulkDestroyResult.new(destroyed_ids, preserved_ids)
```

or

```ruby
class Controller
  def action
    # ...
    respond_to do |format|
      format.html do
        if something
          # ...
        else
          redirect_to cart_path and return
```

All of them had a `return` statement inside a block. But in the end, none of them were callbacks, so I didn't have to change anything.

BTW, all of that - not needed if you have very good code coverage and you can just rely on test failures to bring broken code to your attention after Rails upgrade.

## Read more

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our everyday struggles and solutions for building maintainable Rails apps which don't surprise you.

Also worth reading:

* [Could we drop Symbols from Ruby?](/could-we-drop-symbols-from-ruby/) - one of the most controversial posts of 2017, don't know why ;)
* [Why we follow the Rails repo structure in Rails Event Store](/why-we-follow-rails-repo-structure-in-rails-event-store/) - how we started using monorepo approach for our gems which work together.
* [That one time I used recursion to solve a problem](/that-one-time-i-used-recursion-to-solve-a-problem/) - today I showed you a solution using a recursion. I once used such approach also for calculating reminders.
* [inject vs each_with_object](/inject-vs-each-with-object/) - are you just starting your Ruby journey? Make sure to get the difference between `inject` and `each_with_object`. They are both useful methods you should know.

And don't forget to check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.