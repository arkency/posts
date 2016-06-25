---
title: "Thanks to repositories..."
created_at: 2015-06-11 11:34:14 +0200
kind: article
publish: true
author: Piotr Macuk
tags: [ 'ruby', 'rails', 'repository pattern', 'entity object', 'active record' ]
newsletter: :fearless_refactoring_main
img: "thanks-to-repositories/repository.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("thanks-to-repositories/repository.jpg") %>" width="100%">
    <details>
      Source: <a href="http://commons.wikimedia.org/wiki/File:Documents_stacks_in_a_repository_at_The_National_Archives.jpg">Wikimedia Commons</a>
    </details>
  </figure>
</p>

I am working in Arkency for 2+ months now and building a tender documentation system for our client. The app is interesting because it has a dynamic data structure constructed by its users. I would like to tell you about my approaches to the system implementation and why the repository pattern allows me to be more safe while data structure changes.

<!-- more -->

# System description

The app has users with its tender projects. Each project has many named lists with posts. The post structure is defined dynamically by the user in project properties. The project property contains its own name and type. When the new project is created it has default properties. For example: ProductId(integer), ElementName(string), Quantity(float) Unit(string), PricePerUnit(price). User can change and remove default properties or add custom ones (i.e. Color(string)). Thus all project posts on the lists have dynamic structure defined by the user.


# The first solution

I was wondering the post structure implementation. In my first attempt I had two tables. One for posts and one for its values (fields) associated with properties. The database schema looked as follows:

```
#!ruby
create_table "properties" do |t|
  t.integer  "project_id", null: false
  t.string   "english_name"
  t.string   "value_type"
end

create_table "posts" do |t|
  t.integer  "list_id",              null: false
  t.integer  "position", default: 1, null: false
end

create_table "values" do |t|
  t.integer  "post_id",     null: false
  t.integer  "property_id", null: false
  t.text     "value"
end
```

That implementation was not the best one. Getting data required many SQL queries to the database. There were problems with performance while importing posts from large CSV files. Also large posts lists were displayed quite slow.

# The second attempt

I have removed the values table and I have changed the posts table definition as follows:

```
#!ruby
create_table "posts" do |t|
  t.integer  "list_id",              null: false
  t.integer  "position", default: 1, null: false
  t.text     "values"
end
```

Values are now hashes serialized in JSON into the values column in the posts table.

# The scary solution

In the typical Rails application with ActiveRecord models placed all around that kind of change involve many other changes in the application code. When the app has some code that solution is scary :(

But I was lucky :) At that time I was reading the [Fearless Refactoring Book by Andrzej Krzywda](http://rails-refactoring.com/) and that book inspired me to prepare data access layer as a set of repositories. I have tried to cover all ActiveRecord objects with repositories and entity objects. Thanks to that approach I could change database structure without pain. The changes was only needed in database schema and in PostRepo class. All application logic code stays untouched.

# The source code

## ActiveRecords

Placed in `app/models`. Used only by repositories to access the database.

```
#!ruby
class Property < ActiveRecord::Base
  belongs_to :project
end

class List < ActiveRecord::Base
  belongs_to :project
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :list
  serialize :values, JSON
end
```

## Entities

Placed in `app/entities`. Entities are simple PORO objects with Virtus included. These objects are the smallest system building blocks. The repositories use these objects as return values and as input parameters to persist them in the database.

```
#!ruby
class PropertyEntity
  include Virtus.model

  attribute :id, Integer
  attribute :symbol, Symbol
  attribute :english_name, String
  attribute :value_type, String
end

class ListEntity
  include Virtus.model

  attribute :id, Integer
  attribute :name, String
  attribute :position, Integer
  attribute :posts, Array[PostEntity]
end

class PostEntity
  include Virtus.model

  attribute :id, Integer
  attribute :number, String # 1.1, 1.2, ..., 2.1, 2.2, ...
  attribute :values, Hash[Symbol => String]
end
```

## Post repository

Placed in `app/repos/post_repo.rb`. PostRepo is always for single list only. The API is quite small:

  * `all` -- get all posts for the given list,
  * `load` -- get single post by its id from the given list,
  * `create` -- create post in the list by given PostEntity object,
  * `update` -- update post in the list by given PostEntity object,
  * `destroy` -- destroy post from the list by its id.

The properties array is given in initialize parameters. Please also take a note that ActiveRecord don't leak outside the repo. Even ActiveRecord exceptions are covered by the repo exceptions.

```
#!ruby
class PostRepo
  ListNotFound  = Class.new(StandardError)
  PostNotUnique = Class.new(StandardError)
  PostNotFound  = Class.new(StandardError)

  def initialize(list_id, properties)
    @list_id = list_id
    @ar_list = List.find(list_id)
    @properties = properties
  rescue ActiveRecord::RecordNotFound => error
    raise ListNotFound, error.message
  end

  def all
    ar_list.posts.order(:position).map do |ar_post|
      build_post_entity(ar_post)
    end
  end

  def load(post_id)
    ar_post = find_ar_post(post_id)
    build_post_entity(ar_post)
  end

  def create(post)
    fail PostNotUnique, 'post is not unique' if post.id
    next_position = ar_list.posts.maximum(:position).to_i + 1
    attributes = { position: next_position, values: post.values }
    ar_post = ar_list.posts.create!(attributes)
    ar_post.id
  end

  def update(post)
    ar_post = find_ar_post(post.id)
    ar_post.update!(values: post.values)
    nil
  end

  def destroy(post_id)
    ar_post = find_ar_post(post_id)
    ar_post.destroy!
    ar_list.posts.order(:position).each_with_index do |post, idx|
      post.update_attribute(:position, idx + 1)
    end
    nil
  end

  private

  attr_reader :ar_list, :properties

  def find_ar_post(post_id)
    ar_list.posts.find(post_id)
  rescue ActiveRecord::RecordNotFound => error
    raise PostNotFound, error.message
  end

  def build_post_entity(ar_post)
    number = "#{ar_list.position}.#{ar_post.position}"
    values_hash = {}
    if ar_post.values
      properties.each do |property|
        values_hash[property.symbol] = ar_post.values[property.symbol.to_s]
      end
    end
    PostEntity.new(id: ar_post.id, number: number, values: values_hash)
  end
end
```

# Sample console session

```
#!ruby
# Setup
> name = PropertyEntity.new(symbol: :name,
                            english_name: 'Name',
                            value_type: 'string')
> age = PropertyEntity.new(symbol: :age,
                           english_name: 'Age',
                           value_type: 'integer')
> properties = [name, age]

> post_repo  = PostRepo.new(list_id, properties)

# Post creation
> post = PostEntity.new(values: { name: 'John', age: 30 })
  => #<PostEntity:0x00000006ae93f8 @values={:name=>"John", :age=>"30"},
  => #                             @id=nil, @number=nil>
> post_id = post_repo.create(post)
  => 3470

# Get single post by id (notice that the number is set by the repo)
> post = post_repo.load(post_id)
  => #<PostEntity:0x00000005e52248 @values={:name=>"John", :age=>"30"},
  => #                             @id=3470, @number="1.1">

# Get all posts from the list
> posts = post_repo.all
  => [#<PostEntity:0x00000005eba0a0 ...]

# Post update
> post.values = { age: 31 }
 => {:age=>31}
> post_repo.update(post)
  => nil
> post = post_repo.load(post_id)
  => #<PostEntity:0x00000005ffc828 @values={:name=>nil, :age=>"31"},
  => #                             @id=3470, @number="1.1">

# Post destroy
> post_repo.destroy(post_id)
  => nil
```
