---
created_at: 2024-03-29 23:36:29 +0100
author: Szymon Fiedler
tags: [rails, aasm, enum, active_record, rails upgrade]
publish: true
---

# Replace aasm with Rails Enum today

There’s a great chance that your Rails app contains one of the gems providing so called state machine implementation. There’s even a greater chance that it will be [aasm](https://github.com/aasm/aasm) formerly known as `acts_as_state_machine`. Btw. Who remembers [acts_as_hasselhoff](https://github.com/mariozig/acts_as_hasselhoff)? — ok, boomer. The _aasm_ does quite a lot when included into your `ActiveRecord` model — the question is do you really need all those things?

<!-- more -->

## My problem with aasm

I was struck by reckless use of this gem so many times that first thing I do after joining a new project is running `cat Gemfile | grep aasm` and here comes the meme which I made ~1.5 years ago:

<img src="<%= src_fit("replace_aasm_with_rails_enum_today/703rne.jpg") %>" width="100%">

My main concern with use of this gem is that you probably don’t need all the features it offers. More features means more temptation to use them. Greater use across the codebase means more coupling to external library which can be incompatible with upcoming Rails versions, blocking you from upgrade or making it pretty costly. You have to read yet another changelog to check if there aren’t any breaking changes or some subtle behavior change running your serious business application into problems.

Next thing is that it promotes patterns like callbacks which I personally see as a huge problem within complex rails applications. I prefer explicit code, callbacks aren’t such. _Ackchyually callbacks are a part of the framework_, I know, but let’s leave this discussion for another place in time.

It’s also struggle for all the IDEs, Language Server Providers to find definitions of methods defined by _aasm’s_ DSL and you are forced to use `grep`, read the code carefully and decide whether those `active!` method comes from or where my `pending` scope is defined.

I’ve recently learned that it also autogenerates constants for each state _so I don’t have to_. I’ve recently spotted `Transaction::STATUS_FAILED` somewhere, it took quite some time to figure out the origin of this constant which wasn’t explicitly defined within the `Transaction` class.

Those _free lunches_ can be tasty, but eventually you will be forced to pay for them.

Last, but not least, having attribute like _state_ or _status_ often suggest poor design in your codebase, but that’s a totally different story.

## Starting point

Nine years old legacy Rails app backing very successful business. Let’s have a look at some of the details:

```shell
-> ruby -v
ruby 3.3.0 (2023-12-25 revision 5124f9ac75)

-> bin/rails r "p Rails.version"
"7.1.3.2"

-> bundle list | wc -l
319

-> rg include\ AASM -l | wc -l
33
```

Few uses of `model.aasm.states.map(&:name)`

Two uses of `SwitchRequest.aasm.states_for_select` to provide options for some `<select>` tags.


## Rails, the white knight

As a Rails developer, you’re probably familiar with *enum* which was [introduced in Rails 6.0](https://api.rubyonrails.org/v6.0/classes/ActiveRecord/Enum.html) and allowed to declare an attribute where the values map to integers in the database. It evolved a bit with next framework versions, but Rails 7.1 finally brought all the features required to replace all of the *aasm* uses in the codebase I’m currently working on.

Let’s make use of this simple class as an example for our further work:

```ruby
class Transaction < ApplicationRecord
  include AASM

  PROCESSING = :processing
  FAILED = :failed
  SUCCESSFUL = :successful
  CANCELED = :canceled

  aasm column: :status do
    state PROCESSING, initial: true
    state FAILED
    state SUCCESSFUL
    state CANCELED
  end
end
```


### What’s required to get exact the same behavior

* **Scopes** like `Transaction.successful` to query all the transactions having status `successful` — we can have those for free from `ActiveRecord::Enum`.
* **Instance methods** to:
	* check whether our object’s status is `successful?` — *enum* got you covered
	* change the status to `successful` and run `save!` as we got used to it — same here, *enum* will do it’s job here if you call `transaction.successful!`
* Set desired **initial state** for new objects — this can be done by providing `default` keyword argument to `enum` method, like `default: PROCESSING`.
* Values need to be stored as strings, not as integers in the db — it’s possible since [Rails 7.0](https://api.rubyonrails.org/v7.0/files/activerecord/lib/active_record/enum_rb.html)
* Hopefully there were no transitions or guards in state machines in our application — yet another reason to not employ *aasm* — but I can image implementing it with `ActiveRecord::Dirty` quite easy. Or even better, implement this behavior as a higher level abstracion and keep you model dummy in this matter.
* No callbacks either, yay!
* Constants containing all the possible states were already in place, so those defined by *aasm*, like `STATUS_PROCESSING, STATUS_SUCCESSFUL` and so on were something nobody asked for.

#### Validation of the provided value
There’s slight difference in default *enum* behavior. If the provided a value doesn’t match specified values, you will be struck with `ArgumentError` when trying to assign one.

As mentioned earlier, in Rails 7.1 there’s a possibility to provide `validate: true` keyword argument. *Enum* will behave exactly the same as *aasm* in this manner which checks the validity of provided value before save resulting in `ActiveRecord::RecordInvalid` instead.

### Show me the code

```ruby
class Transaction < ApplicationRecord
    PROCESSING = :processing
    FAILED = :failed
    SUCCESSFUL = :successful
    CANCELED = :canceled

    enum :status,
         { processing: PROCESSING,
           failed: FAILED,
           successful: SUCCESSFUL,
           canceled: CANCELED
         }.transform_values(&:to_s),
         default: PROCESSING.to_s,
         validate: true
end
```

That’s it. Quit clean and understandable, isn’t it?

## The values quirk
There’s one quirk, you’ve probably already noticed: `transform_values(&:to_s)`. I was quite confused what’s going on when I’ve provided symbols as values initially. Let’s see how the code looked like before:

```ruby
class Transaction < ApplicationRecord
    PROCESSING = :processing
    FAILED = :failed
    SUCCESSFUL = :successful
    CANCELED = :canceled

    enum :status,
         { processing: PROCESSING,
           failed: FAILED,
           successful: SUCCESSFUL,
           canceled: CANCELED
         },
         default: PROCESSING,
         validate: true
end
```

The documentation hasn’t clearly stated that values should be strings. The example used `String` values, but there was no clear expectation about that. However, when saving the object, `status` became `nil` at some point, despite assigning `”successful”` value.

I wrote a dummy app and test for this specific case aside from the main application I was working on. To be 100% sure that there’s no other factor influences this behavior:

```ruby
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'activerecord'
  gem 'sqlite3'
  gem 'minitest'
end

require 'active_record'
require 'sqlite3'
require 'minitest/autorun'

begin
  db_name = 'enum_test.sqlite3'.freeze

  SQLite3::Database.new(db_name)
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: db_name)
  ActiveRecord::Schema.define do
    create_table :transactions, force: true do |t|
      t.string :status
    end
  end

  class Transaction < ActiveRecord::Base
    PROCESSING = :processing
    FAILED = :failed
    SUCCESSFUL = :successful
    CANCELED = :canceled

    enum :status,
         { processing: PROCESSING,
           failed: FAILED,
           successful: SUCCESSFUL,
           canceled: CANCELED
         },
         default: PROCESSING,
         validate: true
  end

  class TestTransaction < Minitest::Test
    def test_enum_behavior
      transaction = Transaction.new(status: :successful)
      assert_equal 'successful', transaction.status

      transaction.save!
      assert_equal 'successful', transaction.reload.status
    end
  end
ensure
  Dir.glob(db_name + '*').each { |file| File.delete(file) }
end
```

Result:

```shell
ruby enum.rb
-- create_table(:transactions, {:force=>true})
   -> 0.0076s
Run options: --seed 3038

# Running:

F

Finished in 0.013456s, 74.3163 runs/s, 148.6326 assertions/s.

  1) Failure:
TestTransaction#test_enum [enum.rb:44]:
Expected: "successful"
  Actual: nil

1 runs, 2 assertions, 1 failures, 0 errors, 0 skips
```

Ok, so the value is correctly set, but it disappears when `save!` is called. After quick session with debugger I was able to figure out that undesired change from `"successful"` to `nil` happens inside [Enum::EnumType#deserialize](https://github.com/rails/rails/blob/6f0d1ad14b92b9f5906e44740fce8b4f1c7075dc/activerecord/lib/active_record/enum.rb#L190-L192) method. Generic `ActiveModel::Type::Value` class which is a parent for the `ActiveRecord::Enum::EnumType` describes the purpose of `deserialize` method like that:

> Converts a value from database input to the appropriate ruby type. The return value of this method will be returned from `ActiveRecord::AttributeMethods::Read#read_attribute`. The default implementation just calls `Value#cast`.

Let’s have a  look at our specific scenario:

```ruby
# value = "successful"
# mapping = ActiveSupport::HashWithIndifferentAccess.new({
#  "processing" => :processing,
#  "failed" => :failed,
#  "successful" => :successful,
#  "canceled" => :canceled,
# })
# subtype = ActiveModel::Type::String instance

def deserialize(value)
  mapping.key(subtype.deserialize(value))
end
```

What exactly happens:

1. `subtype.deserialize(value)` returns `”successful”`
2. `mapping` is asked to return a key for `”successful”` value, but there is no such in the hash, there’s a `Symbol` `:succesful` — yikes
3. `deserialize("successful")` returns `nil` instead of `"successful"`

Probably a single line in the docs like: _Don’t put symbols as values when defining the enum_ would do the job and save my time and potentially many other confused developers. What’s even more puzzling is the fact that you can provide default value as a `Symbol`, you can assign a value which is a `Symbol` and it will be stored as a `String`, which is understandable, but the definition has to contain string values — hence the `.transform_values(&:to_s)` trick.

However, _why use symbols to define possible state?_, you may ask. Because it’s a requirement of _aasm_. State has to be `Symbol` or object responding to `#name` method. If you provide `String`, you’ll see nice `NoMethodError` because it doesn’t respond to `name`.

You know what’s even funnier? Database returns `String` when asked for `Transactions#status`. Serializing it to *JSON* will also turn it into `String` as *JSON* doesn’t implement symbols. I could imagine more scenarios when constant casting from `Symbol` to `String` back and forth happen without any particular reason. But that’s exactly how 3rd party gem (*AASM*) drives your architectural decisions.

## We can do even better

If you aren’t using scopes, you can simply disable them with `scopes: false`.

Same goes for instance methods like `succesful!` or `failed?`, those can be disabled with `instance_methods: false`.

Most of the models that was rewritten required both, but whenever it was possible I disabled both of the features.

Occurrences of `Model.aasm.states.map(&:name)` are replaceable by `Model.statuses.values`.

`Model.aasm.states_for_select` helper can be replaced with `Model.statuses.values.map { |name, value| [I18n.l(name), value] }`. Extract this to one of your helpers.
Maybe you don’t need to call `I18n` at all and simple `humanize` will be enough.

Now it’s your turn.
