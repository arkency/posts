---
created_at: 2021-02-09T19:33:50.706Z
author: Paweł Pacana
tags: ['testing']
publish: false
---

# Testing responses from HTTP APIs with cursor-based pagination and Webmock

Once upon a time I was working on importing orders from a phased out Shopify shop instance into an existing system. The application was already interacting with a new shop instance. The business wanted to extend the reporting and gain insight into legacy orders from previous shop, in addition to existing one.

The developers already implemented a tailor-made adapter to interact with Shopify API, which wrapped [shopify_api](https://github.com/Shopify/shopify_api) gem. So far so good — I thought, and jumped straight into the core of the problem I had to solve. The low-level interaction details were abstracted away, allowing me to move focus elsewhere. Yet something was odd when I've been using this adapter against legacy shop endpoint. Some product variant resources were not to be found in the API although I could look them up in the admin UI. 

The part of the adapter in question looked like this:

```ruby
class ShopifyClient
  class << self
    include Dry::Monads[:result]
    
    def find_variant_by_sku(sku)
      wrap_response { ShopifyAPI::Variant.find(:all, params: { limit: 250 }).find { |v| v.sku == sku } }
    end
    
    def wrap_response(&block)
      response = block.call
      return response if response.is_a? Dry::Monads::Result
       return Failure(nil) if response.blank?

       Success(response)
     rescue ActiveResource::ConnectionError => e
       Failure(e)
     end
  end
end        
```

It got me thinking. Why do we use this particular value as the limit? And how many variants do we actually have in each of the shops? Turns out that Shopify by default returns up to 50 items of the collection in the API response. The new shop had not much over 50 variants. Increasing the limit to fit existing variant count was surely a pragmatic way to overcome a similar problem in the past. However the legacy shop had over 400 variants. And the limit of 250 turned out to be the maximum one can set — for a reason. In general, the bigger the query set, the more time is spent:
* preparing (querying the database, serializing results into JSON objects, streaming the response bytes) 
* consuming it (receiving bytes and parsing it into something useful)

## Enter cursor-based pagination

Cursor-based pagination is the one where you navigate through a dataset with a pointer, marking the record where you left, and a number of records to read in a given direction.

In contrast to offset-limit pagination there's no situation where changing a part of the dataset prior to the cursor affects the next set of results. To quote a great explanation from [JSON API](https://jsonapi.org/profiles/ethanresnick/cursor-pagination/) specification:

> For example, with offset–limit pagination, if an item from a prior page is deleted while the client is paginating, all subsequent results will be shifted forward by one. Therefore, when the client requests the next page, there’s one result that it will skip over and never see. Conversely, if a result is added to the list of results as the client is paginating, the client may see the same result multiple times, on different pages. Cursor-based pagination can prevent both of these possibilities.

In SQL databases there are some interesting [performance](https://shopify.engineering/pagination-relative-cursors) [implications](https://use-the-index-luke.com/no-offset) as well.

Shopify API exposes cursor-based pagination. The `page_info` parameter is our cursor, `limit` drives the number of results and we only move forward. This is how it looks like from API client gem perspective:

```ruby
first_batch_products  = ShopifyAPI::Product.find(:all, params: { limit: 50 })
second_batch_products = ShopifyAPI::Product.find(:all, params: { limit: 50, page_info: first_batch_products.next_page_info })
  
```

At this point I could have improved the API adapter and call it a day:

```ruby
class ShopifyClient
  MAX_PAGE_SIZE = 250
  
  class << self
    include Dry::Monads[:result]

    def find_variant_by_sku(sku)
      wrap_response do
        variants  = ShopifyAPI::Variant.find(:all, params: { limit: MAX_PAGE_SIZE })
        variants_ = variants
        while variants.next_page?
          variants = variants.fetch_next_page
          variants_.concat(variants)
        end
        variants_.find { |v| v.sku == sku }
      end
    end
  end
end
```

I did not 😱

In my worldview this `ShopifyClient` adapter is an abstraction of every 3rd party interaction we could have in this application. There may be reasons out of which I would change the implementation of the adapter. At the same time I would not like to change how the application interacts with the adapter. 
When testing, I would like to extensively test how the adapter interacts with the 3rd party API on the HTTP protocol level. On the other hand, I would not like to exercise each piece of the application with that level of detail when it comes to 3rd party — only that it collaborates with the adapter in a way that is expected.

Before you ask: the reason why would I test HTTP interactions of the adapter despite the presence of convenient `shopify_api` gem is to keep options open in the future:
* when its time to change the adapter I'd like to do it with confidence and without hesitating too much how it affects the rest — keeping HTTP interactions in check gives me that
* context switching — I already had to jump into very details of Shopify API and to this particular code, I'm sure months from now I'll not have all that cache in my head, thus making future changes more costly than now 
* dependencies graph — each application dependency constrains it more, the scope of the gem is much bigger than the needs of the application I work on and I'd not hesitate to drop the gem as soon as it becomes a trouble (i.e. its [activeresource dependency](https://github.com/Shopify/shopify_api/issues/826))

## Verifying HTTP interactions with Webmock

Testing paginated responses can be tricky. We need at least two requests for subsequent pages to verify that paging works as expected. The URL and query parameters must match (looking at that maximum per-page limit). Finally the response must be in shape and it can be a lot of records to fake or replay for two pages of results.

Today I'd like to show you how I specifically approached this with [webmock](https://github.com/bblimke/webmock) gem. There are other fine tools one can use instead. Unfortunately I may not have enough patience or forgiveness to use them.

A TDD practitioner would begin with a failing test and fill in the implementation, which in turn makes a "red" go into "green". We already have a non-paginated adapter implementation and the spec is consciously blank for educational purpose.

Let's execute following:

```ruby
RSpec.describe ShopifyClient do
  specify do
     variant = 
       ShopifyClient
         .find_variant_by_sku("some-sky")
         .value!
  end
end
```

Despite no expectation to fulfill, this triggers following error:

```
 WebMock::NetConnectNotAllowedError:
   Real HTTP connections are disabled. Unregistered request: GET https://example.myshopify.com/admin/api/2020-07/variants.json?limit=250 with headers {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic Og==', 'User-Agent'=>'ShopifyAPI/9.3.0 ActiveResource/5.1.1 Ruby/2.7.2'}

   You can stub this request with the following snippet:

   stub_request(:get, "https://example.myshopify.com/admin/api/2020-07/variants.json?limit=250").
     with(
       headers: {
      'Accept'=>'application/json',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Authorization'=>'Basic Og==',
      'User-Agent'=>'ShopifyAPI/9.3.0 ActiveResource/5.1.1 Ruby/2.7.2'
       }).
     to_return(status: 200, body: "", headers: {})
```

That's very useful error to have. It tells that:
* there's non-allowed side-effect (HTTP call) that should be mocked
* what this mock could look like in test

We need expectations on the URL and query params. Let's stick to that, dropping `with(...)` part completely. It is a GET request so no body is posted, but we need body to return as a response. This is something webmock cannot provide for us and where I usually fallback to `curl`:

```
curl "https://SUPER:SECRET@example.myshopify.com/admin/api/2020-07/variants.json?limit=250" | pbcopy
```

Here's a little cheating — I don't actually want to have 250 resources in as response in the test. Just the single one, but still in shape of the collection:

```
curl "https://SUPER:SECRET@example.myshopify.com/admin/api/2020-07/variants.json?limit=1"
```

The response looks more or less like this:

```json
{
  "variants": [
    {
      "id": 2025327296540,
      "product_id": 170817191964,
      "title": "Default Title",
      "sku": "300300300",
      # more attributes cut out for brevity
    }
  ]
}
```

There's one more thing to look at. Response headers!

```
curl -I "https://SUPER:SECRET@example.myshopify.com/admin/api/2020-07/variants.json?limit=250"
```

Among the various key-values, there's the one we're looking for. A `link`. It's value reveals what is the link to the next page of results:

```
HTTP/2 200 
date: Tue, 09 Feb 2021 19:05:51 GMT
content-type: application/json; charset=utf-8
…
link: <https://example.myshopify.com/admin/api/2020-07/variants.json?limit=250&page_info=eyJsYXN0X2lkIjozMTQ1OTE5OTI1NDY0MSwibGFzdF92YWx1ZSI6IjMxNDU5MTk5MjU0NjQxIiwiZGlyZWN0aW9uIjoibmV4dCJ9>; rel="next"
```

With all that knowledge, let's improve the spec and pass the first webmock expectation:


```ruby
RSpec.describe ShopifyClient do
  def first_page_variant_resource
    {
      "id": 2025327296540,
      "product_id": 170817191964,
      "title": "Default Title",
      "sku": "300300300",
      # more attributes cut out for brevity
    }
  end
  
  specify do
    stub_request(:get, "https://exmple.myshopify.com/admin/api/2020-07/variants.json?limit=250")
      .to_return(status: 200, body: JSON.dump({ variants: [first_page_variant_resource] }), headers: { "Link" => <<~EOS.strip })
         <https://example.myshopify.com/admin/api/2020-07/variants.json?limit=250&page_info=eyJsYXN0X2lkIjoyMDI1MzI3Mjk2NTQwLCJsYXN0X3ZhbHVlIjoiMjAyNTMyNzI5NjU0MCIsImRpcmVjdGlvbiI6Im5leHQifQ>; rel="next"
      EOS
 
    variant = 
      ShopifyClient
        .find_variant_by_sku("some-sku")
        .value!
  end
end
```

Our non-paginated Shopify adapter would pass this, a paginated one too. We need to introduce more expectations.

Knowing the value of Link header, let's assert on that:

```ruby
stub_request(:get, "https://example.myshopify.com/admin/api/2020-07/variants.json?limit=250&page_info=eyJsYXN0X2lkIjoyMDI1MzI3Mjk2NTQwLCJsYXN0X3ZhbHVlIjoiMjAyNTMyNzI5NjU0MCIsImRpcmVjdGlvbiI6Im5leHQifQ")
  .to_return(status: 200, body: JSON.dump({ variants: [second_page_variant_resource] }))

```

Client should follow the URL from link header in order to get the next set of results. This link contains the cursor in form of the `page_info` parameter. The result of following the link is the second page with the resource we're looking for. Translating all this into a spec:


```
RSpec.describe ShopifyClient do
  def first_page_variant_resource
    {
      "id": 2025327296540,
      "product_id": 170817191964,
      "title": "Default Title",
      "sku": "300300300",
      # more attributes cut out for brevity
    }
  end
  
  def second_page_variant_resource
    {
      "id": 2025327296541,
      "product_id": 170817191965,
      "title": "Default Title",
      "sku": "300300301",
      # more attributes cut out for brevity
    }
  end
  
  specify do
    stub_request(:get, "https://exmple.myshopify.com/admin/api/2020-07/variants.json?limit=250")
      .to_return(status: 200, body: JSON.dump({ variants: [first_page_variant_resource] }), headers: { "Link" => <<~EOS.strip })
         <https://example.myshopify.com/admin/api/2020-07/variants.json?limit=250&page_info=eyJsYXN0X2lkIjoyMDI1MzI3Mjk2NTQwLCJsYXN0X3ZhbHVlIjoiMjAyNTMyNzI5NjU0MCIsImRpcmVjdGlvbiI6Im5leHQifQ>; rel="next"
      EOS
    stub_request(:get, "https://example.myshopify.com/admin/api/2020-07/variants.json?limit=250&page_info=eyJsYXN0X2lkIjoyMDI1MzI3Mjk2NTQwLCJsYXN0X3ZhbHVlIjoiMjAyNTMyNzI5NjU0MCIsImRpcmVjdGlvbiI6Im5leHQifQ")
      .to_return(status: 200, body: JSON.dump({ variants: [second_page_variant_resource] }))
 
    variant = 
      ShopifyClient
        .find_variant_by_sku(second_page_variant_resource["sku"])
        .value!
         
     expect(variant.id).to eq(second_page_variant_resource["id"])
  end
end
```

We've now covered full interaction with a paginated endpoint:

* we ask for product variants
* there's more than one page of results, as indicated by the link header
* we follow the link to get another batch
* that batch no longer has link header as there are no more pages
* we've modeled the example to include our expected resource in this second batch

All clear and explicitly stated in code, as opposed to VCR-recorded interaction in YAML fixtures. 

I hope this post gave you some useful insight how to use webmock and how a cursor-based pagination can be approached.
