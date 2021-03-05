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
   def allow_and_print_real_requests!
     WebMock.allow_net_connect!
     WebMock.after_request do |request_signature, res|
       puts "=== outgoing request ========================================"
       puts WebMock::RequestSignatureSnippet.new(request_signature).stubbing_instructions
       puts
       puts "parsed body:"
       puts
       pp JSON.parse(res.body)
       puts "============================================================="
       puts
     end
   end
 end
```
