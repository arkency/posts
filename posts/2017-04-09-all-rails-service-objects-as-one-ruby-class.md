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

```
#!ruby

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
  def load_host
  def load_organization(organization_id)
  def add_user_to_organization(user_id, organization_id)
```

