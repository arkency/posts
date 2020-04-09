---
title: "What I learned from reading spreadsheet_architect code"
created_at: 2017-08-18 11:59:07 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'spreadsheet_architect' ]
newsletter: arkency_form
---

Recently I heard about [`spreadsheet_architect` gem](https://github.com/westonganger/spreadsheet_architect) and I wondered a few things after reading its README. It all lead me to look into its code and wonder...

<!-- more -->

What started my curiosity was the API:

```ruby
class Post < ActiveRecord::Base
  include SpreadsheetArchitect
end

Post.order(name: :asc).where(published: true).to_xlsx
```

I was like _wow, why would anyone add such a thing to a model_? Why is it a good idea to extend my ActiveRecord class (which most likely already has tons of responsibilities) with methods responsible for generating reporting files. Dunno. Doesn't sound like the best use of [Single responsibility principle](https://en.wikipedia.org/wiki/Single_responsibility_principle).

But I was like... There must be a way to avoid it. After all, this gem can work with normal classes as well as documented:

```ruby
Post.to_xlsx(instances: posts_array)
```

or another way:

```ruby
headers = ['Col 1','Col 2','Col 3']
data = [[1,2,3], [4,5,6], [7,8,9]]
SpreadsheetArchitect.to_xlsx(data: data, headers: headers)
```

So probably including `SpreadsheetArchitect` is not mandatory.

I was thinking about checking the code to see how it gets the list of records and implementing a compatible interface inside a different class. I was pretty sure the method was `#to_a` because why not? What else could it be? So I hoped for this kind of workaround:

```ruby
class PostsReport
  include SpreadsheetArchitect

  def to_a
    Post.order(name: :asc).where(published: true).to_a
  end
end
```

or

```ruby
class PostsReport
  include SpreadsheetArchitect

  def initialize(collection)
    @collection = collection
  end

  def to_a
    @collection.to_a
  end
end
```

if we want to dynamically build and pass the collection for generating a report.

Then I could define methods such as `def spreadsheet_columns` which configure what is displayed in `PostsReport` instead of `Posts` because that sounded better to me. Less coupling, and bigger separation. Probably easier if we need to support multiple reports.

So I started looking into the code, how it works internally, to confirm my guesses.

```ruby
module SpreadsheetArchitect
  module ClassMethods
    def to_csv(opts={})
      opts = SpreadsheetArchitect::Utils.get_cell_data(opts, self)
      # ...
```

It turned out the logic was implemented in `get_cell_data`. Let's see what inside. It had 80 lines of code including this:

```ruby
def self.get_cell_data(options={}, klass)
  # ...
  if !options[:instances] && defined?(ActiveRecord) && klass.ancestors.include?(ActiveRecord::Base)
    # triggers the relation call,
    # not sure how this works but it does
    options[:instances] = klass.where(nil).to_a
  end
  # ...
```

Ok, so it turned out it is not just `to_a` but rather `where(nil).to_a`. I am not exactly sure why would `where(nil)` be necessary. At this point, I decided that working around the API is probably not worth it and too hard.

But I got curious how can it work? Because you see...

## And now something completely different

* `to_csv`, `to_xlsx`, methods are defined on `Post` (if you include the module)

```
Post.method(:to_csv)
=> #<Method: Class(SpreadsheetArchitect::ClassMethods)#to_csv>
```

* The example shows

```ruby
Post.order(name: :asc).to_xlsx
```

* but that is a relation

```
Post.order(name: :asc).class
# => Post::ActiveRecord_Relation
```

* so this check should fail

```
klass.ancestors.include?(ActiveRecord::Base)
```

* because

```ruby
Post::ActiveRecord_Relation.ancestors.include?(ActiveRecord::Base)
# => NameError: private constant #<Class:0x0000000478a240>::ActiveRecord_Relation referenced
# doh...

# workaround
Post.const_get(:ActiveRecord_Relation).ancestors.include?(ActiveRecord::Base)
# => false
```

Yep, [Ruby has private classes](/2016/02/private-classes-in-ruby/) and they are used here.

So how can this gem work with relations? Let's try something...

```ruby
class Post < ApplicationRecord
  include SpreadsheetArchitect

  def self.bump
    puts self.inspect
  end
end
```

Nothing out of ordinary here:

```ruby
Post.bump
# Post(id: integer, ...)
```

```ruby
Post.where(id: 1).inspect
# Post Load (0.6ms)  SELECT  "posts".* FROM "posts" WHERE "posts"."id" = $1 LIMIT $2  [["id", 1], ["LIMIT", 11]]
# => "#<ActiveRecord::Relation [#<Post id: 1, ...">]>"
```

But check this out:

```ruby
Post.where(id: 1).bump
# Post(id: integer, ...)
```

Even though this is `ActiveRecord::Relation`, methods which are dynamically executed report that `self` is the `Post` class.

Let's investigate further:

```
Post.where(id: 1).method(:method_missing)
# => #<Method: Post::ActiveRecord_Relation(ActiveRecord::Delegation::ClassSpecificRelation)#method_missing>

Post.where(id: 1).method(:method_missing).source_location
# => [".rvm/gems/ruby-2.4.1/gems/activerecord-5.1.2/lib/active_record/relation/delegation.rb", 87]
```

Let's see how this Rails magic works:

```ruby
def method_missing(method, *args, &block)
  if @klass.respond_to?(method)
    self.class.delegate_to_scoped_klass(method)
    scoping { @klass.public_send(method, *args, &block) }
  elsif arel.respond_to?(method)
    self.class.delegate method, to: :arel
    arel.public_send(method, *args, &block)
  else
    super
  end
end
```

* as you can see the method `bump` is delegated to the class directly. So that's why `self` is `Post`.
* But why is only a subset of records used for generating the file, and not all records, when the method is delegated directly to a class? Because `scoping` is used, which works like a global (probably a thread-safe global).

```ruby
Post.where(id: 1).method(:scoping).source_location
# => [".rvm/gems/ruby-2.4.1/gems/activerecord-5.1.2/lib/active_record/relation.rb", 334]
```

```ruby

# Scope all queries to the current scope.
#
#   Comment.where(post_id: 1).scoping do
#     Comment.first
#   end
#   # => SELECT "comments".* FROM "comments"
#        WHERE "comments"."post_id" = 1
#        ORDER BY "comments"."id" ASC
#        LIMIT 1
#
# Please check unscoped if you want to remove all previous scopes (including
# the default_scope) during the execution of a block.
def scoping
  previous, klass.current_scope = klass.current_scope, self
  yield
ensure
  klass.current_scope = previous
end
```

In other words before `Post#to_xlsx` is called, `Post.current_scope` is set temporarily and as a result `Post.where(nil).to_a` called by the `SpreadsheetArchitect` is limited in scope and does not include all records. That's how it works.

<iframe src="https://giphy.com/embed/UtxLc5i9wGdKo" width="480" height="316" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/fighter-jet-ejects-UtxLc5i9wGdKo">via GIPHY</a></p>

## Wanna learn more?

Subscribe to [our newsletter](http://arkency.com/newsletter) to receive weekly free Ruby and Rails lessons.
