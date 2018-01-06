---
title: "Process Managers revisited"
created_at: 2018-01-06 16:12:41 +0100
kind: article
publish: false
author: Paweł Pacana
tags: [ 'process', 'manager', 'rails_event_store' ]
newsletter: :none
---
# Process Managers revisited

I've been telling my story with process managers [some time ago](https://blog.arkency.com/2017/06/dogfooding-process-manager/). In short I've explored there a way to source state of the process using nothing more but domain events. However I've encountered an issue which led to a workaround I wasn't quite happy about. With the release of [RailsEventStore v0.22.0](https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.22.0) this is no longer a case!

Let's remind ourselves what was the original problem to solve:

>  You’re an operations manager. Your task is to suggest your customer a menu they’d like to order and at the same time you have to confirm that caterer can deliver this particular menu (for given catering conditions). In short you wait for `CustomerConfirmedMenu` and `CatererConfirmedMenu`. Only after both happened you can proceed further. You’ll likely offer several menus to the customer and each of them will need a confirmation from corresponding caterers.
>  If there’s a match of `CustomerConfirmedMenu` and `CatererConfirmedMenu` for the same `order_id` you cheer and trigger `ConfirmOrder` command to push things forward. 

The issue manifested when I was about to "publish" events that process manager subscribed to and eventually received:

```
ActiveRecord::RecordNotUnique:
  PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_event_store_events_on_event_id"
  DETAIL:  Key (event_id)=(bddeffe8-7188-4004-918b-2ef77d94fa65) already exists.
```

I wanted to group those events in a short, dedicated stream from which they could be read from on each process manager invocation. 

Within limitations of RailsEventStore version at that time I wasn't able to do so and resorted to looking for past domain events in streams they were originally published to. That involved filtering them from irrelevant events in the light of the process and most notably knowing and depending on such streams (coupling).

## Linking events to the rescue

- [api i zachowanie]
- [jakie zmiany pod spodem]
- [implementacja]

## Inspecting Process Manager state

- [show browser]