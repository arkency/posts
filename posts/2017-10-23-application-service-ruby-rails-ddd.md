---
title: "Application Service Ruby Rails DDD"
created_at: 2017-10-23 09:35:44 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

In DDD-flavored applications your domain logic lives mostly in the form of aggregates (and some bits in domain services). But that logic and object's behavior is usually persistence-agnostic. It means that it is not our domain objects responsibility to worry how they are persisted. So where does it happen? In Application Services. That's their primary role but not the only one. Let's dissect them a bit.

<!-- more -->

## Most common responsibility

Application Service get's domain objects from repositories and saves changed domain objects to repositories.

```ruby
class OrderExpirationService
  # ...

  def call(order_number)
    order_repository.transaction do
      order = order_repository.find(order_number, lock: true) # Load
      order.expire # business operation
      order_repository.save(order) # save back
    end
  end
end
```

If you migrate from Rails-way towards more Domain-Driven approach and you don't have repositories yet but you continue using `ActiveRecord` this will look similar to:


```ruby
class OrderExpirationService
  def call(order_number)
    Order.transaction do
      order = Order.lock.find(order_number) # Load
      order.expire # business operation
      order.save! # save back
    end
  end
end
```

One of the simplest rule that you can follow to make your code more testable and easier to refactor in the future is to avoid calling `save!` (or `save`) from your models.

Don't:

```ruby
class Order < ApplicationRecord
  def expire
    # verify preconditions
    self.state = "expired"
    # other logic
    save!
  end
end
```

it is not a responsibility of the domain object to save itself. It makes testing harder, slower and does not allow you to easily compose multiple operations without constantly saving to DB.

So even if you use ActiveRecord, just don't call `save!` from within the class. Only the application service should do it.

## Other responsibilities

Repository is often just one of the dependencies that our code need. Others can be

* adapters
* message bus
* event store
* domain services

```ruby
class OrdersAddProductService
  def call(order_number, product_id, quantity)
    prices_adapter = ProductPricesApiAdapter.new
    order_repository.transaction do
      order = order_repository.find(order_number, lock: true)
      order.add_product(
        prices_adapter,
        product_id,
        quantity
      )
      order_repository.save(order)
    end
  end
end
```

## Can the application service read more than one object?

I believe it can. But the other object (`Product`) should come from the same bounded context as the object we are updating (`Order`).

```ruby
class OrdersAddProductService
  def call(order_number, product_id, quantity)
    Order.transaction do
      order = Order.lock.find(order_number)
      product = Product.find(product_id)
      order.add_product(product, quantity)
      order.save!
    end
  end
end
```

There are opinions saying that it application services should not be doing it and it should only read and update one object. I am not convinced, however.

There is also a fraction claiming that the 2nd object should not be another aggregate but rather a read-model. I believe it can be an aggregate from the same bounded context.

## Can the application service update more than one object?

It is not recommended as it increases coupling between objects (aggregates) that are being updated at the same time. Potential issues to consider:

* the operation takes longer
* the objects have different lifecycle (one can be updated rarely and by one person, the other can be updated multiple times per second by various users). So the high-throughput nature of one object can cause deadlocks and prevent whole operation from happening. Or the the fact that the operation is longer and both objects remain locked in DB can lower the throughput of the object which is more often edited.
* the objects might be persisted in different DBs so the change is not transactional anyway

## What should the application service receive as an argument?

I believe it's best if the service receives a command. The command can be implemented using your preferred solution - pure ruby, dry-rb, virtus, active model, whatever.

```ruby
class AddProductToOrderCommand
  attr_accessor :order_number,
                :product_id,
                :quantity
end

class OrdersAddProductService
  def call(command)
    command.validate!
    Order.transaction do
      order = Order.lock.find(command.order_number)
      product = Product.find(command.product_id)
      order.add_product(product, command.quantity)
      order.save!
    end
  end
end
```

Having commands can be beneficial if you want to easily see what's supposed to be provided. It is more explicit, and it makes it more visible. The more attributes are provided by a form or API the more likely having this layer can be valuable. Also, the more complicated/nested/repeated the attributes are, the more grateful you will be for having commands.

Commands can perform simple validations that don't require any business knowledge. Usually this is just a trivial thing like making sure a value is present, properly formatted, included in a list of allowed values, etc.

The interesting aspect of defining a closed (not allowing every possible value) structure is that it also increases security and basically acts similar to `strong_parameters`.

### Where should the command be instantiated?

I think, the controller fits nicely to the rule. It has access to all the data from HTTP layer such as currently logged user id (from session or a token), routing parameters, form post parameters etc. And from all that they it can build a command by passing the necessary values.

### Should the command be implemented in same layer as application service or a higher layer (above it)

Ideally, I believe the layer which contains application service should define the interface of the command and a higher layer could implement it. What's the difference?

#### Command implemented in a higher layer

If we implemented the command in a higher layer (ie controller) then it could use objects it already has access to such as cookies, session, params etc.

```ruby
class Controller < ApplicationController
  class MyCommand
    def initialize(session, params)
      @session = session
      @params = params
    end

    def user_id
      session.fetch(:user_id)
    end

    def product_id
      params.fetch(:product).fetch(:id)
    end

    def command_name
      "MyCommand"
    end
  end

  def create
    cmd = MyCommand.new(session, params)
    ApplicationService.new.call(cmd)
    head :ok
  end
end
```

Because of Ruby's duck-typing mechanism this can work but, due to the lack of interfaces, it is not easy for the `ApplicationService` to describe the exact format it expects the data from the command. For simple commands that's not a big issue, bug the bigger they get and the more nested attributes they include the harder it is.

One thing I considered as a substitute for interface was... linters :) Such as [rack linter](http://www.rubydoc.info/gems/rack/Rack/Lint) or [this](https://github.com/RailsEventStore/rails_event_store/blob/master/ruby_event_store/lib/ruby_event_store/spec/event_repository_lint.rb) In other words shared examples distributed as parts of the lower layer (implementing an Application Service) that could be executed in the tests of the higher layer (controller).

```ruby
RSpec.describe Controller::MyCommand do
  include_examples "ApplicationService::MyCommand"
end
```

in case Test Unit frameworks this would be just a module with test methods to include:

```ruby
class TestMeme < Minitest::Test
  include ApplicationService::MyCommandLint

  def setup
    @command = Controller::MyCommand.new
  end
end
```

#### Command implemented in the same layer as the service

In this version, the controller must copy the necessary data to a provided implementation of the command, which might be less convenient when there is more arguments.

```ruby
class Controller < ApplicationController
  def create
    cmd = MyCommand.new
    cmd.user_id = session.fetch(:user_id)
    cmd.product_id = params.fetch(:product).fetch(:id)
    ApplicationService.new.call(cmd)
    head :ok
  end
end
```

or

```ruby
class Controller < ApplicationController
  def create
    cmd = MyCommand.new(
      user_id: session.fetch(:user_id)
      product_id: params.fetch(:product).fetch(:id)
    )
    ApplicationService.new.call(cmd)
    head :ok
  end
end
```

## Can the application service handle more than 1 operation?

I think it can and I would even say that it's often beneficial to group many operations together in one Application Service instead of scattering them across multiple classes. Because usually the use-cases need the same dependencies to finish and have a similar workflow.

```ruby
class OrdersService
  def expire(order_number)
    with_order(order_number) do |order|
      # ...
    end
  end

  def add_product(order_number, product_id, quantity)
    with_order(order_number) do |order|
      # ...
    end
  end

  private

  def with_order(number)
    order_repository.transaction do
      order = order_repository.find(number, lock: true)
      yield order
      order_repository.save(order)
    end
  end
end
```

If you go with commands, you can even hide all those internal methods as private.

```ruby
class OrdersService
  def call(command)
    case command
    when ExpireOrderCommand
      expire(command)
    when AddProductToOrderCommand
      add_product(command)
    else
      raise ArgumentError
    end
  end

  private

  def expire(command)
    with_order(command.order_number) do |order|
      # ...
    end
  end

  def add_product(command)
    with_order(command.order_number) do |order|
      # ...
    end
  end

  def with_order(number)
    order_repository.transaction do
      order = order_repository.find(number, lock: true)
      yield order
      order_repository.save(order)
    end
  end
end
```

## What should the command contain?

* The id/uuid of related entities which should be changed
* The data necessary for performing those changes
* Verified id of the user performing current action
  * `current_user_id` coming from the controller
    * usually based on session, cookies or tokens
* The user id on behalf of whom the action is executed in case that's not the same as the user performing current action
  * Scenario: An Admin executes an operation on behalf of an user who called customer support and asked for help.

## What's the difference between Application Service and Command Handler

I believe there is none, really. It's just the names comes from 2 different communities (DDD vs CQRS) but they represent a similar concept. However, Command Handler is more likely to handle just one command :)

## What should the Application Service return?

Ideally, nothing. The reason most Application Services return anything is because the higher layer needs the ID of the created record. But if you go with client-side generated (JS fronted or in a controller) UUIDs then the only thing the controller needs to know is whether the operation succeeded. This can be expressed with domain events and/or exceptions.

## Should the Application Service contain business logic?

Nope. That should stay in your Aggregates and Domain Services.

## Can the application service handle more than 1 operation at the same time?

Yes, although I am not yet sure what's the best approach for it. I consider a separate command vs a commands container for a batch of smaller commands.

Handling many smaller operations can be useful when there are multiple clients with various needs or when you need to handle less granular (compared to standard UI operations) updates provided via CSV/XLS/XLSX/XML files.

### A separate command

```ruby
class SetDeliveryMethodAndConfirmCommand
  attr_accessor :order_number,
                :delivery_method
end


class OrdersService
  def call(command)
    case command
    when SetDeliveryMethodAndConfirmCommand
      delivery_and_confirm(command)
    when ConfirmCommand
      confirm(command)
    when SetDeliveryMethodCommand
      set_delivery(command)
    # ...
    else
      raise ArgumentError
    end
  end

  private

  def delivery_and_confirm(command)
    with_order(command.order_number) do |order|
      order.set_delivery_method(command.delivery_method)
      order.confirm
    end
  end

  # ...
end
```

### General commands container

```ruby
class BatchOfCommands
  attr_reader :commands

  def initialize
    @commands = []
  end

  def add_command(cmd)
    commands << cmd
    self
  end
end


class OrdersService
  def call(command)
    case command
    when BatchOfCommands
      batch(command.commands)
    when ConfirmCommand
      confirm(command)
    when SetDeliveryMethodCommand
      set_delivery(command)
    # ...
    else
      raise ArgumentError
    end
  end

  private

  def batch(commands)
    commands.each{|cmd| call(cmd) }
  end

  # ...
end

batch = BatchOfCommands.new
batch.
  add_command(SetDeliveryMethodCommand.new(...)).
  add_command(ConfirmCommand.new(...))

OrdersService.new.call(batch)
```

However, this naive approach can lead to a poor performance (reading and writing the same object multiple times) and it does not guarantee processing all commands transactionally. It will be up to your implementation to balance transactionality and performance and choose the model which best covers your application requirements (including non-functional ones). Generally you can choose from:

* one transaction per one operation
  * simplest to implement
  * worst performance
  * short locks on objects
* one transaction per one object
  * balanced performance and lock time
  * guaranteed a whole record processed or skipped (in case of crash in the middle of the process)
* one transaction per whole batch
  * very long lock on many objects which might affect many other operations occurring at the same time
  * guaranteed all or none records processed

Here is an example on how the balanced _one transaction per one object_ approach can be implemented.

```ruby
class OrdersService
  def call(command)
    case command
    when BatchOfCommands
      batch(command.commands)
    when ConfirmCommand
      confirm(command)
    when SetDeliveryMethodCommand
      set_delivery(command)
    # ...
    else
      raise ArgumentError
    end
  end

  private

  def batch(commands)
    groupped_commands = commands.group_by(&:order_number)
    groupped_commands.each do |order_number, order_commands|
      with_order(number) do
        order_commands.each{|cmd| call(cmd) }
      end
    end
  end

  def confirm(command)
    with_order(command.order_number) do |order|
      order.confirm
    end
  end

  def with_order(number)
    if @order && @order.number == number
      yield @order
    elsif @order && @order.number != number
      raise "not supported"
    else
      begin
        order_repository.transaction do
          @order = order_repository.find(number, lock: true)
          yield @order
          order_repository.save(@order)
        end
      ensure
        @order = nil
      end
    end
  end

end

batch = BatchOfCommands.new
batch.
  add_command(SetDeliveryMethodCommand.new(...)).
  add_command(ConfirmCommand.new(...))

OrdersService.new.call(batch)
```

No matter which approach you go with, it can be beneficial when transforming your UI from bunch of fields sent together into more Task Based UI.