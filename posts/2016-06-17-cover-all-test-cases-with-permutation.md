---
title: "Cover all test cases with #permutation"
created_at: 2016-06-17 13:06:21 +0200
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby', 'permutation', 'rspec', 'tests' ]
newsletter: :arkency_form
---

<img src="<%= src_fit("ruby-permutation/permutation-cube.jpg") %> alt="" width="100%" />

When dealing with system which cooperate with many other
subsystems in an asynchronous way, you are presented with
a challenge. Due to the nature of such systems, messages
may not arrive always in the same order. How do you test
that your code will react in the same way in all cases?

Let me present what I used to be doing and how I changed my
approach. The example will be based on [a saga](/course/saga/) but it
applies to any solution that you want to test for
order independence.

<!-- more -->

```
#!ruby
specify "postal sent via API" do
  procs = [
    ->{ postal.call(fill_out_customer_data) },
    ->{ postal.call(paid_data) },
    ->{ postal.call(tickets_generated_data) },
  ].shuffle

  procs[0].call
  procs[1].call

  expect(api_adapter).to receive(:transmit)
  procs[2].call
end
```

This solution however has major drawbacks

* It does not test all possibilities
* Failures are not easily reproducible

It will eventually test all possibilites. Given enough runs on CI.
And you can reproduce it if you pass the [`--seed`](https://www.relishapp.com/rspec/rspec-core/docs/command-line/order)
attribute.

But generally it does not make our job easier. And it might miss some bugs
until it is executed enough times.

It was rightfully questioned by Paweł, my coworker. We can do better.

## #permutation

We should strive to test all possible cases. It's boring to go manually through all 6 of them.
With even more possible inputs the number goes high very quickly. And it might be error prone.
So let's generate all of them with the little help of `#permutation` method.

```
#!ruby

[
  fill_out_customer_data,
  paid_data,
  tickets_generated_data,
].permutation.each do |fact1, fact2, fact3|
  specify "postal sent via API when #{[fact1.class, fact2.class, fact3.class].to_sentence}" do
    postal.call(fact1)
    postal.call(fact2)
    
    expect(api_adapter).to receive(:transmit)
    postal.call(fact3)
  end
end
```

## Caveats

* The more cases you generate the faster they should run individually
* There is obviously a certain limit after which doing this does not make sense anymore.
Maybe in such case fuzzy testing or moving it outside the main build is a better solution.

If you enjoyed this blog post you will like our [books](/products) as well.
