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
    puts "=== outgoing request ========================================"
    puts stubbing_instructions
    puts
    puts "parsed body:"
    puts
    pp parsed_body
    puts "============================================================="
    puts
  end
end
```

Caveat: it's global, i.e. it'll apply to all the test cases you'll run. If you want it for just one test case, run just a single one.

(As far as I tried, there's no easy way to cleanly make it per-example with an `around` hook, because that would mean we need to store and restore the list of WebMock callbacks. You can get them from `WebMock::CallbackRegistry.callbacks`, but I couldn't find a way to set them back, apart from `WebMock::CallbackRegistry.reset` which empties the list of callback, which is fine only when there were no other callbacks in the first place.)
