---
title: Explaining Rack — desugaring Rack::Builder DSL
created_at: 2021-04-22T16:05:59.695Z
author: Paweł Pacana
tags: ['rails', 'ruby', 'rack', '5days5blogposts']
publish: true
---

Yesterday I [wrote a post](https://blog.arkency.com/common-authentication-for-mounted-rack-apps-in-rails/) highlighting Basic Auth and how can we protect Rack applications mounted in Rails with it.
Today when discussing some ideas from this post with my colleague, our focus immediately shifted on `Rack::Builder`.

On one hand Rack interface is simple, fairly constrained and well described in [spec](https://github.com/rack/rack/blob/master/SPEC.rdoc). And ships with a [linter](https://github.com/rack/rack/blob/2c95c7d1eb2f743f64c134bde06c92be24a70717/lib/rack/lint.rb) to help your Rack apps and middleware pass this compliance.

> A Rack application is a Ruby object (not a class) that responds to call. It takes exactly one argument, the environment and returns an Array of exactly three values: [The status](https://github.com/rack/rack/blob/master/SPEC.rdoc#the-status-), [the headers](https://github.com/rack/rack/blob/master/SPEC.rdoc#the-headers-), and [the body](https://github.com/rack/rack/blob/master/SPEC.rdoc#the-body-).

```ruby
class HelloWorld
  def call(env)
    [200, {"Content-Type" => "text/plain"}, ["Hello world!"]]
  end
end
```


On the other hand your first exposure to Rack is usually via `config.ru` in Rails application:

```ruby
# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
```

Behind the scenes, this file [is eventually passed to](https://github.com/rack/rack/blob/2c95c7d1eb2f743f64c134bde06c92be24a70717/lib/rack/server.rb#L344-L350) `Rack::Builder`. It is a convenient DSL to compose Rack application out of other Rack applications. In [yesterday's blogpost](https://blog.arkency.com/common-authentication-for-mounted-rack-apps-in-rails/) we've seen it being used directly:

```ruby
Rack::Builder.new do
    use Rack::Auth::Basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV.fetch("DEV_UI_USERNAME"))) &
       ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV.fetch("DEV_UI_PASSWORD")))
    end
    run Sidekiq::Web
  end
```

Whether you use `Rack::Builder` directly or via [rackup](https://github.com/rack/rack#rackup-) files, you're associating Rack with `use` and `run` DSL. And that triggered an honest question from my colleague — how does this DSL relate to that rather simple Rack interface?

# De-sugaring Rack::Builder DSL

To add even more nuance, some Rack apps are called a _middleware_. What is a middleware? In simple words — it's a Rack application that wraps another Rack application. It may affect the input passed to the wrapped app. Or it may affect the output if it.

An example of a _middleware_ that makes everything sound more dramatic:

```ruby
class Dramatize
  def initialize(app)
    @app = app
  end
	
  def call(env)
    status, headers, body = @app.call(env)
    [status, headers, body.map { |x| "#{x}111one!1" }]
  end
end
```

A composition of such middleware and our previous sample `HelloWorld` application with `config.ru` would look like this:

```ruby
# config.ru

class HelloWorld
  # omitted for brevity
end

class Dramatize
  # omitted for brevity
end

use Dramatize
run HelloWorld.new
```

When executed, it would return very dramatic greeting:

```
$ bundle exec rackup config.ru
* Listening on http://127.0.0.1:9292
* Listening on http://[::1]:9292
Use Ctrl-C to stop

$ curl localhost:9292                                                    
Hello world!111one!1⏎ 
```

Now back to the question that started it all:

> How does this DSL relate to that rather simple Rack interface?

The last example of composition via `Rack::Builder` can be rewritten to avoid some of the DSL:

```ruby
# config.ru

run Dramatize.new(HelloWorld.new)
```

A single `run` is needed to tell a Ruby application server what is our Rack application that we'd like to run. The use of `use` is on the other hand just optional.

If this post got you curious on Rack, a fun way to learn more about it is to check the code of each middleware powering your Rails application:

```
$ bin/rails middleware
use Webpacker::DevServerProxy
use Honeybadger::Rack::UserInformer
use Honeybadger::Rack::UserFeedback
use Honeybadger::Rack::ErrorNotifier
use Rack::Cors
use ActionDispatch::HostAuthorization
use Rack::Sendfile
use ActionDispatch::Static
use ActionDispatch::Executor
use ActiveSupport::Cache::Strategy::LocalCache::Middleware
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use ActionDispatch::RemoteIp
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use ActionDispatch::DebugExceptions
use ActionDispatch::ActionableExceptions
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use ActionDispatch::ContentSecurityPolicy::Middleware
use ActionDispatch::PermissionsPolicy::Middleware
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
use Rack::TempfileReaper
use Warden::Manager
use Rack::Deflater
use RailsEventStore::Middleware
run MyApp::Application.routes
```

Happy learning!
