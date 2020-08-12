---
created_at: 2017-04-09 22:49:09 +0200
publish: true
author: Andrzej Krzywda
tags: ['ddd', 'rails', 'service objects', 'video']
---

# All Rails service objects as one Ruby class

I review many Rails applications every month, every year. One visible change is that **service objects became mainstream in the Rails community**. This makes me happy, as I believe they do introduce some more order in typical Rails apps. Service objects were the main topic of my "Fearless Refactoring: Rails controllers" book, along with adapters, repositories and form objects.

Today I'd like to present one technique for grouping service objects. 

<!-- more -->

I was reminded of this technique, when I've recently came back to the development of the simple Fuckups application. This application started as a simple CRUD, typical Rails Way. Over time, though, I've added the service layer. 
In this application I went with keeping the service objects, as one class, instead of the usual - one service object == one class.
This is not my usual technique and I'm not sure I'm recommending it. However it has some nice features, so I thought it would be worth sharing.

Basically, the whole service layer (or as I like to call it in more DDD-style, the application layer) is one class here. The class is called `App`.

The app layer defines its own exceptions so they're declared at the top. After that it has a number of public methods, each responsible for handling one user request. 

I've followed one important rule here - **the service layer knows nothing about http-related stuff**. This is left to controllers to handle. Rails is great at this.

```ruby
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
end
```

From a Rails controller point of view, this is quite simple, leaving the controllers very thin:

```ruby
class FuckupsController < ApplicationController
  def create
    begin
      authenticate and return
      @fuckup = app.report_fuckup(current_user.id, fuckup_params)
    rescue App::NotAuthorized
      redirect_to root_path and return
    end

    redirect_to(@fuckup)
  end
```

As you may notice, the authentication (who are you?) part is handled at the controller level, while the authorization (can you do that?) is part of the service layer.

Authentication is the usual dilemma, as it's not clear where it belongs. I like to think about it as the app layer. But given the usual coupling between authentication (hello Devise) and Rails controllers, this is usually the last part to decouple, if ever. 

Authorization feels much more in the app layer, that's why it's here too.

What's inside the `report_fuckup` method then?

```ruby
  def report_fuckup(user_id, fuckup_params)
    user = User.find(user_id)

    raise NotAuthorized if !user.organization
    fuckup = user.organization.fuckups.create(fuckup_params)
    stream_name = "fuckup_#{fuckup.id}"
    event_data = { data:
                       {
                           user_id: user_id,
                           organization_id: user.organization.id,
                           tldr: fuckup.tldr,
                           description: fuckup.description,
                           symptoms: fuckup.symptoms,
                           hotfix: fuckup.hotfix,
                           coldfix: fuckup.coldfix,
                       }
    }
    event = FuckupReported.new(event_data)
    event_store.publish_event(event, stream_name)
    fuckup
  end
```

Well, so this is not the usual service object, as it's extended with more things (event_store). 

Let me first start with the more typical stuff. **All the service objects accept params which are primitives, or at least are not Rails objects**. This is important to decouple them at this level from Rails. Passing user_id is more than enough, as we can retrieve the data on our own.
The first part is authorization. We need to ensure you belong to the organization where you try to report the fuckup to. (It might be a good idea somewhere in the future to submit fuckups to foreign organizations, but it's not in the scope yet).
Then we use the normal ActiveRecord associations to create the database record. There's no validations here, so nothing to check.

Depending on ActiveRecord here is another dilemma. It's not perfect here. It would be nicer if we just called `fuckuops_repo.create` but it's not there (yet?).

I left the persistence layer here, without any repo objects. Mostly due to lack of time for this effort, as it would be nice here.

The last part is the unusual part. This is where the app starts to become **beyond service objects**. This is where the app starts to be more Domain-Driven Design in its architecture. We publish an event here and store it. 

Events were not meant to be in the scope of this blogpost, but as a sneak-peek, here they are for this app:

```ruby

FuckupReported               = Class.new(RailsEventStore::Event)
FuckupReportedFromSlack      = Class.new(RailsEventStore::Event)
FuckupReportedFromCodeEditor = Class.new(RailsEventStore::Event)
FuckupRemoved                = Class.new(RailsEventStore::Event)
FuckupBatchUpdated           = Class.new(RailsEventStore::Event)
FuckupShared                 = Class.new(RailsEventStore::Event)
FuckupVisitedByUser          = Class.new(RailsEventStore::Event)
FuckupVisitedByGuest         = Class.new(RailsEventStore::Event)

OrganizationAllowedToUseTheApp = Class.new(RailsEventStore::Event)
UserApprovedInTheOrganization  = Class.new(RailsEventStore::Event)
PersonRemovedFromOrganization  = Class.new(RailsEventStore::Event)
UserRegisteredFromGithub       = Class.new(RailsEventStore::Event)
UserSessionStarted             = Class.new(RailsEventStore::Event)
UserLoggedOut                  = Class.new(RailsEventStore::Event)
UserMadeAdmin                  = Class.new(RailsEventStore::Event)
```

And here is an example test at the app layer:

```ruby

  def test_user_not_able_to_report_fuckup_in_not_her_organization
    app = App.new
    app.register_new_user(github_login: "ak", name: "Andrzej Krzywda")
    app.register_organization("Arkency")
    user_id         = User.last.id
    assert_raises App::NotAuthorized do
      app.report_fuckup(user_id, description: "whatever")
    end
  end
```


If the app itself sounds interesting to you, it's free to use at  [http://fuckups.arkency.com/](http://fuckups.arkency.com/).

If you like this style of organizing the Rails code, then you may like my book: ["Fearless Refactoring: Rails controllers"](http://rails-refactoring.com).

<div style="position:relative;height:0;padding-bottom:56.25%"><iframe src="https://www.youtube.com/embed/lmpPfTy-Tvw?ecver=2" width="640" height="360" frameborder="0" style="position:absolute;width:100%;height:100%;left:0" allowfullscreen></iframe></div>

## Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your
everyday Rails programmer job.

Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring Rails applications.
