---
title: "All Rails service objects as one Ruby class"
created_at: 2017-04-09 22:49:09 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
---

I review many Rails applications every month, every year. One visible change is that service objects became mainstream in the Rails community. This makes me happy, as I believe they do introduce some more order in typical Rails apps. Service objects were the main topic of my "Fearless Refactoring: Rails controllers" book, along with adapters, repositories and form objects.

Today I'd like to present one technique for grouping service objects. 

<!-- more -->

I was reminded of this technique, when I've recently came back to the development of the simple Fuckups application. This application started as a simple CRUD, typical Rails Way. Over time, though, I've added the service layer. 
In this application I went with keeping the service objects, as one class, instead of the usual - one service object == one class.
This is not my usual technique and I'm not sure I'm recommending it. However it has some nice features, so I thought it would be worth sharing.

Basically, the whole service layer (or as I like to call it in more DDD-style, the application layer) is one class here. The class is called `App`.

The app layer defines its own exceptions so they're declared at the top. After that it has a number of public methods, each responsible for handling one user request. 

I've followed one important rule here - the service layer knows nothing about http-related stuff. This is left to controllers to handle. Rails is great at this.

```
#!ruby
class App
  class NotAuthorized                 < StandardError; end
  class AlreadyBelongToAnOrganization < StandardError; end
  class UnrecognizedSlackToken        < StandardError; end


  def initialize(event_store = RailsEventStore::Client.new)
  def register_new_user(github_login:, name:)
  def add_existing_user_to_organization(user_id, organization_id)
  def register_new_user_and_add_to_organization(organization_id:, name:, github_login:)
  def register_organization(name)
  def report_fuckup(user_id, fuckup_params)
  def get_fuckups_for_current_organization(user_id)
  def make_user_admin(user_id)
  def is_user_admin?(user_id)
  def remove_user_from_organization(user_id, organization_id)
  def provide_slack_token(organization_id, slack_token)
  def report_fuckup_from_slack(slack_token, fuckup_tldr)
```

