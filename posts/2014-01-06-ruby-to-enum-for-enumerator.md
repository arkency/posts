---
title: "Stop including Enumerable, return Enumerator instead"
created_at: 2014-01-08 17:22:14 +0100
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'ruby', 'to_enum', 'enumerator', 'enumerable' ]
newsletter: :arkency_form
---

<img src="<%= src_fit("enumerator/each.png") %>" width="100%">

Many times I have seen people including `Enumerable` module into their
classes. But I cannot stop thinking that in many cases having methods
such as [`each_with_index`](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-each_with_index)
or [`take_while`](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-take_while) or
[`minmax`](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-minmax) and many others
that are available in [`Enumerable`](http://ruby-doc.org/core-2.1.0/Enumerable.html) are not
core responsibility of the class that is including them itself.

<!-- more -->

In such case I prefer to go Java-way and provide external `Enumerator` for
those who need to call one of the many useful `Enumerable` methods on the
collection. I think that we need to ask ourselves a question: _Is that class a
collection?_. If it really is then it absolutely makes sense to
`include Enumerable`. If however it is not a collection, but rather a class
which happens contain something else, or providing a collection,
well then maybe external `Enumerator` is your solution.

## Standard library

If you call the most famous `Array#each` method without a block, you will see that
you get an enumerator in the response.

```ruby

e = [1,2,3].each
# => #<Enumerator: [1, 2, 3]:each> 
```

You can manually fetch new elemens:

```ruby
e.next
# => 1 

e.next
# => 2 

e.next
#=> 3 

e.next
# StopIteration: iteration reached an end
```

Or use one of the `Enumerable` method that `Enumerator` gladly provides for you

```ruby

e = [1,2,3].each

e.partition{|x| x % 2 == 0}
# => [[2], [1, 3]] 
```

## Create `Enumerator`

There are 3 ways to create your own `Enumerator`:

* `Kernel#to_enum`
* `Kernel#enum_for`
* `Enumerator.new`

But if you look into MRI implemention you will notice that both `#to_enum` and
`#enum_for` are implemented in the same way:


```cpp
rb_define_method(rb_mKernel, "to_enum", obj_to_enum, -1);
rb_define_method(rb_mKernel, "enum_for", obj_to_enum, -1);

rb_define_method(rb_cLazy, "to_enum", lazy_to_enum, -1);
rb_define_method(rb_cLazy, "enum_for", lazy_to_enum, -1);
```

You can check it out here:

* [enumerator.c#L1994-1995](https://github.com/ruby/ruby/blob/520f0fec9519647e8ae1dfc15756b537fe580d6e/enumerator.c#L1994-1995)
* [enumerator.c#L2021-2022](https://github.com/ruby/ruby/blob/520f0fec9519647e8ae1dfc15756b537fe580d6e/enumerator.c#L2021-2022)

And if you look into rubyspec you will also notice that they are supposed to
have identicial behavior, so I guess currently there is really no difference
between them

* [to\_enum\_spec.rb#L7](https://github.com/rubyspec/rubyspec/blob/7fb7465aac1ec8e2beffdfa9053758fa39b443a5/core/enumerator/to_enum_spec.rb#L7)
* [enum\_for\_spec.rb#7](https://github.com/rubyspec/rubyspec/blob/7fb7465aac1ec8e2beffdfa9053758fa39b443a5/core/enumerator/enum_for_spec.rb#7)

Therfore whenever you see an example using one of them, you can just substitue
it with the other.

## `#to_enum` & `#enum_for`

What can `#to_enum` & `#enum_for` do for you? Well, they can create the
`Enumerator` based on any method which `yield`s arguments. Usually
the convention is to create the `Enumerator` based on method `#each`
(no surprise here).

```ruby
a = [1,2,3]
enumerator = a.to_enum(:each)
```

We will see it in action later in the post.

## `Enumerator.new`

This way (contrary to the previous) has a [nice documentation in Ruby doc](http://www.ruby-doc.org/core-2.1.0/Enumerator.html#method-c-new)
which I am just gonna paste here:

_Iteration is defined by the given block, in which a “yielder” object, given as block parameter, can be used to yield a value_:

```ruby
fib = Enumerator.new do |y|
  a = b = 1
  loop do
    y << a
    a, b = b, a + b
  end
end

fib.take(10) # => [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
```

_The optional parameter can be used to specify how to calculate the size in a lazy fashion. It can either be a value or a callable object._

Here is my example:

```ruby
polish_postal_codes = Enumerator.new(100_000) do |y|
  100_000.times do |number|
    code    = sprintf("%05d", number)
    code[1] = code[1] + "-"
    y.yield(code)
  end
end

polish_postal_codes.size    # => 100000 
                            # returned without computing
                            # all elements

polish_postal_codes.take(3) # => ["00-000", "00-001", "00-002"]
```

## Why?

Of course returning `Enumerator` makes most sense when returning collection (such as `Array`)
would be inconvinient or impossible due to performance reasons, like
[IO#each_byte](http://www.ruby-doc.org/core-2.1.0/IO.html#method-i-each_byte) or
[IO#each_char](http://www.ruby-doc.org/core-2.1.0/IO.html#method-i-each_char).

## What do you need to remember?

Not much actually. Whenever your method `yield`s values, just use `#to_enum`
(or `#enum_for` as you already know there are identical) to create
`Enumerator` based on the method itself, if block code is not provided.
Sounds complicated? It is not. Have a look at the example.

```ruby
require 'digest/md5'

class UsersWithGravatar
  def each
    return enum_for(:each) unless block_given? # Sparkling magic!

    User.find_each do |user|
      hash  = Digest::MD5.hexdigest(user.email)
      image = "http://www.gravatar.com/avatar/#{hash}"
      yield user unless Net::HTTP.get_response(URI.parse(image)).body == missing_avatar
    end
  end


  private

  def missing_avatar
    @missing_avatar ||= begin
      image_url = "http://www.gravatar.com/avatar/fake"
      Net::HTTP.get_response(URI.parse(image_src)).body
    end
  end
end
```

We are working in super startup having milions of users. And thousands of them can
have gravatar. We would prefer not to return them all in an array right? No problem.
Thanks to our magic oneliner `return enum_for(:each) unless block_given?` we can
share the collection without computing all the data.

This might be really usefull, especially when the caller does not need to have it all:

```ruby
class PutUsersWithAvatarsOnFrontPage
  def users
    @users ||= UsersWithGravatar.new.each.take(20)
  end
end
```

Or when the caller wants to be a bit [`#lazy`](http://ruby-doc.org/core-2.1.0/Enumerable.html#method-i-lazy) :

```ruby
UsersWithGravatar.
  new.
  each.
  lazy.
  select{|user| FacebookFriends.new(user).has_more_than?(10) }.
  and_what_not # ...
```

Did i just say `lazy`? I think I should stop here now, because that is a completely
different [story](http://patshaughnessy.net/2013/4/3/ruby-2-0-works-hard-so-you-can-be-lazy).

## TLDR

To be consistent with Ruby Standard Library behavior, please return
`Enumerator` for your `yield`ing methods when block is not provided. Use this code 

```ruby
return enum_for(:your_method_name_which_is_usually_each) unless block_given?`
````

to just do that.

Your class does not always need to be `Enumerable`. It is ok if it just
returns `Enumerator`.

## Don't miss our next blog post

If you enjoyed the article, 
[follow us on Twitter](https://twitter.com/arkency)
[and Facebook](https://www.facebook.com/pages/Arkency/107636559305814), 
or [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always
the first one to get the knowledge that you might find useful in your
everyday programmer job. Content is mostly focused on (but not limited to)
Rails, Webdevelopment and Agile.

Make sure to [check our books and videos](/products)
