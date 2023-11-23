---
created_at: 2023-11-23 12:26:49 +0100
author: Paweł Pacana
tags: ["rails"]
publish: false
---

# ActiveRecord x Repository

Repository is strictly a tactical pattern in a developer's toolbox. It aims to solve a particular problem of (...).

The problem with ActiveRecord pattern comes from its greatest strength. It's a double-edged sword. Immensely useful in rapid prototyping for a solopreneur. Flexible for a well-knit and disciplined team. Spiralling out of control in a wide organisation and relatively big legacy application.

As of now ActiveRecord::Base has 2137 methods in its public interface. Let alone ActiveRecord::Relation that one usually interacts too.

Performing a larger refactoring that covers all possible usage patterns of such ActiveRecord models becomes a nightmare. Initial checklist includes

- vast query API
- callbacks
- relations and its extensions and the conventional (thus implicit) behaviour
- any gem in the `Gemfile` that extends `ActiveRecord::Base` behaviour by adding new methods and altering behaviours

That's a significant scope to cover. It translates to a certain cost of time, energy and confidence to pull out any change on it in a production system that earns money.

I vaguely remember a few attempts from my colleagues in the past to tame AR API a bit.

`not_activerecord`

There were "query objects" that addressed there "read" part [dej linka].

I also recall a saying from Adam Niesłodowy that you can get 80% benefits out of repository by putting 20% effort into AR like this:

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

It still relies much on the discipline of team. To treat AR methods as "private" and only call this by the application-specific methods.

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
```

Let's dissect this sample a bit.

1. TransactionRepository and its public methods form the API. Since it takes no dependencies and carries no state within its lifecycle, the methods are on the singleton. These are the only ways to access the data and the surface is very limited.
2. TransactionRepository::Record is the ActiveRecord class. We have to point to its database table with `self.table_name`, since its namespace is "unconventional" to the framework mechanics. We may use Record within the repository and to implement its functionality. This constant is not available outside the repository — encapsulation is fulfilled.
3. Return values of repository queries are immutable structs. They're not Relation. They're not AR instances either.

Does this approach have drawbacks? It certainly does. Like everything else it is an art of choice — we're trading off convenience in one area for predictability and maintainability in the other. YMMV.

Where vast AR API shines most is the view layer and in the numerous framework helpers built on top of conventional use. We don't get that with our structs. We might get back some of that by including `ActiveModel::Naming` behaviours.

Does this approach have any alternatives? The CQRS — separations to write and read models, where there was previously one, could be a viable option for some. I especially like that one writes and reads are different, the AR is usually the most desired and my preferred vehicle for implementing SQL read models in Rails.
