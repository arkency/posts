---
title: "Always present association"
created_at: 2016-07-12 17:42:41 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'association', 'has_one', 'belongs_to', 'rails', 'super' ]
newsletter: :arkency_form
---

Recently my colleague showed my a little trick
that I found to be very useful in some situations.
It's nothing fancy or mind-blowing or unusual
in terms of using Ruby. It's just applied in a way
that I haven't seen before. It kind of even seems
obvious after seeing it :)

<!-- more -->

## The trick

```ruby
class Order < ActiveRecord::Base
  has_one :meta_data, dependent: :destroy, autosave: true
  
  def meta_data
    super || build_meta_data
  end

  delegate :ip_address,  :ip_address=
           :user_agent,  :user_agent=
           to: :meta_data,
           prefix: false
end
```

## Nice

Now you can just do:

```ruby
order.ip_address = request.remote_ip
order.save!
```

without wondering if `order.meta_data` is `nil` because
if this associated record was never saved then
`build_meta_data` will create a new one for you.

Same goes with reading such attributes. You can get `nil`
but you won't get `NoMethodError` from calling `ip_address`
on an empty association (`nil`).

## Not so nice

It has some downsides, however. Reading (event an empty) `ip_address`
can trigger a side-effect in saving the `meta_data`.

```ruby
ip = order.ip_address
order.save!
```

`MetaData` can not have non-null columns unless you set all of them
at the same time. Otherwise, when
`ip_address` can be null but `user_agent` cannot, setting only
one of them will cause troubles.

```ruby
order.ip_address = request.remote_ip
order.save! # Exception
```

The same problem can occur with validations on `MetaData`.

## Summary

But if you don't have such situations in your code and just have
multiple attributes that are either optional or all set at the
same time, then why not.

## P.S.

* Check out more patterns that can help you in maintaining Rails apps in our [Fearless Refactoring: Rails controllers ebook](http://rails-refactoring.com/)

    <a href="http://controllers.rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="25%" /></a>
