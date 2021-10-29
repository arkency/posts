---
created_at: 2021-10-23 13:19:08 +0200
author: Szymon Fiedler
tags: [ruby, rails, json]
publish: true
---

# A lesser known capability of Ruby's JSON.parse

If you ever got annoyed by the fact that `JSON.parse` returns hash with string keys and prefer hashes with symbols as keys, this post is for you.

<!-- more -->

If you're a Rails developer, you're probably familiar with `deep_symbolize_keys` method in `Hash` which can help with such case. Especially, in ideal world, where our data structure is a hash, like:

```ruby
# if outside of Rails, add the below require statement
#require 'json'

json = <<~JSON
{ 
  foo: {
    bar:
      "baz"
  }
}
JSON

> JSON.parse(json)
=> { "foo" => { "bar" => "baz" } }

> JSON.parse(json).deep_symbolize_keys
=> { foo: { bar: "baz" } } 
```

Maybe it's good enough, but we don't always live in Rails world with all the `ActiveSupport` benefits. Moreover, our JSON payloads won't always be just a hash-like structures. Let's agree on what valid JSON can be, first:

```ruby
> JSON.dump("")
=> "\"\""

> JSON.dump(nil)
=> "null"

> JSON.dump([{ foo: { bar: "baz" } }])
=> "[{\"foo\":{\"bar\":\"baz\"}}]"
```

What we can learn from that is the fact, that the trick with `deep_symoblize_keys` won't work on all the examples above unless you go with some tricky, recursive algorithm checking the type and running `symbolize_keys` or `deep_symbolize_keys` when applicable.

Let's see what Ruby itself can offer us in [JSON class documentation](https://ruby-doc.org/stdlib-3.0.0/libdoc/json/rdoc/JSON.html#module-JSON-label-Output+Options).

```ruby
json = <<~JSON
{ 
  foo: {
    bar:
      "baz"
  }
}
JSON

> JSON.parse(json, symbolize_names: true)
=> { foo: { bar: "baz" } } 
```

Let's check how it rolls on Array with collection of hashes:

```ruby
> JSON.parse("[{\"foo\":{\"bar\":\"baz\"}}]", symbolize_names: true)
=> [{ foo: { bar: "baz" } }]
```

Perfect.

How I discovered this feature? Some time ago I worked on a read model which had some data stored in PostgreSQL json columns. As you probably know, data are serialized and deserialized automatically. Which means, that in result of reading from json column we get data structure with string keys.

```ruby
# before
class FancyModel < ActiveRecord::Base
end

> FancyModel.last.my_json_column
=> [{"foo" => { "bar" => "baz" } }]
```

This was quite inconvenient to me. I wanted a reliable way to have value accessible via symbols, especially that it was an array containing individual hashes. I explored docs a bit, which allowed me to write a custom serializer:
```ruby
class FancyModel < ActiveRecord::Base
  class SymbolizedSerializer
    def self.load(json)
      JSON.parse(json, symbolize_names: true)
    end
    
    def self.dump(data)
      JSON.dump(data)
    end
  end
  
  serialize :my_json_column, SymbolizedSerializer
end

> FancyModel.last.my_json_column
=> [{foo: { bar: "baz" } }]
```

I have a feeling that this is not a popular feature of `JSON` class in Ruby. Please don't mind sharing this post if you find it helpful.
