---
created_at: 2022-11-14 13:50:10 +0100
author: Tomasz Patrzek
tags: []
publish: false
---

# Be careful with turbo and view components

In our project we are using view components to unify button styles in view templates.
Something similar to:

```ruby
class Forms::Button < ViewComponent::Base
  def initialize(type:, text:, options: {}, data: {}, disabled: false)
    @type = type
    @text = text
    @options = options
    @data = data
    @disabled = disabled
  end

  def call
    case @type
    #...
    when "link"
      link_to(
        @options[:href],
        data: @data,
        class: "#{@options[:text_color]} #{@options[:bg_color]} #{css_styles} app-btn",
      ) do
        tag.p(@text)
      end
    end
  end

```
In order to make a POST request with the given component I've decided to make use of the link_to option: `method`:


```ruby
  #...
  link_to(
    @options[:href],
    method: @options[:method] || "GET",
    data: @data,
    class: "#{@options[:text_color]} #{@options[:bg_color]} #{css_styles} app-btn",
  )
  #...
```

And it works. However it turned out there is an issue.
Our other component links stopped to work.
The link_to with option method will dynamically create an HTML form and immediately submit it.
It uses @rails/ujs and it turns out that GET forms are not compatible with turbo stream responses.
The fix was to remove the `:method` option, and use a button_tag for the `:post` request.
Since Rails 7 @rails/ujs library is no longer on by default. Also the link_to attriubute "method" is a deprecated link_to attribute.

