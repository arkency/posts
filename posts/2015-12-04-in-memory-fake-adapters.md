---
title: "In-Memory Fake Adapters"
created_at: 2015-12-04 12:30:32 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'adapters', 'in-memory', 'rails' ]
newsletter: skip
newsletter_inside: clean
img: "fake-in-memory-adapters/gorilla-thinking-about-in-memory-adapters.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("fake-in-memory-adapters/gorilla-thinking-about-in-memory-adapters.jpg") %>" width="100%" />
  </figure>
</p>

There are two common techniques for specifying in a test the behavior of a 3rd party system:

* stubbing of an adapter/gem methods.
* stubbing the HTTP requests triggered by those adapters/gems.

I would like to present you a third option — **In-Memory Fake Adapters** and show an example of one.

<!-- more -->

## Why use them?

I find _In-Memory Fake Adapters_ to be well suited into telling a full story. You can use them to describe actions
that might only be available on a 3rd party system via UI. But such actions often configure the system that
we cooperate with to be in a certain state. State that we depend on. State that we would like to be present in
a test case — showing how our System Under Test interacts with the 3rd party external system.

Let's take as an example an integration with seats.io that I am working with recently. They provide us with
many features:

* building a venue map including sections, rows, and seats
* labeling the seats
* general admission areas with unnumbered (but limited in amount) seats
* a seat picker for customers to select a place
* real-time updates for selected seats during the sale process
* atomic booking of selected seats when they are available

So as a service provider they do a lot for us that we don't need to do ourselves.

On the other hand, a lot of those things are UI/Networking related. And it does not affect the core business logic
which is pretty simple: 

* _Don't let two people to buy the same seat_
* _Don't let customers to buy too many standing places, in a General Admission area_.

In other words: _Don't oversell_. That's their job. To help us not oversell. Which is pretty important.

To have that feature working we need to communicate with them via API and they need to do their job.

Let's see a simple exemplary test.

```ruby
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

When seats.io returns with HTTP 400, the adapter raises `SeatsIo::Error`. The tested service knows that
the customer can't book those seats. It's OK code for a single class test.

But I don't find this approach useful when
writing more story-driven acceptance tests. Because this test does not say a story why the booking could not
be finished. Is that because seats.io was configured via UI so that _Sector 1_ has only 2 places? Was it because
it has 20 standing places, but more than 17 were already sold so there is not enough left for 3 people?

```ruby
seats_adapter.add_event(event_key: "concert")
seats_adapter.add_general_admission(event_key: "concert", section_name: "Sector 1", quantity: 2)

organizer.import_season_pass(
  name: "John Doe",  
  pass_type: :standing,
  section_name: "Sector 1"
)
organizer.import_season_pass(
  name: "Mark Twain",
  pass_type: :standing,
  section_name: "Sector 1"
)

expect do
  customer.buy_ticket(ticket_type: :standing, section_name: "Sector 1")
end.to raise_error(BookingService::NotAllowed)
```

Now, this tells a bigger story. We know what was configured in seats.io using their GUI. When season
passes are imported by the organizer, they took all the standing places in _Sector 1_. If a customer
tries to buy a ticket there, it won't be possible, because there is no more space available.

### No need to stub every call

When using In-Memory Fake Adapters you don't need to stub every call to the adapter (on method or HTTP level)
separately. This is especially useful if the [Unit that you tests is bigger than one class](http://blog.arkency.com/2014/09/unit-tests-vs-class-tests/).
And when it communicates with the adapter in multiple places. To properly test a scenario that invokes multiple API
calls it might be easier for you to plug in a fake adapter. Let the tests interact with it.

## Example

Here is an example of a fake adapter for our _seats.io_ integration. There are 3 categories of methods:

* Real adapter interface implemented: `book_entrance`. These can be called from the [services](http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/) that use
our real Adapter in production and fake adapter in tests.
* UI fakers: `add_event`, `add_general_admission`, `add_seat`. They can only be called from a test setup.
They show how the 3rd party API was configured using the web UI, without using the API. We use them to build the
internal state of the fake adapter which represents the state of the 3rd party system.
* Test Helpers: `clean`. Useful for example to reset the state. Not always needed.

```ruby

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
    @events[event_key].add_general_admission(
      section_name: section_name, 
      quantity: quantity
    )
  end

  def add_seat(event_key:, label:)
    @events[event_key].add_seat(label: label)
  end

  # Real API

  def book_entrance(event_key:, seats: [], places: [])
    @events[event_key].book_entrance(
      seats: seats,
      places: places
    )
  end
end
```

Seats.io has a lot of useful features for us. Despite it, the in-memory implementation of their
core booking logic is pretty simple. For seats we mark them as booked: `@seats[seat] = :booked`. For general admission
areas we lower their capacity: `@places[place_name] -= quantity`. That's it.

In-memory adapters are often used as a step of building [_a walking skeleton_](http://alistair.cockburn.us/Walking+skeleton).
Where your system does not integrate yet with a real 3rd party dependency. It integrates with something that pretends
to be the dependency.

## How to keep the fake adapter and the real one in sync?

Use the same test scenarios. Stub HTTP API responses (based on what you observed while playing with the API)
for the sake of real adapter. The fake one doesn't care. An oversimplified example below.

```ruby

RSpec.shared_examples "TweeterAdapters" do |twitter_db_class|
  specify do
    twitter = twitter_db_class.new("@pankowecki")

    stub_request(
      :post,
      'https://api.twitter.com/1.1/statuses/update.json?status=Hello%20world',
      body: '{status: "status"}'
    ).to_return(
      status: 200, body: "[{text:"Hello world"}]"
    )
    twitter.tweet("Hello world")
    
    stub_request(
      :get, 
      'https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=pankowecki&count=1'
    ).to_return(
      status: 200, body: '[{text:"Hello world"}]'
    )
    expect(twitter.last_tweet).to include?("Hello world")
  end
end


RSpec.describe FakeTwitterAdapter do
  include_examples "TweeterAdapters", FakeTwitterAdapter
end

RSpec.describe RealTwitterAdapter do
  include_examples "TweeterAdapters", RealTwitterAdapter
end
```

You know how to stub the HTTP queries because you played the sequence
and watched the results. So hopefully, you are stubbing with the truth.

What if the external service changes their API in a breaking way? Well,
that's [more of a case for monitoring](/2015/11/monitoring-services-and-adapters-in-your-rails-app-with-honeybadger-newrelic-and-number-prepend/)
than testing in my opinion.

The effect is that you can stub the responses only on real adapter tests.
In all other places rely on the fact that
fake client has the same behavior. Interact with it directly in services
or acceptance tests.

## When to use Fake Adapters?

The more your API calls and business logic depend on previous API calls and the state of the external system.
So we don't want to just check that we called a 3rd party API. But that a whole sequence of calls made sense
together and led to the desired state and result in both systems.

There are many cases in which implementing Fake adapter would not be valuable
and beneficial in your project. Stubbing/Mocking (on whatever level) might be
the right way to go. But this is a useful technique to remember when your needs
are different and you can benefit from it.

## Worth watching

If your state and business logic don't depend at all on those API calls then you
can go with Dummy. What's Dummy? You can find out more about different kinds of
these objects by watching [Episode 23 of Clean Code by Uncle Bob](https://cleancoders.com/episode/clean-code-episode-23-p1/show).

<img src="<%= src_fit("fake-in-memory-adapters/fakes-mock-objects-uncle-bob-ontology.jpg") %>" width="100%">

## Stay tuned

This blog-post was inspired by [Fearless Refactoring](http://rails-refactoring.com/). A book in which we
show you useful techniques for handling larger Rails codebases.

If you liked reading this you can subscribe to our newsletter below and keep getting more
useful tips.

<%= show_product_inline(item[:newsletter_inside]) %>

