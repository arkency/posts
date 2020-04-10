---
title: "Rails components — neither engines nor gems"
created_at: 2017-09-15 01:26:21 +0200
publish: true
author: Paweł Pacana
tags: [ 'cbra', 'gem', 'bounded context', 'ddd' ]
newsletter: arkency_form
---

There has been a very interesting discussion today on [\#ruby-rails-ddd community slack channel](http://blog.arkency.com/domain-driven-rails/). The topic circulated around bounded contexts and introducing certain "component" solutions to separate them.

<!-- more -->

There are various approaches to achieve such separation —  Rails Engines and [CBRA](http://shageman.github.io/cbra.info/) were listed among them. It was, however, the mention of "unbuilt gems" that reminded me of something.

## Gem as a code boundary

Back in the day, we had an approach in Arkency in which distinct code areas were extracted to gems. They had the typical gem structure with `lib/` and `spec/` and top-level `gemspec` file.

```
# top-level app directory

scanner/
├── lib
│   ├── scanner
│   │   ├── event.rb
│   │   ├── event_db.rb
│   │   ├── domain_events.rb
│   │   ├── scan_tickets_command.rb
│   │   ├── scanner_service.rb
│   │   ├── ticket.rb
│   │   ├── ticket_db.rb
│   │   └── version.rb
│   └── scanner.rb
├── scanner.gemspec
└── spec
    ├── scan_tickets_command_spec.rb
    ├── scan_tickets_flow_spec.rb
    └── spec_helper.rb
```

```ruby
# scanner/scanner.gemspec

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scanner/version'

Gem::Specification.new do |spec|
  spec.name          = 'scanner'
  spec.version       = Scanner::VERSION

  # even more stuff here

  spec.add_dependency 'event_store'
end
```

Each gem had its own namespace, reflected in gem's name. In example `Scanner` with `scanner`. It held code related to the scanning context, from the service level to the domain. You were able to run specs related to this particular area in separation.
In fact, at that time we were just starting to use the term Bounded Context.

```ruby
# scanner/lib/scanner.rb

module Scanner
end

require 'scanner/version'
require 'scanner/domain_events'
require 'scanner/scanner_service'
require 'scanner/scan_tickets_command'
require 'scanner/ticket'
require 'scanner/ticket_db'
require 'scanner/event'
require 'scanner/event_db'
```

Yet these gems were not like the others. We did not push them to RubyGems obviously. Neither did we store them on private gem server. They lived among Rails app, at the very top level in the code repository. They're referenced in `Gemfile` using `path:`, like you'd do with vendored dependencies.

```ruby
# Gemfile

gem 'scanner', path: 'scanner'
```

That way much of the versioning/pushing hassle was out of the radar. They could change simultaneously with the app that used them (starting in the controllers calling services from gems). Yet they organized cohesive concept in one place. Quite idyllic, isn't it? Well, there was only one problem…

## Rails autoloading and you

Code packaged as gem suffers from Rails code reload mechanism. While that rarely bothers you with the dependencies distributed from RubyGems that you'd never change locally, it is an issue for "unbuilt" gems.

Struggle with Rails autoload is real. If you keep losing battles with it — go read the [guide](http://guides.rubyonrails.org/autoloading_and_reloading_constants.html) thoroughly. That was also the reason we disregarded the gem approach.

## Code component without gemspec

The solution we're happy with now does not differ drastically from having vendored gems. There's no `gemspec` but the namespace and directory structure from a gem stay. The gem entry in `Gemfile` is gone. Any runtime dependencies this gem had, go into `Gemfile` directly now.

What differs is that we no longer have `require` to load files. Instead, we use autoload-friendly `require_dependency`.

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

With that approach, you also have to make sure that Rails is aware to autoload code from the [path](http://blog.arkency.com/2014/11/dont-forget-about-eager-load-when-extending-autoload/) your Bounded Context lives in.

```ruby
# config/application.rb

config.paths.add 'scanner/lib', eager_load: true
```

And that's mostly it!

As an example you put `Scanner::Ticket` into `scanner/lib/scanner/ticket.rb` as:

```ruby
# scanner/lib/scanner/ticket.rb

module Scaner
  class Ticket
  end
end
```

## Dealing with test files

If you wish to painlessly run spec files in the isolated directory there are certain steps to take.

First, the spec helper should be responsible to correctly load the code.

```ruby
# scanner/spec/spec_helper.rb

require_relative '../lib/scanner'
```

Then the test files should require it appropriately.

```ruby
# scanner/spec/scan_tickets_command_spec.rb

require_relative 'spec_helper'

module Scanner
  RSpec.describe ScanTicketsCommand do
    # whatever it takes to gain confidence in code ;)
  end
end
```

Last but not least — it would be a pity to forget to run specs along the whole application test suite on CI. For this scenario we tend to put following code in app `spec/` directory:

```ruby
# spec/scanner_spec.rb

path = Rails.root.join('scanner/spec')
Dir.glob("#{path}/**/*_spec.rb") do |file|
  require file
end
```

## Summary

The solution picture above is definitely not the only viable option. It has worked for me and my colleagues thus far. No matter which one you're using — [deliberate design with bounded contexts is a win](https://twitter.com/owickstrom/status/889819275820756992).
