---
created_at: 2013-02-01 16:45:58 +0100
publish: true
author: 'Jan Filipowski'
newsletter: arkency_form
tags: [ 'TDD', 'ATDD', 'testing', 'ruby' ]
---

# Black-box Ruby tests

[Chillout.io](http://chillout.io/) architecture is distributed - currently just as few processes on same production server. As professionals we decided to prepare integration tests for each of application (maybe in terms of their business we could call them acceptance tests), but that wasn't enough - _we wanted to expose business scenarios that we're actually aiming in_. We achieved that with fully black-box tests. Curious how we did that? Read on.

<!-- more -->

## Architecture

[Chillout.io](http://chillout.io/) purpose is to _help Rails developers maintain existing projects_ - currently react on exception events and be up-to-date with simple business metrics like model creations. To provide this features its backend is splitted into following apps:

* *api* - API endpoint
* *brain* - decides how to react on messages from *api*
* *brain-reporter* - generates reports for customers
* *mailing* - sends email to customers

It has also gem dedicated to Rails applications, which communicates with our API.

## Test runner

To test whole stack we have to run all apps + Rails server. Let's have a look at our ```AcceptanceTestCase``` class:

```ruby

class AcceptanceTestCase < MiniTest::Unit::TestCase
  def commands_to_run
    # Sample structure
    [
      ["bundle exec ruby -Iapi/lib api/bin/chillout-api", {"BUNDLE_GEMFILE" => "api/Gemfile"}],
      ["bundle exec sample_rails_app/script/rails s --binding=127.0.0.1 --port=3000 --environment=production", ...]
      ...
    ]
  end

  def run(runner, &block)
    output, pids = "F", []
    begin
      commands_to_run.each do |(cmd, env)|
        Bundler.with_clean_env { pids << ProcessSpawner.new(cmd, env).spawn }
      end
      super
    rescue => exc
      runner.puke(self.class, self.__name__, exc)
      return output
    ensure
      pids.each { |pid| ProcessSpawner.kill(pid) }
    end
  end
end
```

As you see we also have sample Rails app to make sure, that our gem really works. To make development easier configuration of that gem is hardcoded in this sample app, and this configuration is also hardcoded in our tests.

## Scenario language

_Business scenarios - stories or use cases - are defined with high-level terms_, i.e. "Someone created model in Rails app, so at the beginning of next day (when scheduler trigger) owner should get email with report containing model's counter increased by one". To expose that business, our product's real value, we use same terms in tests:

```ruby
class SendingBusinessMetricsTest < AcceptanceTestCase
  def setup
    @name, @email, @token = "Rere", "email@example.org", '01234567890123456789012345678901'
    @app   = TestApp.new(@token)
    @admin = TestAdmin.new
    @owner = TestOwner.new(@email)
    @scheduler = TestScheduler.new
  end

  def test_client_delivers_business_metrics
    @admin.add_project(@name, @token)
    @admin.add_recipients(@email)

    @app.create_entity!("Dog")

    @scheduler.invoke_daily_report

    @owner.visit_last_email do |email|
      email.find("h1").has!("Daily report")
      email.find("p").has!("Dog: 1")
    end
  end
end
```

Here's an explanation what really happens in scenario:

1. ```admin.add_project``` and ```admin.add_recipients``` add project and notification recipients to test database.
2. ```app.create_entity!``` enters, using [capybara-webkit](https://github.com/thoughtbot/capybara-webkit), sample Rails app's scaffold and create entity with "Dog" name
3. Scheduler execute shell command to run our reporter app.
4. We run [mailcatcher](http://mailcatcher.me/) in background and owner use it to check if he got an email - he enters (also using capybara-webkit) it's web interface and looks for given data - daily report.

As you can see all steps of this scenario are described in terms of real usage. If we'd describe how our product subcomponents cooperate to handle this use case it would look like this:

<a href="<%= src_original("black-box-ruby-tests/flow1.png") %>" rel="lightbox"><img src="<%= src_fit("black-box-ruby-tests/flow1.png") %>" class="fit"></a>
<a href="<%= src_original("black-box-ruby-tests/flow2.png") %>" rel="lightbox"><img src="<%= src_fit("black-box-ruby-tests/flow2.png") %>" class="fit"></a>

As a side note: approach of tests with actors was introduced in [bbq](http://github.com/drugpl/bbq) gem.

## Real black box

As you can see it is about what scenario actor's will do in real life - one of them will get to Rails app and create some entity, scheduler (cron) will invoke daily report at given time, and then Rails app's owner will go to web mail and see our notification.

All details about our architecture are not available on scenario level. If we decide to split one of our apps to few smaller we will just have to add new commands to run in ```AcceptanceTestClass```. We can also show it to you to tell you about our new feature - _automatic simple business metrics_.

How do like this style of testing? Please leave a comment - maybe you have something better?

## Did you like it?

Make sure to check our [books, videos and bundles](/products)
