---
title: "Filepicker and Aviary - Image uploading on steroids"
created_at: 2012-09-21 13:10:02 +0200
kind: article
publish: false
author: Robert Pankowecki
newsletter: :arkency
tags: [ 'filepicker', 'aviary', 'avatar', 'images', 'uploads', 'resizing', 'saas', 'coffeescript', 'rails' ]
---

We all have been using the same code for uploading images for years, but didn't
you always feel that there is something wrong with it? For every other task
like writing texts, picking a date, selecting from lot of choices we have a
good tool that can help in implementing such feature and improve the user
experience, but file uploads almost always feel a little broken. There are some
Flash tools that might help, but they are still not good enough.

<!-- more -->

## Solution

Well, welcome to the world invaded by [Filepicker](https://www.filepicker.io/)
and [Aviary](http://www.aviary.com/). Speaking short, Filepicker is a tool that
let the user upload images not only from the computer itself but also from web
services such as Facebook or Dropbox. Aviary provides you with a powerful HTML5
editor for manipulating photos. Both of them process the images on their
servers and provide you an url for downloading a file. If you only need more
powerful uploading you can stick with
[Filepicker widgets](https://developers.filepicker.io/docs/web/#widgets)
otherwise we need to get our hands dirty with their Javascript APIs
(or [CoffeeScript](http://coffeescript.org/) as you will see) but is not hard at all.

## Working with code

Let's start with the view:

```ruby
<%= link_to _("Set avatar"), "#", :'data-avatar' => "set" %>
```

```html
<a href="#" data-avatar="set">Set avatar</a>
```

Nothing fancy here. Classic Rails `link_to` method, using `_('')` method for
translating with [FastGettext](https://github.com/grosser/fast_gettext). We
don't care about URL because we are going to handle clicks in Javascript so I
used `"#"` as URL. Instead of using css classes or id for such link
[I prefer to use custom data-* attribute](http://roytomeij.com/2012/dont-use-class-names-to-find-HTML-elements-with-JS.html)

First, we need to display Filepicker popup for choosing image when our link is
clicked.

```coffeescript
filepicker = window.filepicker
filepicker.setKey "filepicker api key"
$(document).ready ->
  $('body').delegate '[data-avatar="set"]', 'click', ->
    images = filepicker.MIMETYPES.IMAGES
    filepicker.getFile images, (url, metadata) ->
      console.log("Choosen image url: #{url}")
```

I use jQuery [delegate](http://api.jquery.com/delegate/) because if it was a
Single Page Application [(_SPA Todo app example_)](https://github.com/gameboxed/todomvc)
or the link is dynamically added via AJAX, it can still be properly handled.

After clicking the user needs to give permission for using data from a service
or simply upload file from computer, or even take a photo using computer
built-in camera.

<a href="/assets/images/filepicker-aviary/1_picker.png"      rel="lightbox[picker]"><img src="/assets/images/filepicker-aviary/1_picker-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/2_dropbox.png"     rel="lightbox[picker]"><img src="/assets/images/filepicker-aviary/2_dropbox-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/3_dropbox.png"     rel="lightbox[picker]"><img src="/assets/images/filepicker-aviary/3_dropbox-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/4_dropbox.png"     rel="lightbox[picker]"><img src="/assets/images/filepicker-aviary/4_dropbox-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/5_bully.png"       rel="lightbox[picker]"><img src="/assets/images/filepicker-aviary/5_bully-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/6_my_computer.png" rel="lightbox[picker]"><img src="/assets/images/filepicker-aviary/6_my_computer-thumbnail.png" /></a>

It's time now to run the photo editor when the file is picked instead of
just using `console.log`.

Create instance of the editor:

```coffescript
featherEditor = new Aviary.Feather(
  apiKey: "key"
  apiVersion: 2
  onSave: (imageID, newURL) ->
    featherEditor.close()
    return false
)
```

Use it when file picked:

```coffeescript
images = filepicker.MIMETYPES.IMAGES
filepicker.getFile images, (url, metadata) ->
  preview = $('[data-avatar="preview"]')[0]
  preview.src = url
  featherEditor.launch
    image: preview
    url: url
```

<a href="/assets/images/filepicker-aviary/7_crop.png"     rel="lightbox[aviary]"><img src="/assets/images/filepicker-aviary/7_crop-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/8_effect.png"   rel="lightbox[aviary]"><img src="/assets/images/filepicker-aviary/8_effect-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/9_warmth.png"   rel="lightbox[aviary]"><img src="/assets/images/filepicker-aviary/9_warmth-thumbnail.png" /></a>
<a href="/assets/images/filepicker-aviary/10_toolset.png" rel="lightbox[aviary]"><img src="/assets/images/filepicker-aviary/10_toolset-thumbnail.png" /></a>

When user finishes editing the photo and presses "Save" button, `onSave`
callback is executed. You can save the url value in JS variable or use it to
fill some hidden field in a form or send it to the server. However the
documentation states that _"this image may not yet be ready so you will have
to poll this link, or alternatively handle the hi-res image server-side"_.
This is my biggest disappointment when using those two products. For that
reason we are going to use `postUrl` option so that Aviary will send us a
request to this given URL when the image is ready. Obviously you will have
to use different value of the setting for development, staging and production
environment. In development you can either forward some port from your router
(I assume it is publicly available) to your computer or alternatively, if
have a server you can use ssh to forward traffic from the server to your
local machine.

Forwarding ports with `ssh`:

```bash
ssh user@YOUR_SERVER_IP -R YOUR_SERVER_IP:SOME_SERVER_PORT:127.0.0.1:3000
```

Launching the editor with `postUrl`:

```coffeescript
featherEditor.launch
  image: preview
  url: url
  postUrl: "http://YOUR_SERVER_IP:SOME_SERVER_PORT/aviary"
```

Let's see the controller that is used when Aviary notifies
us of the ready image:

```ruby
class AviaryController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:create]

  def create
    @user = User.last
    @user.remote_avatar_url = params[:url]
    @user.save!
    head :created
  end
end
```

<a href="/assets/images/filepicker-aviary/11_console.png" rel="lightbox"><img src="/assets/images/filepicker-aviary/11_console-thumbnail.png" /></a>

Find user, set avatar url and save. As simple as that. Where does
`remote_avatar_url` setter comes from ? It is a feature of
[carrierwave](https://github.com/jnicklas/carrierwave/) library that I use
to store and resize avatars. It can download the remote avatar itself so I
do not need to bother myself with that. You can use it with
[`RMagick`](http://rmagick.rubyforge.org/),
[`mini_magick`](https://github.com/probablycorey/mini_magick)
or [`vips`](https://github.com/eltiare/carrierwave-vips).

```ruby
class User < ActiveRecord::Base
  mount_uploader :avatar, AvatarUploader
end
```

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  # include CarrierWave::Vips

  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_url
    asset_path "avatar/default.png"
  end

  version :large do
    process :resize_to_fit => [256, 256]
  end
  version :medium do
    process :resize_to_fit => [128, 128]
  end
  version :small do
    process :resize_to_fit => [64, 64]
  end
end
```

The `default_url` is used when avatar is not set. That way `User#avatar`
method can nicely behave as [Null Object](http://en.wikipedia.org/wiki/Null_Object_pattern)

But we don't want anyone to be capable to send requests to our application
and change avatars, do we ? We need to add some protection. And we need to know
which user avatar should be changed. Every user will have its own token for
updating the avatar. Again, we use custom `data-*` (exactly
`data-avatar-token`) attribute to store the token in HTML.

```ruby
<%= link_to _("Set avatar"), "#", :'data-avatar' => "set", :'data-avatar-token' => AvatarToken.new(current_user).token, :'data-avatar-id' => current_user.id %>
```

```html
<a href="#" 
   data-avatar="set"
   data-avatar-token="akzlEoaW9WhV8djhtWJmCLd9vjQ="
   data-avatar-id="1">Set avatar
</a>
```

We use `postData` to store additional metadata that should come with the request
from Aviary to our App.

```coffeescript
$(document).ready ->
  $('body').delegate '[data-avatar="set"]', 'click', ->
    self  = $(this)
    token = self.attr('data-avatar-token')
    id    = self.attr('data-avatar-id')
    images = filepicker.MIMETYPES.IMAGES
    filepicker.getFile images, (url, metadata) ->
      preview = $('[data-avatar="preview"]')[0]
      preview.src = url
      featherEditor.launch
        image: preview
        url: url
        postUrl: "http://IP:PORT/users/#{id}/avatar"
        postData:
          token: token
```

Now we can use this data in our controller to verify the request:

```ruby
class Users::AvatarsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:create]

  def create
    @user    = User.find(params[:user_id])
    postdata = JSON.parse(params[:postdata]) rescue {}
    token    = postdata['token']
    AvatarToken.new(@user).verify! token
    @user.remote_avatar_url = params[:url]
    @user.save!
    head :created
  end
end
```

And this leaves us with the implementation of AvatarToken class.

```ruby
require 'hmac/sha1'
require 'base64'

class AvatarToken
  class Invalid < StandardError; end

  attr_reader :user
  delegate :login, to: :user

  def initialize(user)
    @user = user
  end

  def verify!(another_token)
    unless token == another_token
      msg = "invalid '#{another_token}' token for user '#{login}'"
      raise Invalid, msg
    end
  end

  def token
    digest = HMAC::SHA1.digest('some key', 'some value')
    Base64.strict_encode64(digest)
  end
end
```

What do you compute digest of ? Well, that depends on your application.


One more thing that I would like to do is to always get square images
from Aviary. I could not find 100% reliable way of doing that. My trick
is to allow users to use only one type of crop ratio and show the crop
tool as initial one. However, the user can still press
_"Cancel"_ unfortunately.

```coffeescript
featherEditor.launch
  cropPresets: ['1:1']
  initTool: 'crop'
```

So the whole JS part looks like this:

```coffeescript
filepicker = window.filepicker
filepicker.setKey "Filepicker API Key"
featherEditor = new Aviary.Feather(
  apiKey: "Aviary API Key"
  apiVersion: 2
  onSave: (imageID, newURL) ->
    featherEditor.close()
    return false
)

$(document).ready ->
  $('body').delegate '[data-avatar="set"]', 'click', ->
    self  = $(this)
    token = self.attr('data-avatar-token')
    id    = self.attr('data-avatar-id')
    images = filepicker.MIMETYPES.IMAGES
    filepicker.getFile images, (url, metadata) ->
      preview = $('[data-avatar="preview"]')[0]
      preview.src = url
      featherEditor.launch
        image: preview
        url: url
        postUrl: "http://IP:PORT/users/#{id}/avatar"
        postData:
          token: token
        fileFormat: 'png'
        cropPresets: ['1:1']
        initTool: 'crop'
        onError: (errorObj) ->
          alert(errorObj.message + errorObj.code)
```

Few more notes about good and bad parts of this solution:

Pro:

 * The concepts behind Filepicker and Aviary are amazing and I believe they will change the web. It's like 'Editor as a Service', 'Picker as a Service'. What else could be a service ? I would love to use [Gliffy](http://gliffy.com) editor in my app the same way I use Aviary.

 * Filepicker can store files directly in S3 so you do not have to keep them. I just prefer to have them on my machine.

 * Javascripts are available via HTTPS links.

Cons:

 * When using filepicker the user accepts _filepicker.io_ application when connecting to Facebook or Dropbox, not our own application. This might be also considered a good thing if you did not connected your App with Facebook, but I would prefer if the widgets asks for permissions for my app. However I am not sure if that would be possible at all.

 * You cannot force Aviary to provide image in one ratio.

 * You cannot download from Aviary the image in different resolutions. The workaround is to [upload it again to Filepicker](https://developers.filepicker.io/docs/web/#fpurl-save) and [download converted](https://developers.filepicker.io/docs/web/#fpurl-images). Too much hassle for me. It was just easier to this step on our server.

 * Both services ask you to link directly to their Javascript files instead of downloading them and using in your asset pipeline solution. So there are going to be additional HTTP requests when loading the page. But the good side is that if they fix some bug or improve the editor, the changes will be automatically available to your users with you deploying your app again.

 * After save, the photo URL from Aviary is not available immediately. This presents a huge UI problem. What should I show to my user after setting new avatar when I might not yet have a new avatar image to display ? Even after refresh of the page the new avatar might not yet be ready if the server is still waiting for a request from Aviary.

 * Aviary is not doing exponential backoff. It sends the request to your server only once. The game is over if you failed to handle it. (Sidenote: if you ever need to implement exponential backoff strategy in Ruby or Rails, check [exponential-backoff gem](https://github.com/pawelpacana/exponential-backoff).

 * The full list of [Aviary translations](http://www.aviary.com/web-documentation#constructor-config-language) is not bad but it is still missing few important ones for me like Greek or Turkish (forgive me my Eurocentrism).

 * You [cannot change the language ](http://www.aviary.com/web-documentation#constructor-launch) after initial Aviary configuration. Single Page Applications that are capable of changing language without reloading the page probably need to create a new instance every time they want to use Aviary editor instead of calling `launch` method multiple times on one object.

 * Filepicker does not allow you to choose any translation.
