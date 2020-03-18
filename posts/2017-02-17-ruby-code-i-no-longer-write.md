---
title: "Ruby code I no longer write"
created_at: 2017-02-17 09:16:33 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'metaprogramming', 'refactoring' ]
newsletter: arkency_form
img: "ruby-code-no-longer-write/ruby_code_puppy_banner.jpg"
---

<%= img_fit("ruby-code-no-longer-write/ruby_code_puppy_banner.jpg") %>

When we learn programming languages and techniques we go through certain phases:

* Curiosity
* Admiration
* Overdosage
* Rejection
* Approval

etc. Similarly with other things we enjoy in our life such as ice cream, pizza and sunbathing :)
We learn to enjoy them, we try too much of it and learn the consequences. Hopefully
some time later we find a good balance. We know, how much of it, we can use without hurting ourselves.

I think we can have a similar experience in programming for example when you find out about
metaprogramming, immutability, unit testing, DDD. Basically anything. We often need to hit
an invisible wall and realize that we overdosed. It's not easy at all to realize it and learn
from it.

After 8 years of using Ruby and Rails, there are certain constructs that I try not to use anymore
because I believe they make maintaining large applications harder.

<!-- more -->

## Example 1

Here is a piece of code I wrote some time ago.

```ruby
class Ticket
  def pdf_of_kind(kind)
    {
      normal: -> { self.normal_pdf },
      zebra:  -> { self.zebra_pdf  },
    }.fetch(kind).call
  end

  # normal_pdf and zebra_pdf methods defined somehow...
end
```

I am sure that, as most developers, you will find it... unusual. After all
the code can be written as:

```ruby
class Ticket
  def pdf_of_kind(kind)
    send(kind.to_s + "_pdf")
  end
end
```

However, there are certain problems with this construct.

It's a bit more insecure. If `kind` comes from external sources we
accidentally allow calling other methods which end in `_pdf`. Granted,
you might think that in such case this should be prevented by different layer
and perhaps you would be right.

But a much bigger issue for me is that this code is hard to refactor, hard to `grep`.
If I try to find usages of `zebra_pdf` method before refactoring it, I won't find out that
`pdf_of_kind` is using it. If your codebase is small or you don't have too many of such
constructs, it doesn't hurt much. But the larger the code is, the more you use it,
the more you will find it is hard to change easily. Perhaps you read it as a sign that
I miss static typing and you would be right. After so many years with Ruby, I miss the
powerful refactoring tooling that comes with statically typed languages. Rubymine can do
a lot, but there are limits to its features.

The surface of `pdf_of_kind` method is infinite. There is an infinite number of things it
can do. I don't handle infinite very well :). If you look more deeply at the code you will
realize that it can do 3 things possibly. Run two methods or raise an exception in case of an incorrect
argument (invalid `kind`). However, to find it out you need to look a bit more deeply. With the first
implementation that I showed you, you quickly and easily see the limited scope of the function.

## Example 2

Here is another similar example.

```ruby
class Salesforce::Mapper
  private

  def parse_key(key_name)
    key_name.gsub('__c', '').underscore
  end

  def fill_keys_with_values(keys, data)
    hash = {}
    keys.each do |salesforce_key|
      our_key  = parse_key(salesforce_key)
      value = data[our_key]
      hash[salesforce_key] = value
    end
    hash
  end
end

class Salesforce::AccountMapper < Salesforce::Mapper
  def map(data)
    keys = %w(
      User_ID__c
      Phone
      Email__c
      IBAN__c
      CurrencyIsoCode
      Company_VAT_Number__c
    )
    fill_keys_with_values(keys, data)
  end
end
```

The purpose of this code is to map certain data computed in a report to salesforce columns
that will be updated. Easy peasy.

However, again the number of columns that we will update is limited and predefined.
There is no need for the mapping to be dynamic (computed based on `gsub` and `underscore`)
instead of static (defined as `A` => `B` once). How would I write this code now:

```ruby
class Salesforce::Mapper
  private

  def fill_keys_with_values(keys, data)
    hash = {}
    keys.each do |salesforce_key, our_key|
      hash[salesforce_key] = data[our_key]
    end
    hash
  end
end

class Salesforce::AccountMapper < Salesforce::Mapper
  def map(data)
    keys = {
      'User_ID__c' => 'user_id',
      'Phone' => 'phone',
      'Email__c' => 'email',
      'IBAN__c', => 'iban',
      'CurrencyIsoCode' => 'currency_iso_code',
      'Company_VAT_Number__c' => 'company_vat_number',
    )
    fill_keys_with_values(keys, data)
  end
end
```

Now the `fill_keys_with_values` method even seems unnecessary and could be refactored
into using `inject` and the inheritance seems excessive.

If I ever want to find out where is `currency_iso_code` used, I will know about
its usage in `AccountMapper`.

What makes this refactoring possible? The fact that we have a limited and predefined
number of attributes that we need to map between. If the number was unlimited then
dynamic transformation would be the only possible solution and the right one. But
there is no need for it if you know upfront about all possibilities.

## Summary

Similarly, I try to avoid [ActiveSupport extensions to String](http://edgeguides.rubyonrails.org/active_support_core_extensions.html#inflections)
such as `constantize` or `underscore` to find ruby classes or build CSS classes.
I prefer explicit mapping from `Abc::Xyz` to `abc_xyz` or whatever. That way when
I Remove `Xyz` class I can also find the mapping and remember to remove other parts
of code related to what I am removing.

On one hand Rails conventions are convenient, but on the other hand, whenever I refactor
something I need to search for `Abc::WhateverXyz`, `WhateverXyz`, `whatever_xyz` and
probably, even more, variations to be sure that everything is going to work. The more
dynamic and _meta_ your code is, the more such cases you will have. So I try to limit
those situations when the mapping is, in fact, predefined and limited.

There are even more conventions in Rails which make refactorings harder. For example
the usage of instance variables when rendering views that we described in
[Fearless Refactoring: Rails Controllers](http://rails-refactoring.com/).
