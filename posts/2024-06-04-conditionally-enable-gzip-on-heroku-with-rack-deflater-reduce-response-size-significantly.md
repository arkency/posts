---
created_at: 2024-06-04 13:09:43 +0200
author: Tomasz Stolarczyk
tags: [gzip, compression, heroku, rack, deflater, middleware]
publish: false
---

# Conditionally Enable GZIP on Heroku with Rack::Deflater: Reduce Response Size Significantly

If you came here after searching for something like "rack deflater path condition" or "rack deflater if option," here is 
your answer:

```ruby
config.middleware.use Rack::Deflater, :if => lambda { |env, status, headers, body| env["PATH_INFO"] == "/your/endpoint/path/here" }
```

Just insert this line in your `application.rb`, and you're set. We could wrap up this post here, but... But we all know 
that we should not take a piece of random information from the Internet for granted. No matter what the most advanced, 
AI-powered search engines in the world may suggest, adding non-toxic glue to pizza sauce is never a good choice.

Let's start by explaining how we ended up with such a config. Recently, we have been working on performance improvements 
of the project's most complex (from the UI perspective) page. Well, basically, those are just... two tables and a chart. 
But those tables are big, like very big, as they usually contain a few thousand cells. It's a lot of HTML when "hotwired" 
<wink, wink>. You could say now that with JSON, it would be less data, but well, I love how Hotwire works, and I totally 
agree with this statement from their [handbook](https://turbo.hotwired.dev/handbook/introduction#turbo-streams%3A-deliver-live-page-changes):

> Yes, the HTML payload might be a tad larger than a comparable JSON, but with gzip, the difference is usually negligible, 
> and you save all the client-side effort it takes to fetch JSON and turn it into HTML."

And that was actually what... **did not** happen in our case 😉. At some point, we noticed that downloading the response 
took longer than waiting for the server on my Internet connection.

<img src="<%= src_original("conditionally-enable-gzip-on-heroku-with-rack-deflater-reduce-response-size-significantly/post_content_compression_download_details.png") %>" width="100%">

You can spot the huge response size, the missing `Content-Encoding` header, and the download time here. The client was 
sending the `Accept-Encoding: gzip, deflate, br, zstd` header, so we just double-checked using cURL. Use the `--write-out` 
option with the `size_download` variable to see the download size.

<img src="<%= src_original("conditionally-enable-gzip-on-heroku-with-rack-deflater-reduce-response-size-significantly/post_content_compression_curl_before_compression.png") %>" width="100%">

The downloaded content size was the same for both requests (with and without the `Accept-Encoding` header).

<img src="<%= src_original("conditionally-enable-gzip-on-heroku-with-rack-deflater-reduce-response-size-significantly/post_content_compression_the_same_response.png") %>" width="100%">

This means the server does not support compression by default. As the project is hosted on a standard Heroku setup, there 
is nothing like a reverse proxy there (with configured compression). In such a case, [Heroku tells us to compress on the application side](https://devcenter.heroku.com/articles/compressing-http-messages-with-gzip).

<img src="<%= src_original("conditionally-enable-gzip-on-heroku-with-rack-deflater-reduce-response-size-significantly/post_content_compression_heroku_docs.png") %>" width="100%">

A small disclaimer here is that for this project, the responses' compression is not needed in most cases as we do exact 
updates of page elements. Compression and then decompression of such small pieces of content would make no sense. You may 
want to see how we usually work with Hotwire in this YouTube episode: [Make your tables alive with turbo streams. Redirect vs Turbo Streaming. Which one to choose?](https://www.youtube.com/watch?v=hc1C0r4a1J4).

Moreover, we even disabled "gzipping" for assets (`config.assets.gzip = false`) so the CDN could do it better. 
There is already a post about it here: [Don't waste your time on assets compilation on Heroku](https://blog.arkency.com/dont-waste-your-time-on-assets-compilation-on-heroku/).

Nevertheless, for this one specific case, also given some timebox conditions, we consider enabling a `Rack::Deflater` 
conditionally a good option. It also gave us satisfying results, as **we were able to reduce the response size from ~5MB to ~100KB** 😉

<img src="<%= src_original("conditionally-enable-gzip-on-heroku-with-rack-deflater-reduce-response-size-significantly/post_content_compression_curl_after_compression.png") %>" width="100%">

We will probably stay with it as long as we don't need compression for many more endpoints (which is doubtful, 
given [our way of working with Turbo Frames and Turbo Streams](https://www.youtube.com/watch?v=hc1C0r4a1J4)).

Last but not least, some food for thought. In the long term, we could gather some metrics about response size and find 
some sweet spot for which responses (above which size, for example) we should compress. Then we could move the compression 
part to the revere proxy (like nginx) using, for example, the [heroku-buildpack-nginx](https://github.com/heroku/heroku-buildpack-nginx). 
Thanks to that, the app itself would not need to spend resources on compression, and that would be done by a specialized 
tool that supports not only GZIP but also Brotli, for example.
