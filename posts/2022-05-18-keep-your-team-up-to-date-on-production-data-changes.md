---
created_at: 2022-05-18 16:51:16 +0200
author: Piotr Jurewicz
tags: ['rails', 'slack', 'team', 'communication']
publish: false
---

# Keep your team up to date on production data changes

It is not uncommon for Ruby developer to manipulate production data via Rails console. Sometimes it is necessary. The crucial thing is to leave track of what commands have we issued.
- Maybe we would be asked to do similar modifications again in the feature.
- Maybe something would go wrong and we will have to analyze what.
- Maybe we just want to keep our teammates informed on what is going on.

There are many more reasons to leave a track.

<!-- more -->

In his <a href="https://blog.arkency.com/rails-console-trick-i-had-no-idea-about/">blogpost</a>, Paweł showed how to load helper module with Rails console start.
Today, in a similar way, we will "hack" our console to get Slack notifications of what commands are being called, by whom, and to what purpose.
Let's prepare `Console` module with a `setup` method which:
- warns developer about working on non-development data
- asks for a name
- sends notification about session's start
- asks for a purpose of current session
- sends notification about the purpose if there is any
- sends notification about commands issued (except the last one which normally is `exit`)
- sends notification about session's finish

```ruby
require 'readline'

module Console
  class << self
    def setup
      warn unless Rails.env.development?
      return unless Rails.env.production?
      get_name
      notify_session_started
      get_purpose
      notify_purpose
      at_exit do
        notify_commands_issued
        notify_session_finished
      end
    end

    private

    def warn
      app_name = Rails.application.class.module_parent_name
      puts "Welcome in #{app_name} console. You are accessing #{Rails.env} data now."
    end

    def get_name
      while @name.blank?
        @name =
          begin
            Readline.readline("Please enter your name: ")
          rescue Exception
            exit
          end
      end
    end

    def get_purpose
      @purpose =
        begin
          Readline.readline("Please enter the purpose of this session (or leave it blank): ")
        rescue Exception
          exit
        end
    end

    def notify_purpose
      return unless @purpose.present?
      text = "The purpose of *#{@name}'s* session is to: #{@purpose}."
      SlackBot.dev_notification text
    end

    def notify_session_started
      text = "New #{Rails.env} console session started by *#{@name}*."
      SlackBot.dev_notification text
    end

    def notify_session_finished
      text = "*#{@name}'s* #{Rails.env} console session finished."
      SlackBot.dev_notification text
    end

    def notify_commands_issued
      Reline::HISTORY[0...-1].each do |command|
        SlackBot.dev_notification "*#{@name}* issued a command: ```#{command}```"
      end
    end
  end
end
```

To make it works, we append our `Application` class with these lines:

```ruby

class Application < Rails::Application
  #...
  console do
    Console.setup
  end
  #...
end
```

<img src="<%= src_original("keep-your-team-up-to-date-on-production-data-changes/slack.png") %>" width="100%">