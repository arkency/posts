---
title: "Custom type-casting with ActiveRecord, Virtus and Dryrb"
created_at: 2016-02-29 15:28:50 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'typecasting', 'rails', 'active record', 'virtus', 'dry-rb' ]
newsletter: :arkency_form
---

In [Drop this before validation and just use a setter method](/2016/01/drop-this-before-validation-and-use-method/)
I showed you how to avoid a common pattern of using `before_validation` to
fix the data. Instead I proposed you just overwrite the setter, call your custom logic there
and use `super`. I also showed you [what you can do if you can't easily call super](/2016/02/using-anonymous-modules-and-prepend-to-work-with-generated-code/) .

But sometimes to properly transform the incoming data or attributes you just need
to improve the type-casting logic. And that's it. So let's see how you can add your
custom typecasting rules to a project.

And let's continue with the simple example of stripped string.

<!-- more -->

## Active Record 4.2+

```
#!ruby
class StrippedString < ActiveRecord::Type::String
  def cast_value(value)
    value.to_s.strip
  end
end
```

```
#!ruby
class Post < ActiveRecord::Base
  attribute :title, StrippedString.new
end
```

```
#!ruby
p = Post.new(title: " Use Rails ")
p.title
# => "Use Rails"
```

## Virtus

```
#!ruby
class StrippedString < Virtus::Attribute
  def coerce(value)
    value.to_s.strip
  end
end
```

```
#!ruby
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

```
#!ruby
a = Address.new(city: " Wrocław ")
a.city
# => "Wrocław"
```

## Dry.rb

```
#!ruby
module Types
  StrippedString = Dry::Data::Type.new(->(val){ String(val).strip }, primitive: String)
end
```

```
#!ruby
class Post < Dry::Data::Struct
  attribute :title, Types::StrippedString
end
```

```
#!ruby
p = Post.new(title: " Use dry ")
p.title
# => "Use dry"
```
