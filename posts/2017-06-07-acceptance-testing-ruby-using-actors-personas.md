---
title: "Acceptance testing using actors/personas"
created_at: 2017-06-07 17:25:36 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'testing', 'actors', 'personas' ]
newsletter: :arkency_form
img: "actors-personas-ruby-rails-testing/actors_in_ruby_testing.jpeg"
---

Today I've been working on chillout.io (new landing page coming soon).
Our solution for sending Rails applications' metrics and building dashboards.
All of that so you can _chill out_ and know that your app is working.

<!-- more -->

We have one, almost full-stack, acceptance test which spawns a Rails app, a thread listening to
HTTP requests and which checks that the metrics are received by chillout.io when
an Active Record object was created. It has some interesting points so let's have a look.

## Higher level abstraction

```ruby
require 'test_helper'

class ClientSendsMetricsTest < AcceptanceTestCase
  def test_client_sends_metrics
    test_app      = TestApp.new
    test_endpoint = TestEndpoint.new
    test_user     = TestUser.new

    test_endpoint.listen
    test_app.boot
    test_user.create_entity('Something')
    assert test_endpoint.has_one_creation
  ensure
    test_app.shutdown if test_app
  end
end
```

The test has higher-level abstractions, which we like to call Test Actors.
In our consulting projects we often introduce classes such as `TestCustomer` or
`TestAdmin` or `TestMerchant`, even `TestMobileApp` and `TestDeveloper` etc.
They usually encapsulate logic/behavior of a certain role.
Their implementation detail varies between project.

## Testing with UI + Capybara (webkit/selenium/rack driver)

Sometimes they will use Capybara and one of its drivers. That can usually happen
at the beginning when we join a new legacy project, which test coverage is not
yet good enough. In that case, you can build helper methods that will navigate
around the page and perform certain actions.

```ruby
merchant = TestMerchant.new
merchant.register
merchant.open_a_new_shop
product = merchant.add_product(price: 100, vat: 23)

customer = TestCustomer.new
customer.add_to_basket(product)
customer.finish_order

merchant.visit_revenue_reporting
expect(merchant.current_gross_revenue).to eq(123)
```

## Defaults

This style allows you to build a story and hide a lot of implementation details.
Usually, defaults are provided either in terms of default method arguments:

```ruby
class TestMerchant
  def open_a_new_shop(currency: "EUR")
    # ...
  end
  
  def add_product(price: 10, vat: 19)
    # ...
  end
end
```

or as instance variables filled by previous actions

```ruby
class TestMerchant
  def open_a_new_shop(currency: "EUR")
    @shop = # ...
  end
  
  def add_product(shop: @shop)
    # ...
  end
end
```

which is useful if you have a multi-tenant application and most of your scenarios
operate in one tenant/country/shop/etc but sometimes you would like to test how
things behave if one merchant has two shops or if one customer buys in two different
countries/currencies etc.

## Memoize

The instance variables will usually contain primitive values. Either identifier (id or slug) of something that was done or a value filled out in a form which can be later used to find the relevant object again.

```ruby
class TestMerchant
  def open_a_new_shop(subdomain: "arkency-shop")
    @shop = subdomain
    fill_in 'Subdomain', with: subdomain)
    # ...
    click_button("Start a new shop")
  end
  
  def place_order
    # ...
    click_button("Buy now")
    expect(page).to have_content("Thanks for your purchase")
    @last_order_id = find(:css, '.order-id').text
  end
end
```

but sometimes it can be a simple struct if that's useful for subsequent method calls.

```ruby
class TestMerchant
  def open_a_new_shop(subdomain: "arkency-shop", currency: "EUR")
    @shop = TestShop.new(subdomain, currency)
    fill_in 'Subdomain', with: subdomain)
    # ...
    click_button("Start a new shop")
  end
end
```

## Testing by changing DB

In some cases, those actors will directly (or indirectly through factory girl) create some Active Record models. That is the case where we don't have UI for some settings because they are rarely changed.

```ruby
class TestDeveloper
  def register_country(currency:, default_vat_rate:)
    Country.create(...)
  end
end
```

## Testing using Service Objects

In other cases an actor will build a command and pass it to a
[service object](/2013/09/services-what-they-are-and-why-we-need-them/) or [command](https://github.com/arkency/command_bus) [bus](http://blog.arkency.com/2016/09/command-bus-in-a-rails-application/). This is a case where we feel that we don't
need (or want to because they are usually slow) to use the frontend
to test the functionality.

```ruby
class TestMerchant
  def open_a_new_shop(subdomain: "arkency-shop", currency: "EUR")
    @shop = subdomain
    ShopsService.new.call(OpenNewShopCommand.new(
      subdomain: subdomain,
      currency: currency,
    ))
    # ...
  end
end
```

```ruby
class TestMerchant
  def open_a_new_shop(subdomain: "arkency-shop", currency: "EUR")
    @shop = subdomain
    command_bus.call(OpenNewShopCommand.new(
      subdomain: subdomain,
      currency: currency,
    ))
    # ...
  end
end
```

I like this approach because such actors can remember certain default attributes
and fill out the commands with `user_id` or `order_id` based on what they did.
That means you don't need to keep too many variables in the test. These personas
have a memory. They know what they just did :)

## MobileClient - testing using HTTP request

If an actor plays a role of a mobile app which uses the API to communicate with
us, then the methods will call the API.

```ruby
class MobileClient
  JSON_CONTENT = {'CONTENT_TYPE' => 'application/json'}.freeze
  def choose_first_country
    response = get_api 'countries', {}, JSON_CONTENT
    raise "Couldn't fetch countries" unless response.status == 200
    @country_id = response.body['data']['countries'][0]['id']
  end
end
```

So let's get back to the acceptance test of our chillout gem which is done in a similar style and see what we can find inside.

## Overview

```ruby
class ClientSendsMetricsTest < AcceptanceTestCase
  def test_client_sends_metrics
    test_app      = TestApp.new
    test_endpoint = TestEndpoint.new
    test_user     = TestUser.new

    test_endpoint.listen
    test_app.boot
    test_user.create_entity('Something')
    assert test_endpoint.has_one_creation
  ensure
    test_app.shutdown if test_app
  end
end
```

## TestEndpoint

Let's start with `TestEndpoint` which plays the role of a chillout.io API server.

```ruby
class TestEndpoint

  attr_reader :metrics, :startups

  def initialize
    @metrics  = Queue.new
  end

  def listen
    Thread.new do
      Rack::Server.start(
        :app  => self,
        :Host => 'localhost',
        :Port => 8080
      )
    end
  end

  def call(env)
    payload = MultiJson.load(env['rack.input'].read) rescue {}

    case env['PATH_INFO']
    when /metrics/
      metrics  << payload
    end

    [200, {'Content-Type' => 'text/plain'}, ['OK']]
  end

  def has_one_creation
    5.times do
      begin
        return metrics.pop(true)
      rescue ThreadError
        sleep(1)
      end
    end
    false
  end
end
```

It can run a very simple rack-based server in a separate thread. When there is an API request to `/metrics` endpoint it saves the payload on in a [`Queue`](https://ruby-doc.org/core-2.2.0/Queue.html), a thread-safe collection.

It is also capable of checking whether there is something received in the queue.

Ok, but what about `TestApp` ?

## TestApp

There is more heavy machinery involved. We start a full Rails application with
chillout gem.

```ruby
class TestApp
  def boot
    sample_app_name = ENV['SAMPLE_APP'] || 'rails_5_1_1'
    sample_app_root = Pathname.new(
      File.expand_path('../support', __FILE__)
    ).join(sample_app_name)
    cmd = [
      Gem.ruby, 
      sample_app_root.join('script/rails').to_s,
      'server'
    ].join(' ')
    @executor = Bbq::Spawn::Executor.new(cmd) do |process|
      process.cwd = sample_app_root.to_s
      process.environment['BUNDLE_GEMFILE'] = 
        sample_app_root.join('Gemfile').to_s
      process.environment['RAILS_ENV']= 'production'
    end
    @executor = Bbq::Spawn::CoordinatedExecutor.new(
      @executor,
      url: 'http://127.0.0.1:3000/',
      timeout: 15
    )
    @executor.start
    @executor.join
  end

  def shutdown
    @executor.stop
  end
end
```

The [`bbq-spawn`](https://github.com/drugpl/bbq-spawn) gem makes sure that the
Rails app is fully started before we try to contact with it.

```ruby
def join
  Timeout.timeout(@timeout) do
    wait_for_io       if @banner
    wait_for_socket   if @port and @host
    wait_for_response if @url
  end
end

private

def wait_for_response
  uri = URI.parse(@url)
  begin
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.open_timeout = 5
      http.read_timeout = 5
      http.head(uri.path)
    end
  rescue SocketError # and much more...
    retry
  end
end
```

It can do it based on a text which appears in the command output (such as `INFO  WEBrick::HTTPServer#start: pid=400 port=3000`). It can do it based on whether you can connect to a port using a socket. Or in our case based on whether it can send and receive a response to an HTTP request, which is the most reliable way to determine that the app is fully booted and working.

## TestUser

There is also `TestUser` (`TestBrowser` would be probably a better name) which sends a request to the Rails app.

```ruby
class TestUser
  def create_entity(name)
    Net::HTTP.start('127.0.0.1', 3000) do |http|
      http.post('/entities', "entity[name]=#{name}")
    end
  end
end
```

## Recap

Together the story goes like this:

* start a fake chillout.io server (endpoint)
* run a rails application with chillout gem installed
* trigger a request to the rails app which creates a DB record
* chillout.io discovers the record was created and sends a metric
* the test endpoint receives the metric

```ruby
class ClientSendsMetricsTest < AcceptanceTestCase
  def test_client_sends_metrics
    test_app      = TestApp.new
    test_endpoint = TestEndpoint.new
    test_user     = TestUser.new

    test_endpoint.listen
    test_app.boot
    test_user.create_entity('Something')
    assert test_endpoint.has_one_creation
  ensure
    test_app.shutdown if test_app
  end
end
```

## More

If you enjoyed reading [subscribe to our newsletter](/newsletter/) and continue receiving useful tips for maintaining Rails applications, plus **get a free e-book** as well. 

## Links

* https://github.com/drugpl/bbq
* https://github.com/drugpl/bbq-spawn
