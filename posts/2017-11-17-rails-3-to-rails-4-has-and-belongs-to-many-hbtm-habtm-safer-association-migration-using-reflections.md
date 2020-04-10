---
title: "Safely migrating has_and_belongs_to_many associations to Rails 4"
created_at: 2017-11-17 10:54:27 +0100
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'active record' ]
newsletter: arkency_form
---

During recent days I've been migrating a _senior_ Rails application from Rails 3 to Rails 5. As part of the process, I was dealing with `has_and_belongs_to_many` associations.

<!-- more -->

As you can read in the official [migration guide](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-3-2-to-rails-4-0-active-record)

_Rails 4.0 has changed to default join table for `has_and_belongs_to_many` relations to strip the common prefix off the second table name. Any existing `has_and_belongs_to_many` relationship between models with a common prefix must be specified with the `join_table` option._ For example:

```ruby
CatalogCategory < ActiveRecord::Base
  has_and_belongs_to_many :catalog_products,
    join_table: 'catalog_categories_catalog_products'
end

CatalogProduct < ActiveRecord::Base
  has_and_belongs_to_many :catalog_categories,
    join_table: 'catalog_categories_catalog_products'
end
```

The application that I was working on has around 50 `has_and_belongs_to_many` associations in a codebase and I did not want to check manually if the `join_table` was properly inferred or not (and the tests don't cover everything in the app).

I decided to use built-in Rails reflection mechanism for associations and check it. Here is how:

* I temporarily (for the time of running next script) set the code to eager load in `config/development.rb`

    ```ruby
    config.cache_classes = true
    config.eager_load = true
    ```

    It was necessary for `ActiveRecord::Base.descendants` to find out all descending classes. They needed to be loaded.

* I executed the same script on Rails 3 and Rails 4 and saved its output in `rails3.txt` and `rails4.txt` file.

    ```ruby
    ActiveRecord::Base.descendants.sort_by(&:name).each do |klass|
      klass.reflections.select do |_name, refl|
        refl.macro == :has_and_belongs_to_many
      end.each do |name, refl|
        if Rails::VERSION::MAJOR == 3
          puts  [
            klass.name,
            name,
            refl.options[:join_table]
          ].inspect
        else
          puts [
            klass.name,
            name,
            refl.join_table
          ].inspect
        end
      end
    end
    ```

* I used `diff` to compare `rails3.txt` and `rails4.txt` files. The output looked like:

    ```
    < ["Bundle", :products, "bundles_products"]
    ---
    > ["Bundle", :products, "discounts_products"]
    ```

    Surprisingly I did not find any difference related to exactly what the changelog was talking about. But I still found a difference and the default was inferred differently due to the inheritance.

    ```ruby
     class Bundle < Discount
       has_and_belongs_to_many :products
    ```

    All I had to do, was to make the `join_table` explicit:

    ```ruby
     class Bundle < Discount
       has_and_belongs_to_many :products,
       join_table: "bundles_products"
    ```

    As this keeps working properly in Rails 3 (it's just explicit over implicit), I could deploy this change to production even before upgrading Rails.

If you are interested in the ability to dynamically examine the associations and aggregations of Active Record classes and objects read more about the available methods in [ActiveRecord::Reflection::ClassMethods documentation](http://api.rubyonrails.org/classes/ActiveRecord/Reflection/ClassMethods.html).

If you need help with your Rails app, we are [available for one project](/assets/misc/How-can-Arkency-help-you.pdf) since November, 27th.

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our everyday struggles and solutions for building maintainable Rails apps which don't surprise you.

Also worth reading:

* [Two ways for testing eager-loading of ActiveRecord associations](/two-ways-for-testing-preloading-eager-loading-of-activerecord-association-in-rails/)
* [The === (case equality) operator in Ruby explained](/the-equals-equals-equals-case-equality-operator-in-ruby/)
* [What I learnt from Jason Fried about running a remote/async software company](/what-i-learnt-from-jason-fried-about-running-a-remote-slash-async-software-company/)

Check out our latest book [Domain-Driven Rails](/domain-driven-rails/). Especially if you work with big, complex Rails apps.
