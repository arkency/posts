---
created_at: 2021-04-21T21:06:51.119Z
author: Paweł Pacana
tags: ['rails', 'rack', '5days5blogposts']
publish: true
---

# Rack apps mounted in Rails — how to protect access to them?

Sidekiq, Flipper, RailsEventStore — what do these Rails gems have in common? They all ship web apps with UI to enhance their usefulness in the application. Getting an overview of processed jobs, managing visibility of feature toggles, browsing events, their correlations and streams — nothing you could not do in code or Rails console already. But never really wanted to do there 😉

In Rails apps we add those UI apps with `mount` in routing:

```ruby
# config/routes.rb

Rails.application.routes.draw do
  mount Sidekiq::Web, at: "/sidekiq"
end
```

In production application you'll want to protect access to this Sidekiq dashboard. Let's assume this Rails application is API-only. There's no Devise nor any other authentication library of your choice there. Fair scenario to rely on HTTP Basic Auth, as illustrated with wonderfully commented example from Sidekiq [wiki](https://github.com/mperham/sidekiq/wiki/Monitoring#rails-http-basic-auth-from-routes):

```ruby
# config/routes.rb

Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end

  mount Sidekiq::Web, at: "/sidekiq"
end	
```

Let's transform this example a bit to not rely on `Sidekiq::Web.use`. That's very convenient to provide such interface from a library. I want to show you something else here — `Sidekiq::Web` is a [Rack](https://github.com/rack/rack/blob/master/SPEC.rdoc) application and can be treated as such.

```ruby
# config/routes.rb

Rails.application.routes.draw do
  mount Rack::Builder.new do
    use Rack::Auth::Basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV.fetch("DEV_UI_USERNAME"))) &
       ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV.fetch("DEV_UI_PASSWORD")))
    end
    run Sidekiq::Web
  end, at: "/sidekiq"
end
```

Little explanation:
* Rack::Builder is a DSL to create new Rack application
* Rack applications can wrap each other, like layers
* when the request comes in, a chain of Rack apps is executed from outermost to innermost
* when the response is to be returned, it goes from innermost Rack app to outermost

Right. Wasn't it supposed to be about protecting access? 

Imagine now that aforementioned Rails application includes all those UIs for Sidekiq, Flipper, RailsEventStore at the same time. How can we have common protection for them without boring copying and pasting same wrapper again and again?

Let's extract (bad word detected) a factory!

```ruby
# config/routes.rb

Rails.application.routes.draw do
  with_dev_auth =
    lambda do |app|
      Rack::Builder.new do
        use Rack::Auth::Basic do |username, password|
          ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV.fetch("DEV_UI_USERNAME"))) &
            ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV.fetch("DEV_UI_PASSWORD")))
        end
        run app
      end
    end

  mount with_dev_auth.call(Sidekiq::Web), at: "sidekiq"
end
```

Fun fact is that a `Proc#[]` is an [equivalent](https://ruby-doc.org/core-3.0.0/Proc.html#method-i-3D-3D-3D) to `Proc#call`.
The last line can be as well written as:

```ruby
  mount with_dev_auth[Sidekiq::Web], at: "sidekiq"
```

And with all those UIs in place we receive:

```ruby
  mount with_dev_auth[Sidekiq::Web],             at: "/sidekiq"
  mount with_dev_auth[RailsEventStore::Browser], at: "/res"
  mount with_dev_auth[Flipper::UI.app(Flipper)], at: "/flipper"
```

In the future we could swap Basic Auth to one or another authentication mechanism. The `with_dev_auth` factory would remain useful and probably survive them all.

