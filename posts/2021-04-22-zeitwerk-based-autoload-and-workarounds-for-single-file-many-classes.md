---
created_at: 2021-04-22T20:51:01.454Z
author: Paweł Pacana
tags: ['rails', 'zeitwerk', 'autoload']
publish: true
---

# Zeitwerk-based autoload and workarounds for single-file-many-classes problem


Rails has deprecated its [classic autoloader](https://guides.rubyonrails.org/autoloading_and_reloading_constants_classic_mode.html) by the release of version 6.1. From now on it by default uses [zeitwerk](https://github.com/fxn/zeitwerk) gem as a basis for new autoloading. The previous autoloader is going to be dropped in future releases. That's good news — the classic autoloader had several, well-documented, but nevertheless tricky [gotchas](https://guides.rubyonrails.org/autoloading_and_reloading_constants_classic_mode.html#common-gotchas). This welcomed change brings back the sanity.

Unfortunately the initial scope of zeitwerk features did not include one, that I'd welcome the most — an ability to host several classes in a single file.

## The Problem

Several years ago I've [described a pattern](https://blog.arkency.com/rails-components-neither-engines-nor-gems/) that we've been using for "components" (or rather a way to express bounded contexts) in Rails apps.

Here's an example of one of such components — the Scanner context. It's a top-level, autoloaded directory in a Rails app. 

```
scanner/
├── lib
│   ├── scanner
│   │   ├── event.rb
│   │   ├── event_db.rb
│   │   ├── domain_events.rb
│   │   ├── scan_tickets_command.rb
│   │   ├── scanner_service.rb
│   │   ├── ticket.rb
│   │   ├── ticket_db.rb
│   │   └── version.rb
│   └── scanner.rb
└── spec
    ├── scan_tickets_command_spec.rb
    ├── scan_tickets_flow_spec.rb
    └── spec_helper.rb
```

```ruby
# config/application.rb

config.paths.add 'scanner/lib', eager_load: true
```

Let's focus on `scanner/lib/scanner/domain_events.rb`. This file hosts several, rather small classes that describe domain events in the Scanner [subdomain](https://medium.com/nick-tune-tech-strategy-blog/domains-subdomain-problem-solution-space-in-ddd-clearly-defined-e0b49c7b586c):

```ruby
# scanner/lib/scanner/domain_events.rb

module Scanner
  class TicketScanned < Fact
    SCHEMA = {
      vendor: String,
      event_id: String,
      barcode: String,
      ticket_type: String,
      scanned_at: Time,
      terminal_name: String
    }
  end

  class TicketAlreadyScanned < Fact
    SCHEMA = {
      vendor: String,
      event_id: String,
      barcode: String,
      ticket_type: String,
      scanned_at: Time,
      terminal_name: String
    }
  end
  
  # ...and many more, skipped for brevity
end
```

This worked with classic autoloader mostly due to `require_dependency` placed in the bottom of `Scanner` module file:

```ruby
# scanner/lib/scanner.rb

module Scanner
end

require_dependency 'scanner/version'
require_dependency 'scanner/domain_events'
require_dependency 'scanner/scanner_service'
require_dependency 'scanner/scan_tickets_command'
require_dependency 'scanner/ticket'
require_dependency 'scanner/ticket_db'
require_dependency 'scanner/event'
require_dependency 'scanner/event_db'
```

In zeitwerk-based autoloader there is no place for [`require_dependency`](https://api.rubyonrails.org/classes/ActiveSupport/Dependencies/Loadable.html#method-i-require_dependency) anymore.

## The Workarounds

The limitation is [known](https://github.com/fxn/zeitwerk/issues/51) and [described](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#one-file-one-constant-at-the-same-top-level) in the migration guide.

What are your options when you have similar code structure and intend to migrate beyond Rails 6.1?


#### Multiple classes in a single file sharing a common namespace

It is totally fine for zeitwerk if multiple classes in a single file are nested under a common module, which maps to a file name:

```ruby
# scanner/lib/scanner/domain_events.rb

module Scanner
  module DomainEvents    # matches file name
    TicketScanned        = Class.new(Fact)
    TicketAlreadyScanned = Class.new(Fact)
    # ...
  end
end  
```

I'm not a fan of excessive nesting and would like to keep namespaces as flat as possible. With `Scanner::DomainEvents::TicketScanned` it is already 3rd level and quite verbose. 

What doesn't suit me however may be totally fine for you.

#### Single class per file in a collapsed directory

Another option is to bow to single-file-per-class philosophy. Yet to keep things organized we can group those related classes within a directory. And make sure this directory does not imply unnecessary namespace with [collapsing](https://github.com/fxn/zeitwerk#collapsing-directories),

```
scanner/
├── lib
│   ├── scanner
│   │   └── domain_events
│   │        ├── ticket_scanned.rb
│   │        └── ticker_already_scanned.rb
│   │   ├── event.rb
│   │   ├── event_db.rb
│   │   ├── scan_tickets_command.rb
│   │   ├── scanner_service.rb
│   │   ├── ticket.rb
│   │   ├── ticket_db.rb
│   │   └── version.rb
│   └── scanner.rb
└── spec
    ├── scan_tickets_command_spec.rb
    ├── scan_tickets_flow_spec.rb
    └── spec_helper.rb
```

We need to tell autoloader to keep `scanner/lib/scanner/domain/events` collapsed.

```ruby
# config/initializers/zeitwerk.rb

SUBDOMAINS = %w(
  scanner
  # ...
)

Rails.autoloaders.each do |autoloader|
  SUBDOMAINS.each do |sub|
    domain_events_dir = 
      Rails.root.join("#{sub}/lib/#{sub}/domain_events")
    autoloader.collapse(domain_events_dir)
  end
end
```

The pro is that namespace is kept intact as in `Scanner::TicketScanned`. The classes are also grouped, although not in a single file.

Then con is obviously a class-per-file religion. Which may be totally fine for some and there's nothing wrong with that.

#### Opt out of autoloading 

<blockquote class="twitter-tweet" data-theme="light"><p lang="en" dir="ltr">Remove zeitwerk, explicit require list. ;)</p>&mdash; Markus Schirp (@_m_b_j_) <a href="https://twitter.com/_m_b_j_/status/1372664853580673025?ref_src=twsrc%5Etfw">March 18, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Perhaps now opting out of autoloading in Rails is easier than ever. With zeitwerk you can tell the autoloader to [ignore particular directories](https://github.com/fxn/zeitwerk#ignoring-parts-of-the-project).

```ruby
# config/initializers/zeitwerk.rb

SUBDOMAINS = %w(
  scanner
  # ...
)

Rails.autoloaders.each do |autoloader|
  SUBDOMAINS.each do |sub|   
    autoloader.ignore(Rails.root.join(sub))
  end
end
```



Feel free to [expand this article](https://github.com/arkency/posts/edit/master/posts/2021-04-22-zeitwerk-based-autoload-and-workarounds-for-single-file-many-classes.md) or [ping me on twitter](https://twitter.com/pawelpacana) with comments.
