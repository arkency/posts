---
title: "Unexpected benefits of storing commands"
created_at: 2019-11-02 15:49:06 +0100
kind: article
publish: true
author: Tomasz Wróbel
tags: [ 'rails_event_store', 'testing', 'commands' ]
newsletter: :arkency_form
---

You probably know that [Rails Event Store](https://railseventstore.org), like the name suggests, is meant to store events. Commands are a different concept, but they're very similar in structure - after all it's just a set of attributes. So in one of our projects we slightly abused RES and made it store commands alongside with events.

<!-- more -->

You can achieve command storage in RES in different ways, with varying levels of sophistication. The most naive way to do it (just to move along with our story) would be to store an "event" named `CommandIssued` with `command_type` && `command_data` attributes:

```ruby
class CommandIssued < RailsEventStore::Event
end

event_store.publish(CommandIssued.new(data: {
  command_type: command_type,
  command_data: command_data,
}))

# You may wanna add it to a specific stream
```

We're thinking about supporting command storage in RES ecosystem, thereby unifying RES & Arkency Command Bus, but there's no clear way forward yet. If you wanna be a part of the conversation feel free to [contribute to the RES project](https://github.com/RailsEventStore/rails_event_store) or join us on [Rails Architect Conference](https://rescon.arkency.com) (formerly RESCon).

Our primary reason to try command storage was to experiment with replaying current state from commands. We didn't get there yet, but in the meantime, we just stored the commands. It obviously gave us additional auditability. But what else?

## Meet the CommandDumper

In the mentioned project we were dealing with quite complicated calculations. We'd get reports telling us that for a specific tenant, for such and such input data, there was an unexpected result. Developers' daily bread. The difference was that because of the nature of that particular project it was often a daunting task to reproduce the specific situation (the reports were often accidental & noisy).

Stored commands can probably help here to see what was going on. But the sole ability to browse them doesn't yet move us a lot forward. One day we thought: **what if we could dump these commands to a plain ruby test, where we'd check if the bug is indeed reproduced**. We could then quickly carve out the unneded commands while still having the test expose the incorrect behaviour. This way we could **isolate the issue from the noise** and reduce the scenario to the simplest possible which still exposes our bug. That would greatly help find the core problem.

And that's exactly what we did:

```ruby
class CommandDumper

  def initialize(event_store)
    @event_store = event_store
  end

  def call(tenant_id)
    @event_store.read.stream("executed-commands-#{ tenant_id }")
      .each.to_a
      .map { |cmd| "execute(#{ cmd.class }.new(#{ cmd.to_h.inspect }))\n" }
      .join
  end

end
```

Now run the dumper:

```ruby
puts CommandDumper.new.call(123)
```

...which outputs a set of statements ready to paste into a test template:

```ruby
execute(AddTenant.new({:tenant_id=>123}))
execute(AddContact.new({:tenant_id=>123, :author_id=>1}))
execute(AddProject.new({:tenant_id=>123, :project_id=>2}))
# ...
# Possibly a waaaaaay longer list of commands
# ...
execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
```

The template obviously needs to have the basic setup, and expose the `execute` command - you get it :)

```ruby
require "test_helper"

class Scenario123Test < BaseTestCase

  def test_scenario_123
    # pasted content below:
    execute(AddTenant.new({:tenant_id=>123}))
    execute(AddContact.new({:tenant_id=>123, :author_id=>1}))
    execute(AddProject.new({:tenant_id=>123, :project_id=>2}))
    execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
    execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
    execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
  end

  private

  def execute(command)
    command_executor.execute(command)
  end

  # ...

end
```

### The drill

First, add the assertion that will tell you if the bug is reproduced:

```ruby

def test_scenario_123
  execute(AddTenant.new({:tenant_id=>123}))
  execute(AddContact.new({:tenant_id=>123, :author_id=>1}))
  execute(AddProject.new({:tenant_id=>123, :project_id=>2}))
  execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
  execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
  execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))

  assert_not_equal expected_result, actual_result
end
```

Then, tinker with it and try reducing the scenario to the simplest version that still exposes the bug. Perhaps the bug would still show up if you only executed `CloseMonth` once, not three times. Perhaps the data can be simplified while still having the bug manifest itself, etc.

```ruby
def test_scenario_123
  execute(AddProject.new({:tenant_id=>123, :project_id=>2}))
  execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))

  assert_not_equal expected_result, actual_result
end
```

Once you've gotten to a fairly simple scenario, it should be way more comfortable to work on the bug itself. You can then can change the assertion to positive, and **TDD your way to victory**!

```ruby
assert_equal expected_result, actual_result
```

That's basically it. Hope it helps or inspires - at least :)

Now read on for some details.

### Why we love Ruby

Interestingly, what made the `CommandDumper` almost a one-liner is the nice property of the `inspect` method - namely that it prints the hash in a form that is often valid ruby code. Of course not always (eg. dates), but you can deal with that.

### Pitfalls 

You may be wondering: there are definitelly some pitfalls when it comes to making sure that stored commands are indeed what happened in the system. I won't cover this in detail, but you wanna be careful about:

- attempted vs succeeded vs failed commands
- db transactions when storing the commands

But it's interesting to realize, that for this particular purpose, we didn't even need to have it all sorted out beforehand - the "MVP" still provided us with some value, because we only cared about being able to reproduce the bug. If we reproduced it, it didn't matter if there was a command that was wrongly stored.

Another potential pitfall could matter if you happen to publish commands eg. in response to some events (possibly in process managers), ie. not as a direct result of user action. You may wanna differentiate between them, otherwise you may end up executing them twice in the test. In our case we made the distinction basing on *causation_id*. Read more: [correlation id and causation id in evented systems](https://blog.arkency.com/correlation-id-and-causation-id-in-evented-systems/).

### Scope

You may also be wondering about the scope, ie. the chunk of the history that is being dumped. We were in a fortunate situation where we had a multitenant system, and a lot of testing was happenning on newly created tenants (ie. not so big) - so there was a natural way to scope the set of commands we wanna dump. But I can imagine that in other settings you can also come up with a way to make it useful - at least for the purpose of reproducing bugs, where (as I mentioned earlier) you don't need 100% accurracy as long as you manage to reproduce the bug. 

### Finally a legit use of `eval` 

I couldn't resist writing a test for the CommandDumper that would go like this:

1. Have a string with ruby code executing commands
2. `eval` it
3. Run CommandDumper
4. Check if the output is the same as originally `eval`ed code

```ruby
class CommandDumperTest < BaseTestCase

  def test_dumping_commands_for_tests
    input_commands_code = <<~END
      execute(AddTenant.new({:tenant_id=>123}))
      execute(AddContact.new({:tenant_id=>123, :author_id=>1}))
      execute(AddProject.new({:tenant_id=>123, :project_id=>2}))
      execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
      execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
      execute(CloseMonth.new({:tenant_id=>123, :month=>"2019-01"}))
    END

    eval(input_commands_code)

    expected_dump = input_commands_code
    actual_dump = CommandDumper.new(event_store).call(123)
    assert_equal(expected_dump, actual_dump)
  end

end
```

Treat it as a sort of tidbit - finally a situation, where using the `eval` method was arguably justified :)

### Another makeshift way of storing commands in RES

An obvious drawback of the `CommandIssued` event approach is eg. that you cannot easily scan or filter by command type (without deserializing). It's just the simplest approach for demonstration purposes. We could go a step further and store our commands in RES as if they were plain events. It should just work, possibly with some small adaptations. Of course, in such case you'd need to always bear in mind that not everything in your event store is now an actual event. You could use metadata to tell them apart (in those rare situations where you wouldn't rely on stream name). This is the approach we actually took in our project.

### Not using commands yet?

It might be about time to start :) There's a lot of benefits. A couple starting points:

* Gem: [Arkency Command Bus](https://github.com/arkency/command_bus)
* Blogpost: [Command bus in a Rails application](https://blog.arkency.com/2016/09/command-bus-in-a-rails-application/)
* Ebook: [Domain Driven Rails](https://blog.arkency.com/domain-driven-rails/)

### Let's meet!

We believe it's great when the community comes together. We believe there are lots of Rails developers strongly interested in serious architecture. That's why we hold another edition of [Rails Architect Conference](https://rescon.arkency.com) (formerly REScon). For those who want to catch up, there are [workshops & online masterclass](https://arkency.com/masterclass/) in one package!

