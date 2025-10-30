---
created_at: 2025-10-30 15:24:50 +0100
author: Szymon Fiedler
tags: [rails, ruby, legacy]
publish: false
---

# The Joy of a Single-Purpose Class: From String Mutation to Message Composition

Recently I started the process of upgrading rather big Rails application to latest Ruby 3.4. I noticed a lot of warnings related to string literal mutation:

```ruby
warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
```

<!-- more -->

## Ruby has both mutable and immutable strings

In short, that’s the source of this behavior:

> In Ruby 3.4, by default, if a file does not have the magic comment and a string object that was instantiated with a literal gets mutated, Ruby still allows the mutation, but it now issues a warning[^[Ruby: The future of frozen string literals by fxn](https://gist.github.com/fxn/bf4eed2505c76f4fca03ab48c43adc72#ruby-34)]

I was able to notice this early since my colleague [Piotr](https://blog.arkency.com/authors/piotr-jurewicz/) took care about [not tuning out the Ruby deprecation warnings](https://blog.arkency.com/do-you-tune-out-ruby-deprecation-warnings/).

This article won’t be about benefits of freezing string literals, but if you’re curious about this topic, you should read this [gist by FXN](https://gist.github.com/fxn/bf4eed2505c76f4fca03ab48c43adc72) with care and the article about [Past, Present and Future of Frozen String Literal by byroot](https://byroot.github.io/ruby/performance/2025/10/28/string-literals.html) if you want a deep dive into details.

## Problem with string literal mutation in our code

I noticed that there’s noticeable amount of deprecation messages related to modifying future frozen string literals coming from one module. It was the one responsible for producing and delivering Slack messages related to customer support, billing, frauds, etc. All the things that improve day-to-day operations in a serious business. 100+ methods representing messages to be delivered to various channels.

The messages were composed in a few ways:

```ruby
module Slack
  module Billing
	  BILLING_CHANNEL_NAME = 'billing'.freeze
	
	  extend self
	
	  def invoice_sent(invoice)
  	  message = ':postbox: *Invoice sent to customer*'
	    message << " | #{invoice.customer_name}"
	    message << " | #{invoice.customer_email}"
	    message << " | <#{inovice.url}|#{invoice.number}>"
	  
	    send_message(BILLING_CHANNEL_NAME, message)
	  end
	
	  def payment_received(payment)
	    message = payment_text(payment)
	    message.push("\n #{payment_text(payment)}")
	    message.push("\n Invoice: #{payment.invoice_number}")
	    message.push("\n Customer: #{payment.customer_name}")
	  
	    send_message(BILLING_CHANNEL_NAME, message)
	  end

    private
  
    def payment_text(payment)
      text = ':moneybag: *Payment Received*'
      text << " | #{format_amount(payment.amount)}"
      text << " | #{payment.channel}"
    
      text
    end
  
    def format_amount(amount, locale)
      number_to_currency(amount, locale: locale)
    end

    def send_message(channel_name, message)
      Client.deliver_message(channel: channel_name, message: message)
    end
  end
end
```

Respective messages produced would be:

```
:postbox: | *Inovice sent to customer* | Jane Doh | jan.doh@example.com | <https://fancyurl.example.com|KAKADUDU123>
```

and

```
:moneybag: *Payment Received* | $123.45 | Credit card
Invoice: KAKADUDU123
Customer: Jane Doh
```

## Noticing the pattern

After reviewing around 100 methods delivering different messages, I instantly noticed the pattern and thought: _Ok, I can deal with that easily with a help of `Array` and improve this repeatable, manual text decorations like `" | "` or `"\n"`_.

```diff
+ # frozen_string_literal: true
+ 
 module Slack
   module Billing
     BILLING_CHANNEL_NAME = 'billing'.freeze
	
	   extend self
	
	   def invoice_sent(invoice)
-	     message = ':postbox: *Invoice sent to customer*'
-	     message << " | #{invoice.customer_name}"
-	     message << " | #{invoice.customer_email}"
-	     message << " | <#{inovice.url}|#{invoice.number}"
+	     message = [':postbox: *Invoice sent to customer*']
+	     message << "#{invoice.customer_name}"
+	     message << "#{invoice.customer_email}"
+	     message << "<#{inovice.url}|#{invoice.number}>"
	  
-	     send_message(BILLING_CHANNEL_NAME, message)
+	     send_message(BILLING_CHANNEL_NAME, message.join(" | "))
	   end
	
  	 def payment_received(payment)
-      message = payment_text(payment)
-      message.push("\n #{payment_text(payment)}")
-      message.push("\n Invoice: #{payment.invoice_number}")
-      message.push("\n Customer: #{payment.customer_name}")
+	     message = [payment_text(payment)]
+	     message.push("#{payment_text(payment)}")
+	     message.push("Invoice: #{payment.invoice_number}")
+	     message.push("Customer: #{payment.customer_name}")
	  
-      send_message(BILLING_CHANNEL_NAME, messsage)
+ 	   send_message(BILLING_CHANNEL_NAME, message.join("\n")) 
     end

     private
  
     def payment_text(payment)
-      text = ':moneybag: *Payment Received*'
-      text << " | #{format_amount(payment.amount)}"
-      text << " | #{payment.channel}"
+      text = [':moneybag: *Payment Received*']
+      text << "#{format_amount(payment.amount)}"
+      text << "#{payment.channel}"
     
-      text
+      text.join(" | ")
     end
  
     def format_amount(amount, locale)
       number_to_currency(amount, locale: locale)
     end

     def send_message(channel_name, message)
       Slack::Client.deliver_message(channel: channel_name, message: message)
     end
   end
 end
```

What we’ve gained by this refactoring:

1. No string literal mutation, so there will be no warnings on Ruby 3.4 and potential issues in the future
2. Less repeatable code, no artisanal text delimiter crafting
3. We still used the same methods for composing message as both `String` and `Array` provide `<<` and `push` methods. I wanted to keep this code similar to previous implementation without any radical changes so other maintainers would be familiar with it.

## Improve the code

I’m sick of primitive obsession in the codebase. I don’t like all those `Array` related internals exposed, irrelevant in the context of building a message. We operate on a very simple example here, multiply this 50 times, add even more complex methods to that. 

What if we introduced dedicated object which:

* produces strings in an immutable manner
* hides all the separator plumbing as most of the 100+ messages use ` | ` to separate message parts
* deals with empty strings
* has API similar to current implementation
* allows composition like current implementation 

Let’s look at the implementation:

```ruby
# frozen_string_literal: true

module Slack
  class Message
    DELIMITER = ' | '

    def initialize(*parts, delimiter: DELIMITER)
      @delimiter = delimiter
      @message = parts
    end

    def <<(message_part) = @message << message_part
    def to_s = @message.compact_blank.join(@delimiter)

    alias_method :to_str, :to_s
    alias_method :push, :<<
  end
end
```

### Benefits of ActiveSupport

What’s important to notice is the fact that it’s a Rails and we benefit from ActiveSupport` here, specifically:

* [`compact_blank`](https://api.rubyonrails.org/classes/Enumerable.html#method-i-compact_blank) in an explicit manner
* and [`blank?`](https://blog.arkency.com/2017/07/nil-empty-blank-ruby-rails-difference/#_code_blank___code_) in an implicit way as `Object` extension

Otherwise we would need to put a bit more effort into our class:

```ruby
def to_s
  @message
    .compact
    .reject { |part| part.respond_to?(:empty?) && part.empty? }
    .join(@delimiter)
end
```

It could be obviously splitted into private method, but I like the explicitness `compact_blank` provides and I’m fine with using it.

### Pass a single string or multiple as an argument

The `*parts` parameter leverages Ruby's splat operator to automatically collect all positional arguments into an array under `@messages`. This gives us a flexible constructor without forcing callers to wrap arguments in array literals.

```ruby
Slack::Message.new('kaka').to_s
=> "kaka"

Slack::Message.new('kaka', 'dudu').to_s
=> "kaka | dudu"
```

### Append our message using different methods

```ruby
message = Slack::Message.new('kaka')
message << 'dudu'
message.to_s
=> "kaka | dudu"

message = Slack::Message.new('kaka')
message.push 'dudu'
message.to_s
=> "kaka | dudu"
```

### Default delimiter, but still customizable

```ruby
Slack::Message.new('kaka', 'dudu').to_s
=> "kaka | dudu"

Slack::Message.new('kaka', 'dudu’, delimiter: „\n”).to_s
=> "kaka\ndudu"
```

### Compose various `Slack::Message` object with different delimiters:

```ruby
Slack::Message.new('kaka', Slack::Message.new('dudu', 'foo', delimiter: " — ")).to_s
=> "kaka | dudu — foo"

msg = Slack::Message.new('kaka', delimiter: "\n")
msg << Slack::Message.new('dudu')
msg.to_s
=> "kaka\ndudu"
```

The magic happens through the `to_str` alias. When  `@message.join(@delimiter)` is called, Ruby's `Array#join` implicitly calls `to_str` on each element (it would fallback to `to_s` if not defined). Since `to_str` is aliased to `to_s`, nested `Slack::Message` objects get automatically stringified.

This recursive flattening happens transparently because `to_str` signals to Ruby that our [object can be treated as a string in implicit contexts](https://ruby-doc.org/3.4/implicit_conversion_rdoc.html#label-String-Convertible+Objects).


## Final refactoring

```diff
 # frozen_string_literal: true
 
 module Slack
   module Billing
     BILLING_CHANNEL_NAME = 'billing'
	
  	 extend self
	
  	 def invoice_sent(invoice)
-	     message = [':postbox: *Invoice sent to customer*']
-	     message << "#{invoice.customer_name}"
-	     message << "#{invoice.customer_email}"
-	     message << "<#{inovice.url}|#{invoice.number}>"
+	     message = Message.new(':postbox: *Invoice sent to customer*')
+	     message << "#{invoice.customer_name}"
+	     message << "#{invoice.customer_email}"
+	     message << "<#{inovice.url}|#{invoice.number}"
	  
-	     send_message(BILLING_CHANNEL_NAME, message.join(" | "))
+	     send_message(BILLING_CHANNEL_NAME, message)
	   end
	
	   def payment_received(payment)
-	     message = [payment_text(payment)]
-	     message.push("#{payment_text(payment)}")
-	     message.push("Invoice: #{payment.invoice_number}")
-	     message.push("Customer: #{payment.customer_name}")
+	     message = Message.new(payment_text(payment))
+	     message.push("#{payment_text(payment)}")
+	     message.push("Invoice: #{payment.invoice_number}")
+	     message.push("Customer: #{payment.customer_name}")
	  
-      send_message(BILLING_CHANNEL_NAME, messsage.join("\n"))
+   	 send_message(BILLING_CHANNEL_NAME, message)
	   end

     private
  
     def payment_text(payment)
-      text = [':moneybag: *Payment Received*']
-      text << "#{format_amount(payment.amount)}"
-      text << "#{payment.channel}"
+      text = Message.new(':moneybag: *Payment Received*')
+      text << "#{format_amount(payment.amount)}"
+      text << "#{payment.channel}"

-      text.join(" | ")
+      text
     end
  
     def format_amount(amount, locale)
       number_to_currency(amount, locale: locale)
     end

     def send_message(channel_name, message)
-      Slack::Client.deliver_message(channel: channel_name, message: message)
+      Slack::Client.deliver_message(channel: channel_name, message: message.to_s)
     end
   end
 end
```

I can’t remember the last time I had so much joy introducing such a simple, single-purpose class.

## Summary

* The class name `Message` nicely reveals its intent. We’re composing some message here.
* There’s no need for artisanal delimiter orchestration
* Our object composes nicely from different pieces
* Output is predictable and immutable
* `frozen string literal` warnings are gone

