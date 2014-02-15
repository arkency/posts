---
title: "Sitemaps with a bit of Metal"
created_at: 2014-02-13 22:06:47 +0100
kind: article
publish: false
author: Szymon Fiedler
newsletter: :arkency_form
tags: [ 'seo', 'rails', 'sitemap', 'actioncontroller::metal' ]
---

<p>
  <figure>
    <img src="/assets/images/sitemaps/ironpour.jpg" width="100%">
    <details>
      <a href="https://www.flickr.com/photos/tinkerszone/3948664111/sizes/z/">Photo</a>
      remix available thanks to the courtesy of
      <a href="http://www.flickr.com/photos/tinkerszone/">tinkerbrad</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

Sooner or later, you will probably start taking care about your application's SEO,
especially if it provides a lot of content and you want to be discovered by users
in search engines results. There are several ways to do this in your Ruby app.
You can create `sitemap.xml` file manually if there aren't very much urls,
but it will become pretty ineffective when you have more than a dozen or so.
There are some very neat tools which will do this for you out of the box,
even if you need a lot of customization.

<!-- more -->

## Tools to the rescue
Tool which I would like to mention is [Sitemap Generator](https://github.com/kjvarga/sitemap_generator)
by [kjvarga](https://twitter.com/kjvarga). It's pretty cool,
it keeps the [standards](http://www.sitemaps.org/) so you don't have to care too much.
It also have custom rake tasks, which will generate Sitemap under given criteria
and ping selected search engines about availability of new one one for your site. Magic.

Installation is very easy. You only need to add one line to your `Gemfile`:

```
#!ruby
sitemap_generator, require: false
```

Then you should run `bundle` and `rake sitemap:install`.
Now you should have `config/sitemap.rb` in your directory structure,
which you need to tweak for your needs.

```
#!ruby
SitemapGenerator::Sitemap.default_host = 'http://example.com'
SitemapGenerator::Sitemap.create do
  add '/home', :changefreq => 'daily', :priority => 0.9
  add '/contact_us', :changefreq => 'weekly'
end
```

And that's it! All you need to do is to run `rake sitemap:refresh`.
Now you have new `sitemap.xml.gz` file in your `/public` directory.

```
#!xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
   <url>
      <loc>http://www.example.com/</loc>
      <changefreq>monthly</changefreq>
      <priority>0.8</priority>
   </url>
   <url>
      <loc>http://www.example.com/home</loc>
      <changefreq>daily</changefreq>
      <priority>0.9</priority>
   </url>
   <url>
      <loc>http://www.example.com/contact_us</loc>
      <changefreq>weekly</changefreq>
      <priority>0.9</priority>
   </url>
</urlset>
```

If your app handle multiple domains, there's no problem,
because you can render multiple sitemap files for different domains,
subdomains or specific locales.

## Hitting Sitemap limits

You might also heard that a single `Sitemap` must have no more than 50,000 URLs and can't be larger
than 10MB. And it's true. There was a risk that our app will hit that limit in close future.
Fortunatelly [Sitemap protocol](http://www.sitemaps.org/protocol.html#index) provides
a possibility to handle such situation through `index` files. As I mentioned earlier,
`sitemap_generator` keeps the standards pretty good, so it creates `index` file if such one is needed by default.
You can also force it to always create `index` file.

Let's use some real life example. Mentioned application is presenting a huge amount of events and allows users to buy tickets to them.
We will fetch all events from database through `find_each` method to get objects in batches.
We do this in case that large amount of objets could not fit into memory.
On each _event_ we would use `event_path` helper to add proper `URL` to our sitemap.

```
#!ruby
SitemapGenerator::Sitemap.create_index = true

SitemapGenerator::Sitemap.default_host = 'http://example.com'
SitemapGenerator::Sitemap.create do
  Event.find_each do |event|
    add event_path(event.slug, locale: false), lastmod: event.updated_at, changefreq: 'daily'
  end
end
```

After running `rake sitemaps:refresh` we now have at least two files: `sitemap.xml.gz` and `sitemap1.xml.gz`.
At least because for each _n_ multiple of 50,000, `sitemap{n}.xml.gz` would get created.

Let's take a close look at `sitemap.xml.gz` content:

```
#!xml
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
 <sitemap>
    <loc>http://www.example.com/sitemap1.xml.gz</loc>
    <lastmod>2004-10-01T18:23:17+00:00</lastmod>
 </sitemap>
 <sitemap>
    <loc>http://www.example.com/sitemap2.xml.gz</loc>
    <lastmod>2005-01-01</lastmod>
 </sitemap>
</sitemapindex>
```

It no longer contains a `Sitemap`, but `index` which specifies where the `Sitemaps` are.

Content of `sitemap1.xml.gz`:

```
#!xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
   <url>
      <loc>http://www.example.com/</loc>
      <changefreq>monthly</changefreq>
      <priority>0.8</priority>
   </url>
   <url>
      <loc>http://www.example.com/events/awesome_event_1</loc>
      <changefreq>daily</changefreq>
      <priority>0.5</priority>
   </url>
   <!-- ... -->
   <url>
      <loc>http://www.example.com/events/awesome_event_50000</loc>
      <changefreq>daily</changefreq>
      <priority>0.5</priority>
   </url>
</urlset>
```

Content of `sitemap1.xml.gz`:

```
#!xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
   <url>
      <loc>http://www.example.com/</loc>
      <changefreq>monthly</changefreq>
      <priority>0.8</priority>
   </url>
   <url>
      <loc>http://www.example.com/events/awesome_event_50001</loc>
      <changefreq>daily</changefreq>
      <priority>0.5</priority>
   </url>
   <!-- ... -->
   <url>
      <loc>http://www.example.com/events/awesome_event_100001</loc>
      <changefreq>daily</changefreq>
      <priority>0.5</priority>
   </url>
</urlset>
```

Pretty easy, isn't it?

## Great, but I don't want to keep this in my /public directory
If you use CDN for static files and don't want to keep `Sitemap` in your `/public` directory,
you can use specific adapter and just customize this in config file:

```
#!ruby
SitemapGenerator::Sitemap.adapter = SitemapGenerator::WaveAdapter.new
```

or even

```
#!ruby
SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new
```

I really appreciate how the author of the gem solved different storage mechanisms.
If you need more customization in this area, you can just write your compatible adapter and save `Sitemap`
whenever you want: database, key-value storage or whatever.
If we want to use `ActiveRecord` for this purpose, we can just write:

```
#!ruby
module SitemapGenerator
  class ActiveRecordAdapter
    def write(location, raw_data)
      Sitemap.new do |sitemap|
        sitemap.data      = gzip(StringIO.new, raw_data).string
        sitemap.filename  = location[:filename]
        sitemap.mime_type = 'multipart/x-gzip'
      end.save!
    end

    def gzip(location, string)
      gz = Zlib::GzipWriter.new(location)
      gz.write string
      gz.close
    end
  end
end
```

One more thing to do to keep this running is to create such db migration:

```
#!ruby
class CreateSitemaps < ActiveRecord::Migration
  def change
    create_table :sitemaps do |t|
      t.binary :data,      null: false
      t.string :filename,  null: false
      t.string :mime_type, null: false

      t.timestamps
    end

    add_index :sitemaps, [:filename, :created_at]
  end
end
```

We must also update our `config/sitemap.rb` file and tell that we want to use custom
adapter:

```
#!ruby
SitemapGenerator::Sitemap.adapter = SitemapGenerator::ActiveRecordAdapter.new
```

Ok, now we have up and running creation of Sitemap. But how to render it if it's no longer
available in `/public` directory?
We need to find away to get the file from db and render to user, in this case search engine crawler.

## Let's write custom controller

To render our file we need to create proper controller.
In typical Rails application we would probably do something like this:

```
#!ruby
class SitemapsController < ApplicationController
  skip_before_filter :authenticate_user! # because you use devise, don't you?

  def show
    sitemap = Sitemap.where(filename: params[:id]).order('created_at desc').first!
    respond_to do |format|
      format.xml_gz { send_data sitemap.data, filename: sitemap.filename }
    end
  end
end
```

Our controller responds to `xml_gz` format which is not supported in Rails by default.
We need to register this format, so our controller could render proper response when
`*.xml.gz` format is requested by client. We can to do this by putting line below
in `config/initializers/mime_types.rb` file.

```
#!ruby
Mime::Type.register "application/x-gzip", :xml_gz, [], ["xml.gz"]
```

One more necessary thing is adding these few lines to `config/routes.rb`:

```
#!ruby
constraints(format: /[a-z]+(\.[a-z]+)?/) do
  resources :sitemaps, only: :show
  get '/sitemap.:format' => 'sitemaps#show'
end
```

We use constraints on `format` because we need to handle non standard, double resource extension `xml.gz`.
Without this, our Rails app would lookup for resource with `.gz` extension and `sitemap.xml`
would be treated as filename.

Let's take a look what exactly our controller has inside:

```
#!ruby
irb(main):001:0> SitemapsController.ancestors
=> [
     SitemapsController,
     ApplicationController,
     #<Module:0x007fc2178c35a8>,
     #<Module:0x007fc2179a01b0>,
     ActionController::Base,
     Turbolinks::XHRHeaders,
     Turbolinks::Cookies,
     Turbolinks::XDomainBlocker,
     Turbolinks::Redirection,
     Devise::Controllers::UrlHelpers,
     Devise::Controllers::Helpers,
     Devise::Controllers::StoreLocation,
     Devise::Controllers::SignInOut,
     ActiveRecord::Railties::ControllerRuntime,
     ActionDispatch::Routing::RouteSet::MountedHelpers,
     ActionController::ParamsWrapper,
     ActionController::Instrumentation,
     ActionController::Rescue,
     ActionController::HttpAuthentication::Token::ControllerMethods,
     ActionController::HttpAuthentication::Digest::ControllerMethods,
     ActionController::HttpAuthentication::Basic::ControllerMethods,
     ActionController::RecordIdentifier,
     ActionController::DataStreaming,
     ActionController::Streaming,
     ActionController::ForceSSL,
     ActionController::RequestForgeryProtection,
     ActionController::Flash,
     ActionController::Cookies,
     ActionController::StrongParameters,
     ActiveSupport::Rescuable,
     ActionController::ImplicitRender,
     ActionController::MimeResponds,
     ActionController::Caching,
     ActionController::Caching::Fragments,
     ActionController::Caching::ConfigMethods,
     AbstractController::Callbacks,
     ActiveSupport::Callbacks,
     ActionController::ConditionalGet,
     ActionController::Head,
     ActionController::Renderers::All,
     ActionController::Renderers,
     ActionController::Rendering,
     ActionController::Redirecting,
     ActionController::RackDelegation,
     ActiveSupport::Benchmarkable,
     AbstractController::Logger,
     ActionController::UrlFor,
     AbstractController::UrlFor,
     ActionDispatch::Routing::UrlFor,
     ActionDispatch::Routing::PolymorphicRoutes,
     ActionController::ModelNaming,
     ActionController::HideActions,
     ActionController::Helpers,
     AbstractController::Helpers,
     AbstractController::AssetPaths,
     AbstractController::Translation,
     AbstractController::Layouts,
     AbstractController::Rendering,
     AbstractController::ViewPaths,
     ActionController::Metal,
     AbstractController::Base,
     ActiveSupport::Configurable,
     Object,
     PP::ObjectMixin,
     ActiveSupport::Dependencies::Loadable,
     JSON::Ext::Generator::GeneratorMethods::Object,
     Kernel,
     BasicObject
   ]

irb(main):002:0> SitemapsController.ancestors.count
=> 68
```

But do we really need to carry whole this stuff which is usually inherited by ApplicationController?
How about no. We don't really need skipping before filters, we don't need url helpers,
turbolinks, devise and any other useless in this case stuff. So, let's slim this down a bit.

## Here comes the Metal

```
#!ruby
class SitemapsController < ActionController::Metal
  include AbstractController::Rendering
  include ActionController::MimeResponds
  include ActionController::DataStreaming
  include ActionController::RackDelegation
  include ActionController::Rescue
  include ActionController::Head

  def show
    sitemap = Sitemap.where(filename: params[:id]).order('created_at desc').first!
    respond_to do |format|
      format.xml_gz { send_data sitemap.data, filename: sitemap.filename }
    end
  end
end
```

Let's take a look what we have achieved:

```
#!ruby
irb(main):004:0> SitemapsController.ancestors
=> [
     SitemapsController,
     ActionController::Head,
     ActionController::Rescue,
     ActiveSupport::Rescuable,
     ActionController::RackDelegation,
     ActionController::DataStreaming,
     ActionController::Rendering,
     ActionController::MimeResponds,
     AbstractController::Rendering,
     AbstractController::ViewPaths,
     ActionController::Metal,
     AbstractController::Base,
     ActiveSupport::Configurable,
     Object,
     PP::ObjectMixin,
     ActiveSupport::Dependencies::Loadable,
     JSON::Ext::Generator::GeneratorMethods::Object,
     Kernel,
     BasicObject
   ]

irb(main):005:0> SitemapsController.ancestors.count
=> 19
```

Our controller is much lighter and contains mostly necessary things to serve our `sitemap.xml.gz` file to Google,
Bing, Yandex or whoever wants our `Sitemap`. [José Valim](https://twitter.com/josevalim) inspired me
to use [ActionController::Metal](http://api.rubyonrails.org/classes/ActionController/Metal.html) in his
_Crafting Rails Applications_ book. Picking only those modules which are indispensable for our
controllers is a pretty cool approach, but in my humble opinion, not rarely seen in Rails applications.
Mounting Sinatra application with requested functionality in `routes.rb` or `config.ru` could be alternative,
but still lightweight solution.

## Making sales and marketing happy
As you can see, such chore like rendering `Sitemap` can be done in a smart way,
in most of the cases with just few lines of code. It's very useful, especially for the applications
with a lot of content. Easy customization is another advantage of presented solution. And now go and make
your sales and marketing teams happy providing better search engine results.

I will try to write another blogpost focused on usage of `ActionController::Metal` in different, but maybe more
surprising use case, on condition that this topic is interesting for you and
[Robert](http://blog.arkency.com/by/pankowecki/) won't forestall me. :)


