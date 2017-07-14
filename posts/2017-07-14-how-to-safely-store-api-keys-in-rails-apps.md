---
title: "How to safely store API keys in Rails apps"
created_at: 2017-07-14 13:48:33 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'security', 'rails', 'api' ]
newsletter: :arkency_form
img: "ruby-store-api/api-keys-rails.png"
---

Inspired by [a question on reddit: Can you store user API keys in the database?](https://www.reddit.com/r/rails/comments/6n63ql/can_you_store_user_api_keys_in_the_database/) I decided to elaborate just a little bit on this topic.

<!-- more -->

Assuming you want store API keys (or passwords for SSL ceritifcate files) what are your options? What are the pros and cons in each case.

## Save directly in codebase

#### How?

```
#!ruby
#config/environments/production.rb
  config.mailchimp_api_key = "ABCDEF"
```

#### Cons:

* Won't work with dynamic keys provided by users of your app
* Every developer working on your app knows API keys. This can bite you later when that person leaves or is fired. And I doubt you rotate your API keys regularly. That includes every notebook your developers have, which can be stolen (make sure it has encrypted disc) or gained access to.
* Every 3rd party app has access to this key. That includes all those cloud-based apps for storing your code, rating your code, or CIs running the tests. Even if you never have a leak, you can't be sure they don't have a breach in security one day. After all, they are very good target.
* Wrong server configuration can lead to exposing this file. There has been historical cases where attackers used `../../something/else` as file names, parameter names to read certain files on servers. Not that likely in Rails environment, but who knows.
* In short: when the project code is leaked, your API key is leaked.
* **Least safe**

## Save in ENV

#### How:

```
#!ruby
config.mailchimp_api_key = ENV.fetch('MAILCHIMP_API_KEY')
```

#### Pros:

* Won't work with dynamic keys provided by users of your app
* Relatively easy. On Heroku you can configure production variables in their panel. For development and test environment you can use [dotenv](https://github.com/bkeepers/dotenv) which will set environment based on configuration files. You can keep your development config in a repository and share it with your whole team.

#### Cons:

* If your `ENV` leaks due to a security bug, you have a problem.

## Save in DB

#### How

```
#!ruby
class Group < ApplicationRecord
end

Group.create!(name: "...", mailchimp_api_key: "ABCDEF")
```

#### Pros

* Easy
* Works with dynamic keys

#### Cons

* If you ever send `Group` as json, via API, or serialize to other place, you might accidentally leak the API key as well. Take caution to avoid it.
* If your database or database backup leaks, the keys leaks as well. This can especially happen when developers download backups or use them for development.

## Save in DB and encrypt (secret in code or in ENV)

#### How

```
#!ruby
class Group < ApplicationRecord
  attr_encrypted_options.merge!(key: ENV.fetch('ATTR_ENCRYPTED_SECRET'))
  attr_encrypted :mailchimp_api_key
end

Group.create!(name: "...", mailchimp_api_key: "ABCDEF")
```

* use [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted)
* and already mentioned [dotenv](https://github.com/bkeepers/dotenv)

#### Pros

* For the sensitive API key to be leaked, two things needs to happen:
  * DB leak
  * ENV or code leak, which contain the secret you use for encryption
* If only one of them happens, that's not enough.
* **The safest approach**

#### Cons

* A bit more complicated, but not much
* Your test might be a bit slower when you strongly encrypt/decrypt in most important models, which are used a lot