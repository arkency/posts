---
title: "Extract a service object using SimpleDelegator"
created_at: 2015-05-04 14:57:53 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
img: "/assets/images/fearless-refactoring-fit.png"
---

<p>
	<figure align="center">
		<img src="/assets/images/fearless-refactoring-fit.png">
	</figure>
</p>

It's now more than 1 year since I released the first beta release (the final release was ready in December 2014) of the "Fearless Refactoring: Rails controllers" book. Many of the readers were pointing to the one technique which was especially useful to them - extracting a service object using SimpleDelegator.

This technique has also been very popular in our Arkency team. It gives you a nice way of extracting a service object immediately, within minutes. It is based on a bit of a hack. The idea is to treat this hack as a temporary solution to make the transition to the service object more easy.

<!-- more -->

# Extract a service object using the SimpleDelegator

New projects have a tendency to keep adding things into controllers. There are things
which don't quite fit any model and developers still haven't figured out the domain exactly. So these features land in controllers. In later phases of the project we usually have better insight into the domain. We would like to restructure domain logic and business objects. But the unclean state of controllers, burdened with too many responsibilities is stopping us from doing it.

To start working on our models we need to first untangle them from the surrounding mess. This technique helps you extract objects decoupled from HTTP aspect of your application. Let controllers handle that part. And let service objects do the rest. This will move us one step closer to better separation of responsibilities and will make other refactorings easier later.

## Prerequisites

### Public methods

As of Ruby 2.0, Delegator does not delegate `protected` methods any more. You might need to temporarly change access levels of some your controller methods for this technique to work. Once you finish all steps, you should be able to bring the acess level back to old value. Such change can be done in two ways.

* by moving the method definition into `public` scope.

    Change

    ```
#!ruby

    class A
      def method_is_public
      end
    
      protected
    
      def method_is_protected
      end
    end
    ```

    into
    
    ```
#!ruby
    class A
      def method_is_public
      end
      
      def method_is_protected
      end
          
      protected
    
    end
    ```

* by overwriting method access level after its definition

    Change

    ```
#!ruby
    class A
      def method_is_public
      end
    
      protected
    
      def method_is_protected
      end
    end
    ```

    into
    
    ```
#!ruby
    class A
      def method_is_public
      end
    
      protected
    
      def method_is_protected
      end
      
      public :method_is_protected
    end
    ```

I would recommend using the second way. It is simpler to add and simpler to remove later. The second way is possible because [`#public`](http://ruby-doc.org/core-2.1.5/Module.html#method-i-public) is not a language syntax feature but just a normal method call executed on current class.

### Inlined filters

Although not strictly necessary for this technique to work, it is however recommended to [inline filters](#inline-filters-recipe). It might be that those filters contain logic that should be actually moved into the service objects. It will be easier for you to spot it after doing so.

## Algorithm

1. Move the action definition into new class and inherit from `SimpleDelegator`.
2. Step by step bring back controller responsibilities into the controller.
3. Remove inheriting from `SimpleDelegator`.
4. (Optional) Use exceptions for control flow in unhappy paths.

## Example

This example will be a much simplified version of a controller responsible for receiving payment gateway callbacks. Such HTTP callback request is received by our app
from gateway's backend and its result is presented to the user's browser. I've seen many
controllers out there responsible for doing something more or less similar. Because it is such an important action (from business point of view) it usually quickly starts to accumulate more and more responsibilities.

Let's say our customer would like to see even more features added here, but before proceeding we decided to refactor first. I can see that Active Record models would deserve some touch here as well, let's only focus on controller right now.


```
#!ruby
class PaymentGatewayController < ApplicationController
  ALLOWED_IPS = ["127.0.0.1"]
  before_filter :whitelist_ip

  def callback
    order = Order.find(params[:order_id])
    transaction = order.order_transactions.create(callback: params.slice(:status, :error_message, :merchant_error_message, :shop_orderid, :transaction_id, :type, :payment_status, :masked_credit_card, :nature, :require_capture, :amount, :currency))
    if transaction.successful?
      order.paid!
      OrderMailer.order_paid(order.id).deliver
      redirect_to successful_order_path(order.id)
    else
      redirect_to retry_order_path(order.id)
    end
  rescue ActiveRecord::RecordNotFound => e
    redirect_to missing_order_path(params[:order_id])
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    redirect_to failed_order_path(order.id), alert: t("order.problems")
  end

  private

  def whitelist_ip
    raise UnauthorizedIpAccess unless ALLOWED_IPS.include?(request.remote_ip)
  end
end
```

### About filters

In this example I decided not to move the verification done by the `whitlist_ip` before filter into the service object. This IP address check of issuer's request actually fits into controller responsibilities quite well.

### Move the action definition into new class and inherit from `SimpleDelegator`

For start you can even keep the class inside the controller.

```
#!ruby
class PaymentGatewayController < ApplicationController
  # leanpub-start-insert
  # New service inheriting from SimpleDelegator
  class ServiceObject < SimpleDelegator
    # copy-pasted method
    def callback
      order = Order.find(params[:order_id])
      transaction = order.order_transactions.create(callback: params.slice(:status, :error_message, :merchant_error_message, :shop_orderid, :transaction_id, :type, :payment_status, :masked_credit_card, :nature, :require_capture, :amount, :currency))
      if transaction.successful?
        order.paid!
        OrderMailer.order_paid(order.id).deliver
        redirect_to successful_order_path(order.id)
      else
        redirect_to retry_order_path(order.id)
      end
    rescue ActiveRecord::RecordNotFound => e
      redirect_to missing_order_path(params[:order_id])
    rescue => e
      Honeybadger.notify(e)
      AdminOrderMailer.order_problem(order.id).deliver
      redirect_to failed_order_path(order.id), alert: t("order.problems")
    end
  end
  # leanpub-end-insert

  ALLOWED_IPS = ["127.0.0.1"]
  before_filter :whitelist_ip

  def callback
    # leanpub-start-insert
    # Create the instance and call the method
    ServiceObject.new(self).callback
    # leanpub-end-insert
  end

  private

  def whitelist_ip
    raise UnauthorizedIpAccess unless ALLOWED_IPS.include?(request.remote_ip)
  end
end
```

We created new class `ServiceObject` which inherits from `SimpleDelegator`. That means that every method which is not defined will delegate to an object. When creating an instance of `SimpleDelegator` the first argument is the object that methods will be delegated to.

```
#!ruby
def callback
  ServiceObject.new(self).callback
end
```

We provide `self` as this first method argument, which is the controller instance that is currently processing the request. That way all the methods which are not defined in `ServiceObject` class such as `redirect_to`, `respond`, `failed_order_path`, `params`, etc are called on controller instance. Which is good because our controller has these methods defined.

### Step by step bring back controller responsibilities into the controller

First, we are going to extract the `redirect_to` that is part of last `rescue` clause.

```
#!ruby
rescue => e
  Honeybadger.notify(e)
  AdminOrderMailer.order_problem(order.id).deliver
  redirect_to failed_order_path(order.id), alert: t("order.problems")
end
```

To do that we could re-raise the exception and catch it in controller. But in our case it is not that easy because we need access to `order.id` to do proper redirect. There are few ways we can workaround such obstacle:

* use `params[:order_id]` instead of `order.id` in controller (simplest way)
* expose `order` or `order.id` from service object to controller
* expose `order` or `order.id` in new exception

Here, we are going to use the first, simplest way. The third way will be shown as well later in this chapter.

```
#!ruby
class ServiceObject < SimpleDelegator
  def callback
    order = Order.find(params[:order_id])
    transaction = order.order_transactions.create(callback: params.slice(:status, :error_message, :merchant_error_message, :shop_orderid, :transaction_id, :type, :payment_status, :masked_credit_card, :nature, :require_capture, :amount, :currency))
    if transaction.successful?
      order.paid!
      OrderMailer.order_paid(order.id).deliver
      redirect_to successful_order_path(order.id)
    else
      redirect_to retry_order_path(order.id)
    end
  rescue ActiveRecord::RecordNotFound => e
    redirect_to missing_order_path(params[:order_id])
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    # leanpub-start-insert
    raise # re-raise instead of redirect
    # leanpub-end-insert
  end
end

def callback
  ServiceObject.new(self).callback
  # leanpub-start-insert
rescue # we added this clause here
  redirect_to failed_order_path(params[:order_id]), alert: t("order.problems")
  # leanpub-end-insert
end
```

Next, we are going to do very similar thing with the `redirect_to` from `ActiveRecord::RecordNotFound` exception.

```
#!ruby
class ServiceObject < SimpleDelegator
  def callback
    order = Order.find(params[:order_id])
    transaction = order.order_transactions.create(callback: params.slice(:status, :error_message, :merchant_error_message, :shop_orderid, :transaction_id, :type, :payment_status, :masked_credit_card, :nature, :require_capture, :amount, :currency))
    if transaction.successful?
      order.paid!
      OrderMailer.order_paid(order.id).deliver
      redirect_to successful_order_path(order.id)
    else
      redirect_to retry_order_path(order.id)
    end
  rescue ActiveRecord::RecordNotFound => e
    # leanpub-start-insert
    raise # Simply re-raise
    # leanpub-end-insert
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    raise
  end
end

def callback
  ServiceObject.new(self).callback
# leanpub-start-insert
rescue ActiveRecord::RecordNotFound => e # One more rescue clause
  redirect_to missing_order_path(params[:order_id])
# leanpub-end-insert
rescue
  redirect_to failed_order_path(params[:order_id]), alert: t("order.problems")
end
```

We are left with two `redirect_to` statements. To eliminte them we need to return the status of the operation to the controller. For now, we will just use `Boolean` for that. We will also need to again use `params[:order_id]` instead of `order.id`.

```
#!ruby
class ServiceObject < SimpleDelegator
  def callback
    order = Order.find(params[:order_id])
    transaction = order.order_transactions.create(callback: params.slice(:status, :error_message, :merchant_error_message, :shop_orderid, :transaction_id, :type, :payment_status, :masked_credit_card, :nature, :require_capture, :amount, :currency))
    if transaction.successful?
      order.paid!
      OrderMailer.order_paid(order.id).deliver
      # leanpub-start-insert
      return true # returning status
    else
      return false # returning status
      # leanpub-end-insert
    end
  rescue ActiveRecord::RecordNotFound => e
    raise
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    raise
  end
end

def callback
  # leanpub-start-insert
  if ServiceObject.new(self).callback
    # redirect moved here
    redirect_to successful_order_path(params[:order_id])
  else
    # and here
    redirect_to retry_order_path(params[:order_id])
  end
  # leanpub-end-insert
rescue ActiveRecord::RecordNotFound => e
  redirect_to missing_order_path(params[:order_id])
rescue
  redirect_to failed_order_path(params[:order_id]), alert: t("order.problems")
end
```

Now we need to take care of `params` method. Starting with `params[:order_id]`. This change is really small.

```
#!ruby
class ServiceObject < SimpleDelegator
  # leanpub-start-insert
  # We introduce new order_id method argument
  def callback(order_id)
    order = Order.find(order_id)
    # leanpub-end-insert
    transaction = order.order_transactions.create(callback: params.slice(:status, :error_message, :merchant_error_message, :shop_orderid, :transaction_id, :type, :payment_status, :masked_credit_card, :nature, :require_capture, :amount, :currency))
    if transaction.successful?
      order.paid!
      OrderMailer.order_paid(order.id).deliver
      return true
    else
      return false
    end
  rescue ActiveRecord::RecordNotFound => e
    raise
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    raise
  end
end

def callback
  # leanpub-start-insert
  # Provide the argument for method call
  if ServiceObject.new(self).callback(params[:order_id])
    # leanpub-end-insert
    redirect_to successful_order_path(params[:order_id])
  else
    redirect_to retry_order_path(params[:order_id])
  end
rescue ActiveRecord::RecordNotFound => e
  redirect_to missing_order_path(params[:order_id])
rescue
  redirect_to failed_order_path(params[:order_id]), alert: t("order.problems")
end
```

The rest of `params` is going to be be provided as second method argument.

```
#!ruby
class ServiceObject < SimpleDelegator
  # leanpub-start-insert
  # One more argument
  def callback(order_id, gateway_transaction_attributes)
    order = Order.find(order_id)
    transaction = order.order_transactions.create(
      # that we use here
      callback: gateway_transaction_attributes
    )
    # leanpub-end-insert
    if transaction.successful?
      order.paid!
      OrderMailer.order_paid(order.id).deliver
      return true
    else
      return false
    end
  rescue ActiveRecord::RecordNotFound => e
    raise
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    raise
  end
end

def callback
  # leanpub-start-insert
  # Providing second argument
  if ServiceObject.new(self).callback(
      params[:order_id],
      gateway_transaction_attributes
    )
    # leanpub-end-insert
    redirect_to successful_order_path(params[:order_id])
  else
    redirect_to retry_order_path(params[:order_id])
  end
rescue ActiveRecord::RecordNotFound => e
  redirect_to missing_order_path(params[:order_id])
rescue
  redirect_to failed_order_path(params[:order_id]), alert: t("order.problems")
end

private

# leanpub-start-insert
# Extracted to small helper method
def gateway_transaction_attributes
  params.slice(:status, :error_message, :merchant_error_message, 
    :shop_orderid, :transaction_id, :type, :payment_status,
    :masked_credit_card, :nature, :require_capture, :amount, :currency
  )
end
# leanpub-end-insert
```

### Remove inheriting from `SimpleDelegator`

When you no longer use any of the controller methods in the Service you can remove the inheritance from `SimpleDelegator`. You just no longer need it. It is a temporary hack that makes the transition to service object easier.

```
#!ruby
# leanpub-start-insert
# Removed inheritance
class ServiceObject
  # leanpub-end-insert
  def callback(order_id, gateway_transaction_attributes)
    order = Order.find(order_id)
    transaction = order.order_transactions.create(callback: gateway_transaction_attributes)
    if transaction.successful?
      order.paid!
      OrderMailer.order_paid(order.id).deliver
      return true
    else
      return false
    end
  rescue ActiveRecord::RecordNotFound => e
    raise
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    raise
  end
end

def callback
  # leanpub-start-insert
  # ServiceObject constructor doesn't need
  # controller instance as argument anymore
  if ServiceObject.new.callback(
       params[:order_id],
       gateway_transaction_attributes
    )
    # leanpub-end-insert
    redirect_to successful_order_path(params[:order_id])
  else
    redirect_to retry_order_path(params[:order_id])
  end
rescue ActiveRecord::RecordNotFound => e
  redirect_to missing_order_path(params[:order_id])
rescue
  redirect_to failed_order_path(params[:order_id]), alert: t("order.problems")
end
```

This would be a good time to also give a meaningful name (such as  `PaymentGatewayCallbackService`) to the service object and extract it to a separate file (such as `app/services/payment_gateway_callback_service.rb`). Remember, you don't need to add `app/services/` to Rails autoloading configuration for it to work ([explanation](http://blog.arkency.com/2014/11/dont-forget-about-eager-load-when-extending-autoload/)).

### (Optional) Use exceptions for control flow in unhappy paths

You can see that code must deal with exceptions in a nice way (as this is critical path in the system). But for communicating the state of transaction it is using `Boolean` values. We can simplify it by always using exceptions for any unhappy path.

```
#!ruby
class PaymentGatewayCallbackService
  # leanpub-start-insert
  # New custom exception
  TransactionFailed = Class.new(StandardError)
  # leanpub-end-insert

  def callback(order_id, gateway_transaction_attributes)
    order = Order.find(order_id)
    transaction = order.order_transactions.create(callback: gateway_transaction_attributes)
    # leanpub-start-insert
    # raise the exception when things went wrong
    transaction.successful? or raise TransactionFailed
    # leanpub-end-insert
    order.paid!
    OrderMailer.order_paid(order.id).deliver
  rescue ActiveRecord::RecordNotFound, TransactionFailed => e
    raise
  rescue => e
    Honeybadger.notify(e)
    AdminOrderMailer.order_problem(order.id).deliver
    raise
  end
end

class PaymentGatewayController < ApplicationController
  ALLOWED_IPS = ["127.0.0.1"]
  before_filter :whitelist_ip

  def callback
    PaymentGatewayCallbackService.new.callback(params[:order_id], gateway_transaction_attributes)
    redirect_to successful_order_path(params[:order_id])
  # leanpub-start-insert    
  # Rescue and redirect
  rescue PaymentGatewayCallbackService::TransactionFailed => f
    redirect_to retry_order_path(params[:order_id])
    # leanpub-end-insert    
  rescue ActiveRecord::RecordNotFound => e
    redirect_to missing_order_path(params[:order_id])
  rescue
    redirect_to failed_order_path(params[:order_id]), alert: t("order.problems")
  end
  
  # ...
end
```

"What about performance?" you might ask. After all, whenever someone mentions exceptions on the Internet, people seem to start raising the performance argument for not using them. Let me answer that way:

* Cost of using exceptions is negligable when the exception doesn't occur.
* When the exception occurs its performance cost is 3-4x times lower compared to one simple SQL statement.

[Hard data](https://gist.github.com/paneq/a643b9a3cc694ba3eb6e) for those statements. Feel free to reproduce on your Ruby implementation and Rails version.

In other words, exceptions may hurt performance when used inside a "hot loop" in your program and in such case should be avoided. Service Objects usually don't have such performance implications. If using exceptions helps you clean the code of services and controller, performance shouldn't stop you. There are probably plenty of other opportunities to speed up your app compared to removing exceptions. So please, let's not use such argument in situations like that.

## Benefits

This is a great way to decouple flow and business logic from HTTP concerns. It makes the code cleaner and easier to reason about. If you want to keep refactoring the code you can easily focus on controller-service communication or service-model. You just introduced a nice boundary.

From now on you can also [use Service Objects for setting proper state in your tests](#service-objects-for-testing).

## Resources

* In the book - [Inline controller filters](#inline-filters-recipe)
* In the book - [Service objects as a way of testing Rails apps](#service-objects-for-testing)
* [Delegator does not delegate protected methods](https://bugs.ruby-lang.org/issues/9542)
* [`Module#public` documentation](http://ruby-doc.org/core-2.1.5/Module.html#method-i-public)
* [`SimpleDelegator` documentation](http://www.ruby-doc.org/stdlib-2.1.5/libdoc/delegate/rdoc/SimpleDelegator.html)
* [Don't forget about `eager_load` when extending autoload paths](http://blog.arkency.com/2014/11/dont-forget-about-eager-load-when-extending-autoload/)
* [Cost of using exceptions for control flow compared to one SQL statement](https://gist.github.com/paneq/a643b9a3cc694ba3eb6e). [Retweet here](https://twitter.com/pankowecki/status/535818231194615810)

