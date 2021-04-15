---
title: Recording real requests with WebMock
created_at: 2021-03-08T21:00:00.000Z
author: Tomasz Wróbel
tags: ['testing', 'ruby']
publish: true
---

# Recording real requests with [WebMock](https://github.com/bblimke/webmock)

...to get an experience almost like with [VCR](https://github.com/vcr/vcr), but without it — thankfully.

If you're my-future-self and you're just looking for the piece of code to paste, it's here:

```ruby
def allow_and_print_real_requests_globally!
  WebMock.allow_net_connect!
  WebMock.after_request do |request_signature, response|
    stubbing_instructions =
      WebMock::RequestSignatureSnippet
        .new(request_signature)
        .stubbing_instructions
    parsed_body = JSON.parse(response.body)
    puts "===== outgoing request ======================="
    puts stubbing_instructions
    puts
    puts "response status: #{ res.status.inspect }"
    puts "parsed body:"
    puts
    pp parsed_body
    puts "=============================================="
    puts
  end
end
```

Caveat: it's global, i.e. it'll apply to all the test cases you'll run. If you want it for just one test case, run just a single one.

(As far as I tried, there's no easy way to cleanly make it per-example with an `around` hook, because that would mean we need to store and restore the list of WebMock callbacks. You can get them from `WebMock::CallbackRegistry.callbacks`, but I couldn't find a way to set them back, apart from `WebMock::CallbackRegistry.reset` which empties the list of callback, which is fine only when there were no other callbacks in the first place.)

## But why?

WebMock is a library for stubbing/mocking HTTP requests in your Ruby code. Once you enable WebMock and try to make a HTTP request in your test, you'll get an error like:

```ruby
WebMock::NetConnectNotAllowedError:
 Real HTTP connections are disabled. Unregistered request: GET https://wrobel.to/ with (...)

 You can stub this request with the following snippet:

 stub_request(:get, "https://wrobel.to/").
   with(
     headers: {
     # ...
     }).
   to_return(status: 200, body: "", headers: {})
```

I really appreciate that WebMock gives you a copy-paste-able snippet to stub your request in a test case, but this snippet is only useful to some extent — to stub your request when you don't care what it returns. When your code cares about the returned response, you need to define the body and you need to take it from somewhere. Usually people play with the real service and take an example response body from it. This can get quite tedious when there's a lot of requests. There are tools that help you with this too — if you run your test again a real service, VCR will record any HTTP interaction to a yaml file called "tape", which can then be replayed in subsequent test runs without hitting the real service.

But personally I'd rather avoid VCR and limit myself to WebMock, unless I'm forced too — for reasons that could make another blogpost. Shortly — it's easy to start with, but tends to be painful to maintain. (Actually, while I'm in the mode of sharing opinions, I'd limit the use of WebMock too — preferrably just to test the _adapters_. Domain tests can stub/mock/fake the adapters. Otherwise the tests quickly get noisy.)

But we can use WebMock like VCR to some degree. WebMock's `after_request` callback can be used to get hold of any outgoing request (once you allow them with `WebMock.allow_net_connect!`) and print it to stdout. Sounds promising, but if you only go with:

```ruby
WebMock.allow_net_connect!
WebMock.after_request { |req, res| p res }
```

...you'll no longer see these ready-to-copy stubbing snippets, but we can have them back with `RequestSignatureSnippet#stubbing_instructions`, which is what the original snippet is about.

Here are some other pieces about WebMock and VCR we've published recenty: [3 tips to tune your VCR in tests](https://blog.arkency.com/3-tips-to-tune-your-vcr-in-tests/) and [Testing cursor-based pagination with Webmock](https://blog.arkency.com/testing-responses-from-http-apis-with-cursor-based-pagination-and-webmock/).

If you want to comment or discuss, feel free to [reply under this tweet](https://twitter.com/tomasz_wro/status/1369262330782027776).
