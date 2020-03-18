---
title: "How mutation testing causes deeper thinking about your code + constructor for an included module in Ruby"
created_at: 2017-09-13 14:40:07 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'inheritance', 'module', 'constructor', 'mutation testing','mutant' ]
newsletter: arkency_form
---

This is a short story which starts with being very surprised by mutation testing results and trying to figure out how to deal with it.

<!-- more -->

Consider this module from [aggregate_root gem](https://github.com/RailsEventStore/rails_event_store/tree/master/aggregate_root) which is part of [Rails Event Store](https://github.com/RailsEventStore/rails_event_store).

```ruby
module AggregateRoot
  def apply(event)
    apply_strategy.(self, event)
    unpublished_events << event
  end

  def load(stream_name, event_store: default_event_store)
    @loaded_from_stream_name = stream_name
    events = event_store.read_stream_events_forward(stream_name)
    events.each do |event|
      apply(event)
    end
    @version = events.size - 1
    @unpublished_events = []
    self
  end

  def store(stream_name = loaded_from_stream_name, event_store: default_event_store)
    event_store.publish_events(
      unpublished_events,
      stream_name: stream_name,
      expected_version: version
    )
    @version += unpublished_events.size
    @unpublished_events = []
  end

  private
  attr_reader :loaded_from_stream_name

  def unpublished_events
    @unpublished_events ||= []
  end

  def version
    @version ||= -1
  end
end
```

In two places it uses `@unpublished_events = []`.

However, besides normal specs, we also check out mutation testing coverage using [mutant](https://github.com/mbj/mutant).

If you are not familiar with the technique, in short, it works like this:

* change the code subtly to introduce an incorrect behavior
* verify if the specs failed

If the specs continue passing, it might indicate that you have a missing test.

However, one thing we realized over time is that mutant often tries to tell you something deeper and point out a potential, higher level problem with your design. With every mutation detected it's good to dig a bit deeper and ask yourself _why_ 5 times :)

Let's discuss a simple example.

Mutant decided to change

```ruby
@unpublished_events = []
```

into

```ruby
@unpublished_events = nil
```

Introducing `nil` in random places is a great technique to discover untested or unused code. After all, if changing an assignment to `nil` does not break your code, why do you need it at all? Either you don't need it and you can remove the line of code, or you miss a spec that properly verifies this line of code.

My first reaction was _fuck you, that doesn't make any sense_. Why would you change an empty array to a nil?

I think about `@unpublished_events` that it is an `Array`. You can see that in

```ruby
unpublished_events << event
```

and in:

```ruby
def unpublished_events
  @unpublished_events ||= []
end
```

so fuck off mutant, mkay? 😤

Then I calmed down and started thinking about it. 😜

I changed the code manually from:

```ruby
@unpublished_events = []
```

to

```ruby
@unpublished_events = nil
```

I run the tests and they passed. I don't know what I was thinking, obviously, they passed, mutant already verified that they pass in such case. That's why I am here. But I didn't believe so I made this change manually and of course specs passed. I was confused. I looked into those specs to find out if we were missing some cases and we did not.

So why was everything working? - I wondered. And I quickly realized.

Because of the getter with a default Array:

```ruby
def unpublished_events
  @unpublished_events ||= []
end
```

3 places in this code which need `@unpublished_events` always access them via this getter:

```ruby
unpublished_events << event
```

```ruby
@version += unpublished_events.size
```

So even though `@unpublished_events` is `nil`, it will work because upon reading it will become an empty array and work nicely with `<<` and `size` methods.

```ruby
def unpublished_events
  @unpublished_events ||= []
end
```

Then I asked myself... Why are we using this `unpublished_events` getter at all? Why do we even need it? Why not use `@unpublished_events` everywhere?

And the answer was... Because we don't set `@unpublished_events = []` in a constructor.

You see, usually, you use the library in two ways. You load historical domain events when you edit an object.

```ruby
product = Product.new
product.load("Product$#{sku}") # this sets
                               # @unpublished_events

# usually we verify business rules before that step
product.apply(ProductReserved.new(
  quantity: quantity,
  order_number: order_number
))
product.store
```

or we may skip loading historical domain events for new records and go straight into changing their state and saving in DB.

```ruby
product = Product.new # @unpublished_events is nil
product.apply(ProductRegistered.new(
  sku: sku,
))
product.store("Product$#{sku}")
```

In this second case, we want to append new domain events to `@unpublished_events` collection but it is a `nil`. Using the `unpublished_events` getter workarounds this problem.

```ruby
unpublished_events << event
```

Ok, so we don't set `@unpublished_events = []` in a constructor. But why? Why don't we do that?

Because `AggregateRoot` is a module and not a class.

```ruby
class Product
  include AggregateRoot
end
```

This led me to next two questions:

* should `AggregateRoot` be a module that you include or a class to inherit from?

    I prefer that it is a module.

* can we have constructors for modules?

    It turns out we can with the little help of `prepend` which is available in Ruby for years now. Check it out.

```ruby
module AggregateRoot
  module Constructor
    def initialize(*vars, &proc)
      @unpublished_events = []
      super
    end
  end
  def self.included(klass)
    klass.prepend(Constructor)
  end

  def apply(event)
    @unpublished_events << event
  end
end

class Product
  include AggregateRoot
end
```

You might be thinking why not simply:

```ruby
module AggregateRoot
  def initialize(*vars, &proc)
    @unpublished_events = []
    super
  end

  def apply(event)
    @unpublished_events << event
  end
end
```

But there are some problems:

* another developer might forget to call `super` in a class constructor to trigger `AggregateRoot#initialize` and `@unpublished_events` will be `nil`.

    ```ruby
    class Product
      include AggregateRoot
      def initialize(dependency)
        @dep = dependency
        # missing super
      end
    end
    ```

* Inside `AggregateRoot#initialize` we don't know how many arguments we should provide for a parent class constructor

    ```ruby
    module AggregateRoot
      def initialize(*vars, &proc)
        @unpublished_events = []
        super
      end

      def apply(event)
        @unpublished_events << event
      end
    end

    class Product
      include AggregateRoot

      def initialize(dependency)
        @dep = dependency
        super
      end
    end

    Product.new(1)

    # ArgumentError: wrong number of arguments (given 1, expected 0)
    # from (irb):4:in  `initialize'
    # from (irb):4:in  `initialize'
    # from (irb):17:in `initialize'
    # from (irb):21:in `new'
    ```

* If we try to workaround the previous problem by not calling `super` from our module we get into problems in different situations.

    ```ruby
    module AggregateRoot
      def initialize(*vars, &proc)
        @unpublished_events = []
        # super
      end

      def apply(event)
        @unpublished_events << event
      end
    end

    class Something
      def initialize(dependency1)
        @dep1 = dependency1
      end
    end

    class Product < Something
      include AggregateRoot

      def initialize(dependency1, dependency2)
        @dep2 = dependency2
        super(dependency1)
      end
    end

    p = Product.new(:one, :two)
    p.instance_variable_get(:@dep1)
    # => nil
    ```


It seems to me that while prepending `Constructor` can work it does not seem to be very intuitive.

```ruby
module AggregateRoot
  module Constructor
    def initialize(*vars, &proc)
      @unpublished_events = []
      super
    end
  end
  def self.included(klass)
    klass.prepend(Constructor)
  end

  def apply(event)
    @unpublished_events << event
  end
end

class Product
  include AggregateRoot
end
```

If I had many instance variables to set I could consider it. But with one or two, I think I am gonna stay with a getter and a default value.

```ruby
def unpublished_events
  @unpublished_events ||= []
end
```

## P.S.

Struggling with complex Rails app and business domain? - Check out [Domain Driven Rails ebook](/domain-driven-rails/) and our [upcoming workshops in London and Berlin](/ddd-training/)
