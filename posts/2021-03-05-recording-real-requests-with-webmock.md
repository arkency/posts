---
title: Recording real requests with WebMock
created_at: 2021-03-05T12:22:44.265Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Recording real requests with WebMock

Almost like VCR, but without VCR — thankfully.

You're looking for this:

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

I really appreciate that WebMock gives you a copy-paste-able snippet to stub your request in a test case, but this snippet is only useful to some extent — to stub your request when you don't care what it returns. When your code cares about the returned response, you need to define the body and you need to take it from somewhere. Usually people play with the real service and take an example response body from it. This can get quite tedious when there's a lot of requests. There are tools that help you with this too — VCR will let you run your test and it 

