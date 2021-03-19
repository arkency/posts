---
title: Comparison of event serialization methods
created_at: 2021-03-16T20:52:15.122Z
author: Tomasz Wróbel
tags: []
publish: false
---

<!--

The default that works everywhere and is  good for starting with RES is the binary column nad YAML serialization of event data/metadata. It handles Time well, if you put Ruby symbol in, you get Ruby symbol out. No surprises.

On potsgres you can choose to have jsonb columns for event data and metadata. The pro is the ability to peform indexed queries on SQL-level, which is useful for quick, ad-hoc reports. The con is that JSON as a serialization method is lossy — Ruby symbols are converted to strings, as well as Time. Therefore it is best matched with event schemas, describing how each attribute in data should be represented (or coerced to) in an event object.

https://railseventstore.org/docs/v2/mapping_serialization/#configuring-a-different-mapper

-->


## YAML

* you can just throw whatever at it and have it serialized
* self-contained schema

```
example payload
```

## JSON

* you need schema definition for anything beyond json types
* dry

## JSONB

* you can query


## Marshal

* almost like yaml - you can throw anything ruby at it
* but unreadable
* and dangerous?

## Protobuf
