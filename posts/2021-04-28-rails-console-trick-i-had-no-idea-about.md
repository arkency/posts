---
created_at: 2021-04-28 09:20:25 +0200
author: Paweł Pacana
tags: ['rails']
publish: true
---

# Rails console trick I had no idea about

Tweaking `.irbrc` to make interactive console comfortable is a highly-rewarding activity. You gets instant boost of productivity and there are less frustrations. There were numerous posts and tips featured in Ruby Weekly on this topic recently.

I've been making my `.irbrc` more useful too. The harder part was always distributing those changes to remote servers. For example to have those goodies available in Heroku console. And not only for me. There are multiple ways to achieve that, duh. The one that stick though was close to the app code:

```ruby
# script/likeasir.rb

# Nice things to have when entering production console
# load 'script/likeasir.rb'

def event_store
  Rails.configuration.event_store
end

def command_bus
  Rails.configuration.command_bus
end

# ...
```

You'd open the console first and load the helpers next to the IRB session with:

```ruby
load 'script/likeasir.rb'
```

And then [Kuba](https://blog.arkency.com/authors/jakub-kosinski/) showed me a neat trick that made this load step completely obsolete:

```ruby
# config/application.rb

module MyApp
  class Application < Rails::Application
    # ...

    console do
      module DummyConsole
        def event_store
          Rails.configuration.event_store
        end

        def command_bus
          Rails.configuration.command_bus
        end
      end
      Rails::ConsoleMethods.include(DummyConsole)
    end
  end
end
```

Now, whenever you load `bin/rails c`, the `command_bus` and `event_store` methods will be present in the IRB session.

That's it. That's the trick I did not know about for years.

You're welcome.

