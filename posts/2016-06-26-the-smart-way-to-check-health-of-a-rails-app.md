---
title: "The smart way to check health of a Rails app"
created_at: 2016-02-26 17:05:19 +0100
kind: article
publish: false
author: Szymon Fiedler
tags: [ 'rails', 'health check', 'ops' ]
newsletter: :arkency_form
---
<p>
    <figure>
        <img src="<%= src_fit('smart-way-to-check-health-of-a-rails-app/header.jpg') %>" width="100%">
    </figure>
</p>

Recently we added monitoring to one of our customer’s application. The app was tiny, but with a huge responsibility. We simply wanted to know if it’s alive. We went with [Sensu](https://sensuapp.org) HTTP check since it was a no-brainer. And it just worked, however, we got warning from monitoring tool.

<!-- more -->

## This is not the HTTP code you are looking for
Authentication is required to access any of given app resources. It simply does redirect to login page. `302` code is returned instead of expected one from  `2xx` family.

<p>
    <figure>
        <img src="<%= src_fit('smart-way-to-check-health-of-a-rails-app/sensu_warning.png') %>" width="100%">
    </figure>
</p>

That's not what satisfies us.

## What to do about that?
We've found out that the best solution would be having a **dedicated endpoint** in the app. This endpoint **should be cheap for app server** to respond. It **shouldn't require any authentication nor unexpected redirection**. It should only return `204 No Content`. Monitoring checks will be green and everyone will be happy.
<p>
    <figure>
        <img src="<%= src_fit('smart-way-to-check-health-of-a-rails-app/sensu_ok.png') %>" width="100%">
    </figure>
</p>

## Implementation
We decided to implement `/health` in our app. Nonetheless, we agreed that it's a really good practice to do such checks in all of our apps and we released a tiny gem for that. Just to easily reuse this approach. The gem is named [wet-healt_endpoint](https://github.com/wetrb/wet-health_endpoint). Btw. We had to prefix *health_endpoint* with something since all simple names are already taken in the _Rubygems_ world.

The gem consists of Middleware which is being attached close to the response in the app's request-response cycle. It checks if application responds to such route, it not it responds to the client with `204 No Content`.
We used such approach not to override already existing endpoints in an app. Just in case, someone is developing app related to _health_.

```
#!ruby
module Wet
  module HealthEndpoint
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        status, headers, body = @app.call(env)
        return [204, {}, ['']] if status == 404 &&
          env.fetch('PATH_INFO') == '/health'
        [status, headers, body]
      ensure
        body.close if body && body.respond_to?(:close) && $!
      end
    end
  end
end
```

That's how it's attached to the app:

```
#!ruby
require 'wet/health_endpoint/middleware'

module Wet
  module HealthEndpoint
    class Railtie < Rails::Railtie
      initializer 'health_endpoint.routes' do |app|
        app.middleware.use Middleware
      end
    end
  end
end
```

To use it, you simply need to add

```
#!bash
gem 'wet-health_endpoint'
```

to your Gemfile and run `bundle install`.

## How to check if it works

You can simply run a _curl_ command

```
#!bash
$ curl -I http://example.com/health
HTTP/1.1 204 No Content
Cache-Control: no-cache
X-Request-Id: 89d3c0c8-0b5c-421b-83a1-757dd04fef30
X-Runtime: 0.000578
Connection: close
```

or even better, write a test:

```
#!ruby
require 'test_helper'

class ApplicationHasHealthMonitoringEnabled < ActionDispatch::IntegrationTest

  def test_health_returns_204
    get "/health"
    assert_response(204)
  end
end
```


## You can do even more!

Reverse proxies like [Haproxy](https://cbonte.github.io/haproxy-dconv/configuration-1.5.html#option%20httpchk) or [Elastic Load Balancer](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/elb-healthchecks.html) understand if app instance is down and don't route traffic to such ones.

Please see the sample _Haproxy_ configuration:

```
#!bash
backend my_fancy_app
  option httpcheck get /health
  http-check expect status 204
  default-server inter 3s fall 3 rise 2
  server srv1 10.0.0.1:80 check
  server srv2 10.0.0.2:80 check
```

Ok, so we order _Haproxy_ to make a `GET` request to `/health` endpoint. We consider everything is ok if `204` code is returned. The action is performed every 3 seconds. After 3 sequential failures, an instance is marked as failed and no traffic is being sent there. After 2 successful checks instance is considered healthy. Last two lines specify which instances should be checked.

## A sum up
It's better to know that the app is down from your monitoring tool than from angry customer's call. ;)
