---
title: "Mastering Rails Validations - Objectify"
created_at: 2014-05-08 20:05:51 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter: :arkency_form
tags: [ 'objectify', 'validation', 'context', 'rails', 'activemodel', 'activerecord' ]
---

<p>
  <figure>
    <img src="<%= src_fit("rails-validations-objectify/objectify.jpg") %>" width="100%">
  </figure>
</p>

In my previous blogpost I showed you
[how Rails validations might become context dependent](/2014/04/mastering-rails-validations-contexts/)
and a few ways how to handle such situation. However none of them were perfect
because our object had to become context-aware. The alternative solution that
I would like to show you now is to extract the validations rules outside, making
our validated object lighter.

<!-- more -->

## Not so far from our comfort zone

For start we are gonna use the trick with `SimpleDelegator` (we use it sometimes in
our [Fearless Refactoring: Rails Controllers](http://rails-refactoring.com/)
book as an intermediary step).


```
#!ruby
class UserEditedByAdminValidator < SimpleDelegator
  include ActiveModel::Validations

  validates_length_of :slug, minimum: 1
end
```

```
#!ruby
user = User.find(1)
user.attributes = {slug: "summertime-blues"}

validator = UserEditedByAdminValidator.new(user)
if validator.valid?
  user.save!(validate: false)
else
  puts validator.errors.full_messages
end
```

So now you have external validator that you can use in one context and
you can easily create another validator that would validate different
business rules when used in another context.

The context in your system can be almost everything. Sometimes the
difference is just _create_ vs _update_. Sometimes it is
in _save as draft_ vs _publish as ready_. And sometimes it based on the
user role like _admin_ vs _moderator_.

## One step further

But let's go one step further and drop the nice DSL-alike
methods such as [`validates_length_of`](http://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html#method-i-validates_length_of)
that Rails used to bought us and that we all love, to see what's [beneath them](https://github.com/rails/rails/blob/fe49f432c9a88256de753a3f2263553677bd7136/activemodel/lib/active_model/validations/length.rb#L119).

```
#!ruby
class UserEditedByAdminValidator < SimpleDelegator
  include ActiveModel::Validations

  validates_with LengthValidator, attributes: [:slug], minimum: 1
end
```

The DSL-methods from [`ActiveModel::Validations::HelperMethods`](http://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html)
are just tiny wrappers for a slightly more object oriented validators.
And they just convert first argument to `Array` value of `attributes` key in a `Hash`.

## Almost there

When you dig deeper you can see that one of
[`validates_with`](http://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates_with)
responsibilities is to actually finally [create an **instance** of validation
rule](https://github.com/rails/rails/blob/bdf9141c039afc7ce56d6c69cfe50b60155e5359/activemodel/lib/active_model/validations/with.rb#L89).

```
#!ruby
class UserEditedByAdminValidator < SimpleDelegator
  include ActiveModel::Validations

  validate LengthValidator.new(attributes: [:slug], minimum: 1)
end
```

Let's create an instance of such rule ourselves and give it a **name**.

## Rule as an object

We are going to do it by simply assigning it to a constant.
That is one, really global name, I guess :)

```
#!ruby
SlugMustHaveAtLeastOneCharacter =
  ActiveModel::Validations::LengthValidator.new(
    attributes: [:slug],
    minimum: 1
  )

class UserEditedByAdminValidator < SimpleDelegator
  include ActiveModel::Validations

  validate SlugMustHaveAtLeastOneCharacter
end
```

Now you can share some of those rules in different validators
for different contexts.

## Reusable rules, my way

The rules:

```
#!ruby
SlugMustStartWithU =
  ActiveModel::Validations::FormatValidator.new(
    attributes: [:slug],
    with: /\Au/
  )

SlugMustHaveAtLeastOneCharacter =
  ActiveModel::Validations::LengthValidator.new(
    attributes: [:slug],
    minimum: 1
  )

SlugMustHaveAtLeastThreeCharacters  =
  ActiveModel::Validations::LengthValidator.new(
    attributes: [:slug],
    minimum: 3
  )
```

Validators that are using them:

```
#!ruby
class UserEditedByAdminValidator < SimpleDelegator
  include ActiveModel::Validations

  validate SlugMustStartWithU
  validate SlugMustHaveAtLeastOneCharacter
end

class UserEditedByUserValidator < SimpleDelegator
  include ActiveModel::Validations

  validate SlugMustStartWithU
  validate SlugMustHaveAtLeastThreeCharacters
end
```

## or the highway

I could not find an easy way to register multiple **instances**
of validation rules. So below is a bit hacky (although valid) way
to work around the problem.

It gives us a nice ability to group common rules in Array and add
or subtract other rules.

Rules definitions:

```
#!ruby

format_validator = ActiveModel::Validations::FormatValidator
length_validator = ActiveModel::Validations::LengthValidator

class SlugMustStartWithU < format_validator
  def initialize(*)
    super(attributes: [:slug], with: /\Au/)
  end
end

class SlugMustEndWithZ < format_validator
  def initialize(*)
    super(attributes: [:slug], with: /z\Z/)
  end
end

class SlugMustHaveAtLeastOneCharacter < length_validator
  def initialize(*)
    super(attributes: [:slug], minimum: 1)
  end
end

class SlugMustHaveAtLeastThreeCharacters < length_validator
  def initialize(*)
    super(attributes: [:slug], minimum: 5)
  end
end
```

Validators using the rules:

```
#!ruby
CommonValidations = [SlugMustStartWithU, SlugMustEndWithZ]

class UserEditedByAdminValidator < SimpleDelegator
  include ActiveModel::Validations

  validates_with *(CommonValidations +
    [SlugMustHaveAtLeastOneCharacter]
  )
end

class UserEditedByUserValidator < SimpleDelegator
  include ActiveModel::Validations

  validates_with *(CommonValidations +
    [SlugMustHaveAtLeastThreeCharacters]
  )
end
```

## Cooperation with rails forms

The previous examples won't cooperate nicely with Rails features expecting
list of errors validations on the validated object, because as I showed in
first example, the `#errors` that are filled are defined on the
validator object.


```
#!ruby
validator = UserEditedByAdminValidator.new(user)
unless validator.valid?
  puts validator.errors.full_messages
end
```

But you can easily overwrite the
`#errors` that come from [including `ActiveModel::Validations`](http://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-errors),
by delegating them to the validated object, which in our case
is `#user`.

```
#!ruby
class UserEditedByAdminValidator
  include ActiveModel::Validations

  delegate :slug, :errors, to: :user

  def initialize(user)
    @user = user
  end

  validates_with *(CommonValidations +
    [SlugMustHaveAtLeastOneCharacter]
  )

  private
  attr_reader :user
end
```

## What next?

That was a brief introduction to the more object oriented aspects of rails
validations. Subscribe to our newsletter below if you don't want to miss our next
blogpost that are going to be about problems with refactoring in rails,
active record aggregates, another part on validations problems and service
objects. We have plenty of ideas for our next posts.

You might also want to read some of our other popular blogposts ActiveRecord-related:

* [3 ways to do eager loading (preloading) in Rails 3 & 4](/2013/12/rails4-preloading/)
* [Single Table Inheritance - problems and solutions](/2013/07/sti/)

## More

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://controllers.rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/async-remote/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
