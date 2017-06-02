---
title: "Testing cookies in rails"
created_at: 2017-06-02 22:31:25 +0200
kind: article
publish: false
author: Rafał Łasocha
tags: [ 'rails', 'cookies', 'testing' ]
newsletter: :arkency_form
---

Recently at Arkency I was working on a task, on which it was very important to 
ensure that the right cookies are saved with the specific expiration time. Obiovusly 
I wanted to test this code to prevent regressions in the future.

<!-- more -->

# Controller tests?

Firstly I thought about [controller tests](https://relishapp.com/rspec/rspec-rails/v/3-6/docs/controller-specs), but you can use only one controller in
one test (at least without strong hacks) and in this case it was important to check
values of cookies after requests sent into few different controllers. **You can now think, that controller
tests are "good enough" for you, if you don't need to reach to different controllers. Not quite, unfortunately**.
Let's consider following code:

```
#!ruby
class ApplicationController
  before_filter :do_something_with_cookies

  def do_something_with_cookies
    puts "My cookie is: #{cookies[:foo]}"
    cookies[:foo] = {
      value: "some value!",
      expires: 30.minutes.from_now,
    }
  end
end
```

And controller test:

```
#!ruby

describe SomeController do
  specify do
    get :index

    Timecop.travel(35.minutes.from_now) do
      get :index
    end
  end
end
```

Note that the **cookie time has expiration time of 30 minutes and we are doing second call
"after" 35 minutes**, so we would expect output to be:

```
My cookie is:
My cookie is:
```

So, we would expect cookie to be empty, twice. Unfortunately, the output is:

```
My cookie is:
My cookie is: some value!
```

**Therefore, it is not a good tool to test cookies when you want to test cookies
expiring.**

# Feature specs?

My second thought was [feature specs](https://relishapp.com/rspec/rspec-rails/v/3-6/docs/feature-specs/feature-spec), but that's capybara and we prefer to avoid capybara if we can
and use it only in very critical parts of our applications, so I wanted to use something lighter than that.
It would probably work, but as you can already guess, there's better solution.

# Request specs

There's another kind of specs, [request specs](https://relishapp.com/rspec/rspec-rails/v/3-6/docs/request-specs/request-spec), which is less popular than previous two, but in this
case it is very interesting for us. Let's take a look at this test:

```
#!ruby
describe do
  specify do
    get "/"

    Timecop.travel(35.minutes.from_now) do
      get "/"
    end
  end
end
```

With this test, we get the desired output:

```
My cookie is:
My cookie is:
```

Now we would like to add some assertions about the cookies. Let's check what
cookies class is by calling `cookies.inspect`:

```
#<Rack::Test::CookieJar:0x0056321c1d8950 @default_host="www.example.com", @cookies=[#<Rack::Test::Cookie:0x0056321976f010 @default_host="www.example.com", @name_value_raw="foo=some+value%21", @name="foo", @value="some value!", @options={"path"=>"/", "expires"=>"Fri, 02 Jun 2017 22:29:34 -0000", "domain"=>"www.example.com"}>]>
```

Great, we see that it has all information we want to check: value of the cookie,
expiration time, and more. You can easily retrieve the value of the cookie by calling
`cookies[:foo]`. **Getting expire time is more tricky, but nothing you couldn't do in ruby.**
On `HEAD` of `rack-test` there's already a method [get_cookie](https://github.com/rack-test/rack-test/blob/a396bd16a1bcdb8a3fc668bd238688911db32199/lib/rack/test/cookie_jar.rb#L130-L132) you can use to get all cookie's options.
If you are on `0.6.3` though, you can add following method somewhere in your specs:

```
#!ruby
def get_cookie(cookies, name)
  cookies.send(:hash_for, nil).fetch(name, nil)
end
```

It is not perfect, but it is simple enough until you migrate to newer version of `rack-test`. In the end, my specs looks like this:

```
#!ruby
describe do
  specify do
    get "/"

    Timecop.travel(35.minutes.from_now) do
      get "/"

      cookie = get_cookie(cookies, "foo")
      expect(cookie.value).to eq("some value!")
      expect(cookie.expires).to be_present
    end
  end

  # That will be built-in in rack-test > 0.6.3
  def get_cookie(cookies, name)
    cookies.send(:hash_for, nil).fetch(name, nil)
  end
end
```

With these I can test more complex logic of my cookies. **Having reliable tests
allows me and my colleagues to easily refactor code in the future and prevent
regressions in our legacy applications** (if topic of refactoring legacy applications
is interesting to you, you may want to check out our [Fearless Refactoring book](http://rails-refactoring.com/)).

What are your experiences of testing cookies in rails?
