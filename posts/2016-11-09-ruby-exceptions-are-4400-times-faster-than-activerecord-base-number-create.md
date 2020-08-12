---
created_at: 2016-11-09 10:15:36 +0100
publish: true
tags: [ 'ruby', 'exceptions' ]
author: Andrzej Krzywda
---

# Ruby exceptions are 4400 times faster than ActiveRecord::Base#create

How slow are Ruby exceptions as compared to other frequent actions we may be doing in Rails apps. Like for example, as compared to ActiveRecord::Base#create

<!-- more -->

Big thanks to [Robert Pankowecki](https://twitter.com/pankowecki) who created [the original gist](https://gist.github.com/paneq/a643b9a3cc694ba3eb6e) and to [Piotr Szotkowski](https://twitter.com/chastell) who provided even more data. The gist was originally created as part of our [Fearless Refactoring: Rails Controllers book](http://rails-refactoring.com) where Ruby exceptions are suggested as one of the possible techniques of the controller communication with service objects.

```ruby

require 'active_record'
require 'benchmark/ips'

ActiveRecord::Base.logger = nil
ActiveRecord::Base.establish_connection adapter:  'postgresql',
                                        database: 'whatevers'

Whatever = Class.new(ActiveRecord::Base)

Benchmark.ips do |bench|
  bench.report('SQL query')      { Whatever.create(text: 'meh') }
  bench.report('exception hit')  { raise StandardError.new rescue nil }
  bench.report('exception miss') { raise StandardError.new if false }
  bench.compare!
end
```

Then we can run it with:

 ruby -v bench.rb 

with results like this:

```
ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-linux]
Warming up --------------------------------------
           SQL query    18.000  i/100ms
       exception hit    57.640k i/100ms
      exception miss   269.546k i/100ms
Calculating -------------------------------------
           SQL query    182.124  (±15.9%) i/s -    882.000  in   5.003193s
       exception hit    808.613k (± 4.8%) i/s -      4.035M in   5.004163s
      exception miss     10.129M (± 3.2%) i/s -     50.675M in   5.007747s

Comparison:
      exception miss: 10129279.5 i/s
       exception hit:   808613.1 i/s - 12.53x slower
           SQL query:      182.1 i/s - 55617.43x slower 
```
 

which means that for this configuration, the exceptions are 4438 times faster than AR::Base#create.
