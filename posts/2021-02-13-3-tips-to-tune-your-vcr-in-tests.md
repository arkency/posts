---
created_at: 2021-02-13T09:19:01.230Z
author: Paweł Pacana
tags: ['ruby', 'testing']
publish: false
---

# 3 tips to tune your VCR in tests

In this post I describe 3 things that have grown my trust in VCR. These are: 

* decompressing stored responses
* not allowing unused mocks
* disabling VCR where not explicitly needed

Read on to see why I've specifically picked them.

## What is VCR from a bird's eye view

VCR is a tool which I'd classify as useful in snapshot testing. You record a snapshot of an interaction with a [System Under Test](http://xunitpatterns.com/SUT.html). Once recorded, these interactions are replayed from stored files — snapshots.

VCR specifically records HTTP interactions and stores results of such in YAML files called "tapes". A tape consists of series of requested URL, request headers, response headers and returned body. There may be multiple requests and responses stored in a single tape.

When added to project, VCR installs globally and intercepts all HTTP requests made in a test environment. When there's no tape recorded for an interaction, an error is raised, i.e.:

```
 VCR::Errors::UnhandledHTTPRequestError:


   ==============================================================
   An HTTP request has been made that VCR does not know how to 
   handle:
     GET https://cdn.contentful.com/spaces/space_id/environments/env/entries?sys.id=beef
```


For an interaction to be recorded, a living HTTP endpoint with data to record must exist. This is usually is your staging or test service instance. Recording is no different from regular data manipulation — querying or modifying. 

## Decompressing stored responses

By default VCR is tuned to store gzipped response data in gzipped-and-base64-encoded yaml-friendly string. This data is not decompressed and definitely not greppable:

```yaml
http_interactions:
- request:
    method: get
    uri: https://cdn.contentful.com/spaces/space_id/environments/env/entries?sys.id=beef
    body:
      encoding: UTF-8
      string: ''
    headers:
      Content-Type:
      - application/vnd.contentful.delivery.v1+json
      Accept-Encoding:
      - gzip
    # …
- response:
    status:
      code: 200
      message: OK
    headers: 
      Content-Encoding:
      - gzip
      Content-Type:
      - application/vnd.contentful.delivery.v1+json
    body:
      encoding: ASCII-8BIT
      string: !binary |-
        H4sIAAAAAAAAA5VTUU/CMBB+51csfRbTT...
```

Problem:

* not greppable response body and no idea what is the data that we make assertions on
* not realizing how huge is the payload to store (i.e. recording the whole index of CMS entries), usually a tiny fraction is what we need for assertion and the rest only contributes to noise
* when tempted to adjust just a single value in such recorded response body, one has to decode and decompress it first, following the reverse procedure on save — not a quick fix to introduce

Solution:

```ruby
VCR.configure do |c|
  c.default_cassette_options = {
    decode_compressed_response: true,
  }
end
```

From now on recorded gzipped responses will be decompressed. 

Caveat: 

> This option should be avoided if the actual decompression of response bodies is part of the functionality of the library or app being tested.

## Not allowing unused mocks

Another default in VCR states that if there are unused interactions recorded on a tape, they will be silently skipped. No error is raised if the tape has a GET request to https://example.net and this request is not actually made. Documentation says:

> The option defaults to true (mostly for backwards compatibility)

I am sure for majority of the projects on VCR this backwards compatibility is not an important argument. I found myself quite puzzled when I was inspecting a tape (of a legacy application) with multiple duplications in recorded yaml. I initially assumed that the code was making all those requests for some bizarre reason. That simply wasn't true.

When I disallowed unused interactions, there was a handful of errors. After removing the duplicates and the obsolete ones the test suite was green again. Pull Request showed following stat:

```
+189 −1,237 
```

Quite a lot of unused YAMLs. To try it yourself, set:

```ruby
VCR.configure do |c|
  c.default_cassette_options = {
    allow_unused_http_interactions: false,
  }
end
```

## Disabling VCR where not explicitly needed

Finally I wanted to make some [well-placed and precise assertions with webmock](https://blog.arkency.com/testing-responses-from-http-apis-with-cursor-based-pagination-and-webmock/) on HTTP interactions for new functionality. 

Recording full snapshots is fine, as long as your test data stays stable. I noticed that some tests had intentionally very limited matching scope to avoid trouble of matching pre-recorded body with always-changing test data:

```ruby
 describe "something", vcr: { cassette_name: "all_of_something", match_requests_on: %i[method host path] } do
   # …
 end
```

That can be addressed for example with webmock and composing rspec matchers. The problem was that VCR already [hijacked all interactions](https://github.com/vcr/vcr/issues/291#issuecomment-17123570) and disallowed webmock to take it over.

The solution was to only enable VCR when the cassette was inserted (via rspec metadata). Or rather to disable VCR when there was no cassette:

```ruby
RSpec.configure do |config|
  config.around do |example|
    if example.metadata[:vcr]
      example.run
    else
      VCR.turned_off { example.run }
    end
  end
end
```

That worked beautifully. 

The caveat is you have to explicitly enable VCR when not using `vcr:` in test metadata:

```rubv
specify do
  begin
    VCR.turn_on!
    VCR.use_cassette("the_caveat") do
      …
    end
  ensure
    VCR.turn_off!
  end
end
```

Not a big deal. If I used this, I'd probably extract the whole block as the `with_cassette` helper method:

```ruby
def with_cassette(name)
  VCR.turn_on!
  VCR.use_cassette(name) do
    …
  end
ensure
  VCR.turn_off!
end
```


## Complete tweak

All above tweaks finally led me to following snippet of configuration:

```ruby
VCR.configure do |c|
  c.hook_into :webmock
  c.default_cassette_options = {
    decode_compressed_response:     true,
    allow_unused_http_interactions: false,
  }
end

RSpec.configure do |config|
  config.around do |example|
    if example.metadata[:vcr]
      example.run
    else
      VCR.turned_off { example.run }
    end
  end
end
```

I hope you found some of these useful. Catch me up on [twitter](https://twitter.com/pawelpacana) and let me know what you think about it.
