---
title: "Service objects as a way of testing Rails apps (without factory_girl)"
created_at: 2014-06-31 12:00:20 +0200
kind: article
publish: true
author: Robert Pankowecki
newsletter_inside: fearless_refactoring_1
tags: [ 'service_objects', 'rails', 'testing']
---

<p>
  <figure>
    <img src="<%= src_fit("services-test-setup/setup_test_services.jpg") %>" width="100%">
  </figure>
</p>

There's been recently an interesting discussion about setting up the initial state of your tests. Some are in favor of
using built-in Rails fixtures (because of speed and simplicity). Others are in favor of using *factory_girl* or similar
gems. I can't provide definite numbers but judging  based on the apps that we review, **in terms of adoption,
*factory_girl* seems to have won**. 

I would like to present you a third alternative "**Setting up tests with services**" (the same ones you use in your
production code, not ones crafted specifically for tests) and compare it to *factory_girl*
to show where it might be beneficial to go with such approach.

<!-- more -->

Let's start with a little background from an imaginary application for teaching languages in schools.
 
There is a school in our system which decided to use our software and buy a license. Teacher can create classes to
teach a language (or use existing one created by someone else). During the procedure multiple pupils can be imported
from file or added manually on the webui. The teacher will be teaching a class. The school is
having a native language and the class is learning a foreign language. Based on that we provide them with access
to school dictionaries suited to kids' needs.

## Everything is ok 

Let's think about our tests for a moment.

```ruby
let!(:school)     { create(:school, native_language: "en") }
let!(:klass)      { create(:klass, school: school) }
let!(:pupil)      { create(:pupil, klass: klass) }

let!(:teacher)    { create(:teacher,
  school:    school, 
  languages: %w(fr it),
) }

let!(:dictionary) { create(:dictionary, 
  native_language:   "en", 
  learning_language: "fr",
) }

let!(:assignment) { create(:assignment, 
  klass:      klass, 
  teacher:    teacher, 
  dictionary: dictionary,
) }


specify "pupil can learn from class dictionaries" do
  expect(
    teaching.dictionaries_for(pupil.id)
  ).to include(dictionary)
end
```

So far so good. Few months pass by, we have more tests we setup like that or in a similar way and then **we start
to stumble upon more of the less common usecases during the conversations with our client. And as it always is
with such features, they force use to rethink the underlying architecture of our app.**

One of our new requirements is that when teacher is no longer assigned to a class this doesn't mean that a class is not
learning the language anymore. In other words in our domain once pupils are assigned to a class that is learning
French it is very unlikely that at some point they stopped learning French (at least in that educational system which
domain we are trying to reflect in our code). It might be that the class no longer has a french teacher for a moment
(ex. before the school finds replacement for her/him) but that doesn't mean they no longer learn French.
 
Because we try to not delete data (soft delete all the way) we could have keep getting this knowledge about dictionaries
from _Assignments_. But since **we determined very useful piece of knowledge domain (_the fact of learning a language is
not directly connected to the fact of having teacher assigned_) we decided to be explicit about it** on our code. So we
added new `KlassLanguage` class which is created when a class is assigned a new language for the first time.

## You don't even know what hit you

We changed the implementation so it creates `KlassLanguage` whenever necessary. And we changed `#dictionaries_for`
method to obtain the dictionaries from `KlassLanguage` instead of `Assignment`. **We migrated old data. We can click
through our webapp and see that everything works correctly. But guess what. Our tests fail**. Why is that so?

Our tests fail because we must add one more piece of data to them. The `KlassLanguage` that we introduced.

```ruby
let!(:klass_language) { create(:klass_language,
  klass: klass, 
  dictionary: dictionary,
) }
```

Imagine adding that to dozens or hundred tests that you already wrote. No fun. It would be as if **almost all those tests
that you wrote discouraged you from refactorings instead of begin there for you so you can feel safely improving your
code**. 

Consider that after introducing our change to code, **some tests are not even properly testing what they used
to test**. Like imagine you had a test like this:

```ruby

let!(:assignment) { create(:assignment,
  klass:      klass, 
  teacher:    teacher, 
  dictionary: french_dictionary
) }

specify "pupil cannot learn from other dictionaries" do
  expect(
    teaching.dictionaries_for(pupil.id)
  ).not_to include(german_dictionary)
end
```

This test doesn't even make sense anymore because we no longer look for the dictionaries that are available for a pupil
in _Assignments_ but rather in _KlassLanguages_ in our implementation.

When you have hundreds of *factory_girl-based* test like that they are (imho) preventing you from bigger changes to your
app. From making changes to your db structure, from moving the logic around. It's almost as if every step you wanna
make in a different direction was not permitted.

## We draw parallel

Before we tackle our problem let's for a moment talk about basics of TDD and testing. Usually when they try to teach you
testing you start with simple data structure such as `Stack` and you try to implement it using existing language structure
and verify its correctness.

```ruby

class Stack
  Empty = Class.new(StandardError)
  
  def initialize
    @collection = []
  end
  
  def push(obj)
    @collection.push(obj)
  end
  
  def pop
    @colllection.empty? and raise Empty
    @collection.pop
  end
end
```

So you put something on the stack, you take it back and you verify that it is in fact the same thing.

```ruby

describe Stack do
  subject(:stack) { described_class.new }
  specify "last put element is first to pop" do
    stack.push(pushed = Object.new)    
    expect(popped = stack.pop).to eq(pushed)
  end
end
```

Why am I talking about this?

Because I think that **what many rails projects started doing with *factory_girl* is no longer similar to our
basic TDD technique**. 

I cannot but think we started to turn our test more into something like:

```ruby

describe Stack do
  subject(:stack) { described_class.new }
  specify "last put element is first to pop" do
    stack.instance_variable_set(:@collection, [pushed = Object.new])
    expect(popped = stack.pop).to eq(pushed)
  end
end
```

So instead of interacting with our SUT (_System under Test_) through set of exposed methods **we violate its boundaries
and directly set the state**. In this example this is visible at first sight because we use
[`instance_variable_set`](http://ruby-doc.org/core-2.1.2/Object.html) and no one would do such thing in real life.
[Right?](/assets/sounds/right.mp3)

But the situation with factories is not much different in fact from what we just saw. Instead of building the state
through set of interactions that happened to system **we tried to build the state directly**.

With factories we build the state as we know/imagine it to be at the very moment of writing the test. And **we rarely tend
to revisit them later with the intent to verify the setup and fix it**. Given enough time  it might be even hard to imagine
what sequence of events in system the original test author imagined leading to a state described in a test. 

This means that we are not protected in any way against changes to the internal implementation that happen in the future.
Same way you can't just rename `@collection` in the stack example because the test is fragile.
 
In other words, **we introduced a third element into _Command/Query_ separation model** for our tests. Instead of issuing
_Commands_ and testing the result with _Queries_ we issue commands and test what's in db. And for _Queries_ we set state
in db and then we run _Queries_. But we usually have no way to ensure synchronization of those test. We are not sure
that what _Commands_ created is the same for what we test in _Queries_.

## You take revenge

What can we do to mitigate this unfortunate situation? Go back to the basic and **setup our tests by directly interacting
with the system** instead of building its state. In case of our original school example it might look like.

```ruby

registration = SchoolRegistration.new
registration.call(SchoolRegistration::Input.new.tap do |i|
  i.school_attributes  = attributes(:school, native_language: "en")
  i.teacher_attributes = teacher_attributes = attributes(:teacher,
    id: "f154cc85-0f0d-4c5a-9be1-f71aa217b2c0", 
    languages: %w(fr it) 
  )
end)

class_creation = ClassCreation.new
class_creation.call(ClassCreation::Input.new.tap do |i|
  i.id = "5c7a1aa9-72ca-46b2-bf8c-397d62e7db19"
  i.klass_number = "1"
  i.klass_letter = "A"
  i.klass_pupils = [{
    id: "6d805bdd-79ff-4357-88cc-45baf103965a",
    first_name: "John",
    last_name:  "Doe",
  }]
end)

assignment = ClassAssignment.new
assignment.call(ClassAssignment::Input.new.tap do |i|
  i.klass_id   = "5c7a1aa9-72ca-46b2-bf8c-397d62e7db19"
  i.teacher_id = teacher_attributes.id
  i.learning_language = "fr"
end)
```

This setup is way longer because in some places we decided to go with longer syntax and set some attribute by hand
(although) we didn't have to. This example mixes two approaches so you can see how you can do things *longer-way* and
*shorter-way* (by using attributes). We didn't take a single step to refactor it into shorter expression and to be more reusable in
multiple tests because I wanted you to see a full picture of it. **But extracting it into smaller test helpers, so that the
test setup would be as short and revealing in our factory girl example would be trivial**. For now let's keep focus on our case. 

What can we see from this test setup? **We can see the interactions that led to the state of the system**. There were 3 of
them and are similar to how I described the entire story for you. First teacher registered (first teacher creates the school
as well and can invite the rest of the teachers). Teacher created a class with pupils (well, one pupil to be exact).
Teacher assigned the class to himself/herself as a French teacher.

It's the last step implementation that we had to change to for our new feature. It had to store `KlassLanguage`
additionally and required our tests to change, which we didn't want to.

## It doesn't have to be all about DB.

Let's recall our test:

```ruby

specify "pupil can learn from class dictionaries" do
  expect(
    teaching.dictionaries_for(pupil.id)
  ).to include(dictionary)
end
```

I didn't tell you what `teaching` was in our first version of the code. It doesn't matter much for our discussion or
to see the point of our changes but let's think about it for a moment. It had to be some kind of
[Repository](http://martinfowler.com/eaaCatalog/repository.html) object implementing `#dictionaries_for` method.
Or a [Query](http://martinfowler.com/eaaCatalog/queryObject.html) object. Something definitely related and coupled to
DB because we set the state with factories deep down creating AR objects.

It can be the same in our last example. But it doesn't have to! All those services can build and store AR objects and
communicate with them and `teaching` would be just a repository object querying the db for dictionaries of class that
the pupil is in. And that would be fine.

But `teaching` could be a submodule of our application that the services are communicating with. Maybe the key Commands/Services
in our system communicate with multiple modules such as `Teaching`, `Accounting`, `Licensing` and in this test we are
only interested in what happened in one of them. So we could stub other dependencies except for `teaching` if they were
explicitly passed in constructor.

```ruby
teaching = Teaching.new
class_creation = ClassCreation.new(
  teaching, 
  double(:accounting), 
  double(:licensing)
)
```

So with this kind of test setup you are way more flexible and less constrained. Having data in db is no longer your only
option.

<%= show_product_inline(item[:newsletter_inside]) %>

## TL;DR;

In some cases you might wanna consider setting up the state of your system using Services/Commands instead of directly
on DB using *factory_girl*. The benefit will be that it will allow you to more **freely change the internal implementation
of your system without much hassle for changing your tests**. 

For me one of the main selling points for having services is the **knowledge of what can happen in my app**. Maybe
there are 10 things that the user can do in my app, maybe 100 or maybe 1000. But I know all of them and I can mix and
match them in whatever order I wish to create the setup of situation that I wish to test. It's hard to set incorrect
state that way that would not have happened in your real app, because you are just using your production code.

## More

This is an excerpt from <%= service_landing_link %> . For our blog post and newsletter we end up here but in the book there will be a
following discussion about shortening the setup. We will also talk about the value of setting UUIDs and generating them
on frontend. As well why it is worth to have an `Input` class that keeps the incoming data for your service (usually user input). 
