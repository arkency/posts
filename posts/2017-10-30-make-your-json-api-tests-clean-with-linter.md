---
title: "Make your JSON API tests clean with linter"
created_at: 2017-10-30 21:47:28 +0100
kind: article
publish: true
author: Szymon Fiedler
tags: [ 'rails', 'json', 'api', 'testing']
newsletter: arkency_form
---

Recently, one of our customers requested that mobile devices should communicate with backend via [JSON API](http://jsonapi.org). We started implementing an endpoint for registering customers.

<!-- more -->

We used [JSON Schema](http://jsonapi.org/faq/#is-there-a-json-schema-describing-json-api) describing JSON API as a part of custom RSpec matcher. To be sure that both request and response body are following the schema.

```ruby
RSpec::Matchers.define :be_valid_jsonapi_document do
  def schema_path
    Rails.root.join("spec/support/schema.json").to_s
  end

  match do |document|
    JSON::Validator.validate(schema_path, document)
  end

  failure_message do |document|
    JSON::Validator.fully_validate(schema_path, document).join("\n")
  end
end
```

As you might notice, [`json-schema`](https://github.com/ruby-json-schema/json-schema) gem was used to validate the schema, but that's an implementation detail. Let's take a look at the test:

```ruby
RSpec.describe "Customers endpoint", type: :request do
  specify "registering customer" do
    json_data = JSON.dump({
      data: {
        id: "de47043c-bd1a-4592-9601-a68ad0d0ea89",
        type: "customers",
        attributes: {
          email: "joe@example.com",
          password: "Foo123Bar",
          toc_agreement: true,
          marketing_agreement: true,
          newsletter_agreement: true,
        }
      }
    })

    post "/users", params: json_data, headers: { "CONTENT_TYPE" => "application/vnd.api+json" }

    expect(JSON.parse(json_data)).to be_valid_jsonapi_document
    expect(request.content_type).to eq("application/vnd.api+json")

    expect(response).to have_http_status(201)
    expect(response.content_type).to eq("application/vnd.api+json")
    parsed_body = JSON.parse(response.body)
    expect(parsed_body).to be_valid_jsonapi_document
    expect(parsed_body["data"]["id"]).to eq("de47043c-bd1a-4592-9601-a68ad0d0ea89")
    expect(parsed_body["data"]["type"]).to eq("customers")
  end
end
```

We're posting data regarding customer like email, password, and some agreements. Then we validate if request and response meet our expectations. Especially if they are valid with JSON Schema.

This test is a bit cluttered, don't you think? Wouldn't it be better to make schema validations more transparent and focus on important things? By important I assume business information, not infrastructural things like proper headers or following the schema.

The spec above is a [request](https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec) type of spec. _Request specs provide a thin wrapper around Rails' integration tests, and are designed to drive behaviour through the full stack, including routing (provided by Rails) and without stubbing (that's up to you)._ If it's a full stack test, probably we can get access to the Rails app via `app` method. `#<UsersApp::Application:0x007fc86503cc7... >`. Yes, we can.

Let's write a middleware which wraps the Rails app instantiated in a spec example to validate request & response. We can do this since [Rails application is a Rack object](http://guides.rubyonrails.org/rails_on_rack.html). According to _[Rack](https://rack.github.io)_ documentation, it _provides a minimal interface between webservers that support Ruby and Ruby frameworks. To use Rack, provide an "app": an object that responds to the call method, taking the environment hash as a parameter, and returning an Array with three elements:_

_- The HTTP response code_
_- A Hash of headers_
_- The response body, which must respond to each_

Linter implementation:

```ruby
class JsonApiLint
  class InvalidContentType < StandardError
    def initialize(content_type)
      super(<<~EOS)
          expected: Content-Type: application/vnd.api+json
          got:      Content-Type: #{content_type}
      EOS
    end
  end

  class InvalidDocument < StandardError
    def initialize(document)
      super(JSON::Validator.fully_validate(Rails.root.join("spec/support/schema.json").to_s, document).join("\n"))
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    request  = Rack::Request.new(env)
    status, headers, body = @app.call(env)
    response = Rack::Response.new(body, status, headers)

    validate_request(request)
    validate_response(response)

    response
  end

  private

  def validate_response(response)
    raise InvalidContentType.new(response.content_type) unless match_content_type(response.content_type)

    document = JSON.parse(response.body.dup.join)
    raise InvalidDocument.new(document) unless valid_schema(document)
  end

  def validate_request(request)
    raise InvalidContentType.new(request.content_type) unless match_content_type(request.content_type)

    document = request.body.read
    request.body.rewind

    raise InvalidDocument.new(document) unless valid_schema(document)
  end

  def valid_schema(document)
    return true unless document.present?
    JSON::Validator.validate(Rails.root.join("spec/support/schema.json").to_s, document)
  end

  def match_content_type(content_type)
    /application\/vnd\.api\+json/.match?(content_type)
  end
end
```

Linter wraps Rails app, takes `env` hash as input to the `call` method and then performs checks. At first glance it verifies `Content-Type` header whether one matches `application.vnd.api+json`. Then it verifies request body whether it's compliant with JSON Schema, same goes for the response. If any deviation occurs, an exception with RSpec look-a-like error is raised. If everything goes fine, the response is returned so we can check other expectations in our spec example.

To make linter working, `app` method has to be overridden as I mentioned before:

```ruby
def app
  JsonApiLint.new(super)
end
```

Our complete spec now looks like:

```ruby
RSpec.describe "Customers endpoint", type: :request do
  specify "registering customer" do
    json_data = JSON.dump({
      data: {
        id: "de47043c-bd1a-4592-9601-a68ad0d0ea89",
        type: "customers",
        attributes: {
          email: "joe@example.com",
          password: "Foo123Bar",
          toc_agreement: true,
          marketing_agreement: true,
          newsletter_agreement: true,
        }
      }
    })

    post "/users", params: json_data, headers: { "CONTENT_TYPE" => "application/vnd.api+json" }

    expect(response).to have_http_status(201)
    expect(parsed_body["data"]["id"]).to eq("de47043c-bd1a-4592-9601-a68ad0d0ea89")
    expect(parsed_body["data"]["type"]).to eq("customers")
  end

  def app
    JsonApiLint.new(super)
  end

  def parsed_body
    JSON.parse(response.body)
  end
end
```

For me this test is now more compact & business value oriented.

### Would you like to continue learning more?

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our every day struggles and solutions for building maintainable Rails apps which don't surprise you.

You might enjoy reading:

* [How and why should you use JSON API in your Rails API?](/2016/02/how-and-why-should-you-use-json-api-in-your-rails-api/)
* [API of the future](/2016/06/api-of-the-future/)
* [Cover all test cases with #permutation](/2016/06/cover-all-test-cases-with-permutation/)

If you want to learn how to support JSON API standard in your Rails application, try our [_Frontend Friendly Rails Book_](http://blog.arkency.com/frontend-friendly-rails/).

Would you like me and my coworkers from Arkency to join your project? Check out [our offer](/assets/misc/How-can-Arkency-help-you.pdf)
