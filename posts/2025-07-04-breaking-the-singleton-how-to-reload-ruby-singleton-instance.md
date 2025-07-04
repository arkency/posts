---
created_at: 2025-07-04 08:45:43 +0200
author: Jakub Kosiński
tags: ['ruby', 'singleton']
publish: false
---

# Breaking the Singleton: How to Reload Ruby Singleton Instance

As you may know, the `Singleton` module implements the singleton pattern in Ruby. Technically it ensures that the class that includes the `Singleton` module will have one and only one instance throughout the application's lifecycle available with the class method `instance`. The most common usage is for some configuration objects, logging or some global third-party clients. What Ruby `Singleton` effectively does is that it hides `new` and `allocate` methods on the class level so you can't create a new instance and undefines the `extend_object` method of your class. It also raises an exception when you try to clone an instance using `clone` or `dup` method. On the first call of the `instance` method the singleton instance will be created and stored internally for the whole application's lifecycle.

But what if you actually need to re-instantiate an instance of a specific singleton?

<!-- more -->

A few days ago I was involved in migrating multiple client libraries that were using singleton pattern to a new internal implementation in a Rails application. The original implementation was implementing some logic for the target URL generation that was using YAML files that were storing some per-env configuration. It was good enough for running the code in a specific environment but I wanted to be 100% sure that my existing production configuration wouldn't break after the migration.

The initial idea was simple - let's generate target URLs on production for every client that needs to be migrated and then write a test case that will change the Rails environment to return `production` in a test and will check whether client URLs are correct after changing the internal implementation. In theory this should work and indeed, it was working when I was running the test in isolation. But then I realised that when I run the whole test suite, the first test that is using an instance of my singleton class will set its state for the whole test suite. This means that my test will pass only if it's called before any other test that is using any of client instances and - even worse - it will return instances with production-like state for all test cases that are executed after my client test. I really needed to re-instantiate my singleton classes or I would need to run a separate test suite where I run only my single test for the migration.

I started from inspecting the Ruby singleton [sources](https://github.com/ruby/singleton/tree/master) and shortly thereafter I found the undocumented [`__init__`](https://github.com/ruby/singleton/blob/3f4e1f55f53eae16d3430761378697b3ebe5f1a4/lib/singleton.rb#L162-L168) method that does exactly what I needed - it resets the singleton class state by removing the instance (setting it to `nil`) and creating a new mutex for thread-safety. So the next time you call the `instance` method of your singleton class, it will create a new instance. Now I only needed to setup the stage in my test so that I stub the Rails env & reset singleton instance before my test and remember to remove the env stub & reset singleton instances again after the test is run:

```ruby
RSpec.describe "Clients migration" do
  before { setup_env('production') }
  after { setup_env('test') }
  
  it 'generates the correct URL for client instance' do
    # ...
  end
  
  def setup_env(env)
    Rails.env = env
    Singleton.__init__(MyClient)
    Singleton.__init__(AnotherClient)
    # ...
  end
end
```

This way I managed to safely migrate my internal implementation and test that it will behave exactly in the same way as the previous one.

Singleton module adds also the `clone` method on class level that is calling `__init__` but it has a slightly different behaviour as it returns a new anonymous singleton class with a fresh state rather than resetting the existing one:

```ruby
class Timer
  include Singleton
  attr_reader :timestamp
  
  def initialize
    @timestamp = Time.now
  end
end

Timer.instance.timestamp #=> 2025-07-04 09:30:36.98988 +0200
Timer.clone.instance.timestamp #=> 2025-07-04 09:30:57.770478 +0200
Timer.instance.timestamp #=> 2025-07-04 09:30:36.98988 +0200
Singleton.__init__(Timer).instance.timestamp #=> 2025-07-04 09:31:42.419874 +0200
Timer.instance.timestamp #=> 2025-07-04 09:31:42.419874 +0200
```

From my experience the `Singleton` pattern is not used very often but if you are using it and find a use case where you need to reset the instance for any reson, using `Singeton::__init__` may help you do so.
