---
title: "Unit tests vs class tests"
created_at: 2014-09-20 14:06:17 +0200
kind: article
publish: false
author: Andrzej Krzywda
newsletter: :skip
newsletter_inside: :fearless_refactoring_course
tags: []
---
<p>
  <figure>
		<img src="/assets/images/unit_tests_vs_class_tests/GULLIVERS-TRAVELS.JPG" width="100%">
  </figure>
</p>

There's a popular way of thinking that unit tests are basically tests for classes.

I'd like to challenge this understanding.

<!-- more -->

When I work on a codebase that is heavily class-tested, I find it harder to do refactoring. If all I want is to move some methods from one class to another, while preserving how the whole thing works, then I need to change at least two tests, for both classes.

## Class tests slow me down

Class tests are good if you don't do refactoring or if most of your refactorings are within 1 class. This may mean, that once you come up with a new class, you know the shape of it.

I like a more light-weight approach. Feel free to create new classes, feel free to move the code between them as easily as possible. It doesn't mean I'm a fan of breaking the functionalities. Totally the opposite. I feel paralysed, when I have to work on untested code. My first step in an unknown codebase is to check how good is the test coverage.

How to combine such light-weight refactoring style with testing?

## Test units, not classes

I was in the "let's have a test file per a class" camp for a long time. If I created a OrderItem class, it would probably have an equivalent OrderItemTest class. If I had a FriendPresenter, it would have a FriendPresenterTest.

With this approach, changing any line of code, would result in failing tests.

Is that really a safety net?

It sounds more like cementing the existing design. It's like building a wall in front of the code.

What's the alternative?

The alternative is to think in units, more than in classes. What's a unit? I already touched on this subject in TDD and Rails - what makes a good unit?

## The Billing example

In one of our projects, which is a SaaS service, we need to handle billing, paying, licenses. We've put it in one module. (BTW, the 'module' term is quite vague nowadays, as well).

* Billing (the facade)
* Subscription
* License
* Purchase
* Pricing
* PurchasingNotEnoughLicenses
* BillingDB
* BillingInMemoryDB
* BillingNotificationAdapter
* SchoolYearSerializer

It's not a perfect piece code (is there any in the world?), but it's a good example for this topic. We've got about 10 classes. How many of them have their own test? Just the Billing. 
What's more, in the tests we don't reference and use and of those remaining classes. We test the whole module through the Billing class. The only other class, that we directly reference is a class, that doesn't belong to this module, which is more of a dependency (shared kernel). Obviously, we also use some stdlib classes, like Time.

Some requirements here include:

* licences for multiple products
* changing licences within a certain date
* terminating licenses
* license counter

It's nothing really complicated - just an example.

What do I gain, by having the tests for the whole unit, instead of per-class?

**I have the freedom of refactoring** - I can move some methods around and as long as it's correct, the tests pass. I tend to separate my coding activities - when I'm adding a new feature, I'm test-driven. I try to pass the test in the simplest way. Then I'm switching to refactoring-mode. I'm no longer adding anything new, I'm just trying to find the best structure, for the current needs. It's about seconds/minutes, not hours. When I have a good shape of the code, I can go to implement the next requirement. 

**I can think about the whole module as a black-box.** When we talk about Billing in this project, we all know what we mean. We don't need to go deeper into the details, like licenses or purchases. Those are implementation details.

When I add a new requirement to this module, I can add it as a test at the higher-level scope. When specifying the new test, I don't need to know how it's going to be implemented. It's a huge win, as I'm not blocked with the implementation structure yet. Writing the test is decoupled from the implementation details.

Other people can enter the module and clearly see the requirements.

Now, would I see value in having a test for the Pricing class directly? Having more tests is good, right?
Well, no - tests are code. The more code you have the more you need to maintain. It makes a bigger cost. It also builds a more complex mental model. 
Low-level tests are often causing more troubles than profit. 

Let me repeat and rephrase - by writing low-level tests, you may be damaging the project. 

As Damian Hickey puts it in [an excellent way](http://dhickey.ie/post/2014/03/03/gulliver-s-travels-tests.aspx):

_Like writing lots and lots of fine-grained "unit" tests, mocking out every teeny-weeny interaction between every single object?
This is your application:_

<img src="/assets/images/unit_tests_vs_class_tests/GULLIVERS-TRAVELS.JPG">


_Now try to change something._

## The class-test example

There's a different project that we're working on. It has a Friends module. One of its responsibilities is to grab the user Facebook friends and find their birthday dates. We don't care about the year of birth, we just need the month and a day. Facebook is chosen for now, but we may want to grab the data also from other sources in the future and combine them.

We've got a FacebookAdapter class, that know how to connect to FB and return the friends data structure. We also have a class called FriendPresenter which is supposed to expose this data as json (we're called through some API) in the format %m/%d.

Thos of you, who implemented this kind of Facebook integration already know, that FB returns the birthdate in multiple ways. It returns 'null' when there's no date set. It returns '12/05/1990' if the whole date is set and returns '12/05' if someone didn't put the year. Obviously, it's not as clear in the docs, you need to discover it by experiments.

Let's say that someone implemented a class-test for the FriendPresenter. It takes the json structure from, as returned from FB and changes it to the format, that we use.

The test would look something like this:

```
#!ruby
describe FriendPresenter do
  context 'without date' do
    let(:date) { nil }
    its(:to_hash) { is_expected.to include({ birth_date: nil }) }
  end

  context 'with partial date' do
    let(:date) { '09/14' }
    its(: to_hash) { is_expected.to include({ birth_date: "09/14" }) }
  end

  context 'with full date' do
    let(:date) { '09/14/1989' }
    its(: to_hash) { is_expected.to include({ birth_date: "09/14" }) }
  end
```

The implementation looks like this:

```
#!ruby
  def parse_date(birthday)
    birthday and Date.strptime(birthday, date_format).strftime(date_format)
  end

  def date_format
    '%m/%d'
  end
```

It's trivial, we've got test coverage and all is good, right?

Not entirely. 

What if someone comes and says "hey, it's the job of the FBAdapter to adapt their dates format into our world, that's what adapters do, they adapt."?

It's obviously a #firstworldproblem, however you can say that **ugly codebases consist of thousands of such #firstworldproblems** and it may be a good idea not to introduce new ones.

What happens, if we want to move the date adapting code to FBAdapter? We need to move part of the tests to the FBAdapter. We can't move it as a whole, as the FriendPresenter still has some work to do, so it deserves some tests. So we need to carefully split those tests so that they live in 2 places now. Then, we need to change both classes to reflect it.

Doing the work above is not a matter of seconds anymore. 

Changing the tests is always risky. Tests reflect requirements, in a way. We need to change them, when the requirements change. Here, however, it wasn't such case. We needed to change tests, because our internal implementation has changed. Something is wrong here.

Developers are in the constant decision-making process. We need to balance, what's worth doing. If we find something trivial to fix, we'll do it, because that's a 5-minutes investment. If we estimate a change for 20 minutes or more, then that may fall off the scope of my work. 

How would the example look like, if we didn't do class-tests, but build a unit test for that?

First, what can help us is a facade object around the internal classes. Let’s say it’s called Social. It uses the FBAdapter and the FriendPresenter under the hood. However, we test it only through the facade object.

```ruby
class Social
  def initialize(fb_adapter)
    @fb_adapter = fb_adapter
  end

  def all_friends(user_uuid, fb_access_token)
    …
  end

  def mark_as_friends(friend_1_uuid, friend_2_uuid)
    ..
  end
end

```

Now, having this facade doesn’t magically improve our codebase, but it gives us a wrapper around this module.

The reason it takes the fb_adapter as a parameter is to highlight it as a dependency. In the tests we don’t want to call the real Facebook servers. We want to pass the in_memory_facebook_adapter which has some prepared responses that fit the real ones.




<%= inner_newsletter(item[:newsletter_inside]) %>


