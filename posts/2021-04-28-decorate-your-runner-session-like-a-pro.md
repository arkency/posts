---
title: Decorate your runner session like a pro
created_at: 2021-04-28T08:17:38.564Z
author: Jakub Kosiński
tags: ["rails"]
publish: true
---

[Paweł](https://blog.arkency.com/authors/pawel-pacana) described some [tricks](https://blog.arkency.com/rails-console-trick-i-had-no-idea-about/) you could use to tune-up your Rails console. 
I want to tell you about the [`runner`](https://api.rubyonrails.org/classes/Rails/Application.html#method-i-runner) method you can use to enhance your runner sessions.

Decorating runner sessions is a little bit less convenient as we don't have a module like `Rails::ConsoleMethods` that is included when runner session is started. So adding some methods available for runner scripts is not that easy.
However you can still add some code that will be executed at the start and the end of your runner sessions.

For example you can send some notifications so you don't need to look at the terminal to check if the script evaluation has been finished. You can also measure time or set some [Rails Event Store](https://railseventstore.org/) metadata 
to easily determine [what has been changed](https://blog.arkency.com/correlation-id-and-causation-id-in-evented-systems/) during your session.

Here is an example we are using in one of our projects to log the elapsed time, set some [RES](https://railseventstore.org/) metadata and send Slack notifications. You can just add it to your `config/application.rb`.

```ruby
runner do
  session_id = SecureRandom.uuid
  script = ARGV.join(" ")
  Rails.configuration.event_store.set_metadata(
    causation_id: session_id,
    correlation_id: session_id,
    script: script,
    locale: I18n.locale.to_s,
  )
  t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  notify_slack(
    username: "Script runner",
    text: "[#{Rails.env}] Runner script session #{session_id} has started: '#{script}'",
    channel: "notifications",
    icon_emoji: ":robot_face:"
  )

  at_exit do
    notify_slack(
      username: "Script runner",
      text: "[#{Rails.env}] Runner script session #{session_id} has finished: '#{script}' (elapsed: #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - t} seconds)",
      channel: "notifications",
      icon_emoji: ":robot_face:"
    )
  end
end
```

With such snippet, each time you run some script (or evaluate some inline Ruby code) with `rails runner` it will set the metadata for your [RES](https://railseventstore.org/) instance and it will send a Slack notification
at the beginning and the end of the runner session.
