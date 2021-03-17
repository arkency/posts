---
title: Async Processing of Events in Order - the Holy Grail of SQL backed Event Store
created_at: 2021-03-17T21:42:46.712Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Async Processing of Events in Order - the Holy Grail of SQL backed Event Store

problem: holes in id sequence

where needed:

* process events from one app in another app
* "persistent projections"


issue 106

how to make it without relying on exotic db features (vendor specific or unavailable in cloud)

* ~sync handlers~
* out of order processing
* always reading the whole stream from the beginning
* linearized writes
* max tx time
* auto increment order (vs tx order) — waits for transaction to finish
