---
created_at: 2025-06-09 08:55:49 +0200
author: Mirosław Pragłowski
tags: ["railseventstore", "performance"]
publish: true
---

# Batch mapper in RailsEventStore - how initial idea evolved into experimental feature

Some time ago, [Bert](https://github.com/Bertg) who uses RES in his project has reached out to us with a performance issue. The data in his event store database are encrypted. RailsEventStore provides an `EncryptionMapper` to handle encryption/decryption of domain events' data. However, in this case the simple use of it caused performance issues.

<!-- more -->

## Idea

The `EncryptionMapper` gets a keys repository as a dependency, and for each event to encrypt/decrypt (or even for each attribute), it might ask the key repository for an encryption key. That was unfortunate because Bert's system keeps the encryption keys in an external KMS storage - which means each time an API call over the network is needed.

Of course, the key repository could be populated with all keys on its initialization or cache the fetched keys on the go, but with a huge number of domain events and keys it quickly becomes an issue to keep them all in memory. And of course, making the separate API call each time a key is needed is not an option.

Bert pushed a PR to RailsEventStore where he introduced a concept of batch mapping, which allows processing a batch of events before transforming them in the mapper.

The idea was great. Then we applied some mutant tests on the initial PR... and the code evolved ;)

## Experiment

We decided to introduce the batch mapping as an [experimental feature](https://railseventstore.org/docs/contributing/maintenance_policy/#experimental-features) in RailsEventStore.

> This means that we are still in process of discovery of the stable API for them, and therefore, the API of them may change breaking backwards compatibility between subsequent minor versions.

We rely on you for feedback to help improve this part of the RailsEventStore code.

## Implementation

The batch mapping implementation is simple. Instead of processing the events one by one (as current mappers do) it processes them in batches.

Where the batches come from? They have always been there :) Even if you just use `to_a` method RailsEventStore always reads from the database in batches and uses an enumerator to deliver the results as an array.

So, as we read in batches, we can also transform the read data in batches. Instead of `record_to_event(record)` and `event_to_record(event)` methods implemented by existing mappers, the code now relies on `records_to_events(records)` and `events_to_records(events)` that receive a batch of events to process.

## Backward compatibility

We always strive to maintain backward compatibility and make sure changes won't break anyone's code. We use RailsEventStore in most of projects we work on. Sometimes the codebase is huge, and we want seamless upgrades between RailsEventStore versions without requiring developers to make changes to their project's code.

We have achieved this by keeping current mappers unchanged. Each time single-item-processing mapper is provided as a RailsEventStore::Client dependency, we wrap it into `RubyEventStore::Mappers::BatchMapper`. It implements new methods to process events in batches but internally uses the single-item-processing mapper to actually do all the work. Basically, we have moved the processing loop to a separate class and use it when needed.

If you provide a mapper that implements batch processing, it will be used as-is - without `BatchMapper` wrapping your implementation.

## Problem solution

These changes solve the initial problem.

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

This pseudocode is all that is needed. As the mapper now processes events in batches, before processing each batch it fetches the required keys from the KMS system. No need for an API call for each domain event, and no need to fetch all keys before. You might implement your own keys caching strategy in the keys repository and tune it to your usage.

The full code to illustrate this use case is [here](https://gist.github.com/mpraglowski/ca852ba76503888be85ec53bacb491fe).
