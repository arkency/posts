---
title: "Mutation testing of Rails views"
created_at: 2016-06-21 21:55:37 +0200
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :skip
---

Thanks to mutation testing we can get much higher confidence while working with Ruby/Rails apps. There is one area, though, where I've been struggling to make mutant to work - the Rails views. People use erb or haml and they're both not a proper Ruby code, they're templating languages.

In this post, I'm showing a trick which can help make Rails views covered by mutation testing coverage.

<!-- more -->

It was 7 or 8 years ago, when I was using another approach to Rails views, called Erector. We wrote a whole project using it. It had some issues, but overall I loved the idea that I can have views written in Ruby, given how elegant our language is.

Since then, I haven't used Erector much, but today I've tried to use it, just to learn that there's another library which sounds like a better version of Erector - it's called [fortitude](https://github.com/ageweke/fortitude).

I have created a simple Rails 5 app and then created a simple Capybara test which will be used by mutant:

```
#!ruby

class HappyTest < ActionDispatch::IntegrationTest

  def test_happy_path
    visit("/")
    assert(page.has_text?("Hello world"))
  end
end
```

with the following routes:

```
#!ruby

Rails.application.routes.draw do
  resource :root, only: [:index]
  root to: "root#index"
end
```

and the controller:

```
#!ruby

class RootController < ApplicationController
  def index
  end
end
```

Then I created a fortitude view:

```
#!ruby

class Views::Root::Index < Views::Base

  def content
    p(:class => 'content') {
      text "Hello world"
    }
  end
end
```

Now when I run mutant with:

```
RAILS_ENV=test bundle exec mutant -r ./config/environment -r ./test/integration/happy_test.rb --use minitest "Views::Root::Index"
```

I get a nice mutation coverage report:

```

(more here...)

Subjects:        1
Mutations:       26
Results:         26
Kills:           16
Alive:           10
Runtime:         3.76s
Killtime:        10.74s
Overhead:        -64.96%
Mutations/s:     6.91
Coverage:        61.54%
Expected:        100.00%
```

and the mutated code:

```
#!ruby

def content
  -  p(class: "content") do
  -    text("Hello world")
  -  end
  +  text("Hello world")
end

```

This means, that the view did get covered by mutant and it was mutated to see what's the coverage.
With this example, it showed me, that I have no test requiring that it's a `<p>` tag. I'm not sure if that's really useful, but at least this technique can be applied in situations where we need to take care of Rails views as well :)

Obviously, if you want to apply it to existing Rails views, they need to be converted to Fortitude first, which may not be the best choise for every project...

## Frontend friendly Rails

You can struggle with Rails views or ... you can make your Rails more frontend-friendly and go with JavaScript-based applications. That's one of our favourite ways at Arkency in the last years.

Marcin has just released a new book describing the techniques we've been using. Our new book is called "Frontend friendly Rails" and during this week (until Friday night) it's on a discounted price 40% off with the code `FF_RAILS_BLOG`.

<a href="https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386">
  <%= img_fit("frontend-friendly-rails/ffr-cover.png") %>
</a>

<a href="https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386" style="display: block; margin: 1em 0; text-align: center; font-size: 2em;">Click here to buy the book!</a>
