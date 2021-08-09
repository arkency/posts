---
created_at: 2021-08-09 12:25:24 +0200
author: Andrzej Krzywda
tags: [event sourcing]
publish: false
---

# Audit log with event sourcing
Recently I've been fixing the way the "history" (essentially an audit log) feature works in the Arkency Ecommerce application. This story may be a good reminder of how audit logs work and how they can be implemented.


<%= img_fit("audit-log-with-event-sourcing/event_view.png") %>

```ruby
Person.new.show_secret
# => 1234vW74X&
```
