---
title: "Instantiating Service Objects"
created_at: 2014-10-12 18:14:39 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter: skip
newsletter_inside: fearless_refactoring_course_instantiating
tags: [ 'ruby', 'rails', 'service', 'objects', 'instantiate' ]
---

<p>
  <figure>
    <img src="<%= src_fit("instantiating-service-objects-ruby-rails/board-cubes-game-2923-16-10.jpg") %>" width="100%">
  </figure>
</p>

In [my last blogpost about adapters](/2014/08/ruby-rails-adapters/) I promised a more detailed insight
into instantiating Adapters & Service Objects. So here we go.

<!-- more -->

## Boring style

```ruby
class ProductsController
  def create
    metrics = MetricsAdapter.new(METRICS_CONFIG.fetch(Rails.env))
    service = CreateProductService.new(metrics)
    product = service.call(params[:product])
    redirect_to product_path(product), notice: "Product created"
  rescue CreateProductService::Failed => failure
    # ... probably render ...
  end
end
```

This is the simplest way, nothing new under the sun. When your needs are small,
dependencies simple or non-existing (or created inside service, or you use
globals, in other words: _not passed explicitely_) you might not need anything more.

### Testing

Ideally we want to test our controllers in simplest possible way. In Rails codebase,
unlike in desktop application, every controller action is an entry point into the
system. Its our `main()` method. So we want our controllers to be very thin,
instantiating the right kind of objects, giving them access to the input, and putting
the whole world in motion. The simplest, the better, because controllers are the
hardest beasts when it come to testing.

#### Controller

```ruby

describe ProductsController do
  specify "#create" do
    product_attributes = {
      "name" =>"Product Name",
      "price"=>"123.45",
    }

    expect(MetricsAdapter).to receive(:new).with("testApiKey").and_return(
      metrics = double(:metrics)
    )
    expect(CreateProductService).to receive(:new).with(metrics).and_return(
      create_product_service = double(:register_user_service,
        call: Product.new.tap{|p| p.id = 10 },
      )
    )

    expect(create_product_service).to receive(:call).with(product_attributes)

    post :create, {"product"=> product_attributes}

    expect(flash[:notice]).to be_present
    expect(subject).to redirect_to("/products/10")
  end
end
```

It's up to you whether you want to mock the service or not. Remember that the
purpose of this test is not to determine whether the service is doing its job,
but whether controller is. And the controller concers are

* passing `params`, `request` and `session` (subsets of) data for the services
when they need it
* controlling the flow of the interaction by using `redirect_to` or `render`. In case
of happy path as well as when something goes wrong.
* Updating the long-living parts of user interaction with our system such as `session`
and `cookies`
* Optionally, notifying user about the achieved result of the actions. Often with the
use of `flash` or `flash.now`. I wrote _optionally_ because I think [in many cases
the communication of action status should actually be a responsibility of the view layer,
not a controller one](http://blog.robert.pankowecki.pl/2011/12/communication-between-controllers-and.html)

These are the things you should be testing, nothing less, nothing more.

However mocking adapters might be necessary because we don't want to be sending
or collecting our data from test environment.

#### Service

When testing the service you need to instantiate it and its dependencies
manually as well.

```ruby

describe CreateProductService do
  let(:metrics_adapter) do
    FakeMetricsAdapter.new
  end

  subject(:create_product_service) do
    described_class.new(metrics_adapter)
  end

  specify "something something" do
    create_product_service.call(..)
    expect(..)
  end
end
```

## Modules

When instantiating becomes more complicated I extract the process of creating
the full object into an `injector`. The purpose is to make it easy to create
new instance everywhere and to make it trivial for people to overwrite the
dependencies by overwriting methods.

```ruby
module CreateProductServiceInjector
  def metrics_adapter
    @metrics_adapter ||= MetricsAdapter.new( METRICS_CONFIG.fetch(Rails.env) )
  end

  def create_product_service
    @create_product_service ||= CreateProductService.new(metrics_adapter)
  end
end
```

```ruby
class ProductsController
  include CreateProductServiceInjector

  def create
    product = create_product_service.call(params[:product])
    redirect_to product_path(product), notice: "Product created"
  rescue CreateProductService::Failed => failure
    # ... probably render ...
  end
end
```

### Testing

The nice thing is you can test the instantiating process itself easily with injector
(or skip it completely if you consider it to be typo-testing that provides very little
value) and don't bother much with it anymore.

#### Injector

Here we only test that we can inject the objects and change the dependencies.

```ruby
describe CreateProductServiceInjector do
  subject(:injected) do
    Object.new.extend(described_class)
  end

  specify "#metrics_adapter" do
    expect(MetricsAdapter).to receive(:new).with("testApiKey").and_return(
      metrics = double(:metrics)
    )
    expect(injected.metrics_adapter).to eq(metrics)
  end

  specify "#create_product_service" do
    expect(injected).to receive(:metrics_adapter).and_return(
      metrics = double(:metrics)
    )
    expect(CreateProductService).to receive(:new).with(metrics).and_return(
      service = double(:register_user_service)
    )

    expect(injected.create_product_service).to eq(service)
  end
end
```

Is it worth it? Well, it depends how complicated setting your object is. Some of my
colleagues just test that the object can be constructed (hopefully this has no
side effects in your codebase):

```ruby
describe CreateProductServiceInjector do
  subject(:injected) do
    Object.new.extend(described_class)
  end

  specify "can instantiate service" do
    expect{ injected.create_product_service }.not_to raise_error
  end
end
```

#### Controller

Our controller is only interested in cooperating with `create_product_service`.
It doesn't care what needs to be done to fully set it up. It's the job of `Injector`.
We can throw away the code for creating the service.

```ruby

describe ProductsController do
  specify "#create" do
    product_attributes = {
      "name" =>"Product Name",
      "price"=>"123.45",
    }

    expect(controller.create_product_service).to receive(:call).
      with(product_attributes).
      and_return( Product.new.tap{|p| p.id = 10 } )

    post :create, {"product"=> product_attributes}

    expect(flash[:notice]).to be_present
    expect(subject).to redirect_to("/products/10")
  end
end
```

#### Service Object

You can use the injector in your tests as well. Just include it.
Rspec is a DSL that is just creating classes and method for you.
You can overwrite the `metrics_adapter` dependency using Rspec DSL
with `let` or just by defining `metrics_adapter` method yourself.

Just remember that `let` is adding memoization for you automatically.
If you use your own method definition make sure to memoize as well
(in some cases it is not necessary, but when you start stubbing/mocking
it is).

```ruby
describe CreateProductService do
  include CreateProductServiceInjector

  specify "something something" do
    create_product_service.call(..)
    expect(..)
  end

  let(:metrics_adapter) do
    FakeMetricsAdapter.new
  end
  
  #or

  def metrics_adapter
    @adapter ||= FakeMetricsAdapter.new
  end
end
```

There is nothing preventing you from mixing classic ruby OOP
with Rspec DSL. You can use it to your advantage.

The downside that I see is that you can't easily say from reading
the code that `metrics_adapter` is a dependency of our
class under test (`CreateProductService`). As I said in simplest
case it might not be worthy, in more complicated ones it might be however.

### Example

Here is a more complicated example from one of our project.

```ruby
require 'notifications_center/db/active_record_sagas_db'
require "notifications_center/schedulers/resque_scheduler"
require "notifications_center/clocks/real"

module NotificationsCenterInjector
  def notifications_center
    @notifications_center ||= begin
      apns_adapter     = Rails.configuration.apns_adapter
      policy           = Rails.configuration.apns_push_notifications_policy
      mixpanel_adapter = Rails.configuration.mixpanel_adapter
      url_helpers      = Rails.application.routes_url_helpers

      db               = NotificationsCenter::DB::ActiveRecordSagasDb.new
      scheduler        = NotificationsCenter::Schedulers::ResqueScheduler.new
      clock            = NotificationsCenter::Clocks::Real.new

      push = PushNotificationService.new(
        url_helpers, 
        apns_adapter,
        policy, 
        mixpanel_adapter
      )
      NotificationsCenter.new(db, push, scheduler, clock)
    end
  end
end
```

## Dependor

You might also consider using [dependor gem](https://github.com/psyho/dependor) for
this.

```ruby
class Injector
  extend Dependor::Let

  let(:metrics_adapter) do
    MetricsAdapter.new( METRICS_CONFIG.fetch(Rails.env) )
  end

  let(:create_product_service)
    CreateProductService.new(metrics_adapter)
  end
end
```

```ruby
class ProductsController
  extend Dependor::Injectable
  inject_from Injector
 
  inject :create_product_service
  def create
    product = create_product_service.call(params[:product])
    redirect_to product_path(product), notice: "Product created"
  rescue CreateProductService::Failed => failure
    # ... probably render ...
  end
end
```

The nice thing about dependor is that it provides a lot of small APIs
and doesn't force you to use any of them. Some of them do more magic
(I am looking at you [`Dependor::AutoInject`](https://github.com/psyho/dependor#dependorautoinject))
and some of medium level ([`Dependor::Injectable`](https://github.com/psyho/dependor#dependorinjectable))
and some almost none magic whatsoever([`Dependor::Shorty`](https://github.com/psyho/dependor#dependorshorty)).
You can use only the parts that you like and are comfortable with.

### Testing

#### Injector

The simple way that just checks if things don't crash and nothing more.

```ruby
require 'dependor/rspec'

describe Injector do
  let(:injector) { described_class.new }
 
  specify do 
    expect{injector.create_product_service}.to_not raise_error
  end
end
```

#### Service

For testing the service you go whatever way you want.
Create new instance manually or use
[`Dependor::Isolate`](https://github.com/psyho/dependor#dependorisolate).

```ruby
require 'dependor/rspec'

describe CreateProductService do
  let(:metrics_adapter) do
    FakeMetricsAdapter.new
  end
  subject(:create_product_service) { isolate(CreateProductService) }

  specify "something something" do
    create_product_service.call(..)
    expect(..)
  end
end
```

## That's it

Thanks for reading. If you liked it and you wanna find out more subscribe
to course below.

<%= show_product_inline(item[:newsletter_inside]) %>
