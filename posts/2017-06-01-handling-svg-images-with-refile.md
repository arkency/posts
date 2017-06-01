---
title: "Handling SVG images with Refile and Imgix"
created_at: 2017-06-01 14:00:39 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'svg', 'refile', 'imgix' ]
newsletter: :arkency_form
---

My colleague Tomek today was responsible for changing a bit how we
handle file upload in project so that it can support SVG logos.

For handling uploads this Rails project uses `Refile` library. And
for serving images there is `Imgix` which helps you save bandwith
and apply transformations (using Imgix servers instead of yours).

<!-- more -->

The normal approach didn't work because it did not recognize SVGs
as images.

```
#!ruby
attachment :logo, type: :image
```

So instead we had to list supported content types manually.

```
#!ruby
attachment :logo, 
  content_type: %w(image/jpeg image/png image/gif image/svg+xml)
```

There is also a bit of logic involved in building proper URL for
the browser.

```
#!ruby
= link_to image_tag(imgix_url("/shop/#{shop.logo_id}",
  { auto: "compress,format",w: 300,h: 300,fit: "crop" }),
  filename: shop.logo_filename)
```

```
#!ruby
def imgix_url(path, **options)
  options[:lossless] = true if options[:lossless].nil?
  host = options.delete(:host) || S3_IMGIX_PRODUCTION_HOST)
  Imgix::Client.new(host: host).path(path).to_url(options)
end
```
