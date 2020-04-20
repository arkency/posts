---
title: "Services - what are they and why we need them?"
created_at: 2013-09-26 01:12:28 +0200
publish: true
author: Marcin Grzywaczewski
newsletter: fearless_refactoring_1
tags: [ 'rails', 'oop', 'design' ]
---

Model-View-Controller is a design pattern which absolutely dominated web frameworks.
On the first look it provides a great and logical separation between our application components. When we apply some basic principles (like 'fat models, slim controllers') to our application, we can live happily very long with this basic fragmentation.

However, when our application grows, our skinny controllers become not so skinny over time. We can't test in isolation, because we're highly coupled with the framework. To fix this problem, we can use service objects as a new layer in our design.

<!-- more -->

## Entry point

I bet many readers had some experience with languages like C++ or Java. This languages have a lot in common, yet are completely different. But one thing is similar in them - they have well defined entry point in every application. In C++ it's a `main()` function. The example `main` function in C++ application looks like this:

```cpp
#include <iostream>
// Many includes...

int main(int argc, char *argv[]) {
  // Fetch your data.
  // Ex. Input data = Input.readFromUser(argc, argv);

  Application app = Application(data);
  app.start();

  // Cleanup logic...
  return 0;
}
```

If you run your application (let it be ./foo), `main` function is called and all arguments after it (`./foo a b c`) are passed in argv as strings. Simple.

When C++ application grows, nobody sane puts logic within `main`. This function only initializes long-living objects and runs a method like `start` in above example.

But why we should be concerned about C++ when we're Rails developers?

## Controller actions are entry points

As title states, Rails has multiple entry points. **Every controller action in Rails is the entry point!** Additionaly, it handles a lot of responsibilities (parsing user input, routing logic [like redirects], logging, rendering... ouch!).

We can think about actions as separate application within our framework - each one with its private `main`. As I stated before, nobody sane puts logic in `main`. And how it applies to our controller, which in addition to it's responsibilities takes part in computing response for a client?

## Introducing service objects

That's where service objects comes to play. Service objects **encapsulates single process of our business**. They take all collaborators (database, logging, external adapters like Facebook, user parameters) and performs a given process. Services belongs to our domain - **They shouldn't know they're within Rails or webapp!**

We get a lot of benefits when we introduce services, including:

* **Ability to test controllers** - controller becomes a really thin wrapper which provides collaborators to services - thus we can only check if certain methods within controller are called when certain action occurs,

* **Ability to test business process in isolation** - when we separate process from it's environment, we can easily stub all collaborators and only check if certain steps are performed within our service.

* **Lesser coupling between our application and a framework** - in an ideal world, with service objects we can achieve an absolutely technology-independent domain world with very small Rails part which only supplies entry points, routing and all 'middleware'. In this case we can even copy our application code without Rails and put it into, for example, desktop application.

* **They make controllers slim** - even in bigger applications actions using service objects usually don't take more than 10 LoC.

* **It's a solid border between domain and the framework** - without services our framework works directly on domain objects to produce desired result to clients. When we introduce this new layer we obtain a very solid border between Rails and domain - controllers see only services and should only interact with domain using them.

## Example

Let's see a basic example of refactoring controller without service to one which uses it. Imagine we're working on app where users can order trips to interesting places. Every user can book a trip, but of course number of tickets is limited and some travel agencies have it's special conditions.

Consider this action, which can be part of our system:

```ruby

class TripReservationsController < ApplicationController
  def create
    reservation = TripReservation.new(params[:trip_reservation])
    trip = Trip.find_by_id(reservation.trip_id)
    agency = trip.agency

    payment_adapter = PaymentAdapter.new(buyer: current_user)

    unless current_user.can_book_from?(agency)
      redirect_to trip_reservations_page, notice: TripReservationNotice.new(:agency_rejection)
    end

    unless trip.has_free_tickets?
      redirect_to trip_reservations_page, notice: TripReservationNotice.new(:tickets_sold)
    end

    begin
      receipt = payment_adapter.pay(trip.price)
      reservation.receipt_id = receipt.uuid

      unless reservation.save
        logger.info "Failed to save reservation: #{reservation.errors.inspect}"
        redirect_to trip_reservations_page, notice: TripReservationNotice.new(:save_failed)
      end

      redirect_to trip_reservations_page(reservation), notice: :reservation_booked
    rescue PaymentError
      logger.info "User #{current_user.name} failed to pay for a trip #{trip.name}: #{$!.message}"
      redirect_to trip_reservations_page, notice: TripReservationNotice.new(:payment_failed, reason: $!.message)
    end
  end
end
```

Although we packed our logic into models (like agency, trip), we still have a lot of corner cases - and our have explicit knowledge about them. This action is big - we can split it to separate methods, but still we share too much domain knowledge with this controller. We can fix it by introducing a new service:

```ruby

class TripReservationService
  class TripPaymentError < StandardError; end
  class ReservationError < StandardError; end
  class NoTicketError < StandardError; end
  class AgencyRejectionError < StandardError; end

  attr_reader :payment_adapter, :logger

  def initialize(payment_adapter, logger)
    @payment_adapter = payment_adapter
    @logger = logger
  end

  def process(user, trip, agency, reservation)
    raise AgencyRejectionError.new unless user.can_book_from?(agency)
    raise NoTicketError.new unless trip.has_free_tickets?

    begin
      receipt = payment_adapter.pay(trip.price)
      reservation.receipt_id = receipt.uuid

      unless reservation.save
        logger.info "Failed to save reservation: #{reservation.errors.inspect}"
        raise ReservationError.new
      end
    rescue PaymentError
      logger.info "User #{user.name} failed to pay for a trip #{trip.name}: #{$!.message}"
      raise TripPaymentError.new $!.message
    end
  end
end
```

As you can see, there is a pure business process extracted from a controller - without routing logic.

Our controller now looks like this:

```ruby

class TripReservationsController < ApplicationController
  def create
    user = current_user
    trip = Trip.find_by_id(reservation.trip_id)
    agency = trip.agency
    reservation = TripReservation.new(params[:trip_reservation])

    begin
      trip_reservation_service.process(user, trip, agency, reservation)
    rescue TripReservationService::TripPaymentError
      redirect_to trip_reservations_page, notice: TripReservationNotice.new(:payment_failed, reason: $!.message)
    rescue TripReservationService::ReservationError
      redirect_to trip_reservations_page, notice: TripReservationNotice.new(:save_failed)
    rescue TripReservationService::NoTicketError
      redirect_to trip_reservations_page, notice: TripReservationNotice.new(:tickets_sold)
    rescue TripReservationService::AgencyRejectionError
      redirect_to trip_reservations_page, notice: TripReservationNotice.new(:agency_rejection)
    end

    redirect_to trip_reservations_page(reservation), notice: :reservation_booked
  end

  private
  def trip_reservation_service
    TripReservationService.new(PaymentAdapter(buyer: current_user), logger)
  end
end
```

It's much more concise. Also, all the knowledge about process are gone from it - now it's only aware which situations can occur, but not when it may occur.

## A word about testing

You can easily test your service using a simple unit testing, mocking your PaymentAdapter and Logger. Also, when testing controller you can stub `trip_reservation_service` method to easily test it. That's a huge improvement - in a previous version you would've been used a tool like Capybara or Selenium - both are very slow and makes tests very implicit - it's a 1:1 user experience after all!

## Conclusion

Services in Rails can greatly improve our overall design as our application grow. We used this pattern  combined with service-based architecture and repository objects in [Chillout.io](http://chillout.io/) to improve maintainability even more. Our payment controllers heavy uses services to handle each situation - like payment renewal, initial payments etc. Results are excellent and we can be (and we are!) proud of Chillout's codebase. Also, we use Dependor and AOP to simplify and decouple our services even more. But that's a topic for another post.

What are your patterns to increase maintainability of your Rails applications? Do you stick with your framework, or try to escape from it? I wait for your comments!
