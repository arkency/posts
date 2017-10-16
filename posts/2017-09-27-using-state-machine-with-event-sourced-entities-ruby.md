---
title: "Using state_machine with event sourced entities"
created_at: 2017-10-15 13:09:06 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ddd', 'state_machine', 'event sourcing' ]
newsletter: :arkency_form
---

Our event sourced aggregates usually have a lifecycle and they need to protect some business rules. Often they start with guard statements checking if performing given action is even allowed. I was wondering if there was a nice way to remove those conditional and make the code more explicit. I wanted to experiment with porting the code from our book to use `state_machine` gem and see if the results are promising.

<!-- more -->

My starting point was a class looking like this:

```ruby
  class Order
    include AggregateRoot
    NotAllowed = Class.new(StandardError)
    Invalid    = Class.new(StandardError)

    def initialize(number:)
      @number         = number
      @state          = :draft
      @items          = []
    end

    def add_item(sku:, quantity:, net_price:, vat_rate:)
      raise NotAllowed unless state == :draft
      raise ArgumentError unless sku.to_s.present?
      raise ArgumentError unless quantity > 0
      raise ArgumentError unless net_price > 0
      raise ArgumentError if vat_rate < 0 || vat_rate >= 100

      # make changes and apply new state
    end

    def submit(customer_id:)
      raise NotAllowed unless state == :draft
      raise Invalid    if items.empty?

      # make changes and apply new state
    end

    def cancel
      raise NotAllowed unless [:draft, :submitted].include?(state)
      apply(OrderCancelled.strict(data: {
        order_number: number}))
    end

    def expire
      return if [:expired, :shipped].include?(state)
      apply(OrderExpired.strict(data: {
        order_number: number}))
    end

    def ship
      raise NotAllowed unless state == :submitted
      apply(OrderShipped.strict(data: {
        order_number: number,
        customer_id: customer_id,
      }))
    end

    private

    attr_reader :number, :state, :items, :fee_calculator, :customer_id

    def apply_strategy
      ->(_me, event) {
        {
          Orders::OrderItemAdded => method(:apply_item_added),
          Orders::OrderSubmitted => method(:apply_submitted),
          Orders::OrderCancelled => method(:apply_cancelled),
          Orders::OrderExpired   => method(:apply_expired),
          Orders::OrderShipped   => method(:apply_shipped),
        }.fetch(event.class).call(event)
      }
    end

    def apply_item_added(ev)
      # ...
    end

    def apply_submitted(ev)
      @state = :submitted
      @customer_id = ev.data[:customer_id]
    end

    def apply_cancelled(ev)
      @state = :cancelled
    end

    def apply_expired(ev)
      @state = :expired
    end

    def apply_shipped(ev)
      @state = :shipped
    end
  end
```

I removed some parts which are not interesting for this discussion.

As you can see, often methods start with some `state` checks.

Sometimes it's one `state` that the `Order` must be in:

```ruby
  def ship
    raise NotAllowed unless state == :submitted
    # ...
  end
```

Sometimes it's two or more:

```ruby
  def cancel
    raise NotAllowed unless [:draft, :submitted].include?(state)
    # ...
  end
```

Sometimes we want idempotency instead of an error:

```ruby
  def expire
    return if [:expired, :shipped].include?(state)
    # ...
  end
```

So when you try to `expire` an already _expired Order_, we will do nothing. This can be in case our app is expiring in a reaction to a message coming from a message queue and we could get duplicated messages.

So I was wondering if using `state_machine` would make the code more readable and expressive. I didn't even need to make the rules exactly the same. I just wanted to get a feeling how it could look like and If I enjoyed it more or less.

One of the things I noticed recently is that the more versions of code I have solving the same problem the better I understand their good and bad sides. I learn what works for me and what not.

So let's see a version using `state_machine`

```ruby
class Order
  include AggregateRoot
  NotAllowed = Class.new(StandardError)
  Invalid    = Class.new(StandardError)

  def initialize(number:)
    @number  = number
    @state   = 'draft'
    @items   = []
  end

  state_machine :state do
    state 'draft' do
      def add_item(sku:, quantity:, net_price:, vat_rate:)
        raise ArgumentError unless sku.to_s.present?
        raise ArgumentError unless quantity > 0
        raise ArgumentError unless net_price > 0
        raise ArgumentError if vat_rate < 0 || vat_rate >= 100

        # ...
      end

      def submit(customer_id:)
        raise Invalid if items.empty?

        # ...
      end
    end

    state 'submitted' do
      def ship
        apply(OrderShipped.strict(data: {
          order_number: number,
          customer_id: customer_id,
        }))
      end
    end

    state 'expired' do
      def expire; end
    end

    state 'cancelled' do
      def cancel; end
    end

    state all - %w(expired shipped) do
      def expire
        apply(OrderExpired.strict(data: {
          order_number: number
        }))
      end
    end

    state *%w(draft submitted) do
      def cancel
        apply(OrderCancelled.strict(data: {
          order_number: number
        }))
      end
    end
  end
```

It is interesting. If a method can be called in one state only you can define it inside that state definition:

```ruby
  state 'submitted' do
    def ship
      # ...
    end
  end
```

If you try to call it in another state, you will get `NoMethodError`. On the other hand, the exception won't be as good as our custom exception which clearly shows line number. It's easier to have a look at that line of code and understand that a method was called in an invalid state compared to understanding a `NoMethodError` without any meaningful info.

It is possible to define a method in 2 states only:

```ruby
  state *%w(draft submitted) do
    def cancel
      # ...
    end
  end
```

But the benefits are not so big in my opinion. You don't see this method around other methods available for `draft` or `submitted` states and this meta-programming statement is not much better than my custom `if` statement.

I also experimented with:

```ruby
  state all - %w(expired shipped) do
    def expire
      # ...
    end
  end
```

but that was the worst. Computers can understand that but for humans like me, it's unbearable. I can't easily recall all possible states in and remove `expired` and `shipped` from them, to understand where could that method be allowed or not.

Notice that I used only a very small subset of the gem's features. That's on purpose.

I looked into [event transitions](https://github.com/pluginaweek/state_machine#explicit-vs-implicit-event-transitions) and transition callbacks but I could not find a nice way for them to play with the expectation that the only way to change a state of an event sourced object is via applying events.

I could define `expire` method that could transition into `expired` state:

```ruby
  event :expire do
    transition all - %w(expired shipped) => :expired
  end
```

But that would set the `state` directly, instead of indirectly via a domain event that I would later save in a database.

```ruby
    def expire
      return if [:expired, :shipped].include?(state)
      apply(OrderExpired.strict(data: {
        order_number: number}))
    end
```

So at the end, I decided that it's probably not worth in many use-cases to use this particular gem with our way of writing event sourced entities. The benefits are small and most features of the library cannot be used easily without introducing problems.

Perhaps there is a different library out there for defining state machines that could play nicer with event sourcing and `aggregate_root`. But I haven't found it yet. The struggle for a nice code involves a lot failed experiments.