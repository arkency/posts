---
title: "Rails and SOA: Do I really need to have this big app?"
created_at: 2013-12-26 14:15:56 +0100
kind: article
publish: true
author: Marcin Grzywaczewski
tags: [ 'architecture', 'rails', 'service', 'multiapp', 'soa' ]
newsletter: :arkency_form
---

Developing complex web applications (not particularly Rails apps) is a tricky
task. You write your models, controllers, services and optimize application
architecture iteratively. But even with the great architecture when your application starts to be huge, bad things happen. Every little feature you'll add will cost you precious time - tests must pass on your CI and workers needs to be reloaded every time you deploy. In addition, you begin to realize that mental overhead with keeping modules separated is huge - you have to remember a lot of things to keep it in right fashion. Ultimately, working on a project is hard, TDD technique is inefficient to use and you're not happy at all with your code.

Have something gone wrong? No. You just didn't notice that you need more
applications than just one.

<!-- more -->

## What is Service Oriented Architecture?

Complex applications tend to create whole ecosystems inside of them - we can
think of such applications as of galaxies. Inside these galaxies we have stars - our services and adapters. 
They should be separated, but they're still in the one galaxy which 
is our big application. What glues these stars together is
their purpose - they're created by us to solve certain problems.

Service Oriented Architecture takes different approach. We can put the same
stars into different galaxies and add an explicit communication between them. This way we create a solid boundaries between our services and make our solution simpler to maintain - working on a small Rails application is easy, right?

## Why it's good?

The most attractive thing about this kind of architecture is an ease of working with smaller applications - you have a small subset of tests and external libraries. Your mini-application has a narrow scope, business domain is singular (as opposed to your previous approach, where you had payments and business logic inside a single app - maybe separated, but still inside one app) and you don't need to have such sophisticated architecture inside - when you choose Rails to implement it, you can even be fine with your ActiveRecord and tight coupling with a framework.

What is more, when it comes to replication of your app, you have much more control about which part and how much you want to replicate it. You can distribute your API within some kind of CDN or cloud, keeping your data processing app centralized. Small application is not as heavy as your previous monolithic application - you can spawn more workers with the same resources you had before.

As a developer, you would certainly appreciate that with this approach you're absolutely technology agnostic. With this approach you can create your API app in Rails with a traditional RDBMS like PostgreSQL and payments processing application in Haskell with MongoDB as a persistence layer. It's your choice and service oriented architecture allows you to have such flexibility.

When you change something in one part of your system, you don't have to reload all subcomponents - deploys are separated from each other and you have zero downtime with API when you only update a data processing app. That makes your system more reliable and clients happier. When something goes wrong and one subsystem hangs, you can defer message passing to it and go on - before you had single point of failure, now your system is much more durable.

You can define or choose protocols you choose, not just HTTP - you can tailor your message passing to suit your needs. You can provide reliable or unreliable communication, use different data formats - it's your choice. When it comes to optimalisation, it's a huge improvement compared to monolithic Rails app, which is adjusted to work with a HTTP protocol and simple, stateless request-response cycle. In chillout, our application which gathers metrics about creation of a certain models within your Rails app, we use ZMQ sockets for internal communication thorough our system and only use HTTP to get requests from our clients. That allowed us to be flexible about reliability of our transmission. We certainly want to be sure when someone pays us, but we don't need to be exactly sure that 1 of 100 gathered metric won't be delivered.

When it comes to coupling, there is less possibilities to couple independent components of your system - in fact, you can't be more explicit about saying "Hey, now we're dealing with a completely different domain"!

Of course, there is no perfect solution - and SOA have its flaws.

## Nothing is perfect (SOA too)

Unfortunately, with this approach you have to provide code for internal communication between subsystems. Often it would imply that your total codebase (sum of codebase of all subcomponents of your system) will be bigger. To overcome this issue I recommend to put this communication code as an external library, shared between your components.

Another issue is that every application which wants to communicate with a certain subsystem needs to know a message format - thus, knows something about a domain of the receiving app. This can be fixed, but with a cost - you can provide a "mediator" app, which is reponsible for translating a message from a sender domain to (possibly multiple) recievers domain format. It's nothing new, though - you made it before when you introduced an adapter to your application. This issue induced a nice discussion inside Arkency team, and it's the only solution we've found so far. It's good, but not as good - we have to provide more code to do so. I would recommend creating a simple adapter first - when you feel it's not enough, you can easily extract it as a new application.

If you're ready to pay this price, SOA is a viable architecture to work with your system. And the best part is that...

## It's not all or nothing

Very good thing about SOA is that it's not all-or-nothing - we can iteratively
transform the code from a certain point to the stand-alone mini-application. 
In fact, when we transform our business logic into services it's quite simple.
Let's define steps of this extraction, and I'll provide a simple example.

1. (If you have not done it before) Create a service object from a given business process inside your app. [My previous post](http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/) can be helpful with this.
2. Choose a service OR adapter which you want to be a separate app. 
Copy the code (with dependencies) to a separate directory. Copy external dependencies (gems) used and include it into your brand-new app.
3. Create the code which processes requests. We can use Rails for it. 
In my example, I'll use [webmachine](https://github.com/seancribbs/webmachine-ruby) for simplicity.
4. If an action needs to send back some kind of message, introduce the code which creates it.
5. Inside your old application, change your controller action's code to the new code which makes communication with your new application.
6. Remove external dependencies which were exclusive to your service from your complex application. Remove copied code from complex application's codebase. Move unit service tests (if any) to your new application.

### Step one:

Let's introduce our example. We have a simple service object which processes
payment creation requests - it communicates with an external service to delegate
the payment processing and handles response from this service. 

It's important to see it's a boundary context of our application - it's not tightly related with what our application does and it's business rules - it's only providing an additional (but needed) feature. These kind services are the most viable choice for extraction, because we can easily build an abstraction around it (more about this later).

The `callback` object here is usually a controller in a Rails application.
If you're unfamiliar with this kind of handling outcoming messages from service within Rails controller, here's an example how the code may look inside the controller:

    #!ruby
    def action
      service = PaymentCreationService.new(PaymentsDB.new, PaymentsProviderAdapter.new, PaymentsMailer.new, self)
      service.call(params[:payment])
    end

    def payment_successful(uuid)
      # code processing successful payment request
    end

    def payment_data_invalid(reason)
      # code processing invalid data within request
    end

    def payment_unknown_error(payment_request)
      # code processing unknown error
    end

Here's how our code might look like:

    #!ruby
    class PaymentCreationService
      def initialize(payments_db, payments_provider_adapter, payments_mailer, callback)
        @payments_db = payments_db
        @payments_provider_adapter = payments_provided_adapter
        @payments_mailer = payments_mailer
        @callback = callback
      end

      def call(payment_request)
        payment = payments_provider_adapter.request(payment_request)

        if payment.accepted?
          payments_db.store(payment.uuid, payment_request)
          payments_mailer.send_confirmation_of(payment_request)
          callback.payment_successful(payment.uuid)
        end

        if payment.data_invalid?
          callback.payment_data_invalid(payment.reason)
        end

        if payment.unknown_error?
          callback.payment_unknown_error(payment)
        end
      end

      private
      attr_reader :payments_db, 
                  :payments_provider_adapter,
                  :payments_mailer, 
                  :callback
    end

We put this file (with it's dependencies, but without a callback object - it's not a dependency!) to the separate directory.

### Step two:

Here we create the code which processes our requests. It's a lie it's only for a request
processing - in our example it's also setting up a HTTP server - but it's all about a protocol. We use HTTP, so we need a HTTP server for this. We can use many
technologies - like raw sockets, ZMQ and such.

You can really skip this code if you don't want to learn about webmachine internals. 
In short it creates HTTP server which processes `/payments` POST calls and binds 
methods read and render appropiate JSON to it. Since webmachine is really small
compared to Rails, we have to create resources (we can think about it as 
controllers) by ourselves.

    #!ruby
    require 'webmachine'
    require 'multi_json'

    require 'payment_creation_service'
    require 'payments_db'
    require 'payments_provider_adapter'
    require 'payments_mailer'

    class ResourceCreator
      def ecall(route, request, response)
        resource = route.resource.new(request, response)
        service = PaymentsCreationService.new(PaymentsDB.new, 
                                              PaymentsProviderAdapter.new, 
                                              PaymentsMailer.new,
                                              resource)
        resource.payments_creation_service = service
        resource
      end
    end

    class PaymentResource < Webmachine::Resource
      attr_accessor :payments_creation_service,
                    :rendered_data

      def allowed_methods
        %w(POST)
      end

      def content_types_accepted
        [['application/vnd.your-app.v1+json', :accept_resource]]
      end

      def content_types_provided
        [['application/vnd.your-app.v1+json', :render_resource]]
      end

      def accept_resource
        body = MultiJson.load(request.body.to_s)

        payments_creation_service.call(body)
      end

      def payment_unknown_error(payment)
        self.rendered_data = MultiJson.dump(message: "UNKNOWN_ERROR",
                                            inspect: payment.inspect)
      end

      def payment_data_invalid(reason)
        self.rendered_data = MultiJson.dump(message: "DATA_INVALID",
                                            reason: reason)
      end

      def payment_successful(id)
        self.rendered_data = MultiJson.dump(message: "SUCCESS",
                                            uuid: id)
      end

      def render_resource
        self.rendered_data
      end
    end

    @webmachine = Webmachine::Application.new do |app|
                    app.routes do
                      add ['payments'], PaymentResource
                    end

                    app.configure do |config|
                      config.adapter = :Rack
                      config.ip      = '127.0.0.1'
                      config.port    = 5555
                      config.adapter = :Webrick
                    end

                    app.dispatcher.resource_creator = ResourceCreator.new
                  end                

    @webmachine.run

### Step three:

We did it already. The `#render_resource`, `#payment_data_invalid`, 
`#payment_unknown_error` and `#payment_successful` methods is the response creation code. 

All it does is providing an interface for a service and creating a JSON response 
based on callback service calls. When it gets bigger, I recommend putting 
response creation code into a separate object.

### Step four:

Now we have to change our old controllers code. It can now look like this, using [Faraday](https://github.com/lostisland/faraday) library:

    #!ruby
    def action
      response = Faraday.post("http://127.0.0.1:5555/payments", params[:payment_request])
      # response handling code
    end

This ends our tricky parts of extraction. Step five is dependent on your application and it's fairly easy. 
Now we have the tiny bit of our complex application as a separate application instead. We can run our new application and check out if everything works fine.

## More abstraction

Remember that I mentioned this is a great candidate for extraction due it's a 
boundary context? You always have this kind of context in your application - for
example, controllers are managing boundary context of Rails applications, like logging
or rendering responses. 

Coming back to our cosmic metaphor - after our step we have a brand-new created galaxy which contains exactly one star. It's not quite efficient to leave a one-star galaxy - we just added some code and separated one particular action away from our old, 
big galaxy. But added code/profit ratio is poor for now. Your next step should 
be finding stars which share similar dependencies and nature of actions, like 
`PaymentNotificationService` and transfer this kind of stars to your new galaxy.

## How SOA works in Arkency?

We have used an service-oriented approach in our product called [Chillout](http://chillout.io/). It's a relatively simple app which is gathering metrics about model creations within clients' Rails applications. We are sending a mail report each day/week/month, containing changes and charts which shows trends of model creations.

During development, 6 applications were created:

* **api** - responsible for receiving data from clients. It takes HTTP requests, and communicates with brain part using ZMQ sockets.
* **brain** - responsible for aggregating data and making it persistent.
* **reporter** - responsible for creating reports from a given interval (day, month, year) from the data aggregated by brain.
* **mailer** - responsible for generating and sending mails from reports generated by reporter.
* **dashboard** - provides a front-end for our clients - they can manage their payments and add new projects to track within this application.
* **artisan** - it's responsibility is to generate a chart from a given interval, using aggregated data.

These application have narrow scopes and totally separate domains. With this kind of logical separation, we can distribute our system whatever we want. In future we can, for example, provide more brains without a hassle.

## Further read

I would greatly recommend a video by Fred George about [micro-services](http://www.youtube.com/watch?v=2rKEveL55TY). It's a great example how SOA can improve thinking and development of your systems.

Also, Clean Architecture is a great start to organize monolithic app to create a SOA from it in the future. You can read more about it [here](http://blog.8thlight.com/uncle-bob/2012/08/13/the-clean-architecture.html).

## Conclusion

Software oriented architecture can be a great alternative for maintaining a big,
complex singular application. When we were developing chillout we had lots of fun
with this kind of architecture - features adding were simple, tests were quick
and thinking about an application was simpler.

What do you think about this kind of architecture? Have you tried it before?
I really looking forward for your opinions.


