---
title: 3 tips to tune your VCR in tests
created_at: 2021-02-13T09:19:01.230Z
author: Paweł Pacana
tags: ['ruby', 'testing']
publish: false
---

In this post I describe 3 things that have grown my trust in VCR. These are: 

* decompressing stored responses
* not allowing unused mocks
* disabling VCR where not explicitly needed

Read on to see why I've specifically picked them.

# What is VCR from a bird's eye view

* what problems it solves well
* what problems it is masking

# Decompressing stored responses

* no idea what is the data we make assertions on
* not realizing how huge is the payload when storing all your un-paginatend products from catalog as a reponse to GET on index

# Not allowing unused mocks

* seeing the mocks for the first time and wondering what really happens in the test

# Disabling VCR where not explicitly needed

* conflicting with webmock-style expectations
* developers dodging the bullet by limiting matching scope too much in VCR

# Complete tweak

* all of the above leading to this

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

