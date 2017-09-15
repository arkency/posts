---
title: "Custom type-casting with ActiveRecord, Virtus and dry-types"
created_at: 2016-03-20 12:38:50 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'typecasting', 'rails', 'active record', 'virtus', 'dry-types' ]
newsletter: :skip
newsletter_inside: :clean
---

In [Drop this before validation and just use a setter method](/2016/01/drop-this-before-validation-and-use-method/)
I showed you how to avoid a common pattern of using `before_validation` to
fix the data. Instead I proposed you just overwrite the setter, call your custom logic there
and use `super`. I also showed you [what you can do if you can't easily call super](/2016/02/using-anonymous-modules-and-prepend-to-work-with-generated-code/) .

But sometimes to properly transform the incoming data or attributes **you just need
to improve the type-casting logic**. And that's it. So let's see how you can add your
custom typecasting rules to a project.

And let's continue with the simple example of stripped string.

<!-- more -->

### Active Record 4.2+

```ruby
class StrippedString < ActiveRecord::Type::String
  def cast_value(value)
    value.to_s.strip
  end
end
```

```ruby
class Post < ActiveRecord::Base
  attribute :title, StrippedString.new
end
```

```ruby
p = Post.new(title: " Use Rails ")
p.title
# => "Use Rails"
```

### Virtus

```ruby
class StrippedString < Virtus::Attribute
  def coerce(value)
    value.to_s.strip
  end
end
```

```ruby
class Address
  include Virtus.model
  include ActiveModel::Validations

  attribute :country_code, String
  attribute :street,       StrippedString
  attribute :zip_code,     StrippedString
  attribute :city,         StrippedString
  attribute :full_name,    StrippedString

  validates :country_code,
    :street,
    :zip_code,
    :city,
    :full_name,
    presence: true
end
```

```ruby
a = Address.new(city: " Wrocław ")
a.city
# => "Wrocław"
```

### dry-types 0.6

```ruby
module Types
  include Dry::Types.module
  StrippedString = String.constructor(->(val){ String(val).strip })
end
```

```ruby
class Post < Dry::Types::Struct
  attribute :title, Types::StrippedString
end
```

```ruby
p = Post.new(title: " Use dry ")
p.title
# => "Use dry"
```

## Conclusion

If you want to improve type casting for you Active Record class or if you need it for a different layer (e.g.
a Form Object or [Command Object](http://www.slideshare.net/robert.pankowecki/2-years-after-the-first-event-the-saga-pattern/4))
in both cases you are covered.

Historically, we have been using Virtus for that non-persistable layers. But
with the [recent release of dry-types (part of dry-rb)](http://dry-rb.org/news/2016/03/16/announcing-dry-rb/)
we started also investigating this angle as it looks very promising. I am very happy with the improvements
added between 0.5 and 0.6 release. Definitelly a step in a right direction.

## Summary

That's it. That's the entire lesson. If you want more free lessons
how to improve your Rails codebase, subscribe to our mailing list below.
We will regularly send you valuable tips and tricks. 3200 developers already
trusted us.

<%= show_product_inline(item[:newsletter_inside]) %>

## More

Did you like this article? You will definitely find [our Rails books interesting as well](/products) .

<a href="http://controllers.rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="48%" /></a><a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="48%" /></a>
