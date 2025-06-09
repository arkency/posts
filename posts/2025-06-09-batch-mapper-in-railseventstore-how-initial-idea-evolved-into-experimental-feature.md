---
created_at: 2025-06-09 08:55:49 +0200
author: Mirosław Pragłowski
tags: ["railseventstore", "performance"]
publish: false
---

# Batch mapper in RailsEventStore - how initial idea evolved into experimental feature

Some time ago one of the developers who uses RES in his project has reached to us with an performance issue. The data in his event store database are encrypted. RailsEventStore provides an `EncryptionMapper` to handle encryption/decryption of domain event's data, however in this case the simple use of it has caused performance issues.

<!-- more -->

## Idea

The `EncryptionMapper` gets a keys repository as a dependency and for each event to encrypt/decrypt (or even for each attribute) it might ask the key repository for an encryption key. That was unfortunate because Bert's system keeps the encryption keys in external KMS storage - what means each time a network API call is needed.

Of course the key repository could be populated with all keys on its initialization, or cache the fetched keys on the go, but with huge number of domain events and keys it quickly becomes an issue to keep them all in memory. And of course keeping the separate API call each time a key is needed is not an option.

Bert's has pushed a PR to RailsEventStore where he introduced a concept of batch mapping, that will allow to process the batch of events before transforming them in the mapper.

The idea was great. Then we applied some mutant tests on the initial PR... and the code evolved ;)

## Experiment

He have decided to introduce the batch mapping as an [experimental feature](https://railseventstore.org/docs/contributing/maintenance_policy/#experimental-features) in RailsEventStore.

> This means that we are still in process of discovery of the stable API for them, and therefore, the API of them may change breaking backwards compatibility between subsequent minor versions.

We will count on you to get the feedback and maybe improve this part of RailsEventStore code.

## Implementation

The batch mapping implementation is simple. Instead of processing the events one by one (as current mappers do) it process it in batches.

Where the batches come from? They have always been there :) Even if you just use `to_a` method RailsEventStore always read from database in batches and use enumerator to deliver the results as an array.

So as we read in batches we could also transform the read data in batches. Instead of `record_to_event(record)` & `event_to_record(event)` methods implemented by existing mappers the code relies now on `records_to_events(records)` & `events_to_records(events)` that gets a batch of events to process.

## Backward compatibility

We always strive to keep the backward compatibility and make sure the changes won't break anyone's code. We are using RailsEventStore in most of projects we are working on. Sometimes the codebase is huge and we want to have seamless upgrade between RailsEventStore versions without making developers to implement changes in project's code.

We have achieved this by keeping current mappers as is, no changes here. Each time single item processing mapper is given as a RailsEventStore::Client dependency we wrap it into `RubyEventStore::Mappers::BatchMapper`. It implements new methods to process events in batches but internally it uses the single item processing mapper to actually do all the work. Basically we have moved the processing loop to a separate class and we use it when needed.

If you provide a mapper that implements batch processing it will be used as is - without `BatchMapper` wrapping your implementation.

## Problem solution

This changes allows to solve the initial problem solution.

```ruby
class CustomEncryptionMapper
 ...
  def records_to_events(records)
    fetch_keys(records)
    super
  end

  def events_to_records(events)
   fetch_keys(events)
    super
  end
end
```

This pseudocode is all what is needed. As the mapper now process events in batches before processing each batch it fetches required keys from the KMS system. No need for API call for each domain event, no need to fetch all keys before. You might implement your keys caching strategy in the keys repository and tune it to your usage.

The full code to illustrate this use case is [here](https://gist.github.com/mpraglowski/a50234a77708b9cb7591f7932c7f95ef).
