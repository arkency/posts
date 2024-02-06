---
created_at: 2024-02-06 17:01:52 +0100
author: Piotr Jurewicz
tags: [ rails zeitwerk ]
publish: false
---

# Completly custom Zeitwerk inflector

In my previous post, I described the general difference between how the classic autolader and Zeitwerk autoloader match
constant and file names. Short reminder:

- Classic autoloader maps missing constant name `Raport::PL::X123` to a file name by
  calling `Raport::PL::X123.to_s.underscore`
- Zeitwerk autoloader finds `lib/report/pl/x123/products.rb` and maps it to `Report::PL::X123::Products` constant name
  with the help of inflection rules
