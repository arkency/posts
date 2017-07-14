---
title: "How to safely store API keys in Rails apps"
created_at: 2017-07-14 13:48:33 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :arkency_form
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

#### Pros:

* Easy

#### Cons:

* Every developer working on your app knows API keys. This can bite you later when that person leaves or is fired. And I doubt you rotate your API keys regularly. That includes every notebook your developers have, which can be stolen (make sure it has encrypted disc) or gained access to.
* Every 3rd party app has access to this key. That includes all those cloud-based apps for storing your code, rating your code, or CIs running the tests. Even if you never have a leak, you can't be sure they don't have a breach in security one day. After all, they are very good target.
* Wrong server configuration can lead to exposing this file. There has been historical cases where attackers used `../../something/else` as file names, parameter names to read certain files on servers. Not that likely in Rails environment, but who knows.
* In short: when the project code is leaked, your API key is leaked.

## Save in ENV

#### How:

```
#!ruby
config.mailchimp_api_key = ENV.fetch('MAILCHIMP_API_KEY')
```

#### Pros:

* Relatively easy. On Heroku you can configure production variables in their panel. For development and test environment you can use [dotenv](https://github.com/bkeepers/dotenv) which will set environment based on configuration files. You can keep your development config in a repository and share it with your whole team.

#### Cons:

* Coming soon...

## Save in DB

Coming soon...

## Save in DB and encrypt

Coming soon...