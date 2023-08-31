---
created_at: 2023-08-29 20:38:59 +0200
author: Szymon Fiedler
tags: [chatgpt, productivity, copilot, llm, parser, ast, ruby]
publish: true
---

# How to become 10x developer with a help of ChatGPT

Is being a 10x developer still a thing? Trends change, currently there's a lot of chatter around whether LLMs will _take our jobs_, sorry couldn't stand this [South Park](https://www.youtube.com/watch?v=APo2p4-WXsc) reference. 

<!-- more -->

I never allow Copilot to write the full implementation for me, but its contextual suggestions are getting better and better every day. Quite tempting to use it, right? I believe that fixing things written mindlessly with put–your–favorite–llm–model–here will be a big market in the near future. It's not much different from fixing things coming from StackOverflow, but the opponent might be harder to defeat. Time will tell.

Still, there are couple scenarios where tools backed with LLMs shine and can boost your productivity.

## Writing verbose pieces of code, like tests

I prefer self–contained test cases, not dependent on shared setup and micro optimizations coming from poorly understood [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) principle. GitHub's Copilot shines in such scenario. Let me share recent example of test which I added when implementing a [value object](https://blog.arkency.com/tags/value-object/) in [RailsEventStore](https://railseventstore.org):

```ruby
specify "adapter_name" do
  expect(DatabaseAdapter::PostgreSQL.new.adapter_name).to eql("postgresql")
  expect(DatabaseAdapter::MySQL.new.adapter_name).to eql("mysql2")
  expect(DatabaseAdapter::SQLite.new.adapter_name).to eql("sqlite")
end
```

First expectation was written by me, two other were suggested by Copilot, so I've hit tab. 

Same goes for this example:

```ruby
specify "MySQL doesn't support jsonb" do
  expect { DatabaseAdapter::MySQL.new("jsonb") }.to raise_error(InvalidDataTypeForAdapter, "MySQL doesn't support \"jsonb\". Supported types are: binary, json.")
end
```

It was written entirely by a Copilot, based on other already present examples for different adapter types.

This speeds up my work, why not make a use of it?

## Writing utility snippet with a library you rarely use

I recently had to find all occurrences of code like in the snippet below:

```ruby
TRANSLATIONS = { 
	foo: t('foo'),
	bar: t('bar'),
	baz: t('baz'),
}
```

Yes, calls to `I18n` library api, from inside `Hash` assigned to a constant. Great optimization, but it hadn't had a chance to work in request–response cycle where it was used. I've could try to find this code with carefully crafted Regex, spending half a day on it. I quickly figured out that the fastest way it would be to use excellent [Parser gem](https://github.com/whitequark/parser) for that purpose and find this code occurrences within Ruby's Abstract Syntax Tree. I do not use this library on a daily basis, rather from time to time. Probably I've would written desired code within half an hour. Instead I've asked ChatGPT to write this snippet for me. In natural language. It took me 3 minutes to have code in a shape which solved my problem — 1/10th of a time. Can I call myself 10x developer now? See how it went:

_— Write me a code snippet using Ruby Parser gem for AST parsing to get all the occurrences of hashes assigned to constants. Those hashes have method t with string argument as values._

_— Sure! You can use the parser gem in Ruby to parse Ruby code and traverse the Abstract Syntax Tree (AST) to find specific patterns. In this case, you're looking for hashes assigned to constants, where the values of the hash are calls to a method t with a string argument._

_Below is a code snippet that does just that. You'll need to install the parser gem if you haven't already._

```ruby
require 'parser/current'

code = <<-RUBY
  MY_CONSTANT = { key1: t('value1'), key2: t('value2') }
  ANOTHER_CONSTANT = { key: 'value' }
  MY_SECOND_CONSTANT = { key3: t('value3'), key4: t('value4') }
RUBY

buffer = Parser::Source::Buffer.new('(string)')
buffer.source = code

parser = Parser::CurrentRuby.new
tree = parser.parse(buffer)

# Define visitor to handle nodes
class Visitor
  def visit(node)
    case node.type
    when :casgn
      handle_casgn(node)
    end
    node.children.each { |child| visit(child) if child.is_a?(AST::Node) }
  end

  def handle_casgn(node)
    constant_name = node.children[1]
    value_node = node.children[2]

    if value_node.type == :hash
      value_node.children.each do |pair|
        key, value = pair.children
        if value.type == :send && value.children[1] == :t
          argument = value.children[2]
          if argument.type == :str
            puts "Found hash assigned to constant #{constant_name}: #{key.children[0]} => t('#{argument.children[0]}')"
          end
        end
      end
    end
  end
end

# Visit the AST
Visitor.new.visit(tree)

```
_— Print the filename and line of code additionally_

```ruby
require 'parser/current'

filename = 'example.rb'
code = File.read(filename)

buffer = Parser::Source::Buffer.new(filename)
buffer.source = code

parser = Parser::CurrentRuby.new
tree = parser.parse(buffer)

# Define visitor to handle nodes
class Visitor
  def initialize(filename)
    @filename = filename
  end

  def visit(node)
    case node.type
    when :casgn
      handle_casgn(node)
    end
    node.children.each { |child| visit(child) if child.is_a?(AST::Node) }
  end

  def handle_casgn(node)
    constant_name = node.children[1]
    value_node = node.children[2]

    if value_node.type == :hash
      value_node.children.each do |pair|
        key, value = pair.children
        if value.type == :send && value.children[1] == :t
          argument = value.children[2]
          if argument.type == :str
            line_number = node.location.line
            line = File.readlines(@filename)[line_number - 1].strip
            puts "Found in #{@filename}, line #{line_number}: #{line} - #{constant_name}: #{key.children[0]} => t('#{argument.children[0]}')"
          end
        end
      end
    end
  end
end

# Visit the AST
Visitor.new(filename).visit(tree)
```
_— Could improve it so it takes several directories as argument from command line?_

```ruby
require 'parser/current'
require 'find'

# Define visitor to handle nodes
class Visitor
  def initialize(filename)
    @filename = filename
  end

  def visit(node)
    case node.type
    when :casgn
      handle_casgn(node)
    end
    node.children.each { |child| visit(child) if child.is_a?(AST::Node) }
  end

  def handle_casgn(node)
    constant_name = node.children[1]
    value_node = node.children[2]

    if value_node.type == :hash
      value_node.children.each do |pair|
        key, value = pair.children
        if value.type == :send && value.children[1] == :t
          argument = value.children[2]
          if argument.type == :str
            line_number = node.location.line
            line = File.readlines(@filename)[line_number - 1].strip
            puts "Found in #{@filename}, line #{line_number}: #{line} - #{constant_name}: #{key.children[0]} => t('#{argument.children[0]}')"
          end
        end
      end
    end
  end
end

def process_file(filename)
  code = File.read(filename)
  buffer = Parser::Source::Buffer.new(filename)
  buffer.source = code

  parser = Parser::CurrentRuby.new
  tree = parser.parse(buffer)

  # Visit the AST
  Visitor.new(filename).visit(tree)
end

def process_directory(directory)
  Find.find(directory) do |path|
    if FileTest.directory?(path)
      next
    else
      if path.end_with?('.rb')
        process_file(path)
      end
    end
  end
end

if ARGV.empty?
  puts "Please provide one or more directory paths to search for Ruby files."
else
  ARGV.each do |directory|
    if File.directory?(directory)
      process_directory(directory)
    else
      puts "#{directory} is not a valid directory."
    end
  end
end
```

Thanks to that I was able to rapidly locate wrong code living in `app/` and `lib/` directories of the application I was working on at that time.

## Handling communication issues

The situation has got pretty tense and you start acting like [Gordon Ramsay](https://knowyourmeme.com/memes/you-fucking-donkey)? There it goes:

_— Write "you f*cking donkey" in a nice manner_

_— Certainly! A more polite way to express the sentiment could be "You've made a mistake."_

_— How would I say that to a coworker?_

_— If you need to address an issue with a coworker, it's important to be respectful and professional. You might say something like:_

_"Hey [Name], it looks like there was a small error here. Could we discuss how to correct it?"_

_This way, you bring attention to the mistake without being confrontational, allowing for a constructive conversation._

You've just avoided meeting with HR. Quite nice, isn't it? 

I've tried to look for a funny example. Obviously you can engage LLM for a more serious use like looking for arguments in support of the thesis you're trying to advance. Or better understanding domain you're working on if you don't have domain expert next to you.

What's your take on that? Hit me up on [X](https://twitter.com/szymonfiedler), I'm happy to discuss other use–cases.

