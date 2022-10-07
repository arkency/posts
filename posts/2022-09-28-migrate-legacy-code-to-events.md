---
created_at: 2022-09-28 12:58:50 0200
author: Łukasz Reszke
tags: ['rails event store', 'event sourcing', 'initial event', 'opening balance', 'ddd']
publish: false
---
# The final trick when moving from CRUD to Event Sourcing 

## From CRUD to EventSourcing
Did you ever wonder how to actually switch the model from the CRUD one to EventSourcing? There's one thing you should consider. The initial event that has to be published for existing data. Also called the opening balance.

<!-- more -->

At some point, one will reach a moment when they're able to switch from the old model to the new one. Well crafted, event sourced aggregate. With 100% mutant coverage. 

But then the questions pop up... How do you migrate data from legacy model to the new aggregate? How should you seed the aggregate with initial event?

## Before you start, you have a decision to make

Basically you have at least two options when it comes to the opening balance. 

The first option is to start with the event that "starts" the life-cycle of your aggregate. If your aggregate is a `BankAccount` that is brought to life by `open` method, which produces `BankAccountOpened` event, you would migrate your legacy model by calling the method to produce this event. You could do that by script, example below 😉.

The second option is a little bit different. Instead of starting with regular event that starts the lifecycle of the aggregate, you can introduce a new one that will be used only for migration. For the initial opening balance. In case of `BankAccount` the opening event could be named `LegacyBankAccountImported`.

Additional, unnecessary work you might say.

This approach has one huge advance. In the future if you have to analyze the stream, you'll be able to distinct aggregates that were migrated from aggregates that were created after the migration. From the debugging perspective this is very useful piece of information. I usually prefer that way.

## Let's deal with the initial event
Once you know which approach you want to follow, you can use a script similar to the one below:
```ruby
def stream_name(aggregate_id)
  "Banking::BankAccount$#{aggregate_id}"
end

legacy_bank_accounts = BankAccount.unscoped

repository = AggregateRoot::Repository.new

legacy_bank_accounts.each do |legacy_bank_account
  aggregate_id = legacy_bank_account.uniq_id
  ApplicationRecord.with_advisory_lock(legacy_bank_account.uniq_id) do
    repository.with_aggregate(Banking::BankAccount.new(aggregate_id), stream_name(aggregate_id)) do |bank_account|
      if (legacy_bank_account.deleted?)
        bank_account.import_deleted(legacy_bank_account.balance, legacy_bank_account.balance_date)
      else
        bank_account.import(legacy_bank_account.balance, legacy_bank_account.balance_date)
      end
    end
  end
end
```

As you can see, the script loads the data with old model. Then it iterates through that data and calls one of the `import` methods (depending on the legacy model state), producing the opening balance for the aggregate. The event in this case is either `LegacyBankAccountImported` or `ClosedLegacyBankAccountImported`

And that's it. You're ready to switch to the new model now 🙌


PS. After the initial migration I recommend to remove the import method. The reason is that you don't want anyone to use the second time after the first usage. It would be a _a little bit_ missleading durning some debugs.