---
title: "Decoding JSON with unknown structure with Elm"
created_at: 2017-11-16 18:00:09 +0100
kind: article
publish: true
author: Anton Paisov
tags: [ 'elm', 'json' ]
---

A
[decoder](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Json-Decode)
is what turns JSON values into Elm values.

<!-- more -->

_This post has been updated after I have received some valuable feedback._

[Paweł](/by/pacana/) and I have been working recently on a web interface for
[RailsEventStore](https://railseventstore.org). The main goal is to have a
dashboard in which one could examine stream contents and look for particular
events. It may serve as an audit log browser available to you out of the box.

It is written in Elm and soon will be an integral part of the RailsEventStore
solution.

## Decoding JSON

For the purpose of this post here's how we imported `Json.Decode`.

```elm
import Json.Decode as D exposing (Decoder, Value, field, list, string, at, value)
```

First lets examine how you could decode JSON with a known structure:

```json
{
  "name": "Order$42"
}
```

Here is how a corresponding Elm JSON decoder looks like:

```elm
type Stream = Stream String

streamDecoder : Decoder Stream
streamDecoder =
    D.map Stream
        (field "name" string)
```

We transform value of the attribute `name` into Elm `String` first. In the end
what we receive from decoder is `Stream "Order$42"`.

It gets more interesting when we want to decode an event.

```json
{
  "event_type": "OrderPlaced",
  "event_id": "f6c96c3c-c138-4ee2-b228-bfe363004ee4",
  "data": {
    "order_id": 42,
    "net_value": 999
  },
  "metadata": {
    "timestamp": "2017-11-14 23:21:04 UTC",
    "remote_ip": "1.2.3.4"
  }
}
```

We cannot assume what exact structure will `data` and `metadata` have. It can be
different for each event type. For example an event published from background
job process will not record `remote_ip` in `metadata`.

There is no event schema that we could parse and generate decoder from it. So we
fallback to mapping `data` and `metadata` as strings in our event decoder.

What seemed fairly easy ended not so well in `elm-repl`:

```elm
> sampleData = "{ \"data\": { \"order_id\": 42 } }"
> D.decodeString (field "data" string) sampleData

Err "Expecting a String at _.data but instead got: {\"order_id\":42}"
    : Result.Result String String
```

You can't _just_ pass JSON subtree and expect it to be decoded with `string`.
Here's the solution we've ended up with:

```elm
type alias EventWithDetails =
    { eventType : String
    , eventId : String
    , data : String
    , metadata : String
    }

getEvent : String -> Cmd Msg
getEvent eventId =
    let
        decoder =
            D.andThen eventWithDetailsDecoder rawEventDecoder
    in
        Http.send EventDetails (Http.get "/event.json" decoder)


rawEventDecoder : Decoder ( Value, Value )
rawEventDecoder =
    D.map2 (,)
        (field "data" value)
        (field "metadata" value)


eventWithDetailsDecoder : ( Value, Value ) -> Decoder EventWithDetails
eventWithDetailsDecoder ( data, metadata ) =
    D.map4 EventWithDetails
        (field "event_type" string)
        (field "event_id" string)
        (field "data" (D.succeed (toString data)))
        (field "metadata" (D.succeed (toString metadata)))
```

First we've replaced `string` with `value`.
[Documentation](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Json-Decode#value)
on this states:

> Do not do anything with a JSON value, just bring it into Elm as a Value. This
> can be useful if you have particularly crazy data that you would like to deal
> with later. Or if you are going to send it out a port and do not care about
> its structure.

Once we decoded `data` and `metadata` into a generic `Value` we needed a way to
fit it into `EventWithDetails` record. This is where
[`andThen`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Json-Decode#andThen)
helped us. It allowed us to combine two decoders together with a second one
taking result from previous.


### Update

_After submitting this post to Elmlang slack, Ilias Van Peer suggested an even better solution with a following comment:_

> cool. Might be a little more safe if you `Json.Encode.encode 0` the value; otherwise you’ll get some pretty weird looking strings for stuff like json arrays
> (`toString` on a value isn’t stringifying the json)
> And safer towards the future, where `toString` will move to the `Debug` module and will behave differently in production
> So essentially you could replace the entire thing like so:

```elm
eventDetailedDecoder : Decoder EventWithDetails
eventDetailedDecoder =
    D.map4 EventWithDetails
        (field "event_type" string)
        (field "event_id" string)
        (field "data" (value |> D.map (encode 0)))
        (field "metadata" (value |> D.map (encode 0)))
```

With this solution we don't need `rawEventDecoder` and for it to work we would also need to expose `encode` from `Json.Encode` like this:

```elm
import Json.Encode exposing (encode)
```

Thank you Ilias :)
