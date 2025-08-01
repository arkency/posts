---
created_at: 2025-08-01 13:07:00 +0200
author: Łukasz Reszke
tags: []
publish: false
---

# Watch out for this one deprecation warning when upgrading from Rails 7.1 to 7.2 on Heroku

We recently upgraded Rails from 7.0 to 7.1 for one of our clients. It went smoothly.
When Rails 7.1 went live, we were pleased to see a new set of deprecation warnings. To avoid being overwhelmed by them, we decided to address the issue right away.
However, we ran into a nasty issue...

## The one with nasty issue

The application didn't crash.

The server wasn't throwing 500s like a crazy Viking throwing axes.

Either of those would have been better. The worst that can happen is silence.

The deprecation warning was:

```ruby
[DEPRECATION] DEPRECATION WARNING: `Rails.application.secrets` is deprecated 
in favor of `Rails.application.credentials` and will be removed in Rails 7.2.
```

We removed values from `ENV["SECRET_KEY_BASE"]` to credentials and checked that the value was correct by calling
`Rails.application.credentials.secret_key_base`.

It turned out that you can also get the secret_key_base by calling `Rails.application.secret_key_base`. 


Let's take a look at this code: 

```ruby
def secret_key_base
  if Rails.env.development? || Rails.env.test?
    secrets.secret_key_base ||= generate_development_secret
  else
    validate_secret_key_base(
      ENV["SECRET_KEY_BASE"] || credentials.secret_key_base || secrets.secret_key_base
    )
  end
end
```

Ok so to sum it up, until now:
- We removed ENV 
- So it should take the value from credentials 

Right? But instead...

Instead it failed silently. So where’s the poop?

<img src="<%= src_original("deprecation_warning_rails_7-1_to_7-2/himym-wheres.gif") %>" width="100%">

The poop is in Heroku trying to be smarter than developers. Unfortunately. It turned out that removing `SECRET_KEY_BASE` env leads to.. regenerating it with new **random** value.

So our external devices depending on it couldn’t work because of new, randomly generated key.

## Summary
To sum it up:
- If you’re getting rid of the `Rails.application.secrets` is deprecated in favor of `Rails.application.credentials` and will be removed in Rails 7.2
- And you’re on Heroku
- And you’re using Heroku Buildpacks
- Make sure you keep `SECRET_KEY_BASE` in both credentials and in Heroku ENV variable
- Either way... you may end up in nasty silent error. Which is not good.
