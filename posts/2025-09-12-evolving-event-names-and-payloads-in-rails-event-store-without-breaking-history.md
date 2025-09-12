---
created_at: 2025-09-12 12:26:59 +0200
author: Jakub Rozmiarek
tags: ["event store", "event sourcing", "ddd", "rails event store"]
publish: false
---

# Evolving event names and payloads in Rails Event Store without breaking history

Your product team just decided that 'Refunds' should be called 'Returns' across the entire system. In a traditional CRUD application, this might be a simple find-and-replace operation. But in an Event Sourced system with thousands of historical events, this becomes a migration challenge that could break your entire application.

Event sourced systems store immutable events as the source of truth. When business terminology evolves, you can't just update the database - you need to maintain backward compatibility with all historical events while allowing new code to use updated terminology.

<!-- more -->

## The problem we faced

In an event sourced ecommerce app a decision was made to rename legacy events to new terminology: 
- `Ordering::DraftRefundCreated` -> `Ordering::DraftReturnCreated`
- `Ordering::ItemAddedToRefund`-> `Ordering::ItemAddedToReturn`
- `Ordering::ItemRemovedFromRefund` -> `Ordering::ItemRemovedFromReturn`

What is more also a payload transformation was needed:
- `refund_id` -> `return_id`
- `refundable_products` -> `returnable_products`

## Simple solutions don't work

In event sourced systems:
- we can't modify historical events because it breaks Event Sourcing fundamentals
- if we ignore old events it results in business-critical historical data loss
- data migrations don't apply as events are immutable by design

## The Rails Event Store context

### How RES handles event serialization/deserialization

Rails Event Store uses a two-phase process for event persistence. When events are published, RES serializes domain events into Record objects containing event_type, data, metadata, and timestamps, then stores them in the database. During reads, it deserializes these records back into domain events that your application code can work with. This process involves multiple transformation layers that can modify both the structure and content of events as they move between your domain model and storage.

### The role of mappers in the event pipeline

Mappers are the transformation engine of RES, sitting between your domain events and the database. They form a pipeline where each mapper can transform events during serialization (dump) and deserialization (load). Common transformations include DomainEvent (converts plain objects to domain events), SymbolizeMetadataKeys (normalizes metadata keys), and PreserveTypes (maintains data types like timestamps). This pipeline architecture allows you to compose multiple transformations, making it possible to evolve event schemas while maintaining backward compatibility.

## Our solution: custom event transformation pipeline

As described [here](https://railseventstore.org/docs/advanced-topics/mappers/#custom-mapperRES) RES allows to create custom mappers and plug them into the transformation pipeline.

We decided to create a custom `Transformations::RefundToReturnEventMapper`and include it in the transformation pipeline of our RES client:


```ruby
  mapper = RubyEventStore::Mappers::PipelineMapper.new(
    RubyEventStore::Mappers::Pipeline.new(
      Transformations::RefundToReturnEventMapper.new(
          'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
          'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
          'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
        ),
      RubyEventStore::Mappers::Transformation::DomainEvent.new,
      RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
      RubyEventStore::Mappers::Transformation::PreserveTypes.new
    )
  )
  client = RailsEventStore::JSONClient.new(mapper: mapper)
```

### Key components

1. Event class name transformation

```ruby
  class_map = {
    'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
    'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
    'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
  }
```

it's passed to our custom mapper and it is then used to map old classes to new ones during deserialization:

```ruby
module Transformations
  class RefundToReturnEventMapper
    def initialize(class_map)
      @class_map = class_map
    end

    def load(record)
      old_class_name = record.event_type
      new_class_name = @class_map.fetch(old_class_name, old_class_name)

      if old_class_name != new_class_name
        transformed_data = transform_payload(record.data, old_class_name)
        record.class.new(
          event_id: record.event_id,
          event_type: new_class_name,
          data: transformed_data,
          metadata: record.metadata,
          timestamp: record.timestamp || Time.now.utc,
          valid_at: record.valid_at || Time.now.utc
        )
      else
        record
      end
    end

    def dump(record)
      record
    end
  end
end
```

2. Payload data transformation

As you probably notice there's also a call to `transform_payload`, here's how it works:

```ruby
module Transformations
  class RefundToReturnEventMapper
    private

    def transform_payload(data, old_class_name)
      case old_class_name
      when 'Ordering::DraftRefundCreated'
        data = transform_key(data, :refund_id, :return_id)
        transform_key(data, :refundable_products, :returnable_products)
      when 'Ordering::ItemAddedToRefund', 'Ordering::ItemRemovedFromRefund'
        transform_key(data, :refund_id, :return_id)
      else
        data
      end
    end

    def transform_refund_to_return_payload(data, old_key, new_key)
      if data.key?(old_key)
        data_copy = data.dup
        data_copy[new_key] = data_copy.delete(old_key)
        data_copy
      else
        data
      end
    end
  end
end
```

### Other considerations

1. We use load-time transformation only: load() transforms when reading, dump() preserves original format
2. our pipeline relies on three RubyEventStore transformations:
  - `DomainEvent` hydrates objects and normalizes data structure
  - `SymbolizeMetadataKeys` ensures metadata follows Ruby conventions
  - `PreserveTypes` prevents data type corruption during the transformation process

## Why not use RES upcast feature?

As described in [this post](https://blog.arkency.com/4-strategies-when-you-need-to-change-a-published-event/#2__upcasting_the_event_on_the_fly__) RES provides `Transformation::Upcast` mapper.

After investigating its capabilities, we discovered that upcast can indeed handle both event class name changes and payload transformation through lambda functions. However, we chose to stick with our custom mapper approach for several practical reasons:

1. Pipeline integration complexity

RES upcast works beautifully as a standalone solution, but doesn't integrate cleanly with the transformation pipeline we needed:

```ruby
  # This doesn't work - Default mapper isn't pipeline-compatible
  RubyEventStore::Mappers::PipelineMapper.new(
    RubyEventStore::Mappers::Pipeline.new(
      RubyEventStore::Mappers::Default.new(events_class_remapping: upcast_map),  # No dump() method
      RubyEventStore::Mappers::Transformation::DomainEvent.new,
      RubyEventStore::Mappers::Transformation::PreserveTypes.new
    )
  )
```

We needed `DomainEvent.new`, `SymbolizeMetadataKeys.new`, and `PreserveTypes.new` transformations, but upcast's `Default` mapper isn't designed to work within a transformation pipeline.

2. Excessive boilerplate when using lambdas

Lambdas could be used to handle paload transformation, however using upcast with lambdas required significant boilerplate code for each event type:

```ruby
  'Ordering::DraftRefundCreated' => lambda { |record|
    new_data = symbolize_keys(record.data.dup)  # Manual key conversion
    new_data = transform_payload(new_data)      # Our transformation logic

    record.class.new(                           # Manual object creation
      event_id: record.event_id,                # Boilerplate
      event_type: 'Ordering::DraftReturnCreated',
      data: new_data,
      metadata: symbolize_metadata_keys(record.metadata),  # Manual metadata handling
      timestamp: record.timestamp,              # Manual preservation
      valid_at: record.valid_at                # Manual preservation
    )
  }
```

This approach would require us to manually implement what DomainEvent.new and PreserveTypes.new handle automatically.

Without the transformation pipeline, we'd lose the automatic benefits of:
- type preservation for timestamps and other complex objects
- metadata key symbolization
- domain event hydration

We'd need to reimplement these features manually in each lambda.

3. Code organization and maintainability

Our custom mapper provides better separation of concerns:
- single responsibility: one class handles all transformation logic
- easier testing: clear interface for unit tests
- better debugging: stack traces point to specific transformation methods
- DRY principle: Shared transformation logic across all event types
