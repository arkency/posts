---
title: "A single Rails API endpoint to accept all changes to the app state"
created_at: 2015-12-06 02:45:55 +0100
publish: true
tags: [ 'rails', 'cqrs', 'commands' ]
author: Andrzej Krzywda
---

This idea is heavily influenced by CQRS and its way of applying changes to the app via commands objects. In this blogpost we're showing how it could work with Rails.

<!-- more -->

Commands are data structures which represent the intention of the user. In the Rails community, we sometimes use the name of "a form object" to represent the same meaning.

In some of our projects, we started moving to a command-driven approach. A command is handled by a command handler (often it's a service object). As a result of handling the command we publish domain events.

When you switch to commands, you'll notice that many controllers look alike and they're becoming a boiler-plate code which you repeat over and over.

This is what led to a conversation between me and [Paweł](https://twitter.com/pawelpacana). We discussed whether it makes sense to have just one controller, being represented by just one API endpoint.

Paweł decided to experiment with this idea and wrote the code below. This code is also a nice example of how concise can be a one-file-Rails application. 

```ruby

require 'action_controller/railtie'
require 'securerandom'

module Command
  Error = Class.new(StandardError)
end

module Service
  Error = Class.new(StandardError)
end

FooBarCommand = Class.new(OpenStruct) do
  ValidationError = Class.new(Command::Error)
  def validate!
    raise ValidationError if [foo, bar].any? { |value| value.nil? || value == '' }
  end
end

class FooBarService
  FooNotFooError = Class.new(Service::Error)
  def call(cmd)
    raise FooNotFooError unless cmd.foo == 'foo'
  end
end

COMMANDS =
  { 'foo_bar' => FooBarCommand,
  }

HANDLERS =
  { FooBarCommand => FooBarService.new,
  }

class Dummy < ::Rails::Application
  config.eager_load = false
  config.secret_key_base = SecureRandom.hex
end

class CommandsController < ActionController::Base
  def create
    cmd =
      COMMANDS
        .fetch(params[:command])
        .new(params.except(:command))
    cmd.validate!
    HANDLERS
      .fetch(cmd.class)
      .call(cmd)
    head :no_content
  rescue KeyError
    render json: {}, status: :not_found
  rescue Command::Error
    render json: {}, status: :unprocessable_entity
  rescue Service::Error
    render json: {}, status: :unprocessable_entity
  end
end

Dummy.initialize!
Dummy.routes.draw do
  resources :commands, only: :create
end
Dummy.routes.default_url_options[:host] = 'dummy.org'

run Rails.application

# How to run this example:
#
# rackup
# http POST localhost:9292/commands command=foo_bar foo=foo bar=bar
```

I really like this concept. I think it has the potential of removing a lot of controller code. 

If this can work in some cases, this idea would become the most radical one in [my book on dealing with Rails controllers](http://rails-refactoring.com). In the current version of the book, we talk a lot about the concept of form objects as a data structure which is initialized in the controller and passed to the service object. 

The approach with a generic controller handling commands removes a big part of the controller layer. 

Knowing Paweł, there will be updates and improvements to this approach, so stay tuned :)
