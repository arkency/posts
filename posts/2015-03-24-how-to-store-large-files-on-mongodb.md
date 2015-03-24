---
title: "How to store large files on MongoDB?"
created_at: 2015-03-24 17:24:29 +0100
kind: article
publish: false
author: Robert Krzysztoforski
tags: [ 'mongodb', 'gridfs' ]
newsletter: :arkency_form
img: "/assets/images/how-to-store-large-files-on-mongodb/img-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/how-to-store-large-files-on-mongodb/img-fit.jpg" width="100%">
  </figure>
</p>

The common problem we are dealing with is importing files containing a large amount of records. In my previous article
i've presented how to [speed up saving data in MongoDB](http://blog.arkency.com/2015/03/why-saving-data-using-mongohq-takes-so-long/). In this article i will focus on how we can store these files.

<!-- more -->

##First solution:

MongoDB allows us to store files lower than 16MB as a string in DB. We can simply do it by put all the data in _file\_data_ attribute. 

```
#!ruby
class FileContainer
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :file_name,   type: String
  field :file_format, type: String
  field :file_data,   type: String
end

file = File.open(xls_file_path)
FileContainer.tap do |file_container|
  file_container.file_format  = File.extname(file.path)
  file_container.file_name    = File.basename(file.path, file_container.file_format)
  file_container.file_data    = file.read
  file_container.save
end
```

The code above may work well if you upload files lower than 16MB, but sometimes users want to import (or store) files even larger.
**Be aware that here we are losing information about original file.** It is problematic if you want to work with files using different encodings. If you ever worked with encodings, that you should have known that converting between encodings isn't easy. It's better to have original file. 

##Second solution:

In this case we'll use concept called **GridFS**. To enable this feature in Rails we need to import library called
_mongoid-grid\_fs_. The lib give us access to methods such as:

- grid\_fs.put(file_path) - to put file in GridFS
- grid\_fs.get(id) - to load file by id
- grid\_fs.delete(id) - to delete file


```
#!ruby
require 'mongoid/grid_fs'

class FileContainer
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :grid_fs_id, type: String
end

file = File.open(xls_file_path)

grid_fs   = Mongoid::GridFs
grid_file = grid_fs.put(file.path)

FileContainer.tap do |file_container|
  file_container.grid_fs_id = grid_file.id
  file_container.save
end
```

In second solution, we store original file. We can do anything what we want with file. GridFS is useful not only for storing files that exceed 16MB but also for storing any files for which you want access without having to load the entire file into memory.

##References:
- https://github.com/ahoward/mongoid-grid_fs

