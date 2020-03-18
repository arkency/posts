---
title: "Implementing & Testing SOAP API clients in Ruby"
created_at: 2016-07-18 16:51:03 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'SOAP', 'API', 'ruby', 'testing']
newsletter: arkency_form
---

The bigger your application, the more likely you will need
to integrate with less common APIs. This time, we are going
to discuss testing communication with SOAP based services.
It's no big deal. Still better
than gzipped XMLs over SFTP (I will leave that story to
another time).

I am always a bit anxious when I hear SOAP API. It sounds
so enterprisey and intimidating. But it doesn't need to be.
Also, I usually prematurely worry that Ruby tooling won't
be good enough to handle all those XMLs. Perhaps this is
because of some of my memories of terrible SOAP APIs that
I needed to integrate with when I was working as a .NET
developer. But SOAP is not inherently evil. In fact, it has
some good sides as well.

<!-- more -->

## Implementation

We are going to use `savon` gem for the implementation
and `webmock` to help us with testing. The plan is to
implement a `capture` functionality for a payment gateway.
It means that goods were already shipped or delivered to
the customer and the reserved amount can be paid to the
merchant.

Let's see the implementation first and go through it.

```ruby
def capture(order_id)
  client = Savon.client(
    wsdl:        static_configuration.goods_shipped_url,
    logger:      Rails.logger,
    log_level:   :debug,
    log:         true,
    ssl_version: :TLSv1,
  )

  data = {
    companyID:  static_configuration.company_id.to_s,
    orderID:    order_id,
    retailerID: static_configuration.retailer_id.to_s,
  }.tap do |params|
    params[:signature] = HashGuard.new(
      static_configuration.shared_secret
    ).calculate(params.values)
  end

  response = client.call(
    :goods_shipped,
    message: data,
  )

  result = response.body[:goods_shipped_response][:goods_shipped_result]
  result[:status] == "Ok" or raise CaptureFailed, "Capture status is: #{result[:status]}"
  return result[:TransactionID]
end
```

The example is not long but sufficient enough
to discuss a few aspects.

There is a static configuration that we don't need
to bother ourselves with right now. It contains API URLs
and API keys. In Rails app they usually differ per
environment. Development and staging are using the pre-production
environment of the API provider. Our production env 
is using API production host. In tests, I usually use
pre-production config for safety as well. But thanks to webmock
we should never reach this host anyway.

We use Savon gem to communicate with the API. I explicitly
configure it to use `TLS` instead of the obsolete `SSL` protocol
for safety. Depending on your preferences you might set
it to log the full communication and to which file. I find
it very useful to have full dump during the exploratory phase.
When I just play with the API in development to see how it
behaves and what it responds. Having full output of the XML
from requests and responses can be a lifesaver when debugging
and comparing with documentation.

The most important part of the initialization is:

```ruby
Savon.client(
  wsdl: static_configuration.goods_shipped_url,
)
```

It tells `Savon` where to find `WSDL` - _an XML file
for describing network services as a set of
endpoints operating on messages_. 

It can be used to descripe messages/types:

This is for example what we need to send:

```
<s:element name="GoodsShipped">
  <s:complexType>
    <s:sequence>
      <s:element minOccurs="1" maxOccurs="1" name="companyID" type="s:int" />
      <s:element minOccurs="1" maxOccurs="1" name="retailerID" type="s:int" />
      <s:element minOccurs="0" maxOccurs="1" name="orderID" type="s:string" />
      <s:element minOccurs="0" maxOccurs="1" name="signature" type="s:string" />
    </s:sequence>
  </s:complexType>
</s:element>
```

and this is what we will receive:

```
<s:complexType name="GoodsShippedResponse">
  <s:sequence>
    <s:element minOccurs="1" maxOccurs="1" name="Status" type="s1:GoodsShippedStatus" />
    <s:element minOccurs="0" maxOccurs="1" name="TransactionID" type="s:string" />
    <s:element minOccurs="1" maxOccurs="1" name="ContractID" type="s:int" />
    <s:element minOccurs="1" maxOccurs="1" name="LoanAmount" type="s:double" />
  </s:sequence>
</s:complexType>
```

What is a `GoodsShippedStatus` ?

```
<s:simpleType name="GoodsShippedStatus">
  <s:restriction base="s:string">
    <s:enumeration value="Ok" />
    <s:enumeration value="WrongState" />
    <s:enumeration value="Error" />
  </s:restriction>
</s:simpleType>
```

So as you can see the whole API is defined based on primitives
which build more complex types which can be parts of even more
complex types.

The best thing about using SOAP APIs with WSDL is that the client
can parse such API definition and dynamically or statically define
all the methods and conversions required to interact with the API.

Also, even when the API documentation written by humans is incorrect,
you can peek into the WSDL to see what's actually going on there.
It helped me a lot a few times.

In next part, we build a Hash with keys matching the names
from the WSDL definition of the type.

```ruby
data = {
  companyID:  static_configuration.company_id.to_s,
  orderID:    order_id,
  retailerID: static_configuration.retailer_id.to_s,
}.tap do |params|
  params[:signature] = HashGuard.new(
    static_configuration.shared_secret
  ).calculate(params.values)
end
```

The signature is a cryptographic digest of all the other
values based on a secret that only me and the payment gateway
should know. That way the gateway can check the integrity of
the message and that it is coming from me and not somebody else.
So it plays a role of authentication token as well.
I extracted the implementation into `HashGuard` class which
is not interesting for us today.

Finally, we call `goods_shipped` API endpoint which is also
defined in the WSDL so `Savon` knows how to reach it and
how to build the XML with the `data` that we provide.

```ruby
response = client.call(
  :goods_shipped,
  message: data,
)
```

The result of the API call is also automatically converted for us
from XML to Ruby primitives such as numbers, strings, arrays
and hashes.

```ruby
result = response.body[:goods_shipped_response][:goods_shipped_result]
result[:status] == "Ok" or raise ::PaymentGateway::Errors::CaptureFailed, "Capture status is: #{result[:status]}"
return result[:TransactionID]
```

So we can extract the interesting part and
see if everything worked correctly.

## Testing

I am going to test this code based on the underlying
networking communication protocol. In other words,
we will stub the HTTP requests with the XML being sent.

This is on purpose. I want to be able to switch to
different gem or a library provided by the payment
gateway authors without the need to change the
tests.

If I just stubbed Ruby method calls, I would not have
the ability to change the implementation without
changing tests. I would be just typo-testing the
implementation. That way I check if we send proper
data over the wire and how we react to response
data. It does not matter if I use `Savon` or handcraft
those XMLs and URLs myself.

```
specify "successful capture" do
  stub_getting_wsdl_definition
  stub_request(:post, 'https://example.org/Services/WebshopIntegration.asmx').with(body: <<-XML.split("\n").map(&:strip).join
    <?xml version="1.0" encoding="UTF-8"?>
    <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="http://abc.example.org/" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ins0="http://abc.example.org/OrderStatusdResponse">
      <env:Body>
        <tns:GoodsShipped>
          <tns:companyID>3</tns:companyID>
          <tns:orderID>devz2556219t0r61</tns:orderID>
          <tns:retailerID>9999</tns:retailerID>
          <tns:signature>H1MgHg81vVEVOiJt7ivGz5aVvPM2wIm1GnzTHSqg2m8=</tns:signature>
        </tns:GoodsShipped>
      </env:Body>
    </env:Envelope>
  XML

  ).to_return(:status => 200, :body => body = <<-XML
    <?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <soap:Body>
        <GoodsShippedResponse xmlns="http://abc.example.org/">
          <GoodsShippedResult xmlns="http://abc.example.org/GoodsShippedResponse">
            <Status>Ok</Status>
            <TransactionID>8c2ee655b5114</TransactionID>
            <ContractID>1005869</ContractID>
            <LoanAmount>2222</LoanAmount>
          </GoodsShippedResult>
        </GoodsShippedResponse>
      </soap:Body>
    </soap:Envelope>
  XML
  )

  transaction_id = gateway.capture("devz2556219t0r61")
  expect(transaction_id).to eq("8c2ee655b5114")
end

private

def stub_getting_wsdl_definition
  stub_request(:get, "https://i.example.org/Services/WebshopIntegration.asmx?WSDL").
    to_return(
      status: 200, 
      body: Rails.root.join("spec/fixtures/pg.wsdl.xml").read,
    )
end
```

First, we stub getting the `WSDL`. I downloaded it
myself and saved under `spec/fixtures/pg.wsdl.xml`.
They are usually quite a long files, so I prefer to
keep their content outside of the specification.
It remains the same and does not depend on any
parameters that we could pass so it does not bring
anything valuable to the spec.

Then we stub the `GoodsShipped` request that we issue.
It contains the static data coming from the configuration
and the provided `order_id`. I have taken the XML
structure of the file from savon logs while playing
with the API. Sometimes you have the correct 
XML structure provided as part of the API documentation.

Notice the `body: <<-XML.split("\n").map(&:strip).join`
part. The XML generated by savon is not pretty formatted.
I like my XMLs in tests to be human readable. So I use
this little trick to compact my XML into the same format
as savon will generate. It has no indentation.

We also stub the response. In this test, we are checking
the successful path. So the status is "Ok". In such
case, our adapter should return the `transaction_id`
from the response. That would be `8c2ee655b5114`.

## Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your
everyday Rails programmer job.

Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring Rails applications.

Also, make sure to check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.
