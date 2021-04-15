---
created_at: 2017-09-18 22:45:53 +0200
publish: true
author: Szymon Fiedler
tags: [ 'rspec', 'rails' , 'rails_event_store']
newsletter: arkency_form
---

# Composable RSpec matchers

<%= img_fit("composable-rspec-matchers/caleb-woods-269348.jpg") %>

While developing [RSpec matchers](http://railseventstore.org/docs/rspec/) for [RailsEventStore](http://railseventstore.org/) we figured out that in some cases it would be good to compose multiple matchers together.

<!-- more -->

## Make it work with `include`
The core scenario would be checking whether given event is part of a collection. It's a common case in our customers' applications. We want to verify if a certain domain event has been published. We make an assertion on a given _RailsEventStore_ stream and check whether the event is in place. But let's go with a simple example:

```ruby
expect([FooEvent.new, BarEvent.new, BazEvent.new])
  .to include(an_event(BarEvent))
```

It should work, since it is possible to build an expectation like:

```ruby
expect([1, 2, 3]).to include(kind_of(Integer))
```

But nope, not gonna happen:

```shell
  3) RailsEventStore::RSpec::Matchers should include #<RailsEventStore::RSpec::BeEvent:0x007fb53342bbd0 @differ=#<RSpec::Support::Differ:0x007fb53342bc70 ...y/gems/2.4.0/gems/rspec-support-3.6.0/lib/rspec/support/differ.rb:69 (lambda)>>, @expected=FooEvent>               
     Failure/Error: specify { expect([FooEvent.new]).to include(an_event(FooEvent)) }                                                                                  
                                                                       
       expected [#<FooEvent:0x007fb532b6ffa0 @event_id="7902e78d-8a2f-4563-928b-fafda75491c7", @metadata={}, @data={}>] to include #<RailsEventStore::RSpec::BeEvent:0x007fb53342bbd0 @differ=#<RSpec::Support::Differ:0x007fb53342bc70 ...y/gems/2.4.0/gems/rspec-support-3.6.0
/lib/rspec/support/differ.rb:69 (lambda)>>, @expected=FooEvent>                                         
       Diff:                                                                                            
       @@ -1,2 +1,2 @@                                                                                
       -[#<RailsEventStore::RSpec::BeEvent:0x007fb53342bbd0 @differ=#<RSpec::Support::Differ:0x007fb53342bc70 @color=true, @object_preparer=#<Proc:0x007fb53342bc20@/Users/fidel/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rspec-support-3.6.0/lib/rspec/support/differ.rb:
69 (lambda)>>, @expected=FooEvent>]                                                                                                     
       +[#<FooEvent:0x007fb532b6ffa0 @event_id="7902e78d-8a2f-4563-928b-fafda75491c7", @metadata={}, @data={}>]                         
                                                                                                                                        
     # ./spec/rails_event_store/rspec/matchers_spec.rb:13:in `block (2 levels) in <module:RSpec>'                   
```

Can you see what happened? There's an RSpec matcher in actual collection rather than expected domain event instance. We quickly figured out that our custom matcher is missing some behavior. The one which allows composing it with other matchers. We dived into the RSpec's codebase and found out that [`RSpec::Matchers::Composable`](https://github.com/rspec/rspec-expectations/blob/add9b271ecb1d65f7da5bc8a9dd8c64d81d92303/lib/rspec/matchers/composable.rb) mixin is our missing block. As docs state: _Mixin designed to support the composable matcher features of RSpec 3+. Mix it into your custom matcher classes to allow them to be used in a composable fashion._ It works in a quite simple manner by delegating `===` to `#matches?`. It _allows matchers to be used in composable fashion and also supports using matchers in case statements._

Adding `include ::RSpec::Matchers::Composable` to our `BeEvent` matcher class made the test passing. [That was quick](https://github.com/RailsEventStore/rails_event_store/commit/75ea7ee42944fea8f69c6d5bd535d5fc44697ff2).

## Other cases for composability

Sometimes you expect your domain event to contain data provided by a database. It's hard to expect specific value. You can build an expectation using `kind_of` built-in matcher:

```ruby
expect(domain_event)
  .to be_an_event(OrderPlaced).with_data(order_id: kind_of(Integer))
```

or `include`:

```ruby
expect(domain_event)
  .to 
    be_an_event(OrderPlaced)
      .with_data(products: include("Domain Driven Rails Book"))
```

There a cases where we want to be very precise about domain event data. In such situation, we add `strict` matcher.

```ruby
domain_event = OrderPlaced.new(
  data: {
    order_id: 42,
    net_value: BigDecimal.new("1999.0")
  }
)

# this would fail as data contains unexpected net_value
expect(domain_event)
  .to be_an_event(OrderPlaced).with_data(order_id: 42).strict
```

Strictness applies both to domain event data and metadata. If you want to be strict for data, but give more room to metadata, you can go with compound `and` expression:

```ruby
expect(domain_event)
  .to(
    be_event(OrderPlaced)
      .with_data(order_id: 42, net_value: BigDecimal.new("1999.0"))
      .strict
      .and(an_event(OrderPlaced).with_metadata(timestamp: kind_of(Time)))
```

It's also a part of RSpec's `Composable` mixin, together with `or`.

## More on that topic

There's a very good post on RSpec blog explaining [Composable matchers](http://rspec.info/blog/2014/01/new-in-rspec-3-composable-matchers/). It's 4 years old now, but still a good read. Especially if you're curious how RSpec internals work.
