---
title: "Instantiating Service Objects"
created_at: 2014-09-28 11:14:39 +0200
kind: article
publish: false
author: Robert Pankowecki
newsletter: :skip
newsletter_inside: :fearless_refactoring_course_instantiating
tags: [ 'ruby', 'rails', 'service', 'objects', 'instantiate' ]
---

<p>
  <figure>
    <img src="/assets/images/instantiating-service-objects-ruby-rails/board-cubes-game-2923-16-10-fit.jpg" width="100%">
  </figure>
</p>

In [my last blogpost about adapters](/2014/08/ruby-rails-adapters/) I promised a more detailed insight
into instantiating Adapters & Service Objects. So here we go.

<!-- more -->

## Boring style

```
#!ruby
class ProductsController
  def create
    metrics = MetricsAdapter.new(METRICS_CONFIG.fetch(Rails.env))
    service = CreateProductService.new(facebook_adapter)
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

```
#!ruby

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

```
#!ruby

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

## Dependor


<%= inner_newsletter(item[:newsletter_inside]) %>
