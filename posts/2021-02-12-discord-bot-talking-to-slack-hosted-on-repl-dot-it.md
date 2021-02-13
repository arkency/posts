---
title: Discord-to-Slack bot hosted on repl.it 
created_at: 2021-02-12T12:02:20.443Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Discord-to-Slack bot hosted on repl.it

## The story

So we started using Discord alongside Slack recently. The selling point were voice channels and screen streaming. It made voice conversations much smoother and  more _async_ friendly and made us overall closer to each other. More context [here](https://twitter.com/tomasz_wro/status/1355222703221968900).

Basically, whenever someone joins a voice channel it means _I'm available to talk_ or _I don't mind company_.

But since we're using Slack as the primary means of communication, and not everyone is used to having Discord open at all times, we needed one thing: an integration that would **notify us on Slack, whenever someone joins a voice channel on Discord**. Simple.

<!-- image of joining notifications -->

## Let's do it

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
