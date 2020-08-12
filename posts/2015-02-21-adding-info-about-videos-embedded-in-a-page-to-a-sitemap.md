---
created_at: 2015-02-21 21:50:58 +0100
publish: true
author: Robert Pankowecki
tags: [ 'sitemap', 'video', 'ruby' ]
newsletter: coaching
img: "sitemap-video-ruby-rails/sitemap.jpeg"
---

# Adding videos embedded in a page to a sitemap

<p>
  <figure>
    <img src="<%= src_fit("sitemap-video-ruby-rails/sitemap.jpeg") %>" width="100%">
  </figure>
</p>

One of our customer has a solution that allows them to quickly
create landing pages that are then used
for [SEM](http://en.wikipedia.org/wiki/Search_engine_marketing). Of course
such pages are listed in the [sitemap](/2014/02/sitemaps-with-a-bit-of-metal/)
of the application domain. The lates addition to that combo was to
list the videos embedded on the landing pages in the sitemap. It sounded hard,
but turned out to be quite easy.

<!-- more -->

Our landing pages contain html that is saved with content editor. It is just html.
The videos are embeded in a normal way recommended by the providers such as:

```html
<iframe width="560" height="315" src="https://www.youtube.com/embed/BBnN5VLuxKw" frameborder="0" allowfullscreen></iframe>
<iframe src="//player.vimeo.com/video/2854412" width="500" height="311" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
```

## Get the list of embedded videos from the html of landing page

Nokogiri for the rescue :)

```ruby

html = LandingPage.first.content

Nokogiri::HTML(html).xpath("//iframe").map do |iframe|
  extract_metadata( iframe[:src] )
end.compact
```

More about:

* [Nokogiri parsing from string](http://www.nokogiri.org/tutorials/parsing_an_html_xml_document.html#from_a_string)
* [Nokogiri searching in document](http://www.nokogiri.org/tutorials/searching_a_xml_html_document.html#basic_searching)
* [Xpath](http://www.w3schools.com/xpath/)

## Get the metadata of videos based on their url

[VideoInfo](https://github.com/thibaudgg/video_info/) to the rescue :)

```ruby

VideoMetadata = Struct.new(
  :title,
  :description,
  :thumbnail_location,
  :player_location,
  :duration_in_seconds,
  :publication_date,
)

def extract_metadata(url)
  player_location = url
  player_location = "http:#{url}" if URI(url).scheme.nil?

  vi = VideoInfo.new(url)
  VideoMetadata.new(
    vi.title,
    vi.description,
    vi.thumbnail_large,
    player_location,
    vi.duration,
    vi.date
  )
rescue VideoInfo::UrlError, *NetHttpTimeoutErrors.all
  return nil
end
```

If an `iframe` is not for a recognizable video then `VideoInfo` will raise an exception
that we catch. If there is networking problem we gracefuly handle
it as well.

* [Catching all Http errors from standard ruby lib](https://github.com/barsoom/net_http_timeout_errors) .
It's harder then you might think.

## Use metadata in the sitemap

[SitemapGenerator](https://github.com/kjvarga/sitemap_generator) to the rescue.

```ruby
SitemapGenerator::Sitemap.create do
  LandingPage.find_each do |landing_page|
    videos = extracted(landing_page.content).map do |video_metadata|
      {
        title:            video_metadata.title,
        description:      video_metadata.description,
        thumbnail_loc:    video_metadata.thumbnail_location,
        player_loc:       video_metadata.player_location,
        duration:         video_metadata.duration_in_seconds,
        publication_date: video_metadata.publication_date
      }
    end
    
    add(
      landing_page_path(id: landing_page.slug),
      lastmod: landing_page.updated_at,
      changefreq: 'monthly',
      priority: 0.7,
      videos: videos
    )
  end
end
```

* [Adding video content to a Sitemap based on the Sitemap protocol](https://support.google.com/webmasters/answer/80472?hl=en#2)
* [Supported sitemap options by `sitemap_generator` gem](http://www.rubydoc.info/gems/sitemap_generator/4.3.1/SitemapGenerator/Builder/SitemapUrl:initialize)

## That's it

These three snippets are the essence of it. There are of course tests, and there is
[adapter](http://blog.arkency.com/2014/08/ruby-rails-adapters/) for obtaining video
data so that tests don't connect to the internet.

But it turned out to be way simpler than I expected. Which is always a nice surprise
in our industry.
