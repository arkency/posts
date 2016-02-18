---
title: "Testing aggregates with commands and events"
created_at: 2016-02-17 12:26:59 +0100
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :arkency_form
---

Once you start switching to using aggregates in your system (as opposed to say, ActiveRecord objects), you will need to find good ways of testing those objects. This blogpost is an attempt to explore one of the possible ways.

<!-- more -->

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


