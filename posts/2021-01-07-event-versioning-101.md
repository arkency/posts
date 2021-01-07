---
title: Event Versioning 101
created_at: 2021-01-07T15:53:20.059Z
author: Tomasz Wróbel
tags: []
publish: false
---

You publish an event. You handle it in some consumers, perhaps aggregates or process managers. Soon you realize you need to change something in the event's schema... Like add an attribute, fill up a missing value, flatten the attribute structure. What do you in such a situation?

0. Loop over your events and just mutate the payload in the database 😧
1. Weaken the schema or make the code more defensive
2. Upcasting
3. Stream rewriting

