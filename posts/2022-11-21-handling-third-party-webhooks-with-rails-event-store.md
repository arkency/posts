---
created_at: 2022-11-21 11:44:08 +0100
author: Piotr Jurewicz
tags: ['rails event store']
publish: false
---

# Handling third-party webhooks with Rails Event Store

Lately, one of our clients asked us for reviewing his Rails Event Store based application. RES mentoring is one of the fields of our professional activity.
What caught our attention was the way of handling webhooks from third-party services.

<!-- more -->


```ruby
Person.new.show_secret
# => 1234vW74X&
```
