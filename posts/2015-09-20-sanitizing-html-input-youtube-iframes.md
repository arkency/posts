---
title: "Sanitizing html input: youtube iframes, css inline styles and customization"
created_at: 2015-09-20 13:00:07 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'sanitize', 'html', 'security' ]
newsletter: :arkency_form
img: "rails-sanitize-html-inpute-iframe-embed-youtube-ted/editor-problem.jpg"
---

Sometimes we give users tremendous power over the content generated
on the web platforms that we write. **The power to add content using
HTML/WYSIWYG editors**.

<p>
  <figure>
    <img src="<%= src_fit("rails-sanitize-html-inpute-iframe-embed-youtube-ted/editor-problem.jpg") %>" width="100%" />
  </figure>
</p>

There is only one gotcha. We need to make sure
that this power is not **abused by malicious users**. After all,
you are a [responsible developer](/responsible-rails/), right?

<!-- more -->

One of the libraries that you can use for that is the [Sanitize ruby gem](https://github.com/rgrove/sanitize) .

```
#!ruby
Sanitize.clean(html)
```

## Why it matters

* Most importantly to avoid [XSS attacks](https://en.wikipedia.org/wiki/Cross-site_scripting).

    You are probably already aware of them and know of the danger.

* And to avoid [CSS Injection](https://www.owasp.org/index.php/Testing_for_CSS_Injection_(OTG-CLIENT-005)) attacks.

    They can be used to lead the customer to an unsafe page outside of your website **without
    the customer being aware of that**. Imagine that your shopping platform allows people to buy
    products. When people click a _"buy"_ button somewhere outside a product description they might
    think they are still on your page. But malicious attacker can use CSS and HTML to place
    **identically looking button at the same location** on the page that your original button is
    placed on.

    User can click such button and be redirected to their own domain with layout
    identical to your shopping platform. They might think they are logging in or buying on your platform but
    instead **they are providing their login and password or credit card credentials on the attacker page**.

## Youtube iframe

But sometimes you want to include or exclude some parts of the HTML conditionally. For example
you might not want the user to be able to include all `<iframe>`-s but you might want them
to be able to include youtube videos of cats or ted.com talks.

```
#!ruby
class IframeWhiteList
  def initialize(src, attributes)
    @src = src
    @attributes = attributes
  end

  def call(env)
    node      = env[:node]
    node_name = env[:node_name]

    # Don't continue if this node is already whitelisted or is not an element.
    return if env[:is_whitelisted] || !node.element?

    # Don't continue unless the node is an iframe.
    return unless node_name == 'iframe'

    # Verify that the video URL is actually a valid video URL.
    return unless node['src'] =~ @src

    # We're now certain that this is a valid embed, but we still need to run
    # it through a special Sanitize step to ensure that no unwanted elements or
    # attributes that don't belong in a YouTube embed can sneak in.
    Sanitize.clean_node!(node, {
      :elements => %w[iframe],
      :attributes => {'iframe'  => @attributes}
    })

    # Now that we're sure that this is a valid embed and that there are
    # no unwanted elements or attributes hidden inside it, we can tell Sanitize
    # to whitelist the current node.
    {:node_whitelist => [node]}
  end
end

class YouTubeWhiteList < IframeWhiteList
  def initialize
    super(
      /\A(https?:)?\/\/(?:www\.)?youtube(?:-nocookie)?\.com\//,
      %w(
        allowfullscreen frameborder height src width scrolling
        webkitallowfullscreen mozallowfullscreen
        style title id name seamless
        allowtransparency hspace vspace marginheight
        marginwidth border
      )
    )
  end
end

Sanitize.clean(@html, Sanitize::Config::RELAXED.merge(transformers: [
  YouTubeWhiteList.new,
  TedCom.new
])
```

**Be very careful when defining the regexp** for the URL and make sure to write some tests.
If you forget to escape one character (for example a dot) the attacker can embed
an iframe from similarly looking domain.

```
#!ruby
let(:html) do
  %q{
    <iframe src="//wwwXyoutube.com/embed/IqajIYxbPOI"></iframe>
    <iframe src="//www.youtubeXcom.com/embed/IqajIYxbPOI"></iframe>
    }
end
it { expect(html_description.sanitized.strip).to eq("") }
```

And be careful to **write tests for the attributes**:

```
#!ruby
let(:html) do
   %q{<iframe width="560" height="315" src="//www.youtube.com/embed/IqajIYxbPOI"
              frameborder="0" allowfullscreen style="box-sizing: border-box;">
      </iframe>
     }
end
it { expect(html_description.sanitized).to eq(
   %q{<iframe width="560" height="315" src="//www.youtube.com/embed/IqajIYxbPOI"
              frameborder="0" allowfullscreen>
      </iframe>
   }
) }
```

## Allowing inline styles

For allowing certain styles you might want to use `HTML::WhiteListSanitizer` that comes
from your Rails 4.1 or `Rails::Html::WhiteListSanitizer` from [`rails-html-sanitizer` gem](https://github.com/rails/rails-html-sanitizer)
in later versions (which under the hood uses [`loofah` gem](https://github.com/flavorjones/loofah)).

Allowing and sanitizing inline styles might be required for your editor to work properly.

```
#!ruby
class CssStyleCheck
  class Sanitizer < HTML::WhiteListSanitizer
    self.allowed_css_properties = HTML::WhiteListSanitizer.
      allowed_css_properties + %w(border-style border-width)
  end

  def initialize
    @sanitizer = Sanitizer.new
  end

  def call(env)
    node      = env[:node]
    node_name = env[:node_name]
    return if env[:is_whitelisted] || !node.element? || !node['style']
    node['style'] = @sanitizer.sanitize_css(node['style'])
  end
end


Sanitize.clean(html, Sanitize::Config::RELAXED.merge(transformers: [
  CssStyleCheck.new,
])
```

Make sure to test it as well. I usually test that all allowed attributes/styles
are left unchanged and some of the disallowed (after all the list is infinite...)
are removed:

```
#!ruby
let(:html) do
  %q{<div style="background-color: 1px; border-bottom-color: 1px;"></div>}
end
it { expect(html_description.sanitized).to eq(html) }
```

```
#!ruby
let(:html) do
  %q{<div style="background-color: black; min-width: 10px;
                 mso-pagination:none; box-sizing: border-box;">
     </div>
    }
end
it { expect(html_description.sanitized).to eq(
   %q{<div style="background-color: black;"></div>})
}
```

## Relaxing even more

Even though the list of HTML tags and attributes allowed by `Sanitizer` is quite long, you
might still want to **customize it a bit depending on your needs** and the
way the editor of your choice works.

```
#!ruby
def self.relaxed_config_hash_deep_copy
  Marshal.load(Marshal.dump(Sanitize::Config::RELAXED))
end

Config = relaxed_config_hash_deep_copy.tap do |config|
  config[:elements]            += %w(hr)
  config[:attributes][:all]    += %w(border)
  config[:attributes]["a"]     += %w(target)
end.freeze

Sanitize.clean(html, Config)
```

## Note

The examples are using `sanitize` in version `2.1`.

Did you like this article? You might find [our Rails books interesting as well](/products) .

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="15%" /></a>
<a href="/rails-react"><img src="<%= src_fit("react-for-rails/cover.png") %>" width="15%" /></a>
<a href="http://reactkungfu.com/react-by-example/"><img src="http://reactkungfu.com/assets/images/rbe-cover.png" width="15%" /></a>
<a href="/developers-oriented-project-management/"><img src="<%= src_fit("dopm.jpg") %>" width="15%" /></a>
<a href="https://arkency.dpdcart.com"><img src="<%= src_fit("blogging-small.png") %>" width="15%" /></a>
<a href="/responsible-rails"><img src="<%= src_fit("responsible-rails/cover.png") %>" width="15%" /></a>
