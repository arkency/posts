---
title: "Image Placeholder for your development environment"
created_at: 2018-11-13 19:09:29 +0100
kind: article
publish: true
author: Szymon Fiedler
tags: [ 'rails', 'rack', 'middleware' ]
newsletter: :arkency_form
---

Some time ago I was working together with [Paweł](https://twitter.com/pawelpacana) on one of our clients web application. We used copy of products catalog coming from production server on our development machines. What we were lacking were product photos, causing application layout to look poorly and making any css job hard. We tried to find a smart solution for that case.

<!-- more -->

Every time you request non-existing image in your app, you got a 404. What if we could detect such case and modify response to actually contain image and return 200 OK? Custom rack middleware is a perfect place for that. The code is pretty simple:

```ruby
require 'net/http'

module ImagePlaceholder
  class Middleware
    def initialize(app, image_extensions: %w(jpg png), size_pattern: {/.*/ => 100}, host: 'via.placeholder.com')
      @app = app
      @image_extensions = image_extensions
      @size_pattern = size_pattern
      @host = host
    end

    def call(env)
      status, headers, response = @app.call(env)
      request_path = URI.decode(Rack::Request.new(env).fullpath)

      if not_found?(status) && image?(request_path)
        serve_placeholder_image(matched_size(request_path))
      else
        [status, headers, response]
      end
    end

    private

    def serve_placeholder_image(size = 100)
      net_response  = Net::HTTP.get_response(URI("https://#{@host}/#{size}"))
      rack_response = Rack::Response.new(net_response.body, net_response.code.to_i)
      safe_headers  = net_response.to_hash
                        .reject { |key, _| hop_by_hop_header_fields.include?(key.downcase) }
                        .reject { |key, _| key.downcase == 'content-length' }

      safe_headers.each do |key, values|
        values.each do |value|
          rack_response.add_header(key, value)
        end
      end
      rack_response.finish
    end

    def hop_by_hop_header_fields
      # https://tools.ietf.org/html/draft-ietf-httpbis-p1-messaging-14#section-7.1.3.1
      %w(connection keep-alive proxy-authenticate proxy-authorization te trailer transfer-encoding upgrade)
    end

    def not_found?(status)
      status == 404
    end

    def image?(path)
      @image_extensions.include? File.extname(path)[1, 3]
    end

    def matched_size(path)
      @size_pattern.find { |pattern, _| pattern.match(path) }[1]
    end
  end
end
```

1. Check whether image is requested
2. Check if status is 404
3. If yes, make a get request to a service like [placeholder.com](placeholder.com) and modify response with image from it
4. Otherwise, just return standard response

Our initial version used [Fill Murray](https://fillmurray.com) which brought us smile every time we launched products catalog to do some work on.

<img src="<%= src_fit('fill_murray.png') %>" width="100%" />

You can go with [Steven Seagal eating a carrot](https://www.stevensegallery.com) or [Nicolas Cage](https://www.placecage.com) if you would like to. Just add `host` option to middleware use:

```ruby
# config/environments/development.rb

Rails.application.configure do
  config.middleware.use ImagePlaceholder::Middleware, host: 'fillmurray.com'
end
```

You can also match desired image sizes, providing pattern:

```ruby
# config/environments/development.rb

Rails.application.configure do
  config.middleware.use ImagePlaceholder::Middleware, size_pattern: {
    %r{/uploads/.*/s_[0-9]+\.[a-z]{3}$}  => 200,  # /uploads/product/cover/42/s_9781467775687.jpg
    %r{/uploads/.*/xl_[0-9]+\.[a-z]{3}$} => 750,  # /uploads/product/cover/42/xl_9781467775687.jpg
    %r{.*} => 1024,                               # /uploads/random/spanish_inquisition.png
  }
end
```

By default, `ImagePlaceholde::Middleware` supports `.jpg` and `.png` images, but you can extend supported filetypes with ease:

```ruby
# config/environments/development.rb

Rails.application.configure do
  config.middleware.use ImagePlaceholder::Middleware, image_extensions: %w(jpg jpeg png webp gif)
end
```

And last, but not least, it can be used with any Rack application:

```ruby
# config.ru
use ImagePlaceholder::Middleware, size_pattern: { /.*/ => '320/320' }, host: 'fillmurray.com'
run YourRackApp
```

To start using it, put `gem image_placeholder` into your `Gemfile`. If you would like to contribute or read more, visit [https://github.com/arkency/image_placeholder](https://github.com/arkency/image_placeholder)

Enjoy!

