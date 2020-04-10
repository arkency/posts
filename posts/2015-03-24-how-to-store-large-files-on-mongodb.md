---
title: "How to store large files on MongoDB?"
created_at: 2015-04-02 11:58:03 +0200
publish: true
author: Robert Krzysztoforski
tags: [ 'mongodb', 'gridfs', 'sidekiq' ]
newsletter: arkency_form
img: "how-to-store-large-files-on-mongodb/img.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("how-to-store-large-files-on-mongodb/img.jpg") %>" width="100%">
  </figure>
</p>

The common problem we deal with is importing files containing a large amount of records. In my previous article
I've presented how to [speed up saving data in MongoDB](http://blog.arkency.com/2015/03/why-saving-data-using-mongohq-takes-so-long/). In this article i will focus on how we can store these files.

<!-- more -->

Sometimes we want to store file first and parse it later. This is the case when you use async workers like Sidekiq.
To workaround this problem you need to store the file somewhere.

##First solution:

MongoDB allows us to store files smaller than 16MB as a string in DB. We can simply do it by putting all the data in _file\_data_ attribute. 

```ruby
class FileContainer
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :file_name,   type: String
  field :file_format, type: String
  field :file_data,   type: String
end

file = File.open(xls_file_path)
FileContainer.new.tap do |file_container|
  file_container.file_format  = File.extname(file.path)
  file_container.file_name    = File.basename(file.path, file_container.file_format)
  file_container.file_data    = file.read
  file_container.save
end
```

The code above may work well if you upload files smaller than 16MB, but sometimes users want to import (or store) files even larger.
The bad thing in presented code is that **we are losing information about the original file**. That thing may be very helpful when you need to open the file in a different encoding. **It's always good to have the original file.**

##Second solution:

In this case we’ll use a concept called **GridFS**. This is MongoDB module for storing files. To enable this feature in Rails we need to import a library called
_mongoid-grid\_fs_. The lib gives us access to methods such as:

- grid\_fs.put(file_path) - to put file in GridFS
- grid\_fs.get(id) - to load file by id
- grid\_fs.delete(id) - to delete file


```ruby
require 'mongoid/grid_fs'

class FileContainer
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :grid_fs_id, type: String
end

file = File.open(xls_file_path)

grid_fs   = Mongoid::GridFs
grid_file = grid_fs.put(file.path)

FileContainer.new.tap do |file_container|
  file_container.grid_fs_id = grid_file.id
  file_container.save
end
```

In the second solution we are storing the original file. We can do anything what we want with it. **GridFS is useful not only for storing files that exceed 16MB but also for storing any files for which you want access without having to load the entire file into memory.**

##References:
- https://github.com/ahoward/mongoid-grid_fs
- http://docs.mongodb.org/manual/faq/developers/#faq-developers-when-to-use-gridfs

