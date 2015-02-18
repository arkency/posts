---
title: "upgrade capybara-webkit to 1.4 and save your time"
created_at: 2015-02-18 18:58:10 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :coaching
tags: [ 'rails', 'capybara', 'webkit', 'bbq' ]
img: "/assets/images/capybara-webkit/page_driver_block_unknown_urls-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/capybara-webkit/page_driver_block_unknown_urls-fit.jpg" width="100%">
  </figure>
</p>

I spent quite some time on Monday debugging an interesting issue. Our full
stack acceptance tests stopped working on CI. Just CI. Everything was passing
locally just fine for every developer. So I had to dig deeper.

<!-- more -->

After initial investigation it turned out that tests which were timing out on CI with
3 minutes limit of inactivity were passing given enough time (around 15 minutes).
I used SSH to log into Circle CI instance and tried executing them myself to see that.
So...

**Suddenly, one day, subset of our tests become really slow. How would that happen?**

I was stuck trying to figure out the reason when my coworker suggested that
it might be related to problems with javascript files. At the same time I was
in contact with [Marc O'Morain](https://twitter.com/atmarc) from Circle who
suggested it might be related to Mixpanel because other customers who used
Mixpanel experienced problems as well.

So I disabled Mixpanel Javascript, tested it out and everything was working
correctly. We were already using `capybara-webkit` version `1.3.1` with **blacklisting
feature** to prevent exactly such kind of problems:

```
#!ruby
Capybara.register_driver :webkit_with_blacklist do |app|
  driver = Capybara::Webkit::Driver.new(app)
  driver.browser.url_blacklist = %w(
    http://player.vimeo.com
    http://maps.googleapis.com
    http://google-analytics.com
  )
  driver
end

Capybara.javascript_driver = :webkit_with_blacklist
```

However mixpanel tracking was added later compared to this code.
So it was never put on the blacklist because _we simply forgot_.
What a shame.

## capybara 1.4

But this is where new version of `capybara-webkit` comes into the story. It has a
really nice feature which allows you to **disable any external JS** by calling

```
#!ruby
page.driver.block_unknown_urls
```

That way you don't need to remember in the future to blacklist any
external dependencies in your project. They make your test much **slower
and unreliable** because of possible networking issue. So blacklisting
as much as possible will save you time on executing tests and on debugging
such issues as mine.

It turned out that we couldn't reproduce the problem
locally because our developers work from **Europe and the mixpanel networking
issue occured in US** only. Guess where Circle CI node is located :)

You can put the blocking snippet of code in `before/setup` part of your
acceptance test, or in `spec_helper` or in a constructor of class that
is using capybara api.

## bbq

Because we use [`bbq` gem](https://github.com/drugpl/bbq) in our project,
for me it was:

```
#!ruby
class Webui < Bbq::TestUser
  def initialize(*)
    super
    page.driver.block_unknown_urls if page.driver.respond_to?(:block_unknown_urls)
  end
end
```

I added the `respond_to?` check because `rack-test` driver don't
have (and don't need) this feature available.

## rspec

If you follow standard way described in [Using Capybara with RSpec](http://www.rubydoc.info/gems/capybara#Using_Capybara_with_RSpec)
you can write:

```
#!ruby
describe "the signin process", js: true do
  before do
    page.driver.block_unknown_urls
  end

  it "signs me in" do
    visit '/sessions/new'
    # ...
  end
end
```

or in Capybara DSL:

```
#!ruby
feature "Signing in" do
  background do
    page.driver.block_unknown_urls
  end

  scenario "Signing in with correct credentials", js: true do
    visit '/sessions/new'
    # ...
  end
end
```

Of course it doesn't need to be in `before/background/setup`. It can be
used directly in every `scenario/it/specify` but that way you will
have to repeat it multiple times.

You can also configure it globally in `spec_helper` with:

```
#!ruby
RSpec.configure do |config|
  config.before(:each, js: true) do
    page.driver.block_unknown_urls
  end
end
```

## verbose

The nice thing about capybara 1.4 is that it is very verbose for the external resources that
you haven't specify allow/disallow policy about.

```
To block requests to unknown URLs:
  page.driver.block_unknown_urls
To allow just this URL:
  page.driver.allow_url("http://api.mixpanel.com/track")
To allow requests to URLs from this host:
  page.driver.allow_url("api.mixpanel.com")
```

So next time you add new external URL you will notice that you need to do
something. Unless of course you went with `page.driver.block_unknown_urls`
which I recommend if your project can work with it. For all other cases
there is `allow_url`.

## summary

* Upgrade to latest `capybara-webkit`
* Use `page.driver.block_unknown_urls`
* Have more reliable and faster tests that don't depend on network
