---
created_at: 2022-05-18 16:51:16 +0200
author: Piotr Jurewicz
tags: ['rails', 'slack', 'team', 'communication']
publish: true
---

# Keep your team up to date on production data changes

It is not uncommon for Ruby developers to manipulate production data via Rails console. Sometimes it is just necessary. The crucial thing is to leave a trace of what commands you have issued.
- Maybe you would be asked to do similar modifications again in the feature.
- Possibly something would go wrong, and you will have to analyze what.
- I am sure you want to keep our teammates informed on what is going on.

There are many more reasons to have some kind of logging.

<!-- more -->

In his <a href="https://blog.arkency.com/rails-console-trick-i-had-no-idea-about/">blog post</a>, Paweł showed how to load the helper module with the Rails console's start.
This time, in an analogous way, we will "hack" our console to get Slack notifications of what commands are being called, by whom, and for what purpose.
Let's prepare a `Console` module with a `setup` method that does the following actions:
- warns developer about working on non-development data
- asks for his name
- sends notification about session's start
- asks for a purpose of the current session
- sends notification about the purpose if there is any
- sends notification about commands issued (except the last one which is typically `exit`)
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

To make it works, we have to append our `Application` class with these lines:

```ruby
class Application < Rails::Application
  #...
  console do
    Console.setup
  end
  #...
end
```

Running the console, you will be asked for your name and the purpose of the current session. Then you can operate normally, and all the commands you typed will be posted to your team's Slack channel.

<img src="<%= src_original("keep-your-team-up-to-date-on-production-data-changes/slack-notifications.png") %>" width="100%">

### Check also Kuba's <a href="https://blog.arkency.com/decorate-your-runner-session-like-a-pro/">blog post</a> to know how to do a similar thing with rails runner sessions.