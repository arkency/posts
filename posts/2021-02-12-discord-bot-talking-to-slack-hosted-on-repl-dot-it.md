---
title: Discord bot talking to Slack hosted on repl.it 
created_at: 2021-02-12T12:02:20.443Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Discord bot talking to Slack hosted on repl.it

```ruby
require "discordrb"
require "httparty"

post_message = lambda do |message|
  HTTParty.post(
    "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXXXX/xxxxxxxxxxxxxxxxxxxxxxxx",
    body: JSON.dump({ text: message }),
    headers: { "Content-Type" => "application/json" }
  )
end

bot = Discordrb::Bot.new(token: "xxxxxxxxxxxxxxxxxxxxxxxx.xxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxx")

bot.voice_state_update(self_mute: false, self_deaf: false, mute: false, deaf: false) do |event|
  case event.channel
  when NilClass
    post_message["#{event.user.name} disconnected"]
  else
    case event.old_channel
    when NilClass
      post_message["#{event.user.name} joined #{event.channel.name}"]
    else
      # share|unshare while being on the channel
      post_message["#{event.user.name} joined #{event.channel.name}"] unless event.channel.name == event.old_channel.name 
    end
  end
end

at_exit { bot.stop }
bot.run
```
