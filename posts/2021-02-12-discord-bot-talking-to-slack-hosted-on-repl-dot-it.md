---
title: Discord bot talking to Slack hosted on repl.it 
created_at: 2021-02-12T12:02:20.443Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Discord-to-Slack bot hosted on repl.it

```ruby
require "discordrb"
require "httparty"

def notify(message)
  HTTParty.post(
    "https://hooks.slack.com/services/xxx/xxxx/xxxxx",
    body: JSON.dump({ text: message }),
    headers: { "Content-Type" => "application/json" }
  )
end

bot = Discordrb::Bot.new(token: "xxxx.xxx.xxxx")

bot.voice_state_update do |event|
  case 
  when event.channel.nil?
    notify "✂️ #{event.user.name} disconnected"
  when event.old_channel.nil?
    notify "👋 #{event.user.name} connected to #{event.channel.name}"
  when event.channel.name != event.old_channel.name
    notify "🔀 #{event.user.name} switched to #{event.channel.name}"
  end
end

at_exit { bot.stop }
bot.run
```
