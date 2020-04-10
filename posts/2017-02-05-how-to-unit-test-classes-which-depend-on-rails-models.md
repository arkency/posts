---
title: "How to unit test classes which depend on Rails models?"
created_at: 2017-02-05 16:48:44 +0100
publish: true
author: Andrzej Krzywda
tags: ['testing']
---

Let's say you have such a class:
(this code is borrowed from this [Reddit thread](https://www.reddit.com/r/rails/comments/5rzeeb/how_do_you_unit_test_classes_that_depend_on_models/)

```ruby

class CreateSomethingService
  def initialize(params)
    parse_parameters params
  end

  def run
    Something.create(name: @name)
  end

  private

  def parse_parameters(params)
    @name = params[:name]
  end
end
```

<!-- more -->

How can we test this class without loading Rails?

One way to unit test it is by using the repository object and the concept of replacing the repo object with an in-memory one in tests.

```ruby

class CreateSomethingService
  def initialize(repo, params)
    @repo = repo
    parse_parameters params
  end

  def run
    repo.create_something(@name)
  end

  private

  def parse_parameters(params)
    @name = params[:name]
  end
end

class SomethingsRepo
  def create_something(name)
    Something.create(name: @name)
  end
end

class InMemorySomethingsRepo
  attr_accessor :somethings

  def initialize
    @somethings = []
  end

  def create_something(name)
    @somethings << name
  end
end

class SomethingsTest
  def test_creates_somethings
    repo = InMemorySomethingsRepo.new
    CreateSomethingService.new(repo, "Arkency")
    assert_equal(1, repo.somethings.length)
  end
end
```

Note that the service now takes the repo as the argument. It means the controller needs to pass the right repo in the production code and we use the InMemory one in tests.
Obviously, if your implementations of the repos diverge, you have a problem :) (which best to mitigate by having integration tests which do run this code with Rails)

You can read more about the setup here:

[InMemory fake adapters](http://blog.arkency.com/2015/12/in-memory-fake-adapters/)

[Rails and adapter objects - different implementations in production and tests](http://blog.arkency.com/2016/11/rails-and-adapter-objects-different-implementations-in-production-and-tests/)

It's worth noting here, that it may be better to treat a bigger thing as a unit than a single service object. For example you may want to consider testing CreateSomethingService together with GetAllSomethings, which makes the code even simpler, as the InMemory implementation doesn't need to have the :somethings attribute.

[Unit tests vs class tests](http://blog.arkency.com/2014/09/unit-tests-vs-class-tests/)

[Services - what they are and why we need them](http://blog.arkency.com/2013/09/services-what-they-are-and-why-we-need-them/)
This setup has its limitations (the risk of diverging), but it's solvable. The benefit here is that you don't rely on Rails in tests, which makes them faster.

If you like this kind of approaches to Rails apps, then you will enjoy more such techniques in my book about [Refactoring Rails](http://rails-refactoring.com)


