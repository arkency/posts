---
title: "ruby to enum enumerator"
created_at: 2013-12-30 17:22:14 +0100
kind: article
publish: false
author: Robert Pankowecki
tags: [ 'ruby', 'to_enum', 'enumerator', 'enumerable' ]
---

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
which happens contain something else, well then maybe external `Enumerator`
is your solution.

## Standard library

If you call the most famous `Array#each` method without a block, you will see that
you get an enumerator in the response.

```
#!ruby

e = [1,2,3].each
# => #<Enumerator: [1, 2, 3]:each> 
```

You can manually fetch new elemens:

```
e.next
# => 1 

e.next

# => 2 

# e.next
=> 3 

e.next
# StopIteration: iteration reached an end
```

Or use one of the `Enumerable` method that `Enumerator` gladly provides for you

```
#!ruby

e = [1,2,3].each

e.partition{|x| x % 2 == 0}
# => [[2], [1, 3]] 
```

## Create `Enumerator`

There are 3 ways to create your own `Enumerator`:

* `Kernel#to_enum`
* `Kernel#enum_for`
* `Enumerator.new`

### `to_enum` & `enum_for`

Same thing:

* https://github.com/ruby/ruby/blob/520f0fec9519647e8ae1dfc15756b537fe580d6e/enumerator.c#L1994
* https://github.com/ruby/ruby/blob/520f0fec9519647e8ae1dfc15756b537fe580d6e/enumerator.c#L2021

void
InitVM_Enumerator(void)
{
    rb_define_method(rb_mKernel, "to_enum", obj_to_enum, -1);
    rb_define_method(rb_mKernel, "enum_for", obj_to_enum, -1);



   rb_define_method(rb_cLazy, "to_enum", lazy_to_enum, -1);
    rb_define_method(rb_cLazy, "enum_for", lazy_to_enum, -1);

```
#!ruby
a = [1,2,3]
e = a.to_enum(:each)
```

## Your library

If you want to pr
