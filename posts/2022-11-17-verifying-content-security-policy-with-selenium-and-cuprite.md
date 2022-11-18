---
created_at: 2022-11-17 13:16:10 +0100
author: Paweł Pacana
tags: [ 'ruby', 'testing' ]
publish: true
---

# Verifying Content-Security Policy with Selenium and Cuprite

Once upon a time, a fellow RailsEventStore enthusiast [reported an issue](https://github.com/RailsEventStore/rails_event_store/issues/1062). It turned out that the `RES::Browser` component was not compatible with a quite reasonable Content-Security Policy they were using in their Rails app. His report led to an interesting discussion. Eventually, one pull-request later, the project gained new contributor and a more CSP-friendly setup.

How did we ensure that this improvement will not be broken in future releases without manual testing? Read on.

## What is Content-Security Policy?

Quick reminder [what this CSP thing is](https://content-security-policy.com):

> Content-Security-Policy is the name of a HTTP response header that modern browsers use to enhance the security of the document (or web page). The Content-Security-Policy header allows you to restrict how resources such as JavaScript, CSS, or pretty much anything that the browser loads.

In short — setting CSP headers can [help protect against XSS and injection attacks]([https://edgeguides.rubyonrails.org/security.html](https://edgeguides.rubyonrails.org/security.html#content-security-policy-header)).

For example, a web server tells your browser, that inline scripts cannot be executed. The web browser knows this because it received the following HTTP header in the response.

```
content-security-policy: script-src 'self'
```

Whenever the browser finds an inlined script in the HTML body of the response, it won't execute it.

```html
<script type="text/javascript">
  alert("spanish inquisition");
</script>
```

Instead, an error will be raised and logged. It doesn't matter whether the inlined script was legitimate or injected by the attacker. The policy strictly disallows it.

```
Refused to execute inline script because it violates the following Content Security Policy directive: "script-src 'self'". Either the 'unsafe-inline' keyword, a hash ('sha256-b1No4u4UwgH6M1mNU7GPc4D3Fc2lJ26AvLJAgCR+lvE='), or a nonce ('nonce-...') is required to enable inline execution.
```

## How to detect Content-Security Policy violation

At this point, we already know that it's the application or web server dictating policy. And the web browser has "the engine" to verify end enforce it. Thus it would be best to lean on a headless web browser in the test and never look into that black box.

In order to verify desired Content-Security Policy, we first need to emulate it. `RES::Browser` is technically speaking a Rack application that you either mount in a Rails app or run standalone. Let's focus on the former. That's the most frequent use case.

When mounted, `RES::Browser` would rely on the CSP header from Rails. In a test, we don't need to involve the whole application though. Just a tiny Rack middleware that adds Content-Security Policy headers will be enough here to emulate it.

```ruby
class CspApp
  def initialize(app, policy)
    @app = app
    @policy = policy
  end

  def call(env)
    status, headers, response = @app.call(env)

    headers["content-security-policy"] = @policy
    [status, headers, response]
  end
end
```

We will wrap the `RES::Browser` component with this middleware. Now, when the web browser — driven by [Capybara](https://github.com/teamcapybara/capybara) and [Cuprite](https://github.com/rubycdp/cuprite) — visits the root URL, it will compare the received Content-Security Policy header with the reality of served HTML. Quickly making objections if there should be any. The same objections would be raised outside the tested system, on a real web browser.

```ruby
session =
  Capybara::Session.new(
    :cuprite,
    CspApp.new(
      RubyEventStore::Browser::App.for(event_store_locator: -> { event_store }),
      "style-src 'self'; script-src 'self'",
    ),
  )

session.visit("/")
```

How do we know there were any issues? Parts of the page may not load correctly and we could assert that. That is perfect for checking dynamic content.

```ruby
expect(session).to have_content("RubyEventStore v2.5.1")
```

But what about [inline CSS not loading due to restrictive policy](https://github.com/RailsEventStore/rails_event_store/issues/1346)? We may not be able to detect it by looking only at HTML content.
However, more universally — we could peek into web browser logs, looking for errors.

```ruby
expect(logger.messages.select { |m| m["params"]["entry"]["level"] == "error" }).to be_empty
```

Where does this `logger` come from? In Cuprite one can pass it to the driver. Logger simply [has to respond to puts](https://github.com/rubycdp/ferrum#customization) method. Implementation good enough for a single test might look like this:

```ruby
logger =
  Class.new do
    attr_reader :messages

    def initialize
      @messages = []
    end

    def puts(message)
      _, _, body = message.strip.split(" ", 3)
      body = JSON.parse(body)

      @messages << body if body["method"] == "Log.entryAdded"
    end
  end.new

Capybara.register_driver(:cuprite_with_logger) { |app| Capybara::Cuprite::Driver.new(app, logger: logger) }
```

## Cuprite vs Selenium

Only recently I've learned that Cuprite does not require Chromedriver to operate. That alone convinced me to give it a try — who doesn't like reducing dependencies? And Chromedriver is this annoying dependency that needs to be frequently updated, in version sync with Chrome browser and [lifted from quarantine](https://timonweb.com/misc/fixing-error-chromedriver-cannot-be-opened-because-the-developer-cannot-be-verified-unable-to-launch-the-chrome-browser-on-mac-os/).

Previously in RailsEventStore were using Selenium with a headless Chrome. On such a setup, we were inspecting browser logs differently. The logger didn't have to be explicitly passed and was already exposed on the driver interface.

```ruby
expect(session.driver.browser.manage.logs.get(:browser).select { |le| le.level == "SEVERE" }).to be_empty
```

Transitioning from Selenium to Cuprite can be best seen fully in this [commit](https://github.com/RailsEventStore/rails_event_store/commit/b6ec85c6cb4510496a4406eef34f3d1111ae9034). I haven't found any drawbacks of Cuprite yet on this small sample set.

Happy hacking!
