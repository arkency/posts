---
title: "Rails API - my simple approach"
created_at: 2013-01-10 18:30:12 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :aar
tags: [ 'rails', 'api' ]
---

I have seen people using very different techniques to build API around Rails applications.
I wanted to show what I like to do in my projects. Mostly because it is a very simple
solution and it does not make your models concerned with another responsibility.

<!-- more -->

## Naming

First, I have a problem with the naming around API. I believe we use invalid nomenclature to describe our intentions.
Let's think about it for a moment. Imagine we have a `Customer` object
and we need to keep it somewhere between the restarts of our application (not necessarily Rails application).
So what do we do ? We use serialization to store it in a file. May it be binary format, JSON, XML or YAML:

```
#!ruby
require 'yaml'

class Customer < Struct.new(:first_name, :last_name, :email) # Or ActiveRecord::Base
  def full_name
    [first_name, last_name].join(" ")
  end
end

c = Customer.new("Robert", "Pankowecki")
text = c.to_yaml
# =>
# --- !ruby/struct:Customer
# first_name: Robert
# last_name: Pankowecki
# email:

File.open("serialized.txt", "w"){|f| f.puts(text) }

c2 = YAML.load(text)
# => #<struct Customer first_name="Robert", last_name="Pankowecki", email=nil>

c2 == c
#=> true
```

What is the point of serialization ?

To store the _inner state_ of an object and use it to recreate it later.

But this is not what we usually want to achieve when building APIs. In such case we want to deliver
some data to the consumer of our API. We don't try to save the state of an object.

Rather I would say, we present it. Therefore I prefer to use the name **serialization** when the object
is stored and processed by the same application and its _inner state_ is stored. And the name **presenter**
sounds good to me in cases when you talk about an object with a separate application. When you display it
to others. When you show its, what I would say, _external state_ (if such thing might exist).

You might wanna ask _"well, what is the difference"?_ I shall answer you immediately.

The _inner state_ and _external state_ might often not be the same thing. In our case we store `first_name` and
`last_name` separately but our clients might only be interested in `full_name`. There is no reason to send them
`{"first_name":"Robert","last_name":"Pankowecki"}` when they actually need: `{"full_name":"Robert Pankowecki"}`.

So... What shall we do ? Bring up the presenters on stage.

## Initial implementation

Presenter, for me, in API requests has a role similar to the _View_ layer in classic requests to obtain HTML page.
We want a layer whose responsibility is to build the response data. And we want it to be separated from our
domain and most likely contain some presentation logic that should not be in model.

```
#!ruby
class CustomerPresenter
  attr_accessor :customer
  delegate :full_name, to: :customer

  def initialize(customer)
    @customer = customer
  end

  def as_json(*)
    {
      fullName: full_name
    }
  end
end
```

You look at that `as_json` method and you know from the first look what is being sent to your API clients.
How do you use it in a controller ?

```
#!ruby
class CustomersController < ApplicationController
  respond_to :json

  def show
    customer  = Customer.find(params[:id])
    presenter = CustomerPresenter.new(customer)
    respond_with(presenter)
  end
end
```

As simple as that.

## Presenters might have logic

Let's say that the consumers of the API would like to display the avatar of `Customer`. We know the
email of a customer so we might compute Gravatar url and give it the consumer. We might be tempted
to write such logic in our model (and it is not that bad idea) but because it is of no use to our app,
I would prefer to have a method for that in the presenter itself.

```
#!ruby
class CustomerPresenter
  attr_accessor :customer
  delegate :full_name, :email, to: :customer

  def initialize(customer)
    @customer = customer
  end

  def as_json(*)
    {
      fullName:  full_name,
      avatarUrl: gravatar_url
    }
  end

  private

  def gravatar_url
    "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}"
  end
end
```

## Presenters might use multiple objects

Do you like Hypermedia API ? I still don't know but let's give it a try here just to prove my point _☺_.
There is a feature that customer can be notified about promotions and other events. It is done by
sending request to URL that we have available under `customer_notification_url` route method in our controller.
We would like to send it also to the API clients of our app.

```
#!ruby
class CustomerPresenter
  attr_accessor :customer, :url_generator

  delegate :full_name, :email,          to: :customer
  delegate :customer_notification_url,  to: :url_generator

  def initialize(customer, url_generator)
    @customer      = customer,
    @url_generator = url_generator
  end

  def as_json(*)
    {
      fullName:        full_name,
      avatarUrl:       gravatar_url,
      notificationUrl: notification_url
    }
  end

  private

  def gravatar_url
    "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}"
  end

  def notification_url
    customer_notification_url(customer.id)
  end
end
```

And the controller:

```
#!ruby
class CustomersController < ApplicationController
  respond_to :json

  def show
    customer  = Customer.find(params[:id])
    presenter = CustomerPresenter.new(customer, self)
    respond_with(presenter)
  end
end
```

## Tidying up the the presenter

You can simply have you presenter talk multiple dialects by including
[`ActiveModel::Serializers`](http://api.rubyonrails.org/classes/ActiveModel/Serializers.html) :

```
#!ruby
class CustomerPresenter

  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  attr_accessor :customer, :url_generator

  delegate :full_name, :email,          to: :customer
  delegate :customer_notification_url,  to: :url_generator

  def initialize(customer, url_generator)
    @customer      = customer,
    @url_generator = url_generator
  end

  def attributes
    @attributes ||= {
      fullName:        full_name,
      avatarUrl:       gravatar_url,
      notificationUrl: notification_url
    }
  end

  def to_xml(options = {})
    options        ||= {}
    options[:root] ||= :customer
    super(options)
  end

  def to_json(options = {})
    options        ||= {}
    options[:root] ||= :customer
    super(options)
  end

  private

  def gravatar_url
    "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}"
  end

  def notification_url
    customer_notification_url(customer.id)
  end
end
```

And embrace it in your controller by responding to multiple mime types:

```
#!ruby
class CustomersController < ApplicationController
  respond_to :json, :xml

  def show
    customer  = Customer.find(params[:id])
    presenter = CustomerPresenter.new(customer, self)
    respond_with(presenter)
  end
end
```

## A little bit of declarativeness

I am also a big fan of [`decent_exposure`](https://github.com/voxdolo/decent_exposure)
and love how the controllers look when using it:

```
#!ruby
class CustomersController < ApplicationController
  respond_to :json, :xml

  expose(:customers) { Customer.active } # ActiveRecord scope
  expose(:customer)
  expose(:presenter) { CustomerPresenter.new(customer, self) }

  def create
    if customer.save
      respond_with(presenter, location: nil)
    else
      # ...
    end
  end

  def show
    respond_with(presenter)
  end
end
```

## Multiple presenters

It might happen that different usecases demend different presentation. We might need a different value
or additional field. I heard you like inheritance:

```
#!ruby
class Admin::CustomerPresenter < ::CustomerPresenter
  def attributes
    @admin_attributes ||= super.merge(
      admin_field: some_value
    )
  end

  private

  def some_value
    # ...
  end
end
```

Or maybe you prefer dynamic mixins ?

```
#!ruby
module Admin::CustomerPresenter
  def attributes
    @admin_attributes ||= super.merge(
      admin_field: some_value
    )
  end

  private

  def some_value
    # ...
  end
end

presenter = CustomerPresenter.new(...)
presenter.extend(Admin::CustomerPresenter)
```

Delegation ?

```
#!ruby
class Admin::CustomerPresenter
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  def initialize(base_presenter)
    @base_presenter = base_presenter
  end

  def attributes
    @attributes ||= base_presenter.attributes.merge(
      admin_field: some_value
    )
  end

  def to_xml(options = {})
    options        ||= {}
    options[:root] ||= :"customer-for-admin"
    super(options)
  end

  def to_json(options = {})
    options        ||= {}
    options[:root] ||= :"customer-for-admin"
    super(options)
  end

  private

  def some_value
    # ...
  end
end

base_presenter = CustomerPresenter.new(...)
presenter      = Admin::CustomerPresenter.new(base_presenter)
```

It doesn't matter which way you like most. All options are still available to you. You know
how they work and what are the implications of using the solution you have chosen. Because
they are part of the language that you use daily. Not yet another DSL which must implement its
own syntax to let you share some parts of the code and mimic inheritance. Plain, old, simple
Ruby.

## Limitations

Nothing of what I showed here will help in the case where you actually need to created objects
based on XML or JSON that you received. Roar might be really helpful in such situation.

## Note

If you dislike my solution, feel free to use 
[roar](https://github.com/apotonick/roar),
[rails-api](https://github.com/rails-api/rails-api) or 
[active model serializers](https://github.com/rails-api/active_model_serializers).
I think they all have their own advantages.

## Conclusion

There many libraries that try to help you deliver a well crafted API representations.
But maybe you do not need them and you can achieve your goals using just plain Ruby features ?

If you like this article you might be interested in our product that we would like to publish
in the future. It will be full of such analysis. You can sign up below.
