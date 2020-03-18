---
title: "How to use Greg's Event Store from ruby"
created_at: 2015-03-27 15:23:03 +0100
kind: article
publish: true
author: Tomasz Rybczyński
tags: [ 'event', 'eventstore', 'greg' ]
newsletter: arkency_form
img: "events/stream.jpg"
---

<p>
  <figure align="center">
    <img src="<%= src_fit("events/stream.jpg") %>">
  </figure>
</p>

I one of a previous blog's [post](/2015/03/your-solid-tool-for-event-sourcing-eventstore-examples/) I mentioned that we have to create a some tool to communicate with Greg's ES. We did it. We created [HttpEventstore](https://github.com/arkency/http_eventstore) gem which is a HTTP connector to the Greg's Event Store. The reason of creating such tool was that in our projects we already use Event Sourcing and we experiment with Greg's tool.

<!-- more -->

## How to use it

To communicate with ES you have to create instance of `HttpEventstore::Connection` class. After configuring a client, you can do the following things.

```ruby
client = HttpEventstore::Connection.new do |config|
   #default value is '127.0.0.1'
   config.endpoint = 'your_endpoint'
   #default value is 2113
   config.port = 'your_port'
   #default value is 20 entries per page
   config.page_size = 'your_page_size'
end
```

### Creating new event

* Creating a single event:

```ruby
stream_name = "order_1"
event_data = { event_type: "OrderCreated",
               data: { data: "sample" },
               event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd" }
client.append_to_stream(stream_name, event_data)
```

OR

```ruby
EventData = Struct.new(:data, :event_type)
stream_name = "order_1"
event_data = EventData.new({ data: "sample" }, "OrderCreated")
client.append_to_stream(stream_name, event_data)
```

You can pass event's data as a **Hash** or **Struct**. As you can see in above example `event_id` is optional parameter. If you don't set it we will generate it for you.

* Creating a single event with optimistic locking:

```ruby
stream_name = "order_1"
event_data = { event_type: "OrderCreated", data: { data: "sample" }}
expected_version = 1
client.append_to_stream(stream_name, event_data, expected_version)
```

The expected version is a number representing the version of the stream. It is a next expected identifier of event. So, if your last event's position id is equal 40 that `expected_version` will be 41.

### Deleting stream

The soft delete cause that you will be allowed to recreate the stream by creating new event. If you recreate soft deleted stream all events are lost. After an hard delete any try to load the stream or create event will result in a 410 response.

* The soft delete of single stream:

```ruby
stream_name = "order_1"
client.delete_stream("stream_name")
```

* The hard delete of single stream:

```ruby
stream_name = "order_1"
hard_delete = true
client.delete_stream("stream_name", hard_delete)
```

### Reading stream's event forward

* Reading stream forward without Long Pooling

```ruby
stream_name = "order_1"
start = 21
count = 40
client.read_events_forward(stream_name, start, count)
```

* Reading stream forward using Long Pooling

```ruby
stream_name = "order_1"
start = 21
count = 40
pool_time = 15
client.read_events_forward(stream_name, start, count, poll_time)
```

Long Pooling in ES works as when you want to load head of stream and no data is available the server will wait specified amount of time. So, if you want to fetch the a newest entries you can specify `pool_time` attribute to wait before returning with no result. The `pool_time` is time in seconds.

### Reading stream's event backward

```ruby
stream_name = "order_1"
start = 21
count = 40
client.read_events_backward(stream_name, start, count)
```

### Reading all stream's event forward

```ruby
stream_name = "order_1"
client.read_all_events_forward(stream_name)
```

This method allows us to load all stream's events ascending.

### Reading all stream's event backward

```ruby
stream_name = "order_1"
client.read_all_events_backward(stream_name)
```

This method allows us to load all stream's events descending.

## Example

One of my teammates has created sample application which uses Greg's Event Store and our gem. You can find out it [here](https://github.com/mpraglowski/cqrses-sample). This project represents example of rails app based on CQRS/ES architecture.
