---
title: "My first 10 minutes with EventIDE"
created_at: 2017-08-03 17:01:24 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ddd', 'eventide' ]
newsletter: :arkency_form
---

* https://eventide-project.org/
* https://github.com/eventide-examples/account-component
* Part of https://ruby-onward.org/ initiative
  * same as https://github.com/arkency/rails_event_store

<!-- more -->

### File structure

My first thought was that there is quite interesting structure of directories:

```
lib/
├── account
│   ├── client
│   │   ├── controls.rb
│   │   └── namespace.rb
│   └── client.rb
├── account_component
│   ├── account.rb
│   ├── commands
│   │   ├── command.rb
│   │   └── withdraw.rb
│   ├── consumers
│   │   ├── commands
│   │   │   └── transactions.rb
│   │   ├── commands.rb
│   │   └── events.rb
│   ├── controls
│   │   ├── account.rb
│   │   ├── commands
│   │   │   ├── close.rb
│   │   │   ├── deposit.rb
│   │   │   ├── open.rb
│   │   │   └── withdraw.rb
│   │   ├── customer.rb
│   │   ├── events
│   │   │   ├── closed.rb
│   │   │   ├── deposited.rb
│   │   │   ├── opened.rb
│   │   │   ├── withdrawal_rejected.rb
│   │   │   └── withdrawn.rb
│   │   ├── id.rb
│   │   ├── message.rb
│   │   ├── money.rb
│   │   ├── position.rb
│   │   ├── replies
│   │   │   └── record_withdrawal.rb
│   │   ├── stream_name.rb
│   │   ├── time.rb
│   │   └── version.rb
│   ├── controls.rb
│   ├── handlers
│   │   ├── commands
│   │   │   └── transactions.rb
│   │   ├── commands.rb
│   │   └── events.rb
│   ├── load.rb
│   ├── messages
│   │   ├── commands
│   │   │   ├── close.rb
│   │   │   ├── deposit.rb
│   │   │   ├── open.rb
│   │   │   └── withdraw.rb
│   │   ├── events
│   │   │   ├── closed.rb
│   │   │   ├── deposited.rb
│   │   │   ├── opened.rb
│   │   │   ├── withdrawal_rejected.rb
│   │   │   └── withdrawn.rb
│   │   └── replies
│   │       └── record_withdrawal.rb
│   ├── projection.rb
│   ├── start.rb
│   └── store.rb
└── account_component.rb
```


I was not sure where to look first to find the business logic but from the names you can quickly figure out what the project is about.

I looked at `start.rb` but that didn't tell me much:

```
module AccountComponent
  module Start
    def self.call
      Consumers::Commands.start('account:command')
      Consumers::Commands::Transactions.start('accountTransaction')
      Consumers::Events.start('account')
    end
  end
end
```

I could not easily navigate to an interesting place in RubyMine so I just started poking around.

### Commands

The first place that I felt I am on a known ground was around files in `lib/account_component/messages/commands/` which include commands such as:

```
#!ruby
# lib/account_component/messages/commands/deposit.rb
module AccountComponent
  module Messages
    module Commands
      class Deposit
        include Messaging::Message

        attribute :deposit_id, String
        attribute :account_id, String
        attribute :amount, Numeric
        attribute :time, String
      end
    end
  end
end
```

commands are for telling services/handlers what to do. They're just data structures. That's important. So we have our input. Let's see where it is coming into.

### Handlers

In `lib/account_component/handlers/commands.rb` and `lib/account_component/handlers/commands/transactions.rb` you can find handlers and the logic for processing those commands. I won't show the whole code. It's pretty interesting. Just the most important snippets.

```
#!ruby

  category :account

  handle Open do |open|
    account_id = open.account_id

    account, version = store.fetch(account_id, include: :version)

    if account.open?
      logger.info(tag: :ignored) { "Command ignored (Command: #{open.message_type}, Account ID: #{account_id}, Customer ID: #{open.customer_id})" }
      return
    end

    time = clock.iso8601

    opened = Opened.follow(open)
    opened.processed_time = time

    stream_name = stream_name(account_id)

    write.(opened, stream_name, expected_version: version)
  end
```

What I recognized immediately was:

* getting account in its current version based on historically stored domain events.

```
#!
account, version = store.fetch(account_id, include: :version)
```

* saving new domain events in the account stream using optimistic concurrency (we expect the version has not changed since we got it last time)

```
write.(opened, stream_name, expected_version: version)
```

The other interesting parts are:

* What seems to me like preserving idempotent behavior. Don't do anything if asked to `Open` account when the account is already `open?`

```
#!ruby
if account.open?
  return
end
```

* building new domain event with all the data

```
#!ruby
opened = Opened.follow(open)
opened.processed_time = time
```

But at that point I could not easily navigate to `follow` method to check its implementation. I will probably find out later how it works.

### Events

Anyway `Opened` is a domain event. Let's see it:

```
#!ruby
# lib/account_component/messages/events/opened.rb
module AccountComponent
  module Messages
    module Events
      class Opened
        include Messaging::Message

        attribute :account_id, String
        attribute :customer_id, String
        attribute :time, String
        attribute :processed_time, String
      end
    end
  end
end
```

> Events are written to streams. All of the events for a given account are written to that account's stream. If the account ID is 123, the account's stream name is account-123, and all events for the account with ID 123 are written to that stream.

Classic thing if you already learned about event sourcing basics.

### Handlers again

Here is an interesting thing:

> A handler might also respond (or react) to events by other services, or it might respond to events published by its own service (when a service calls itself).


```
#!ruby
# lib/account_component/handlers/events.rb

  handle Withdrawn do |withdrawn|
    return unless withdrawn.metadata.reply?

    record_withdrawal = RecordWithdrawal.follow(withdrawn, exclude: [
      :transaction_position,
      :processed_time
    ])

    time = clock.iso8601
    record_withdrawal.processed_time = time

    write.reply(record_withdrawal)
  end
```

### Replies

Events and commands are messages in EventIDE. Apparently there is also one more class of messages: Replies.

```
#!ruby
# lib/account_component/messages/replies/record_withdrawal.rb
module AccountComponent
  module Messages
    module Replies
      class RecordWithdrawal
        include Messaging::Message

        attribute :withdrawal_id, String
        attribute :account_id, String
        attribute :amount, Numeric
        attribute :time, String
        attribute :processed_time, String
      end
```

I haven't yet figured out what Replies are used for. It seems interesting.

### File structure

So far we haven't looked at these files in `controlers` directory. I wonder what's there.

```
│   ├── controls
│   │   ├── account.rb
│   │   ├── commands
│   │   │   ├── close.rb
│   │   │   ├── deposit.rb
│   │   │   ├── open.rb
│   │   │   └── withdraw.rb
│   │   ├── customer.rb
│   │   ├── events
│   │   │   ├── closed.rb
│   │   │   ├── deposited.rb
│   │   │   ├── opened.rb
│   │   │   ├── withdrawal_rejected.rb
│   │   │   └── withdrawn.rb
│   │   ├── id.rb
│   │   ├── message.rb
│   │   ├── money.rb
│   │   ├── position.rb
│   │   ├── replies
│   │   │   └── record_withdrawal.rb
│   │   ├── stream_name.rb
│   │   ├── time.rb
│   │   └── version.rb
│   ├── controls.rb
```

### Controls

```
#!ruby
lib/account_component/controls/commands/close.rb
module AccountComponent
  module Controls
    module Commands
      module Close
        def self.example
          close = AccountComponent::Messages::Commands::Close.build

          close.account_id = Account.id
          close.time = Controls::Time::Effective.example

          close
        end
```

```
#!ruby
# lib/account_component/controls/events/withdrawn.rb
module AccountComponent
  module Controls
    module Events
      module Withdrawn
        def self.example
          withdrawn = AccountComponent::Messages::Events::Withdrawn.build

          withdrawn.withdrawal_id = ID.example
          withdrawn.account_id = Account.id
          withdrawn.amount = Money.example
          withdrawn.time = Controls::Time::Effective.example
          withdrawn.processed_time = Controls::Time::Processed.example

          withdrawn.transaction_position = Position.example

          withdrawn
        end
```

```
#!ruby
# lib/account_component/controls/account.rb
module AccountComponent
  module Controls
    module Account
      def self.example(balance: nil, transaction_position: nil)
        balance ||= self.balance

        account = AccountComponent::Account.build

        account.id = id
        account.balance = balance
        account.opened_time = Time::Effective::Raw.example

        unless transaction_position.nil?
          account.transaction_position = transaction_position
        end

        account
      end

      module Closed
        def self.example
          account = Account.example
          account.closed_time = Time::Effective::Raw.example
          account
        end
      end
```

It looks to me like these are helpers that help you build exemplary data, maybe test data. Maybe some kind of builders.