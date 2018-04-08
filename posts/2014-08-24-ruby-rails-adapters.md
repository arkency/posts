---
title: "Adapters 101"
created_at: 2014-08-24 09:50:10 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter: :skip
newsletter_inside: :fearless_refactoring_course
tags: [ 'ruby', 'rails', 'adapters' ]
---

<p>
  <figure>
    <img src="<%= src_fit("rails-ruby-adapter/raspberry.jpg") %>" width="100%">
  </figure>
</p>

Sometimes people get confused as to **what is the roles of adapters, how to use them,
how to test them and how to configure** them. Misunderstanging often comes from lack
of examples so let's see some of them.

<!-- more -->

Our example will be about sending apple push notifications (APNS). Let's say in our
system we are sending push notifications with text (alert) only
(no sound, no badge, etc). Very simple and basic usecase. One more thing that we
obviously need as well is device token. Let's **have a simple interface for sending
push notifications**.

```ruby
def notify(device_token, text)
end
```

That's the interface that every one of our adapters will have to follow. So let's
write our first implementation using the `apns` gem.

```ruby
module ApnsAdapters
  class Sync
    def notify(device_token, text)
      APNS.send_notification(device_token, text)
    end
  end
end
```

Wow, that was simple, wasn't it? Ok, what did we achieve?

* We've protected ourselves from the dependency on `apns` gem. We are still using it
  but **no part of our code is calling it directly. We are free to change it later**
  (which we will do)
* We've **isolated our interface from the implementation** as **Clean Code** architecture
  teaches us. Of course in Ruby we don't have interfaces so it is kind-of _virtual_
  but we can make it a bit more explicit, which I will show you how, later.
* We designed **API that we like and which is suitable for our app**. Gems and 3rd party
  services often offer your a lot of features which you might not be even using.
  So here we explicitly state that we only use `device_token` and `text`. If it ever
  comes to dropping the old library or migrating to new solution, you are coverd.
  It's simpler process when the cooperation can be easily seen in one place
  (adapter). Evaluating and estimating such task is faster when you know exactly
  what features you are using and what not.

## Adapters in real life

<a href="<%= src_fit("rails-ruby-adapter/ac_power_ruby.jpg") %>" rel="lightbox[adapters]"><%= img_thumbnail("rails-ruby-adapter/ac_power_ruby.jpg") %></a>
<a href="<%= src_fit("rails-ruby-adapter/camera.jpg") %>"        rel="lightbox[adapters]"><%= img_thumbnail("rails-ruby-adapter/camera.jpg") %></a>
<a href="<%= src_fit("rails-ruby-adapter/sim.jpg") %>"           rel="lightbox[adapters]"><%= img_thumbnail("rails-ruby-adapter/sim.jpg") %></a>
<a href="<%= src_fit("rails-ruby-adapter/speaker.jpg") %>"       rel="lightbox[adapters]"><%= img_thumbnail("rails-ruby-adapter/speaker.jpg") %></a>
<a href="<%= src_fit("rails-ruby-adapter/usb.jpg") %>"           rel="lightbox[adapters]"><%= img_thumbnail("rails-ruby-adapter/usb.jpg") %></a>

As you can imagine looking at the images, the situation is always the same. We've got to parts with
incompatible interfaces and adapter mediating between them.

## Adapters and architecture

![](<%= src_fit("rails-ruby-adapter/uml_rails_ruby_adapter.png") %>)

Part of your app (probably a service) that we call _client_
is relying on some kind of interface for its proper behavior.
Of course **ruby does not have explicit interfaces so what I mean is a
compatibility in a _duck-typing_ way**. Implicit interface defined by how we
call our methods (what parameters they take and what they return). There is
a component, an already existing one (**_adaptee_**) that can do the job our client wants but
**does not expose the interface that we would like to use**. The **mediator** between
these two is our **_adapter_**.

The interface can be fulfilled by possibily many adapters. They might be wrapping
another API or gem which **we don't want our app to interact directly with**.

## Multiple Adapters

Let's move further with our task.

**We don't wanna be sending any push notifications from our development environment** and
from our test environment. What are our options? I don't like putting code such as
`if Rails.env.test? || Rails.env.production?` into my codebase. It makes testing
as well as playing with the application in development mode harder. **For such usecases new
adapter is handy**.

```ruby
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

Now whenever your [service objects](http://rails-refactoring.com) are taking `apns_adapter` as dependency you can use this one
instead of the real one.

```ruby
describe LikingService do
  subject(:liking)   { described_class.new(apns_adapter) }
  let(:apns_adapter) { ApnsAdapters::Fake.new }

  before { apns_adapter.clear }
  specify "delivers push notifications to friends" do
    liking.painting_liked_by(user_id, painting_id)

    expect(apns_adapter.delivered).to include(
     [user_device_token, "Your friend 'Robert' liked 'The Kiss' "]
    )
  end
end
```

I like this more then using doubles and expectations because of its **simplicity**.
But using mocking techniques here would be apropriate as well. In that case
however I would recommend using [Verifying doubles](https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles)
from Rspec or to go with [bogus](https://github.com/psyho/bogus). I recommend watching great video about
possible problems that mocks and doubles introduce from the author of bogus and
solutions for them. [Integration tests are bogus](https://www.youtube.com/watch?v=7XI3H_rKmRU).

## Injecting and configuring adapters

Ok, so we have two adapters, **how do we provide them to those who need these adapters to work?**
Well, I'm gonna show you an example and not talk much about it because it's going to be a topic
of another blogpos.

```ruby
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

## One more implementation

Sending push notification takes some time (just like sending email or communicating with
any remote service) so quickly we decided to do it asynchronously.

```ruby

module ApnsAdapters
  class Async
    def notify(device_token, text)
      Resque.enqueue(ApnsJob, device_token, text)
    end
  end
end
```

And the `ApnsJob` is going to use our sync adapter.

```ruby
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

Did you notice that HoneyBadger is not hidden behind adapter? Bad code, bad code... ;)

What do we have now?

## The result

We separated our interface from the implementations. Of course our interface is
not defined (again, Ruby) but we can describe it later using tests. App with the
interface it dependend is one component. Every implementation can be a separate
component.

![](<%= src_fit("rails-ruby-adapter/apns_ruby_adapter.png") %>)

Our goal here was to get closer to
[Clean Architecture](http://blog.8thlight.com/uncle-bob/2012/08/13/the-clean-architecture.html) .
**Use Cases (_Interactors, Service Objects_) are no longer bothered with implementation details. Instead they relay
on the interface and accept any implementation that is consistent with it.**

![](<%= src_fit("rails-ruby-adapter/CleanArchitecture.jpg") %>)

The part of application which responsibility is to put everything in motion is called
**_Main_** by Uncle Bob. **We put all the puzzles together by using Injectors and
Rails configuration**. They define how to construct the working objects.

## Changing underlying gem

In reality I no longer use `apns` gem because of its global configuration. I
prefer `grocer` because I can more easily and safely use it to send push
notifications to 2 separate mobile apps or even same iOS app but built with
either production or development APNS certificate.

So let's say that our project evolved and now **we need to be able to send push
notifications to 2 separate mobile apps**. First we can **refactor the interface** of
our adapter to:

```ruby
def notify(device_token, text, app_name)
end
```

Then we can change the implementation of our `Sync` adapter to use `grocer` gem
instead (we need some tweeks to the other implementations as well).
In simplest version it can be:

```ruby
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

```ruby
require 'singleton'

class GrocerFactory
  include Singleton

  def pusher_for(app)
    Thread.current[:pushers] ||= {}
    pusher = Thread.current[:pushers][app] ||= create_pusher(app)
    yield pusher
  rescue
    Thread.current[:pushers][app] = nil
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

```ruby
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

## Adapters configuration

I already showed you one way of configuring the adapter by using `Rails.config`.

```ruby
YourApp::Application.configure do
  config.apns_adapter = ApnsAdapters::Async.new
end
```

The downside of that is that **the instance of adapter is global**. Which means you might
need to take care of it being thread-safe (if you use threads). And you must
take great care of its state. So calling it multiple times between requests is
ok. The alternative is to use proc as factory for creating instances of your adapter.

```ruby

YourApp::Application.configure do
  config.apns_adapter = proc { ApnsAdapters::Async.new }
end
```

If your adapter itself needs some dependencies consider using factories or injectors
for fully building it. From my experience adapters usually can be constructed quite
simply. And they are building blocks for other, more complicated structures like
service objects.

## Testing adapters

I like to verify the interface of my adapters using shared examples in rspec.

```ruby
shared_examples_for :apns_adapter do
  specify "#notify" do
    expect(adapter.method(:notify).arity).to eq(2)
  end

  # another way without even constructing instance
  specify "#notify" do
    expect(described_class.instance_method(:notify).arity).to eq(2)
  end
end
```

Of course this will only give you very basic protection.

```ruby

describe ApnsAdapter::Sync do
  it_behaves_like :apns_adapter
end

describe ApnsAdapter::Async do
  it_behaves_like :apns_adapter
end

describe ApnsAdapter::Fake do
  it_behaves_like :apns_adapter
end
```

Another way of testing is to **consider one implementation as leading and
correct** (in terms of interface, not in terms of behavior) and another
implementation as something that must stay identical.

```ruby
describe ApnsAdapters::Async do
  subject(:async_adapter) { described_class.new }

  specify "can easily substitute" do
    example = ApnsAdapters::Sync
    example.public_instance_methods.each do |method_name|
      method = example.instance_method(method_name)
      copy   = subject.public_method(method_name)

      expect(copy).to be_present
      expect([-1, method.arity]).to include(copy.arity)
    end
  end
end
```

This gives you some very basic protection as well.

**For the rest of the test you must write something specific to the adapter implementation**.
Adapters doing http request can either stub http communication
with [webmock](https://github.com/bblimke/webmock)
or [vcr](https://github.com/vcr/vcr). Alternatively, you can just use mocks and expectations to check,
whether the gem that you use for communication is being use correctly. However,
if the logic is not complicated the test are quickly becoming _typo test_,
so they might even not be worth writing.

Test specific for one adapter:

```ruby
describe ApnsAdapter::Async do
  it_behaves_like :apns_adapter

  specify "schedules" do
    described_class.new.notify("device", "about something")
    ApnsJob.should have_queued("device", "about something")
  end

  specify "job forwards to sync" do
    expect(ApnsAdapters::Sync).to receive(:new).and_return(apns = double(:apns))
    expect(apns).to receive(:notify).with("device", "about something")
    ApnsJob.perform("device", "about something")
  end
end
```

In many cases I don't think you should test `Fake` adapter because this is what we use for
testing. And testing the code intended for testing might be too much.

## Dealing with exceptions

Because we don't want our app to be bothered with adapter implementation
(our clients don't care about anything except for the interface) **our
adapters need to throw the same exceptions**. Because what exceptions are raised
is part of the interface. This example does not suite us well to discuss it
here because we use our adapters in _fire and forget_ mode. So we will have
to switch for a moment to something else.

Imagine that we are using some kind of geolocation service which based on
user provided address (not a specific format, just String from one text input)
can tell us the longitude and latitude coordinates of the location. We are in
the middle of switching to another provided which seems to provide better data
for the places that our customers talk about. Or is simply cheaper. So we have
two adapters. Both of them communicate via HTTP with APIs exposed by our
providers. But both of them use separate gems for that. As you can easily imagine
when anything goes wrong, **gems are throwing their own custom exceptions. We need
to catch them and throw exceptions which our clients/services except to catch**.

```ruby
require 'hypothetical_gooogle_geolocation_gem'
require 'new_cheaper_more_accurate_provider_gem'

module GeolocationAdapters
  ProblemOccured = Class.new(StandardError)

  class Google
    def geocode(address_line)
      HypotheticalGoogleGeolocationGem.new.find_by_address(address_line)
    rescue HypotheticalGoogleGeolocationGem::QuotaExceeded
      raise ProblemOccured
    end
  end

  class NewCheaperMoreAccurateProvider
    def geocode(address_line)
      NewCheaperMoreAccurateProviderGem.geocoding(address_line)
    rescue NewCheaperMoreAccurateProviderGem::ServiceUnavailable
      raise ProblemOccured
    end
  end
end
```

**This is something people often overlook which in many cases leads to
leaky abstraction**. Your services should only be concerned with exceptions
defined by the interface.

```ruby
class UpdatePartyLocationService
  def call(party_id, address)
    party = party_db.find_by_id(party_id)
    party.coordinates = geolocation_adapter.geocode(address)
    db.save(party)
  rescue GeolocationAdapters::ProblemOccured
    scheduler.schedule(UpdatePartyLocationService, :call, party_id, address, 5.minutes.from_now)
  end
end
```

Although some developers experiment with exposing exceptions that should be caught
as part of the interface (via methods), I don't like this approach:

```ruby
require 'hypothetical_gooogle_geolocation_gem'
require 'new_cheaper_more_accurate_provider_gem'

module GeolocationAdapters
  ProblemOccured = Class.new(StandardError)

  class Google
    def geocode(address_line)
      HypotheticalGoogleGeolocationGem.new.find_by_address(address_line)
    end

    def problem_occured
      HypotheticalGoogleGeolocationGem::QuotaExceeded
    end
  end

  class NewCheaperMoreAccurateProvider
    def geocode(address_line)
      NewCheaperMoreAccurateProviderGem.geocoding(address_line)
    end

    def problem_occured
      NewCheaperMoreAccurateProviderGem::ServiceUnavailable
    end
  end
end
```

And the service

```ruby
class UpdatePartyLocationService
  def call(party_id, address)
    party = party_db.find_by_id(party_id)
    party.coordinates = geolocation_adapter.geocode(address)
    db.save(party)
  rescue geolocation_adapter.problem_occured
    scheduler.schedule(UpdatePartyLocationService, :call, party_id, address, 5.minutes.from_now)
  end
end
```

But as I said I don't like this approach. The problem is that **if you want to
communicate something domain specific via the exception you can't relay on 3rd
party exceptions**. If it was adapter responsibility to provide in exception
information whether service should retry later or give up, then you need custom
exception to communicate it.

## Adapters ain't easy

There are few problems with adapters. **Their interface tends to be
lowest common denominator between features supported by implementations**.
That was the reason which sparkled big discussion about queue interface for
Rails which at that time was removed from it. If one technology limits you so
you schedule background job only with JSON compatibile attributes you are
limited to just that. If another technology let's you use Hashes with every
Ruby primitive and yet another would even allow you to pass whatever ruby object
you wish then the interface is still whatever JSON allows you to do. No only
you won't be able to easily pass instance of your custom class as paramter for
scheduled job. You won't even be able to use `Date` class because there is no
such type in JSON. Lowest Common Denominator...

**You won't easily extract Async adapter if you care about the result**. I think that's
obvious. You can't easily substitute adapter which can return result with such
that cannot. **Async is architectural decision here**. And rest of the code must be
written in a way that reflects it. Thus expecting to get the result somehow later.

Getting the **right level of abstraction for adapter might not be easy**. When you cover
api or a gem, it's not that hard. But once you start doing things like
`NotificationAdapter` which will let you send notification to user without bothering
the client whether it is a push for iOS, Android, Email or SMS, you might find yourself in
trouble. The closer the adapter is to the domain of adaptee, the easier it is to
write it. The closer it is to the domain of the client, of your app, the harder it
is, the more it will know about your usecases. And the more complicated and
unique for the app, such adapter will be. You will often stop for a moment to **reflect
whether given functionality is the responsibility of the client, adapter or maybe
yet another object**.

## Summary

Adapters are puzzles that we put between our domain and existing solutions such
as gems, libraries, APIs. Use them wisely to decouple core of your app from 3rd party code
for whatever reason you have. **Speed, Readability, Testability, Isolation,
Interchangeability**.

![](<%= src_fit("rails-ruby-adapter/adapter_client_adaptee.png") %>)

<%= show_product_inline(item[:newsletter_inside]) %>

##### Images with CC license

* https://www.flickr.com/photos/elwillo/5210663993
* https://www.flickr.com/photos/uscpsc/14640846183
* https://www.flickr.com/photos/smaedli/3581980712
* https://www.flickr.com/photos/groovenite/4738347028
* https://www.flickr.com/photos/mightyohm/2979795890
