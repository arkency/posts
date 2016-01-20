---
title: "From legacy to DDD: Start with publishing events"
created_at: 2016-01-20 13:55:18 +0100
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :skip
---

When you start your journey with DDD, it's quite easy to apply DDD in a fresh app. It's a bit more complicated for existing, legacy apps.
This blog post shows how you can start applying DDD by publishing events.

<!-- more -->

In an existing app, the biggest worry is to not break the existing functionality. This makes applying DDD even harder, as full DDD will require some refactorings.

**I suggest to start with publishing events**. Just publishing, no handling, no subscriptions. By just publishing events, you don't change the main behaviour of your system. What you're doing is adding a new no-op (no operation).

**An optional step is to also store the events**. I have an easy tool for both those things at once, so I publish/store at the same time.

Publishing events is like a compilable/interpretable code comment. You register a fact. This is what happened at this state of code.

I recently work on an app called Fuckups. Its role is to allow teams to track fuckups in their projects and it allows learning from those situations. I started with a typical framework approach (The Rails Way) and only after some time, I gradually escape from the framework and start applying DDD/CQRS/ES.

It's best to focus on the events which are clearly statements of some state changes. If you escape from a CRUD app (as I did) - they will be all those CRUD operations.

What I did, was I also tried not to use the CRUD verbs. Instead of FuckupCreated I called it FuckupReported. That's more true, as I'm not really creating a fuckup by filling the form. It's more that I report that fuckt to the system.

This is what I ended up with, in terms of events:

```
#!ruby

FuckupReported               = Class.new(RailsEventStore::Event)
FuckupReportedFromSlack      = Class.new(RailsEventStore::Event)
FuckupReportedFromCodeEditor = Class.new(RailsEventStore::Event)
FuckupRemoved                = Class.new(RailsEventStore::Event)
FuckupBatchUpdated           = Class.new(RailsEventStore::Event)
FuckupShared                 = Class.new(RailsEventStore::Event)
FuckupVisitedByUser          = Class.new(RailsEventStore::Event)
FuckupVisitedByGuest         = Class.new(RailsEventStore::Event)

OrganizationAllowedToUseTheApp = Class.new(RailsEventStore::Event)
UserApprovedInTheOrganization  = Class.new(RailsEventStore::Event)
UserRegisteredFromGithub       = Class.new(RailsEventStore::Event)
UserSessionStarted             = Class.new(RailsEventStore::Event)
UserLoggedOut                  = Class.new(RailsEventStore::Event)
UserMadeAdmin                  = Class.new(RailsEventStore::Event)
```

Using the [Rails Event Store](https://github.com/arkency/rails_event_store) gem, this is how I publish those events:

```
#!ruby

    @fuckup = current_organization.fuckups.create(fuckup_params)
    stream_name = "fuckup_#{@fuckup.id}"
    event_data = { data:
                       {
                           user_id: current_user.id,
                           organization_id: current_organization.id,
                           tldr: @fuckup.tldr,
                           description: @fuckup.description,
                           symptoms: @fuckup.symptoms,
                           hotfix: @fuckup.hotfix,
                           coldfix: @fuckup.coldfix,

                       }
    }
```

It's still a bit too verbose as for my taste, but it's quite explicit what it's doing.

Publishing events (and storing them) is just the first step. On its own it doesn't really change your architecture that much.

So what's the value?

The value is in the fact that you need to come up with non-CRUD names, that's first. You start using more domain vocabulary in your code.
The main value, though, is that those events are quickly showing you potential next steps. **The events tend to group in two ways**.
They show you the **aggregates**. If you look at the event prefixes, it's quite clear that User and Fuckup are aggregates.
The second grouping is by a **bounded context**. In my case, it's quite clear that I have a `Identity&Access` bounded context (authentication, authorization, sharing, access). The other one is just the Core - Fuckups.

You may notice that the aggregates split when you think in aggregates. The Fuckup can be shared. This is an Identity&Access concern, not the core Fuckups bounded context. In a way, the fuckup exists in both bounded contexts.

This kind of thinking and analysing is very useful in the later phases.

Stay tuned for the next steps!
