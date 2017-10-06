---
title: "How to overwrite to_json (as_json) in Active Record models in Rails"
created_at: 2017-09-26 11:44:52 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'to_json', 'as_json', 'rails', 'active_record']
newsletter: :arkency_form
---

Let's say you have a model in Rails with certain attributes and columns. When you serialize it with `to_json`, by default Rails will include all columns. How can you add one more or remove some from now appearing there?

<!-- more -->

In the simplest way you can define the `as_json` method on your model. You can call `super` to get the standard behavior from `ActiveRecord::Base` and then add or remove more attributes on that result.

Imagine that you have `Event` class. And initially the JSON looks like.

```js
{
  "id": 1,
  "title": "Ergonomic Granite Table course",
  "description": "You can’t just skip ahead to where you think...",
  "starts_at": "2017-10-10T00:00:00.000Z",
  "ends_at": "2017-10-13T00:00:00.000Z",
  "category": "Holiday",
  "state": "published",
  "image_url": "http://lorempixel.com/600/338/animals/1",
  "created_at": "2017-10-03T09:30:25.481Z",
  "updated_at": "2017-10-04T08:36:43.049Z",
}
```

You might want to remove `created_at`, `updated_at` and add one new field such as `is_single_day_event`.

You can do it that way:

```ruby
class Event < ApplicationRecord
  def single_day_event?
    starts_at.to_date == ends_at.to_date
  end

  def as_json(*)
    super.except("created_at", "updated_at").tap do |hash|
      hash["is_single_day_event"] = single_day_event?
    end
  end
end
```

And now when you call `event.to_json` you are going to get

```js
{
  "id": 1,
  "title": "Ergonomic Granite Table course",
  "description": "You can’t just skip ahead to where you think...",
  "starts_at": "2017-10-10T00:00:00.000Z",
  "ends_at": "2017-10-13T00:00:00.000Z",
  "category": "Holiday",
  "state": "published",
  "image_url": "http://lorempixel.com/600/338/animals/1",
  "is_single_day_event": true,
}
```

If the logic around serializing your objects gets more complex over time or you need multiple representations of the same model, I suggest you decouple JSON serialization from ActiveRecord. You can do it by using of the gems such as `ActiveModel::Serializers` or similar.

<a href="https://ruby.libhunt.com/categories/24-api-builder" rel="nofollow">Potential gems for you to investigate</a>

## Would you like to continue learning more?

If you enjoyed the article, [subscribe to our newsletter](http://arkency.com/newsletter) so that you are always the first one to get the knowledge that you might find useful in your
everyday Rails programmer job.

Content is mostly focused on (but not limited to) Ruby, Rails, Web-development and refactoring big, complex Rails applications.