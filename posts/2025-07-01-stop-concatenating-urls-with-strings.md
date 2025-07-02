---
created_at: 2025-07-01 16:10:21 +0200
author: Szymon Fiedler
tags: []
publish: false
---

# Stop concatenating URLs with strings — Use proper tools instead

How many times have you seen code like this in a Ruby application?

```ruby
base_url = "https://api.example.com"
endpoint = "/users"
user_id = params[:id]
  
full_url = "#{base_url}#{endpoint}/#{user_id}
```

At first glance, it looks harmless, but it hides several traps that can lead to hard–to–debug errors.

<!-- more -->

## Problems with Naive URL Concatenation
### 1. Double or missing slashes

```ruby
base_url = "https://api.example.com/" # has trailing hash
endpoint = "/users" # has leading hash
  
url = "#{base_url}{#endpoint}"
# => "https://api.example.com//users"
```

Double slash is likely not desired. While most servers will handle it, this looks unprofessional.

```ruby
base_url = "https://api.example.com" # no trailing hash
endpoint = "users" # no leading hash
  
url = "#{base_url}{#endpoint}"
# => "https://api.example.comusers"
```

TLD concatenated with `path` is not a thing we’re looking for.

### 2. Improper parameter escaping

```ruby
query = "hello world"
url = "https://api.example.com/search?q=#{query}"
# => "https://api.example.com/search?q=hello world"
# space is not properly encoded
```

### 3. Protocol and port issues

```ruby
host = "localhost:3000"
path = "/api/v1/users"

url = "https://#{host}#{path}"
```

What if host already contains protocol?

## Solutions
### 1. Ruby’s URI

Ruby has a built–in [URI](https://docs.ruby-lang.org/en/master/URI.html) class that solves most of these problems:

```ruby
require "uri"

base = URI("https://api.example.com")
base.path = "/users"
base.query = URI.encode_www_form(q: "hello world", limit: 10)

puts base.to_s
# => "https://api.example.com/users?q=hello+world&limit=10"
```

Let’s join some paths:

```ruby
base_url = URI("https://api.example.com/api/v1/")
URI.join(base_url, "users", "123")
# => #<URI::HTTPS https://api.example.com/api/v1/users/123>
```

#### More advanced URI example

```ruby
class ApiClient
  def initialize(base_url)
    @base_url = URI(base_url)
  end
  
  def build_url(path, query_params = {})
    uri = @base_uri.dup
    uri.path = File.join(uri.path, path)
    uri.query = URI.encode_www_form(query_params) unless query_params.empty?
    uri.to_s
  end
end

client = ApiClient.new("https://api.example.com/v1")
client.build_url("users/123", { include: "profile", format: "json" })
# => https://api.example.com/v1/users/123?include=profile&format=json
```

### 2. Pathname for local paths

If you’re working with file paths or local URLs, `Pathname` can be helpful:

```ruby
require "pathname"

base_bath = Pathname.new("/var/www/uploads")
user_folder = "user_123"
filename = "avatar.jpg"

full_path = base_path.join(user_folder, filename)
# => #<Pathname:/var/www/uploads/user_123/avatar.jpg>

URI("file://#{full_path}")
# => #<URI::File file:///var/www/uploads/user_123/avatar.jpg>
```

### 3. Addresable gem

For more advanced use cases, consider the [addressable](https://github.com/sporkmonger/addressable) gem:

```ruby
require "addressable/uri"

uri = Addressable::URI.new(
  scheme: "https",
  host: "api.example.com",
  path: "users/123",
  query_values: {
    includes: ["profile", "posts"],
    format: "json"
  }
)

puts uri.to_s
# => "https://api.example.com/users/123?include[]=profile&include[]=posts&format=json"
```

### 4. Rails URL helpers

In Rails applications, use built–in helpers instead of string concatenation whenever possible:

```ruby
# Instead of:
base_url = "https://myapp.com"
url = "#{base_url}/users/#{user.id}/posts/#{post.id}"

# Use this
url = user_post_url(user, post, host: "https://myapp.com")

# Or this
url = api_v1_user_url(user, host: request.base_url)
```

### 5. Test URL building 

You might think that having test can catch these URL building issues and you would be partially right. However, many developers stub their HTTP client methods directly:

```ruby
allow(http_client).to receieve(:get).and_return(mock_response)
```

This test won’t catch URL formatting issues.

When you stub the HTTP client method itself, malformed ULRs slip through because stub intercepts the call regardless of what URL was passed. A better approach is using [WebMock](https://github.com/bblimke/webmock), which sets expectations on the actual URLs being requested:

```ruby
stub_request(:get, "https://api.example.com/users/123")
  .to_return(status: 200, body: response_json)
```

1. WebMock will fail if the URL is malformed
2. This will catch URL building errors:

* double slashes
* missing slashes
* unescaped parameters

WebMock forces you to be explicit about the exact URLs your code should generated, making URL building bugs much more visible during test runs.

## Summary

Concatenating URLs with strings is a recipe for trouble. Instead:

1. Use `URI` for basic URL building scenarios
2. Leverage `Pathname` for local file paths
3. Consider `addressable` for advanced use cases
4. Utilize Rails URL helpers in Rails applications
5. Always escape parameters using `URI.encode_www_form`
6. Test your external http calls 

Your code will be more reliable, easier to maintain and less prone to URL formatting errors.
