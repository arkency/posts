---
title: "Unexpected benefits of storing commands"
created_at: 2019-11-02 15:49:06 +0100
kind: article
publish: false
author: Tomasz Wróbel
tags: [ 'rails_event_store' ]
newsletter: :arkency_form
---

You probably know that Rails Event Store, like the name suggests, is meant to store events. Commands are a different concept, but they're very similar in structure - after all it's just a set of attributes. So in one of our projects we slightly abused RES and made it store commands alongside with events.

<!-- more -->

You can achieve some makeshift command storage in RES in different ways, with varying levels of sophistication. The most naive way to do it (just to move along with our PoC) was to store an "event" named CommandIssued with `command_type` && `command_data` attributes:

```ruby
class OrderPlaced < RailsEventStore::Event
end

# ...

event_store.publish(OrderPlaced.new(data: {
  command_type: command_type,
  command_data: command_data,
}))
```

An obvious drawback here is eg. that you cannot easily filter by command type (without deserializing). It's just the simplest approach for demonstration purposes. We could go a step further and just store our commands in RES as if they were plain events. It should just work, possibly with some small adaptations. Of course, in such case you'd need to always bear in mind that not everything in your event store is now an event. You could use metadata to tell them apart (in those rare situations where you wouldn't rely on stream name). This is the approach we actually took in our project, but that doesn't make a lot of difference here.

We're thinking about supporting command storage in RES ecosystem, thereby unifying RES & Arkency Command Bus, but there's no clear way forward yet. If you wanna be a part of the conversation feel free to contribute to the RES project or join us on Rails Architect Conference (formerly RESCon).

Our primary reason to try command storage that was to experiment with replaying current state from commands. We didn't get there yet, but in the meantime, we, well, stored the commands, which obviously gave us additional auditability. But what else?

## Meet the command dumper

In the mentioned project we were dealing with quite complicated calculations. We'd then get reports telling us that for that specific tenant, for such and such input data, there was an unexpected result. Quite normal. The difference was that because of the nature of that particular project it was often a daunting task to reproduce the specific situation (the reports were often accidental & noisy).

Stored commands can probably help here. But the sole ability to browse them doesn't yet move us a lot forward. One day we thought: what if we could dump these commands to a plain ruby test, where we'd check if the bug is indeed reproduced. We could then quickly carve out the unneded commands while still having the test expose the incorrect behaviour. This way we could isolate the issue from the noise and reduce the scenario to the simplest possible, that still exposes our bug. That would greatly help find the core problem.

And that's exactly what we did.


TODOs

- tenants
- triage
- dat flow with finding bugs
- don't care if its complete, we just care if we could reproduce the bug
- cmd.inspect accidentally good enough
- pass thru, no pass thru
- arkency command bus
- CommandDumper test
- no commands - how about request initiated
- streams

Obviously, you wanna be careful about:

- storing commands & transactions
- attempted vs failed vs succeeded commands
- side effects - 3rd party api calls, mailers, etc.


META todos:

- headlines
- digressions to the bottom
- related posts (maybe that: correlation id, causation id...)
- rescon links
- rescon invitation at the end
