---
title: "Why saving data using MongoHQ takes so long?"
created_at: 2015-03-23 17:16:31 +0100
kind: article
publish: true
author: Robert Krzysztoforski
tags: [ 'heroku', 'mongodb', 'import data' ]
newsletter: :arkency_form
img: "/assets/images/why-saving-data-using-mongohq-takes-so-long/img-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/why-saving-data-using-mongohq-takes-so-long/img-fit.jpg" width="100%">
  </figure>
</p>

Recently in one of the projects we've taken over, which uses MongoDB and is hosted on Heroku, we have been asked to speed up an importing file process.
It seemed to be a simple thing but without a few tricks we wouldn't have made it.

<!-- more -->

I need to say a few things first, we're using a standard Heroku app configuration and MongoHQ addon. 
It's been enough for our needs so far. The question is why **import of 10MB file takes so long? It took around 1h.**
You would say that the problem is in the code, but it's a half-truth. 

Below you can see an example of a service to import files with BIM (Building Information Model) objects.
Every BIM object has properties. The properties may be duplicated. The important thing is that we have 2 loops here.
10MB file may include 10k objects and 5k properties, so the service has to save 15k records in DB. 

```
#!ruby
class ImportBimObjectsService
  def call(model, data)
    bim_object_parser = BimObjectsParser.new(data)
    
    bim_object_parser.bim_properties.each do |name|
      bim_property = model.bim_properties.find_or_initialize_by(name: name)
      unless bim_property.model_ids.include?(model.id)
        bim_property.model_ids << model.id
      end
      bim_property.save
    end
    
    bim_object_parser.bim_objects.each do |bim_object_attrs|
      model.bim_objects.create(bim_object_attrs)
    end
  end
end
```

We can imagine where the problem is. 15k requests to DB isn't a small number, especially when we're using MongoHQ and Heroku.
**Usually DB server is in a different location than webserver, so the latency isn't so small like it's on local environment.**
In our case the difference between Heroku and local environment was quite big. On development we were able to import the file in 7 min, on Heroku in 1h.

##How to minimize the number of requests?
We can use MongoDB _insert_ method, however _insert_ doesn't run validations and it's on our hands to make sure that our model is correct. We can compare _insert_ with storing raw data in DB. There is the last thing to remember, before we store data, we have to add fields like _updated_\__at_ and _created_\__at_ to attributes.

```
#!ruby
class ImportBimObjectsService
  def call(model, data)
    bim_object_parser = BimObjectsParser.new(data)
    
    bim_object_parser.bim_properties.each do |name|
      bim_property = model.bim_properties.find_or_initialize_by(name: name)
      unless bim_property.model_ids.include?(model.id)
        bim_property.model_ids << model.id
      end
      bim_property.save
    end
    
    now = Time.now
    valid_bim_objects = bim_object_parser.bim_objects.map do |bim_object_attrs|
      bim_object = model.bim_objects.build(bim_object_attrs)
      if bim_object.valid?
        bim_object.as_document.merge({ created_at: now, updated_at: now })
      end
    end
    
    model.bim_objects.collection.insert(valid_bim_objects)
  end
end
```

Thanks to solution presented above we were able to reduce the number of requests from 15k into 5k, but we can make it even better. Be aware that part of the code responsible for saving properties isn't optimal. We could reduce _find\_or\_initialize\_by_ calls. To do that, we can use some kind of cache which stores only unique properties.

```
#!ruby
class ImportBimObjectsService
  class BimPropertyUniqCache
    attr_accessor :objects
  
    def initialize
      @objects = []
    end
    
    def add(name, model_id)
      if objects[name].present?
        unless objects[name].include?(model_id)
          @objects[name] << model_id
        end
      else
        @objects[name] = [model_id]
      end
    end
  end

  def call(model, data)
    bim_object_parser = BimObjectsParser.new(data)
    
    bim_property_cache = BimPropertyUniqCache.new
    bim_object_parser.bim_properties.each do |name|
      bim_property_cache.add(name, model.id)
    end
    
    bim_property_cache.objects.each do |(name, model_ids)|
      bim_property = model.bim_properties.find_or_initialize_by(name: name)
      bim_property.model_ids += model_ids
      bim_property.model_ids.uniq
      bim_property.save
    end
    
    now = Time.now
    valid_bim_objects = bim_object_parser.bim_objects.map do |bim_object_attrs|
      bim_object = model.bim_objects.build(bim_object_attrs)
      if bim_object.valid?
        bim_object.as_document.merge({ created_at: now, updated_at: now })
      end
    end
    
    model.bim_objects.collection.insert(valid_bim_objects)
  end
end
```

Thanks to _BimPropertyUniqCache_ class we were able to avoid unnecessary requests.

## Conclusion:

Remember that access time to MongoDB locally is faster than on Heroku. You can easly bypass it by using mass insert. Unluckily by _insert_ we're skipping validations and we need to validate records before. We're forced to write more code, but processing time is significantly decreased. Eventually importing a 10MB file takes around 1 min.

## References:
- http://docs.mongodb.org/manual/reference/method/db.collection.insert/