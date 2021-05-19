---
created_at: 2021-05-19 07:58:17 +0200
author: Rafał Łasocha
tags: ['distributed systems', 'integrations']
publish: true
---

# Limit your automatic retries

Recently I've seen such a code:

```ruby
def build_state(event)
  # ...
rescue RubyEventStore::WrongExpectedEventVersion
  retry
end
```

As you can see, the `build_state` may raise an `RubyEventStore::WrongExpectedVersion`, which if raised, is always automatically retried.

This error is raised if there are two concurrent writes to the same stream in `RubyEventStore` but only one of them is allowed to succeed.
One of them will successfully append it's event to the end of the stream and the second one will fail.
That second request with automatic retry implemented (like in above snippet) will retry after fail, and most likely succeed this time.

**But what if it doesn't?**

What if there is so much concurrent writes, that this request will fail over and over?

What if there is a bug in the code which will always raise that error and we always retry? **We have created an infinite loop, which deployed to production can bring our system down in seconds.** :)

At least for these reasons, there code should be always be retried limited number of times (one should be enough ;) ). An example could be:

```ruby
def build_state(event)
  with_retry do
    # ...
  end
end

private
def with_retry
  yield
rescue RubyEventStore::WrongExpectedVersion
  yield
end
```

## How many retries to choose?

The less, the better for your system resilience (thus **I recommend only one retry at most**). Instead of automatically retry, it's better to let it fail the background job and retry it with [exponential backoff](https://github.com/pawelpacana/exponential-backoff) (sidekiq has that built-in, other background job libraries may have too).

The same applies to frontend, especially because user, tired of waiting, could already close the tab and we are still trying to prepare a response for him -- it's better to fail the request and let the frontend decide whether to retry it again or not. By letting it fail we have faster requests, and therefore one less reason to have a production outage related to request queuing.

Remember that if your worker continue working on this failed task, it is not working on other tasks. And some failure reasons (like network error on third parties) have a high chance of happening again.

## Third party integrations

All of the above applies also to integration with third parties. Even if HTTP request has failed for transient failure (like timeout), it has a high chance to happen again if retried just after fail. Maybe your third party is temporarily overload, maybe they are just in the middle of the deployment, maybe they have a temporary bug on which their team is already working. Let it fail, and retry later.

## Error reporting and metrics

Why there were retries in the first place? Often they are added because the code failed once, the error came up to error reporting software and someone decided that if it has failed, then we need to retry it again. Noone likes to get a notification for an error about which you can't do anything, therefore it's best to just ignore these transient errors. Instead of reporting them, it's better to add a metric to your monitoring system each time your request succeed or fail and add an alert threshold when it fails too often. This is possible in all open source monitoring systems (like Grafana+InfluxDB) or proprietary ones (like NewRelic).
