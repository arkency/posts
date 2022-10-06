---
created_at: 2022-09-28 12:58:50 0200
author: Łukasz Reszke
tags: []
publish: false
---

Did you ever wonder how to get from CRUD to EventSourcing? There's one thing you should consider. The opening balance.

At some point, one will reach a moment when they're able to switch from the old model to the new one. Well crafted, event sourced aggregate, with 100% mutant coverage. 

But then the question pops up... How do you migrate data from legacy model to the new aggregate? How should you seed the aggregate with initial event?

## Before you start, you have a decision to make

Basically you have at least two options when it comes to the opening balance. 

The first option is to start with the event that "starts" the life-cycle of your aggregate. If your aggregate is a `BankAccount` that is brought to life by `OpenBankAccount` method, which produces `BankAccountOpened` event, you would migrate your legacy model by calling the method to produce this event. You could do that by script, example below :wink:.

The second option is a little bit different. Instead of starting with regular event that starts the lifecycle of the aggregate, you can introduce a new one that will be used only for migration. For the initial opening balance. In case of `BankAccount` the opening evnet could be named `LegacyBankAccountImported`.

Additional, unnecessary work you might say.

This approach has one huge advance. In the future if you have to analyze the stream, you'll be able to distinct aggregates that were migrated from aggregates that were created after the migration. From the debugging perspective this is very useful piece of information. I usually prefer that way.

## How to migrate from legacy model to the new one?
Once you know which approach you want to follow, it's quite simple. All you need is script that is similar to the one below:
```ruby
def stream_name(aggregate_id)
  "Banking::BankAccount$#{aggregate_id}"
end

legacy_bank_accounts = BankAccount.unscoped

repository = AggregateRoot::Repository.new

legacy_bank_accounts.each do |legacy_bank_account|
  aggregate_id = legacy_bank_account.uniq_id
  repository.with_aggregate(Banking::BankAccount.new(aggregate_id), stream_name(aggregate_id)) do |bank_account|
    if (legacy_bank_account.deleted?)
      bank_account.import_deleted(legacy_bank_account.balance, legacy_bank_account.balance_date)
    else
      bank_account.import(legacy_bank_account.balance, legacy_bank_account.balance_date)
    end
  end

  p '.'

end
```

As you can see, the script loads the data with old model. Then it iterates through that data and calls one of the `import` methods (depending on the legacy model state) producing the opening balance for the aggregate.

And that's it. You're ready to switch to the new model now :v:


PS. After the initial migration I recommend to remove the import method. The reason is that you don't want anyone to use the second time after the first usage. It would be a _a little bit_ missleading durning some debugs.