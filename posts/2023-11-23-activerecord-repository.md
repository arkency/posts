---
created_at: 2023-12-28 16:00:00 +0100
author: Paweł Pacana
tags: ["rails"]
publish: true
---


# Repository implementation on ActiveRecord

In its essence, a Repository separates domain objects from how they're persisted and provides a limited interface to access them. It's a tactical pattern described with far more words by [Fowler](https://martinfowler.com/eaaCatalog/repository.html) and [Evans](https://www.domainlanguage.com) than I'd like to include in this introduction.
It stands in complete opposition to what [ActiveRecord](https://www.martinfowler.com/eaaCatalog/activeRecord.html) pattern promotes. Why bother transforming one into another?  

The problem with ActiveRecord pattern comes from its greatest strength. It's a double-edged sword. Immensely useful in rapid prototyping for a "solopreneur". Flexible for a well-knit and disciplined team. Spiralling out of control in a wide organisation with multiple teams working on a relatively big legacy application.

As of now bare `ActiveRecord::Base` begins with 350 instance methods on its public interface. Add to that 496 methods of `ActiveRecord::Relation` that one usually interacts with. Performing a larger refactoring that covers all possible usage patterns of such ActiveRecord models becomes a nightmare. Initial checklist includes:

- vast query API
- callbacks
- relations, its extensions and the conventional behaviour
- gems in the `Gemfile` that extend `ActiveRecord::Base` — adding new methods and altering behaviours

That's a significant scope to cover. It translates to a certain cost of time, energy and confidence to pull out any change on it in a production system that earns money.

I remember a few past attempts from my colleagues to control the scope of ActiveRecord surfaced in larger codebases.
There was the [not_activerecord](https://github.com/paneq/not_activerecord) to help express the boundaries. There were various approaches to [query](https://codeclimate.com/blog/7-ways-to-decompose-fat-activerecord-models) [objects](https://thoughtbot.com/blog/a-case-for-query-objects-in-rails) that addressed the read part.

I also vaguely recall a quote from [Adam Pohorecki on a DRUG meetup](https://adam.pohorecki.pl/blog/2013/06/27/bogus-talk-at-drug/) that you can get 80% benefits out of Repository by putting 20% effort into shaping ActiveRecord like this:

```ruby
class Transaction
  def self.of_id(id)
    find(id)
  end

  def self.last_not_pending_of_user_id(user_id)
    where.not(status: "pending").where(user_id: user_id).order(:id).last
  end
end
```

It relies very much on the discipline of team — to treat `ActiveRecord::Base` methods as "private" and only access the model by the application-specific class methods.

This the repository I'd make today, without any external dependencies in the framework you already have:

```ruby
class TransactionRepository
  class Record < ActiveRecord::Base
    self.table_name = "transactions"
  end
  private_constant :Record

  Transaction = Data.define(Record.attribute_names.map(&:to_sym))

  class << self
    def of_id(id)
      as_struct(Record.find(id))
    end

    def last_not_pending_of_user_id(user_id)
      as_struct(Record.where.not(status: "pending").where(user_id: user_id).order(:id).last)
    end

    private

    def as_struct(record)
      Transaction.new(**record.attributes.symbolize_keys)
    end
  end
end
```

Let's dissect this sample a bit.

1. `TransactionRepository` and its public methods form the API. Since it takes no dependencies and carries no state within its lifecycle, the methods are on the singleton. These are the only ways to access the data and the surface is very limited.
2. `TransactionRepository::Record` is the ActiveRecord class. We have to point to its database table with `self.table_name`, since its namespace is "unconventional" to the framework mechanics. We may use `Record` within the repository and to implement its functionality. This constant is not available outside the repository — encapsulation is fulfilled.
3. Return values of repository queries are immutable structs. They're not `ActiveRecord::Relation`. They're not `ActiveRecord::Base` instances either.

Does this approach have drawbacks? It certainly does. Like everything else it's an art of choice. We're trading convenience off in one area for predictability and maintainability in the other. YMMV.

Where vast ActiveRecord surface shines the most is the view layer and the numerous framework helpers built on top of it. We don't get that benefits with our structs. We might get back some of them by including `ActiveModel::Naming` behaviours.

Does this approach have any alternatives? The CQRS — a separation of write and read models, where there was previously one, could be a viable option for some. Given that writes and reads are implemented and optimised differently, the ActiveRecord fits the read part perfectly. It is my preferred vehicle to implement Read Model on top of denormalised SQL database tables in Rails.
