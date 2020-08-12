---
created_at: 2016-10-11 16:43:59 +0200
publish: true
author: Jakub Rozmiarek
tags: [ 'domain event', 'ddd', 'rails_event_store', 'payments', 'e-commerce' ]
---

# How we save money by using DDD and Process Managers in our Rails app

It's obvious that e-commerce businesses depend on an ability to sell goods or services. If an e-commerce platform is unable to sell, even temporarily, it becomes useless. It suffers from short-term revenue loss, but also it appears as untrustworthy to both it's customers and merchants.

<!-- more -->

Unfortunately only the biggest players can afford to become an independent payment service provider. All other platforms have to depend on external providers and these providers have their own problems: infrastructure failures, errors in code, DDOS attacks etc. To ensure the ability to operate a platform needs at least two independent payment providers. There are numerous interesting challenges related to having more than one payment provider, but let's focus on one of them only: how to detect that a gateway is failing and be able to use another one instead.

One simple yet effective solution is to use a process manager that reacts to a set of business events, maintains its internal state and makes a decision to switch to the backup gateway when some condition is met.

Let's assume the system publishes these business events:

* `PaymentSucceeded`              - published after a payment ends with a success
* `PaymentFailed`                 - published after payment is declined
* `RemoteTransactionCreateFailed` - in some of the gateways it's required to register a payment first, only then a customer can be redirected to a payment page

Each of these business events include `payment_provider_identifier` in their data so the information is available which provider was related to the event. With these types of events it's possible to detect if there is a problem with the payment gateway that is currently in use. To achieve this a process manager can be used. It will react to these events and keep track of a number of failures. If the number exceeds a certain threshold a command is issued to switch to a backup provider:

```ruby
module Payments
  class SwitchToFallbackProvider
    include CommandBusInjector

    class State < ActiveRecord::Base
      self.table_name = "switch_to_fallback_provider"

      def self.purge(payment_provider_identifier)
        where(
          payment_provider_identifier: payment_provider_identifier
        ).update_all(failed_payments_count: 0)
      end

      def self.failures_count(payment_provider_identifier)
        find_by(payment_provider_identifier: payment_provider_identifier).
          failed_payments_count
      end
    end

    def self.perform(fact)
      new.call(fact)
    rescue => e
      ErrorReporting.notify(e)
      raise
    end

    def initialize(fallback_configuration:)
      @fallback_configuration = fallback_configuration
    end

    def call(fact)
      data = fact.data.symbolize_keys
      return if fallback_configuration.nil?


      case fact
        when PaymentEvents::PaymentSucceeded
          purge_state(data)
        when PaymentEvents::PaymentFailed, PaymentEvents::CreateRemoteTransactionFailed
          payment_failed(data)
          state = process_state(data, fallback_configuration)
          if is_critical?(state)
            send_command(data)
            purge_state(data)
          end
      end
    end

    private

    attr_reader :fallback_configuration

    def process_state(data, fallback_configuration)
      count = State.failures_count(data[:payment_provider_identifier])
      count > fallback_configuration.max_failed_payments_count ? "critical" : "normal"
    end

    def purge_state(data)
      State.purge(data[:payment_provider_identifier])
    end

    def payment_failed(data)
      record = State.lock.find_or_create_by(
        payment_provider_identifier: data[:payment_provider_identifier]
      )
      State.increment_counter(:failed_payments_count, record.id)
    rescue ActiveRecord::RecordNotUnique
      retry
    rescue ActiveRecord::StatementInvalid => exc
      if exc.message =~ /Deadlock found/
        retry
      else
        raise
      end
    end

    def is_critical?(state)
      state == "critical"
    end

    def send_command(data)
      command = Payments::SwitchToFallbackPaymentProvider.new(
        payment_provider_identifier: data[:payment_provider_identifier],
      )
      command_bus.(command)
    end
  end
end
```

Let's trace what the process manager does when one of the events it's subscribed to happens.

After a failure, when `PaymentFailed` or `CreateRemoteTransactionFailed` occurs the process manager finds a related `State` record that keeps a current number of failures for the provider and increases the counter.
Next it checks for the current state. If the number of failures defined in configuration wasn't exceeded the state is not critical so nothing more happens.
If the state is critical a command is sent to the command bus that triggers provider switch. A command handler takes care of it and also notifies appropriate people about the fact. Then the counter is reset.

When there was a successful payment and `PaymentSucceeded` was published it just finds the state record and nullifies the counter.

To sum up: if too many problems pile up it makes a decision to switch to a backup provider.

Some may argue that failed payment isn't actually a failure, but experience with payment gateways shows that it's a common problem when a provider seem to work normally but all or most of the payments are declined because for example, an underlying acquirer is having issues.

Of course, this solution is prone to false-positives. It can happen that a group of customers have their payments declined because lack of funds etc. and no successful payment happens in the meantime. The process manager records it as a problem with payment provider and triggers a switch.
However, in platforms with heavy traffic it's very unlikely. And even if it does happen it's still better than the inability to sell goods for a period of time before someone notices and manually selects a backup gateway.

## Did you like it?

Make sure to check our [books](/products)
and upcoming [Smart Income For Developers Bundle](http://www.smartincomefordevelopers.com/).
