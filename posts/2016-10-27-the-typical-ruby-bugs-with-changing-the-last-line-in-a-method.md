---
title: "The typical Ruby bugs with changing the last line in a method"
created_at: 2016-10-27 23:00:34 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---


<!-- more -->

```
#!ruby
Person.new.show_secret
# => 1234vW74X&
```

