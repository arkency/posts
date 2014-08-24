---
title: "ruby rails adapters"
created_at: 2014-08-24 09:50:10 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
---

Sometimes people get confused as to what is the roles of adapters, how to use them,
how to test them and how to configure them. Misunderstanging often comes from lack
of examples so let's see some of them.

<!-- more -->

Our example will be about sending apple push notifications (APNS). Let's say in our
system we are sending push notifications with text (alert) only
(no sound, no badge, etc). Very simple and basic usecase. One more thing that we
obviously need as well is device token. Let's have a simple interface for sending
push notifications.

```
#!ruby
def notify(device_token, text)
end
```

That's the interface that every one of our adapters will have to follow. So let's
write our first implementation using the `apns` gem.

```
#!ruby
module ApnsAdapters
  class Sync
    def notify(device_token, text)
      APNS.send_notification(device_token, 'Hello iPhone!' )
    end
  end
end
```

Wow, that was simple, wasn't it? Ok, what did we achieve?

* We've protected ourselves from the dependency on `apns` gem. We are still using it
  but no part of our code is calling it directly. We are free to change it later
  (which we will do)
* We've isolated our interface from the implementation as Clean Code architecture
  teaches us. Of course in Ruby we don't have interfaces so it is kind-of _virtual_
  but we can make it a bit more explicit, which I will show you how, later.
* We designed API that we like, which is suitable for our app. Gems and 3rd party
  services often offer your a lot of features which you might not be even using.
  So here we explicitly state that we only use device_token and text. If it ever
  comes to dropping the old library or migrating to new solution, you are coverd.
  It's way easier process when the cooperation can be easily seen in one place
  (adapter). Evaluating and estimating such task is faster when you know exactly
  what features you are using and what not.

Let's move further with our task.

We don't wanna by sending any push notifications from our development environment and
from our test environment. What are our options? I don't like putting code such as
`if Rails.env.test? || Rails.env.production?` into my codebase. It makes testing harder
as well as playing with the application in development mode. For such usecases new
adapter is handy.

```
#!ruby
module ApnsAdapters
  class Fake
    attr_reader :delivered

    def initialize
      clear
    end

    def notify(device_token, text)
      @delivered << [device_token, text]
    end

    def clear
      @delivered = []
    end
  end
end
```

Now whenever your services are taking `apns_adapter` as dependency you can use this one
instead of the real one.

```
#!ruby
describe LikingService do
  subject(:liking)   { described_class.new(apns_adapter) }
  let(:apns_adapter) { ApnsAdapters::Fake.new }

  before{ apns_adapter.clear }
  specify "delivers push notifications to friends" do
    liking.painting_liked_by(user_id, painting_id)
    expect(apns_adapter.delivered).to include([user_device_token, "Your friend 'Robert' liked 'The Kiss' "])
  end
end
```

I like this more then using doubles and expectations because of its simplicity.
But using mocking techniques here would be apropriate as well. In that case
however I would recommend using [Verifying doubles](https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles)
from Rspec or to go with [bogus](https://github.com/psyho/bogus). I recommend watching great video about
possible problems that mocks and doubles introduce from the author of bogus and
solutions for them. [Integration tests are bogus](https://www.youtube.com/watch?v=7XI3H_rKmRU).

Ok, so we have two adapters, how do we provide them? Well, I'm gonna show you an example
and not talk much about it because it's going to be a topic of another blogpos.

```
#!ruby
module LikingServiceInjector
  def liking_service
    @liking_service ||= LikingService.new(Rails.config.apns_adapter)
  end
end

class YourController
  include LikingServiceInjector
end

#config/environments/development.rb
config.apns_adapter = ApnsAdapter::Fake.new

#config/environments/test.rb
config.apns_adapter = ApnsAdapter::Fake.new
```

Sending push notification takes some time (just like sending email or communicating with
any remote service) so quickly we decided to do it asynchronously.

```
#!ruby

module ApnsAdapters
  class Async
    def notify(device_token, text)
      Resque.enqueue(ApnsJob, device_token, text)
    end
  end
end
```

And the `ApnsJob` is going to use our sync adapter.

```
#!ruby
class ApnsJob
  def self.perform(device_token, text)
    new(device_token, text).call
  rescue => exc
    HoneyBadger.notify(exc)
    raise
  end

  def initialize(device_token, text)
    @device_token = device_token
    @text = text
  end

  def call
    ApnsAdapter::Sync.new.notify(@device_token, @text)
  end
end
```

## Changing underlying gem

In reality I no longer use `apns` gem because of its global configuration. I
prefer Grocer way more because I can more easily and safely use it to send push
notifications to 2 separate mobile apps or even same iOS app but built with
either production or development APNS certificate.

So let's say that our project evolved and now we need to be able to send push
notifications to 2 separate mobile apps. First we can refactor the interface of
our adapter to:

```
#!ruby
def notify(device_token, text, app_name)
end
```

Then we can change the implementation of our `Sync` adapter to use `grocer` gem
instead. In simplest version it can be:

```
#!ruby
module ApnsAdapters
  class Sync
    def notify(device_token, text, app_name)
      notification = Grocer::Notification.new(
        device_token: device_token,
        alert:        text,
      )
      grocer(app_name).push(notification)
    end

    private

    def grocer(app_name)
      @grocer ||= {}
      @grocer[app_name] ||= begin
        config = APNS_CONFIG[app_name]
        Grocer.pusher(
          certificate: config.fetch('pem']),
          passphrase:  config.fetch('password']),
          gateway:     config.fetch('gateway_host'),
          port:        config.fetch('gateway_port'),
          retries:     2
        )
      end
    end
  end
end
```

However every new grocer instance is using new conncetion to Apple push
notifications service. But, the recommended way is to reuse the connection.
This can be especially usefull if you are using sidekiq. In such case every
thread can have its own connection to apple for every app that you need
to support. This makes sending the notifications very fast.

```
#!ruby
require 'singleton'

class GrocerFactory
  include Singleton

  def pusher_for(app_name)
    Thread.current[:grocer_factory_pushers] ||= {}
    pusher = Thread.current[:grocer_factory_pushers][app_name] ||= create_pusher(app_name)
    yield pusher
  rescue
    Thread.current[:grocer_factory_pushers][app_name] = nil
    raise
  end

  private

  def create_pusher(app_name)
    config = APNS_CONFIG[app_name]
    pusher = Grocer.pusher(
      certificate: config.fetch('pem']),
      passphrase:  config.fetch('password']),
      gateway:     config.fetch('gateway_host'),
      port:        config.fetch('gateway_port'),
      retries:     2
    )
  end
end
```

In this implementation we kill the grocer instance when exception happens (might happen
because of problems with delivery, connection that was unused for a long time, etc).
We also reraise the exception so that higher layer (probably sidekiq or resque) know
that the task failed (and can schedule it again).

And our adapter:

```
#!ruby
module ApnsAdapters
  class Sync
    def notify(device_token, text, app_name)
      notification = Grocer::Notification.new(
        device_token: device_token,
        alert:        text,
      )
      GrocerFactory.instance.pusher_for(app_name) do |pusher|
        pusher.push(notification)
      end
    end
  end
end
```

The process of sharing instances of `grocer` between threads could be
probably simplified with some kind of threadpool library.

