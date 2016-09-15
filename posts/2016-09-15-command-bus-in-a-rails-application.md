---
title: "Command bus in a Rails application"
created_at: 2016-09-15 08:26:38 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

Using commands is an important part of a DDD/CQRS-influenced architecture. In this blogpost I'd like to show you how to use the [https://github.com/arkency/command_bus](Arkency Command Bus gem) within a Rails application.

<!-- more -->

Let's first look at what a command may look like:

```
#!ruby

class AddCostCode < Dry::Types::Struct
  attribute :code, Types::String
  attribute :description, Types::String
  attribute :company_id, Types::String
end
```

As you see, it's just a data structure. We've used DryTypes here, but you can use whatever you want, as long as it may help you define the expected params and have some basic "validations".

Now, let's look how it's used from a Rails controller:

```
#!ruby

class CostCodesController < ApplicationController
  def create
    execute(AddCostCode.new(cost_code_params))
    head :created
  rescue Dry::Types::StructError => err
    head :unprocessable_entity
    raise err
  end
end
```

The `execute` method is defined in the `ApplicationController` as it is used from many controllers:

```
#!ruby

class ApplicationController < ActionController::Base

  def execute(command)
    command_executor.execute(command)
  end

  def command_executor
    @command_executor ||= CommandExecutor.new
  end
end
```

So, there's a `CommandExecutor` class which is responsible for dispatching commands.

```
#!ruby

class CommandExecutor
  include EventStoreConfiguration

  def initialize
    @bus = Arkency::CommandBus.new

    register_commands
  end

  def execute(command)
    @bus.(command)
    resubscribe_processes(event_store)
  end

  private
  def register_commands
    @bus.register(AddCostCode, AddCostCodeHandler.new)
    # ...
  end

end
```

In this case, we declare a dedidacted command handler, called `AddHostCodeHandler`.

```
#!ruby
class AddCostCodeHandler < CommandHandler

  def call(command)
    aggregate(CompanyCostCentre, Company.new(id: command.company_id)) do |company_settings|
      company_settings.add_cost_code(command.code, command.description)
    end
  end
end
```


What is the `CommandHandler` class which we inherit from?

```
#!ruby
class CommandHandler
  protected
  def aggregate(aggregate_type, *aggregate_id, &block)
    if block
      load(aggregate_type, *aggregate_id).tap do |aggregate|
        block.call(aggregate)
        publish_changes(aggregate)
      end
    else
      load(aggregate_type, aggregate_id)
    end
  end

  private
  def load(aggregate_type, *aggregate_id)
    aggregate_type.new(*aggregate_id).tap do |aggregate|
      repository.load(aggregate)
    end
  end

  def publish_changes(aggregate)
    repository.store(aggregate)
  end
end

```

We use a full-CQRS approach here together with event sourcing and aggregates. Let's look at the aggregate here:

```
#!ruby
class CompanyCostCentre
  include AggregateRoot::Base

  def initialize(company)
    @company = company
    @codes = []
  end
  
  def add_cost_code(code, description)
    ensure_code_is_unique(code)
    apply(cost_code_added(code, description))
  end
  
  def cost_code_added(code, description)
    CostCodeAdded.new(data: {
        code: code,
        description: description,
        company_id: company.id
    })
  end
```

This means, that we're publishing a successful `CostCodeAdded` event, which can be used in other places of the system. One main place may be a read model - to help us retrieve the data from the system.
(In CQRS read models serve as the Query part)

How are the events then connected?

```
#!ruby
module EventStoreConfiguration
  def event_store
    @client ||= RailsEventStore::Client.new.tap do |client|
      client.subscribe(BuildCostCodeReadModel.new, [CostCodeAdded])
    end
  end
end
```

```
#!ruby
class BuildCostCodeReadModel

  def call(event)
    case event.class.to_s
      when 'CostCodeAdded' then handle_cost_code_added(event)
    end
  end

  def handle_cost_code_added(event)
    CompanyCostCode.create!(code: event.data.code, company_id: event.data.company_id, description: event.data.description)
  end
end
```

In which, the CompanyCostCode is just a normal ActiveRecord class:

```
#!ruby
class CompanyCostCode < ActiveRecord::Base
  def self.all_for_company(company)
    where(company_id: company.id)
  end
end
```

And on the read side of the application, it's used from a controller, as any other ActiveRecord objects collection.


