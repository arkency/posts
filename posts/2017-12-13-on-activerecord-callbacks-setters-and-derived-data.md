---
title: "On ActiveRecord callbacks, setters and derived data"
created_at: 2017-12-13 16:02:52 +0100
publish: true
author: Robert Pankowecki
tags: ['ddd', 'setters', 'rails', 'ruby', 'derived', 'active record']
newsletter: arkency_form
img: "rails-active-record-derrived-data-columns-attributes/dervied.png"
---

We've already written in Arkency [a few times](/2016/01/drop-this-before-validation-and-use-method/) [about callbacks](/2016/02/using-anonymous-modules-and-prepend-to-work-with-generated-code/) [alternatives in Rails](/2016/05/domain-events-over-active-record-callbacks/) and what kind of [problems you can expect from them](https://medium.com/planet-arkency/the-biggest-rails-code-smell-you-should-avoid-to-keep-your-app-healthy-a61fd75ab2d3). But I still see them being used in the wild in many scenarios so why not write about this topic a bit one more time with different examples.

<!-- more -->

## Double method invocation from a controller

```ruby
class Controller
  def update
    @cart = Cart.find(params[:id])
    @cart.update_attributes!(...)
    @cart.update_tax
    head :ok
  end
end
```

This is a pattern that I've seen quite often. Predefined (existing) methods from `ActiveRecord::Base` are used to set some attributes. Often with the combination of `accepts_nested_attributes_for` being used to edit some objects deeper in the tree.

And then derived-data must be recomputed such as maybe taxes, maybe sums, counters, discounts, it varies between applications. An example can be that sales tax in US depends on the shipping address. So when you set it, you would like to have taxes recalculated (in `Order`, `Sale`, `Cart`, or whatever you call it in your app).

The usual reason why those calculations are kept in a database is that we don't want them to change in the future when prices or taxes or discount amounts change etc. So we want to compute and store the derived data based on current values. The other reason is that it might make calculating reports on DB faster and/or easier.

In such case instead of using `update_attributes!` or `attributes=` to set the address and then calling `update_tax` to trigger recalculations, it's better to have a single, public, intention revealing method such as `shipping_address=` setter.

I must say that having a public interface, in which no matter the order of calling methods or their arguments, I always end with a correct state (or an exception clearly indicating an incorrect usage of the object), is a must-have for me. Write your objects so that either the order does not matter, or you prevent the wrong order by keeping an internal state. I believe the word I am looking for is _commutative_.

It also makes refactoring flows much much easier. If you decide to change your checkout process so that you provide discount before or after the address, it won't matter because your code will always properly recalculate the derived-data. If you decide to split a big screen which allowed changing 10 values into 2 smaller screens you will feel safe things still work just fine.

## Callback in a model for re-calculating values

Another typical example looks like this:

```ruby
class Order
  before_save :set_amount

  def add_line(...)
    # ...
  end

  private

  def set_amount
    self.amount = line_items.map(&:amount).sum
  end
end
```

It's the same issue as before; just automated a little bit more, because when you call `save!` the method will get called automatically. But you still can't write your tests like:

```ruby
order.add_line(product)
expect(order.amount).to eq(product.price)
```

Instead, you need to trigger re-computation manually or save:

```ruby
order.add_line(product)
order.save!
expect(order.amount).to eq(product.price)
```

```ruby
order.add_line(product)
order.set_amount # can't be private
expect(order.amount).to eq(product.price)
```

which is no fun at all (at least for me).

How can you avoid it? Add meaningful, intention-revealing methods which you are going to use such as `add_line`, `remove_line`, `update_line` etc which will re-compute derived data such as `amount` or `tax`. Make those domain operations explicit instead of hiding them somewhere in callbacks. Remember that you can often overwrite Rails setters or getters to call `super` and then continue with your job.

```ruby
class Wow < ActiveRecord::Base
  def column_1=(val)
    super(val)
    self.sum = column_1 + column_2
  end

  def column_2=(val)
    super(val)
    self.sum = column_1 + column_2
  end
end
```

This is especially useful when you have many calculations that need to be evaluated again.

```ruby
class Wow < ActiveRecord::Base
  def column_1=(val)
    super(val)
    compute_derived_calculations
  end

  def column_2=(val)
    super(val)
    compute_derived_calculations
  end

  private

  def compute_derived_calculations
    self.sum = column_1 + column_2
    self.discounted = sum * percentage_discount
    self.tax = (sum - discounted) * 0.02
    self.total = sum - discounted + tax
  end
end
```

Today I had 6 such values 😉.

## Why do we deal with those problems?

I believe the root problem of those issues is that by default there are so many `public` methods in `ActiveRecord` subclasses. Every attribute, every association, all of that is public and anyone can change it from anywhere. In a situation like that, you as a developer need to be responsible for making the real API used by your application smaller, limited and predictable.

I gotta say when I watched some code from other languages (or maybe frameworks would be a more accurate depiction as this is not Ruby's fault) it is much more common to have encapsulated methods which protect rules and trigger computing of derived data. In Rails, it's rather common to set anything in columns and worry about it during validation phase or when it's time to save the object and heavily rely on callbacks for that. I prefer my objects to be OK all the time.

## far-far-reaching analogy

I hope I won't lose you here. But do you use React.js? Do you know how it is best when `render` is a pure function based only on component's `state` and `props`? The result of calling `render` in React is derived data which should always give the same result for the same arguments.

You can think about methods like these in the same way:

```ruby
  def compute_derived_calculations
    self.sum = column_1 + column_2
    self.discounted = sum * percentage_discount
    self.tax = (sum - discounted) * 0.02
    self.total = sum - discounted + tax
  end
```

There are values you can set such as `column_1` or `column_2`

```ruby
  def column_2=(val)
    super(val)
    compute_derived_calculations
  end
```

And there are derived values that you get such as `sum`, `discounted`, `tax` and `total` which are automatically recomputed. I am sure you that is obvious to you, it's just `ActiveRecord` does not make it easy for you at all, so we need to make some effort.

## It's just about cohesive aggregates

If you follow us and read the [Domain-Driven Design](/domain-driven-rails/) ebook you might recognize that the refactorings that I mention, they bring us closer to having nice _Aggregates_ which protect their internal rules all the time.

## More about this

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our everyday struggles and solutions for building maintainable Rails apps which don't surprise you.

Also worth reading:

* [Drop this before validation and use a method](/2016/01/drop-this-before-validation-and-use-method/)
* [Domain Events over ActiveRecord callbacks](/2016/05/domain-events-over-active-record-callbacks/)
* [The biggest Rails code smell you should avoid to keep your app healthy](https://medium.com/planet-arkency/the-biggest-rails-code-smell-you-should-avoid-to-keep-your-app-healthy-a61fd75ab2d3)
* [Application Services - 10 common doubts answered](https://blog.arkency.com/application-service-ruby-rails-ddd/)

Check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.
