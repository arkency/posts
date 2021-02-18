---
title: Discord-to-Slack bot hosted on repl.it 
created_at: 2021-02-18T12:02:20.443Z
author: Tomasz Wróbel
tags: ['ruby', 'async-remote']
publish: true
---

# Discord-to-Slack bot hosted on repl.it

## The story

So we started using Discord alongside Slack recently. The selling point were voice channels and screen streaming. It made voice conversations much smoother and  more _async_ friendly and made us overall closer to each other. More context [here](https://twitter.com/tomasz_wro/status/1355222703221968900).

Basically, whenever someone joins a voice channel it means:

* _I'm available to talk_, or
* _I don't mind company_.

But since we're using Slack as the primary means of communication, not everyone in our team is used to having Discord open at all times. We need one thing: an integration that would **notify us on Slack, whenever someone joins a voice channel on Discord**:

<%= img_original("discord-bot.png") %>

## Let's do it

We'll need to:

* Set up a Discord bot — your starting point is [here](https://discord.com/developers/applications). We've found [this guide](https://discordpy.readthedocs.io/en/latest/discord.html) helpful.
* Set up an [Incoming Webhook](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) on Slack.

Now the code takes the [discordrb gem](https://github.com/shardlab/discordrb) and uses it to listen to voice channel updates (basically any event related to voice status, like self-mute or screen share). The updates get filtered and posted to the Slack webhook.

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

Run it from my local machine... Works!

## Now, where do I deploy such a tiny lil' thing?

* Heroku charges you $7/month for a dyno that never sleeps 🤔
* Now, for $7 I can have 5 _always-on_ apps on [repl.it](https://repl.it) which is now allegedly [_the fastest way to spin up a webservice_](https://twitter.com/paulg/status/1359588595561082883). Fortunately it supports Ruby. Let's give it a try 🚀

Click, click, click, the app is live 🎉

I have to admit it was fast. Personally I really like it when services and tools improve DX, eliminate friction and are more approachable. 


