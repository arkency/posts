---
title: "A scary side of ActiveRecord's find"
created_at: 2019-03-19 10:10:33 +0100
kind: article
publish: true
author: Jakub Kosiński
tags: [ 'active record', 'find' ]
newsletter: arkency_form
---
<%= img_fit("scary_record/hacker.jpg") %>

Recently I was refactoring a part of one our projects to add more domain events to the Identity bounded context so that we can have better audit logs of certain actions performed on identities in our system. I started from extracting a service that was responsible for consuming commands. I started with something like this:

```ruby
class UpdatePersonalSettings
  include Command
  attribute :email, String
  attribute :name, String
  attribute :identity_id, Integer
end

class IdentityService
  # ...

  def update_personal_settings(command)
    Identity.find(command.identity_id) do |identity|
      identity.email = command.email
      identity.name = command.name
      identity.save!
      publish(
        PersonalSettingsUpdated.strict(
          data: {
            identity_id: identity.id,
            email: identity.email,
            name: identity.name
          }
        )
      )
    end
  end

  # ...
end
```

At first sights, everything looked OK. I had some tests that was verifying the intended behaviour so I deployed the code to the test environment. Then I realized that something is wrong - when I was trying to update the name of my test account, I received a uniqueness validation error on the email field.

<!-- more -->

What?! I started to debug logs and it turned out that I was actually updating the **first** identity and not the one identitfied with `command.identity_id`. I looked back at the test suite - everything looks correct, my test cases where I update the name & the email pass, so what's wrong here? Then I looked at the ActiveRecord's `find` method sources:

```ruby
# File activerecord/lib/active_record/core.rb, line 157
      def find(*ids) # :nodoc:
        # We don't have cache keys for this stuff yet
        return super unless ids.length == 1
        return super if block_given? ||
                        primary_key.nil? ||
                        scope_attributes? ||
                        columns_hash.include?(inheritance_column)

        id = ids.first

        return super if StatementCache.unsupported_value?(id)

        key = primary_key

        statement = cached_find_by_statement(key) { |params|
          where(key => params.bind).limit(1)
        }

        record = statement.execute([id], connection).first
        unless record
          raise RecordNotFound.new("Couldn't find #{name} with '#{primary_key}'=#{id}",
                                   name, primary_key, id)
        end
        record
      rescue ::RangeError
        raise RecordNotFound.new("Couldn't find #{name} with an out of range value for '#{primary_key}'",
                                 name, primary_key)
      end
```

That `super` was really interesting, so I started the console and just run the following snippet:

```
>> User.find(123) do |identity|
?>     puts identity
>>   end
  User Load (3.3ms)  SELECT `users`.* FROM `users`
#<User:0x00007faf2d800c30>
#<User:0x00007faf2d800af0>
#<User:0x00007faf2d8009b0>
#<User:0x00007faf2d800870>
#<User:0x00007faf2d800730>
#<User:0x00007faf2d8005f0>
#<User:0x00007faf2d8004b0>
#<User:0x00007faf2d800370>
#<User:0x00007faf2d800230>
#<User:0x00007faf2d8000f0>
=> nil
```

Now I realized what was going on - my code was just iterating over all records in the DB table and try to evaluate given block on each record. Thankfully validations have detected this behaviour on the test environment quickly, but it might be really dangerous if the code would be run on production and there would be no uniqueness validation - I would just update all reacords in DB.
The other thing is that my test cases were also not smart enough to detect this issue - I should just create more than one identity in tests & try to update at least two of them.

You might ask what was the solution? The solution was really obvious - I just forgot to add `tap` to my `find` call:

```ruby
class IdentityService
  # ...

  def update_personal_settings(command)
    Identity.find(command.identity_id).tap do |identity|
      identity.email = command.email
      identity.name = command.name
      identity.save!
      publish(
        PersonalSettingsUpdated.strict(
          data: {
            identity_id: identity.id,
            email: identity.email,
            name: identity.name
          }
        )
      )
    end
  end

  # ...
end
```

I am considering reporting this as a bug since when you pass arguments & a block to `find` the arguments will be silently ignored. I think such calls should at least issue a warning that your arguments are ignored due to the block so that you can easily find out why your code does not work as intended.
