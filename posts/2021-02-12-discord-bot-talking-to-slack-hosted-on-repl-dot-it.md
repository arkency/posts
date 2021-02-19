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

First, some basic setup of Discordb that will puts whenever something related to voice happens on Discord:

```ruby
require "discordrb"

bot = Discordrb::Bot.new(token: "xxxx.xxx.xxxx")

bot.voice_state_update { |event| p event }

at_exit { bot.stop }
bot.run
```

Now we only care about a specific set of events — when someone joins, leaves or changes a voice channel. That's how we can filter them out in the main method:

```ruby
bot.voice_state_update do |event|
  case 
  when event.channel.nil?
    notify_slack "✂️ #{event.user.name} disconnected"
  when event.old_channel.nil?
    notify_slack "👋 #{event.user.name} connected to #{event.channel.name}"
  when event.channel.name != event.old_channel.name
    notify_slack "🔀 #{event.user.name} switched to #{event.channel.name}"
  end
end
```

Now we need to actually send these notifications to slack. It's just a plain post to the configured webhook:


```ruby
require "httparty"

def notify_slack(message)
  HTTParty.post(
    "https://hooks.slack.com/services/xxx/xxxx/xxxxx",
    body: JSON.dump({ text: message }),
    headers: { "Content-Type" => "application/json" }
  )
end
```

Run it from my local machine... Works!

You can find the [full gist here](https://gist.github.com/tomaszwro/c6574aa95c0c4009adcba92a8da2cec1).

Special thanks for [Paweł](https://twitter.com/pawelpacana) for working on it together as a short coffee-break-hack.

## Now, where do I deploy such a tiny lil' thing?

* Heroku charges you $7/month for a dyno that never sleeps 🤔
* Now, for $7 I can have 5 _always-on_ apps on [repl.it](https://repl.it) which is now allegedly [_the fastest way to spin up a webservice_](https://twitter.com/paulg/status/1359588595561082883). Fortunately it supports Ruby. Let's give it a try 🚀

Click, click, click, the app is live 🎉

I have to admit it was fast. Personally I really like it when services and tools improve DX, eliminate friction and are more approachable. 

Want to discuss? Leave a [reply under this tweet](https://twitter.com/tomasz_wro/status/1362433027738066953).

