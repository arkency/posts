---
title: "Testing aggregates with commands and events"
created_at: 2016-02-17 12:26:59 +0100
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

Once you start switching to using aggregates in your system (as opposed to say, ActiveRecord objects), you will need to find good ways of testing those objects. This blogpost is an attempt to explore one of the possible ways.

<!-- more -->


The code I'm going to show is part of a project that I was recently working on. The app is called Fuckups (yes, I consider changing that name) and it helps us track and learn from all kinds of mistakes we make. 

Yes, we make mistakes. 

The important part is to **really** learn from those mistakes. This is our company habit that we have for years now. During the week we collect all the fuckups that we see. It doesn't matter who did them, the story and the lesson matters. We used to track them in a Hackpad called "Fakapy jak startupy" which means "Fuckups as Startups" (don't ask). That's why this name persisted until today. Our hackpad has all the archives now.
Every Friday we have a weekly sync. [As a remote/async company](http://blog.arkency.com/developers-oriented-project-management/) we avoid all kinds of "sync" meetings. Fridays are the exception, when we disuss all kinds of interesting things as the whole team. We call it "weeklys".

One part is usually the most interesting is the Fuckups part. We iterate through them, one person says what happened and we try to discuss and find the root problems. Once a fuckup is discussed we mark it as "discussed".

The app is a replacement for hackpad. In its core, it's a simple list, where we append new things. 

I tried to follow the "Start from the middle" approach here and it mostly worked. It's far from perfect, but we're able to use it now. One nice thing is that we can add a new fuckup to the list by a simple Slack command. 

```
/fuckup SSL Certificates has not been updated before expiration date
```

No need to leave Slack anymore.

Although the app is already "in production", new organizations can't start using it yet. The main reason was that I started from the middle with authentication by implementing the Github OAuth.

Before releasing it to public, I wanted to implement the concept of a typical authentication - you know - logins/passwords, etc.

This is where I got sidetracked a bit. 

It's our internal project and not a client project, so there's a bit more freedom to experiment. As you may know, we talk a lot about going from legacy to DDD. That's what we usually do. It's not that often that we do DDD from scratch. So, the fuckups app core is a legacy Rails Way approach. But, authentication is another bounded context. I can have the excitement of starting a new "subproject" here.

Long story, short, I started implementing what I call `access` library/gem. A separated codebase responsible for authentication, not coupled to fuckups in any way.

There will be a concept of organizations, but for now I just have the concept of Host (a container for organizations). We can think of it as the host for other tenants (organizations).

I implemented the host object as the aggregate. At the moment it should know how to:

*register a user
*chossing a login for the user
*providing the password
*authenticate



```
#!ruby
  class Host
    include RailsEventStore::AggregateRoot

    def initialize
      @users = {}
    end

    def handle(command)
      case command
        when RegisterUser
          register_user(command.user_id)
        when Authenticate
          authenticate(command.credentials)
        when ChooseLogin
          choose_login(command.user_id, command.login)
        when ProvidePassword
          provide_password(command.user_id, command.password)
      end
    end
    # ...
  end
```


