---
title: "A single Rails API endpoint to accept all changes to the app state"
created_at: 2015-12-06 02:45:55 +0100
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :arkency_form
---

This idea is heavily influenced by CQRS and its way of applying changes to the app via commands objects. In this blogpost we're showing how it could work with Rails.

<!-- more -->

``` #!ruby
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

