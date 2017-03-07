---
title: "Prototypes in Ruby"
created_at: 2017-03-07 22:24:48 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby','rails','prototypes' ]
newsletter: :arkency_form
img: "prototypes-in-ruby-rails-active-record-dup-clone/prototypes_in_ruby_rails_header.png"
---

<%= img_fit("prototypes-in-ruby-rails-active-record-dup-clone/prototypes_in_ruby_rails_header.png") %>

Today I was working on a feature where I had to create a few similar
Active Record objects. I was creating a _read model_ for
some financial data. Most of the attributes of created objects were the
same but a few were different. In one refactoring step I removed the
duplication in passing attributes by using a prototype. Although at that
moment I haven't thought of the object in such way.

<!-- more -->

### Before

The code before refactoring looked similar to this:

```
#!ruby
Entry.create!(
  fact_id: fact.id,
  time: fact.metadata.fetch(:timestamp),
  level: order.level,
  order_id: order.id,
  column_a: something,
  column_b: something_else,
  column_c: another_computation,
  column_d: one_more,
  column_e: not_yet_finished,

  entry_number: 1,
  entry_type: "REVENUE",
  gross_value: BigDecimal.new("100.00"),
  vat: BigDecimal.new("13.05"),
)

Entry.create!(
  fact_id: fact.id,
  time: fact.metadata.fetch(:timestamp),
  level: order.level,
  order_id: order.id,
  column_a: something,
  column_b: something_else,
  column_c: another_computation,
  column_d: one_more,
  column_e: not_yet_finished,

  entry_number: 2,
  entry_type: "FEE_TYPE_1",
  gross_value: BigDecimal.new("-10.00"),
  vat: BigDecimal.new("-1.30"),
)
```

There were more columns and more entries
(betwen 2 and 5) being created for the financial ledger.

I could have extracted the common attributes into a Hash
but I decided to go with a slighthly different direction.

## After

```
#!ruby
base_entry = Entry.new(
  fact_id: fact.id,
  time: fact.metadata.fetch(:timestamp),
  level: order.level,
  order_id: order.id,
  column_a: something,
  column_b: something_else,
  column_c: another_computation,
  column_d: one_more,
  column_e: not_yet_finished,
)

base_entry.dup.update_attributes!(
  entry_number: 1,
  entry_type: "REVENUE",
  gross_value: BigDecimal.new("100.00"),
  vat: BigDecimal.new("13.05"),
)

base_entry.dup.update_attributes!(
  entry_number: 2,
  entry_type: "FEE_TYPE_1",
  gross_value: BigDecimal.new("-10.00"),
  vat: BigDecimal.new("-1.30"),
)
```

I used [dup](http://ruby-doc.org/core-2.4.0/Object.html#method-i-dup) method
which is available for every `Object` in Ruby. Including in
[ActiveRecord](http://api.rubyonrails.org/v5.0.1/classes/ActiveRecord/Core.html#method-i-dup) .
When using `dup` be aware of its differences from
[clone](http://ruby-doc.org/core-2.4.0/Object.html#method-i-clone),
especially in [ActiveRecord case][http://api.rubyonrails.org/v5.0.1/classes/ActiveRecord/Core.html#method-i-clone].
Those [semantics changed a few years ago in in Rails 3.10](http://guides.rubyonrails.org/3_1_release_notes.html#active-record).

The most important difference for me turns out to be the record identity.

```
#!ruby
User.last.dup.id
# => nil

User.last.clone.id
# => 4
```

`#dup` is like _I want a similar (in terms of attributes) but new record_ and `#clone` is like
_i want a copy pointing to the same db record_.
