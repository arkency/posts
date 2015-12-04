---
title: "In-Memory Fake Adapters"
created_at: 2015-12-04 12:30:32 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
---

There are two common techniques for specifying in a test the behavior of a 3rd party system that we
integrate with:

* stubbing of an adapter/gem methods.
* stubbing the HTTP requests triggered by those adapters/gems.

I would like to present you a third option — **In-Memory Fake Adapters** and show an example of one.

<!-- more -->

## Why use them?

I find _In-Memory Fake Adapters_ to be well suited into telling a full story. You can use them to describe actions
that might only be available on a 3rd party system via UI. But such actions often configure the system that
we cooperate with to be in a certain state, state that we depend on. State that we would like to present in
a test case showing how our System Under Test interacts with the 3rd party external system.

Let's take as an example an integration with seats.io that I am working with recently. They provide us with
multiple features:

* building a venue map including sections, rows and seats
* labeling the seats
* general admission areas with unnumbered (but limited in amount) seats
* a seat picker for customers to select a place
* realtime updates for selected seats during purchase process
* atomic booking of selected seats when they are available

So as a service provider they do a lot for us that we don't need to do ourselves.

On the other hand a lot of those things are UI/Networking related and it does not affect the core business logic
which is pretty simply: _Don't let 2 people to buy the same seat, and buy too many standing places in General Admission
area_. In other words: _Don't oversell_. That's their job. To help us not oversell. Which is pretty important.

To have that feature working we need to communicate with them via API and they need to their job.

Let's see a simple exemplary test.

```
#!ruby
booking = BookingService.new(seats_adapter)
expect(seats_adapter).to receive(:book_entrance).with(
  event_key: "concert",
  places: [{
    section_name: "Sector 1",
    quantity: 3
}]).and_raise(SeatsIo::Error)

expect do
  booking.book_standing_place(section_name: "Sector 1", quantity: 3)
end.to raise_error(BookingService::NotAllowed)
```

When seats.io returns with HTTP 400 and the adapter raises `SeatsIo::Error` then the tested service knows that
the customer can't book those seats. It's ok code for a single class test.

But I don't find this approach useful when
writing more story-driven acceptance tests. Because this test does not say a story why the booking could not
be finished. Is that because seats.io was configured via UI so that _Sector 1_ has only 2 places? Was it because
it has 20 standing places but more than 17 were already sold so there is not enough left for 3 people?

```
#!ruby
seats_adapter.add_event(event_key: "concert")
seats_adapter.add_general_admission(event_key: "concert", section_name: "Sector 1", quantity: 2)

organizer.import_season_pass(name: "John Doe",  pass_type: :standing, section_name: "Sector 1")
organizer.import_season_pass(name: "Mark Twain", pass_type: :standing, section_name: "Sector 1")

expect do
  customer.buy_ticket(ticket_type: :standing, section_name: "Sector 1")
end.to raise_error(BookingService::NotAllowed)
```

Now, this tells a bigger story. We know what was configured in seats.io using the GUI. We can see that when season
passes are imported by the organizer then those guest took all the standing places in _Sector 1_ so if a customer
tries to buy a ticket there, it won't be possible because there is no more space available.

### No need to stub every call

When using In-Memory Fake Adapters you don't need to stub every call to the adapter (on method or HTTP level)
separately. This is especially useful if the [Unit that you tests is bigger than one class](http://blog.arkency.com/2014/09/unit-tests-vs-class-tests/)
and it communicates with the adapter in multiple places. To properly test a scenario that invokes multiple API
calls it might be easier for you to plug in a fake adapter and let the tests interact with it.

## Example

Here is an example of a fake adapter for our _seats.io_ integration . There are 3 categories of methods:

* Real adapter interface implemented: `book_entrance`. These can be called from the [services](http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/) that use
our real Adapter in production and fake adapter in tests.
* UI fakers: `add_event`, `add_general_admission`, `add_seat`. They can only be called from a test setup.
They show how the 3rd party API was configured using the web UI, without using the API. We use them to build the
internal state of the fake adapter which represents the state of the 3rd party system.
* Test Helpers: `clean`. Useful for example to reset the state. Not always needed.

```
#!ruby

module SeatsIo
  Error = Class.new(StandardError)
end

class FakeClient
  class FakeEvent
    def initialize
      @seats  = {}
      @places = {}
    end

    def book_entrance(seats: [], places: [])
      verify(seats, places)
      update(seats, places)
    end

    def add_seat(label:)
      @seats[label] = :released
    end

    def add_general_admission(section_name:, quantity:)
      @places[section_name] = quantity
    end

    private

    def update(seats, places)
      seats.each do |seat|
        @seats[seat] = :booked
      end

      places.each do |place|
        place_name = place.fetch(:section_name)
        quantity   = place.fetch(:quantity)
        @places[place_name] -= quantity
      end
    end

    def verify(seats, places)
      seats.all? do |seat|
        @seats[seat] == :released
      end or raise SeatsIo::Error

      places.all? do |place|
        place_name = place.fetch(:section_name)
        quantity   = place.fetch(:quantity)
        @places[place_name] >= quantity
      end or raise SeatsIo::Error
    end
  end

  def initialize()
    clear
  end

  # Test helpers

  def clear
    @events = {}
  end

  # UI Fakes

  def add_event(event_key:)
    raise "Event already exists" if @events[event_key]
    @events[event_key] = FakeEvent.new
  end

  def add_general_admission(event_key:, section_name:, quantity:)
    @events[event_key].add_general_admission(section_name: section_name, quantity: quantity)
  end

  def add_seat(event_key:, label:)
    @events[event_key].add_seat(label: label)
  end

  # Real API

  def book_entrance(event_key:, seats: [], places: [])
    @events[event_key].book_entrance(seats: seats, places: places)
  end
end
```

You can see that despite the fact that seats.io has a lot of useful feature the in-memory implementation of their
core booking logic is pretty simple. For seats we mark them as booked `@seats[seat] = :booked` and for general admission
areas we lower their capacity `@places[place_name] -= quantity`. That's it.

In-memory adapters are often used as a step in the process of building [_a walking skeleton_](http://alistair.cockburn.us/Walking+skeleton).
Where your system don't integrate yet with a real 3rd party dependency but with something that pretends to be it.

# TODO: ...

## How to keep fake client and real one in sync?

Through the same scenarios but you stub HTTP API responses in real test (based on what you observed while playing with the API), but not in the fake adapter test.

## When to use them?

* The more the state of external API depends on your calls
* The more your API calls and business logic depend on previous API calls. So don't want to just check that we called a 3rd party API.
But that the whole sequence of calls made sense together and led to a desired state.

## Notes

Better when multiple calls.

You can stub the responses only on real adapter tests and in all other places rely on the fact that fake client
has the same implementation

Sometimes the API is simple, and every call is detached and the backend is very complicated.
Sometimes the core logic of 3rd party service is simple but there are multiple API calls.

If your state and business logic don't depend at all on those API calls then you can go with Dummy.

<img src="/assets/images/fake-in-memory-adapters/fakes-mock-objects-uncle-bob-ontology-fit.jpg" width="100%">

Recommend uncle bob video: CleanCode-E23-P1-1080p

