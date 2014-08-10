---
title: "Truncating UTF8 Input For Apple Push Notifications (APNS) in Ruby"
created_at: 2014-08-10 12:20:33 +0200
kind: article
publish: false
author: Robert Pankowecki
newsletter: :skip
newsletter_inside: :mobile
tags: [ 'apns', 'push', 'notifications', 'apple', 'utf8', 'truncate' ]
---

<p>
  <figure align="center">
    <img src="/assets/images/apns-ruby/phones.png">
  </figure>
</p>

When sending push notifications ([APNS](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/ApplePushService.html))
to apple devices such iPhone or iPad there is a constraint that makes implementing it a bit challenging:

_The maximum size allowed for a notification payload is 256 bytes; Apple Push Notification Service refuses any notification that exceeds this limit_

This wouldn't be a problem itself unless you want to put user input into the notification.
This also wouldn't be that hard unless the input can be international and contain non-ascii character. Which still would
not so hard, but the payload is in JSON and things get a little more complicated.

<!-- more -->

## Desired payload

```
      {
        aps: {
          alert: "'User X' started following you",
        },
        path: "appnameios://users/123",
      }
```

This is simplified version of our payload. The notifications is about someone who started following you on our fancy
social platform that we are writing. The `path` allows the app to open it on a view related to the user who started
following. The things that are going to vary are user name (_User X_ in our example) and user id (_123_).

## Payload template

So let's extract the template of the payload into a method. This will be come handy later:

```
#!ruby
  def payload_template(user_name, user_id)
    {
      aps: {
        alert: "'#{user_name}' started following you",
      },
      path: "appnameios://users/#{user_id}",
    }
  end
```

## Bytes, bytes everywhere

Remember when I said that we have 256 bytes? We do, but # of useful bytes for our case is even smaller.

```
#!ruby
payload_template("", "").to_json.bytesize
# => 73
```

Even when we don't substitute data into our payload we are out of 73 bytes. That means we have only...
 
```
#!ruby
  MAX_APS_BYTES = 256
  def payload_arg_max_size
    MAX_APS_BYTES - payload_without_args_size
  end
  
  def payload_without_args_size
    payload_template("", "").to_json.bytesize
  end
  
  payload_arg_max_size
  # => 183
```

... 183 bytes for user input

If your payload (required for the app to properly behave when the notification is clicked) is bigger or your
message is longer you are left with even fewer bytes of user input.

## Not everything can be truncated

But wait... We can't truncate user id. If we did we could be misleading about who actually started following
the recipient of the notification. So even though it _kind-of_ external data we can't truncate it.

We can see that the logic for this is slowly getting more and more complicated. That's why for every push notification
we have a class that encapsulates the logic of formatting it properly according to APNS rules.

```
#!ruby
class StartedFollowing < Struct.new(:user_name, :user_id)
  def payload
    # ...
  end
  
  private
  
  def payload_template(user_name)
    {
      aps: {
        alert: "'#{user_name}' started following you",
      },
      path: "appnameios://users/#{user_id}",
    }
  end
  
  MAX_APS_BYTES = 256
  def payload_arg_max_size
    MAX_APS_BYTES - payload_without_args_size
  end
    
  def payload_without_args_size
    payload_template("").to_json.bytesize
  end
end
```

## Truncating

Ok, we know how many bytes we have so let's truncate our international string. But remember that we are not truncating
up to N chars, we are truncating up to N bytes! We can
use [`String#byteslice`](http://www.ruby-doc.org/core-2.1.2/String.html#method-i-byteslice) for that.

It's all nice and handy if we happen to truncate exactly between characters. 

```
#!ruby
"łøü".bytes
# => [197, 130, 195, 184, 195, 188]

"łøü".byteslice(0, 4)
# => "łø"
```

But sometimes we won't:

```
#!ruby
"łøü".byteslice(0, 3)
 => "ł\xC3"
```

We are left we one proper character and one byte which is ugly.

I've been looking long time to figure out how to properly fix it and it seems
that the right answer is [`String#scrub`](http://ruby-doc.org/core-2.1.0/String.html#method-i-scrub). For those of you
who are stuck with older ruby version, there is backport of it in form of
[string-scrub gem](https://github.com/hsbt/string-scrub).

So if you ever need to truncate user provided utf-8 string and support international characters `byteslice` + `scrub`
will do the job for you:

```
#!ruby
"łøü".byteslice(0, 3).scrub("")
 => "ł"
```

## Full solution

```
#!ruby
require 'string-scrub' unless String.instance_methods.include?(:scrub)
require 'json'

class StartedFollowing < Struct.new(:user_name, :user_id)
  InvalidPayloadGenerated = Class.new(StandardError)

  def payload
    raise PayloadTooBigToGenerate if payload_arg_max_size < 0

    payload_template(truncated_user_name).tap do |hash|
      size = hash.to_json.bytesize
      size <= MAX_APS_BYTES or raise InvalidPayloadGenerated.new("Payload size was: #{size}")
    end
  end
  
  private
  
  def payload_template(name)
    {
      aps: {
        alert: "'#{name}' started following you",
      },
      path: "appnameios://users/#{user_id}",
    }
  end
  
  MAX_APS_BYTES = 256
  def payload_arg_max_size
    MAX_APS_BYTES - payload_without_args_size
  end
    
  def payload_without_args_size
    payload_template("").to_json.bytesize
  end

  def truncated_user_name
    user_name.byteslice(0, payload_arg_max_size).scrub("")
  end
end


notif = StartedFollowing.new("łøü"*100, 12345)
notif.payload
# => {:aps=>{:alert=>"'łøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłøüłø' started following you"}, :path=>"appnameios://users/12345"}

notif.payload.to_json.bytesize
# => 256
```

Yay! We used our payload to full extent!

## Troubles

I added this line `size <= MAX_APS_BYTES or raise InvalidPayloadGenerated.new("Payload size was: #{size}")` at the end
just to make sure that everything is ok with my approach and catch errors early (and implemented tests as well). Lucky me!

In my case it turned out my json encoder was using [numeric escape characters](http://stackoverflow.com/questions/583562/json-character-encoding-is-utf-8-well-supported-by-browsers-or-should-i-use-nu),
so they way I calculated the size of my truncated size was wrong because in JSON it turned out to be bigger:

```
#!ruby
puts "łøü".to_json
# => "łøü"
"łøü".to_json.bytesize
# => 8 # 6 bytes for string plus 2 bytes for ""
```

vs

```
#!ruby
irb(main):059:0> puts "łøü".to_json
# => "\u0142\u00f8\u00fc"

"łøü".to_json.bytesize
# => 20
```

So I extracted the code responsible to truncating one string into a class
 
```
#!ruby
class TruncateStringWithMbChars
  def initialize(string_with_mb_chars, maxbytes)
    @string_with_mb_chars = string_with_mb_chars
    @maxbytes = maxbytes
  end

  def call
    string_with_mb_chars.mb_chars[0..last_char_id].to_s
  end

  private

  attr_reader :string_with_mb_chars, :maxbytes

  def last_char_id
    string_with_mb_chars.
      each_char.
      map{|c| c.to_json.bytesize }.
      each_with_index.
      inject(maxbytes){|bytesum, (bytes, i)| bytesum -= (bytes-2) ; return i-1 if bytesum < 0; bytesum }
    return string_with_mb_chars.size
  end
end
```

This algorithm basically iterates over every char, checks how many bytes it is going to take in our json payload
and stops when we don't have more space for our text. I am not proud of this code. Do you know a better way of how to
do it? What's they right way to check how many bytes a char will take if encoded as numeric escape character? I am
sure there must be an easier way to do it.

_Warning_: It has a bug when `maxbytes` is not enough for even one character to be left. 

## Multiple strings to substitute in notifications

The logic gets even more complicated if you want to embed in your payload multiple strings.
Good example can be a notification like _'UserX' & 'UserY' invite you to game 'Game'_. We could use ⅓ of bytes
for each substituted string in naive implementation. But I wanted the algorithm to be smart and work well even in
case when some names are long and some are short. My algorithm for truncating multiple strings so that they
all use no more than N bytes looks like this:

```
#!ruby
class TruncateMultipleStrings
  def initialize(strings, maxjsonbytes)
    @strings      = strings
    @maxjsonbytes = maxjsonbytes
  end

  def call
    hash = @strings.inject({}){|memo, string| memo[string.object_id] = string; memo }
    maxjsonbytes = @maxjsonbytes
    hash.values.sort_by{|s| string_json_bytesize(s) }.each_with_index do |string, index|
      maxjsonbytes_for_string = maxjsonbytes / (@strings.size - index)
      shortened = TruncateStringWithMbChars.new(string, maxjsonbytes_for_string).call
      maxjsonbytes -= string_json_bytesize(shortened)
      hash[string.object_id] = shortened
    end
    hash.values
  end

  private

  def string_json_bytesize(string)
    string.to_json.bytesize - 2
  end
end
```

Be aware that it doesn't favor any of the String. If they are all very long, then all of them will
be allowed to use same amount of bytes. If any of the strings is short, then the unused bytes are split equally amongst
the other strings.

```
#!ruby
TruncateMultipleStrings.new(["short", "medium medium", "long "*30], 60).call
# => ["short", "medium medium", "long long long long long long long long lo"]
 
TruncateMultipleStrings.new(["long "*30, "medium medium", "long "*30], 60).call
#  => ["long long long long lon", "medium medium", "long long long long long"]
  
TruncateMultipleStrings.new(["long "*30, "long "*30, "long "*30], 60).call
# => ["long long long long ", "long long long long ", "long long long long "]
```

Here is an example of class that could be using it

```
#!ruby
class GameInvited < Struct.new(:user1, :user2, :game_name, :game_id)
  InvalidPayloadGenerated = Class.new(StandardError)

  def payload
    raise PayloadTooBigToGenerate if payload_arg_max_size < 0

    payload_template(*truncated_names).tap do |hash|
      size = hash.to_json.bytesize
      size <= MAX_APS_BYTES or raise InvalidPayloadGenerated.new("Payload size was: #{size}")
    end
  end
  
  private
  
  def payload_template(u1, u2, g)
    {
      aps: {
        alert: "#{u1} and #{u2} invite you to game #{g}",
      },
      path: "appnameios://games/#{game_id}",
    }
  end
  
  MAX_APS_BYTES = 256
  def payload_arg_max_size
    MAX_APS_BYTES - payload_without_args_size
  end
    
  def payload_without_args_size
    payload_template("", "", "").to_json.bytesize
  end

  def truncated_names
    TruncateMultipleStrings.new([user1, user2, game_name], payload_arg_max_size).call
  end
end


notif = GameInvited.new("User1 "*100, "User2 "*100, "Game "*100, 123457890123)
notif.payload

# => {:aps=>{:alert=>"User1 User1 User1 User1 User1 User1 User1 User1 User1 Use and User2 User2 User2 User2 User2 User2 User2 User2 User2 Use invite you to game Game Game Game Game Game Game Game Game Game Game Game G"}, :path=>"appnameios://games/123457890123"}
```

## Resources

* [JSON UTF-8 numeric escape sequences, should I use it?](http://stackoverflow.com/questions/583562/json-character-encoding-is-utf-8-well-supported-by-browsers-or-should-i-use-nu)
* I can recommend using [grocer gem for APNS push notifications](https://github.com/grocer/grocer)
* [ios7 features](https://www.apple.com/ios/features/)

Notes:

* UA i o tym, że on swój payload dodaje
* CTA
* Newsletter