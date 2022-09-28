---
created_at: 2022-09-28 10:33:43 +0200
author: Łukasz Reszke
tags: ['rails event store', 'event sourcing', 'linking event to stream']
publish: true
---

# Simplify your system debugging by introducing event store linking

Last week I was dealing with an interesting bug. In our system, there was a user that didn’t belong to any tenant. And a tenant that didn’t have any users. It’s a situation that shouldn’t happen in our application.

Debugging that issue was quite simple because of the [linking feature](https://railseventstore.org/docs/v2/link/) of RailsEventStore that we use in our application to correlate all events related to a user in a single stream. By linking to such a user stream you get the possibility to see all events that are related to that certain user account.

<img src="<%= src_original("linking/res-events.png") %>" width="100%">

What is interesting here is that there’s a `UserLeftTenant` event, which in our case, should lead to deleting the user’s account if that was the only tenant that the user belonged to. But that didn’t happen. Additionally, as you can see events that happened after, there was still a possibility to log in as that user. Which resulted in a very ugly error.

<img src="<%= src_original("linking/linking-error.png") %>" width="100%">

Well, at least we can see that the account still exists and it’s still possible to log in, right? Eventually, it turned out that there was another way for a user to leave the tenant. It didn’t follow the process of checking if that was the only tenant that the user belongs to. It was also quite easy to find in the code as I was able to grep by the `UserLeftTenant` event and find that place in our codebase. Another benefit of using events ;)

```ruby
  class LinkByUserId
    def initialize(event_store: Rails.configuration.event_store, prefix: "$by_user_id_")
      @event_store = event_store
      @prefix = prefix
    end

    def call(event)
      user_id = event.metadata[:user_id]
      @event_store.link([event.event_id], stream_name: "#{@prefix}#{user_id}") if user_id
    end
  end
```

You have to subscribe to all events
```ruby
    event_store.subscribe_to_all_events(LinkByUserId.new)
```

Now we have to add the user_id into the metadata.
In the usual Rails application, you can set it up in your `ApplicationController` as `around_action` callback.

```ruby
class ApplicationController < ActionController::Base
	…
	around_action :enrich_events_with_current_user_metadata, if: :current_user
	…
	def enrich_events_with_current_user_metadata
	 extra_metadata = { user_id: current_user.id, locale: I18n.locale.to_s }
	 event_store.with_metadata(extra_metadata) { yield }
	end
end
```

Of course, you don’t have to limit yourself to linking events to user streams. Anything interesting for you, your team, or the business stakeholders will work well. Don’t be scared to find new insights about your application.

If you get in trouble setting up your RES, feel free to join our [community](https://railseventstore.org/community/)