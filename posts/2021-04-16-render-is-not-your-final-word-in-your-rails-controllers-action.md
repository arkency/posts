---
title: "'render' is not your final word in your Rails controller's action"
created_at: 2021-04-16T07:45:16.021Z
author: Jakub Kosiński
tags: ["rails", "rendering"]
publish: false
---

Today I have a quick tip for you. Suppose you are using some library that performs some logic in your controller and render some templates once some invariants are not met. 
Assume the library is old and was created once you were not using JSON API but was only rendering HTML templates.
Now you need to add similar logic to your API controller. You may think that you should now modify the library to handle JSON responses, but that's not the only solution you can use.

Remember that the `render` method in your controllers is not returning the control flow from your action and you can still modify the response or perform some operations once you call `render`. 
You only cannot call `render` more than once in a single action as that will raise the `DoubleRenderError` exception.

This means you can enhance your action without touching the library. Let's assume your library is exposing a module with a method that is rendering a template in case on an exception (I'm not going to discuss if the library is well-written here, this in only an example):

```ruby
module ActivationCheck

  def check_active(id)
    ActivationChecker.new.call(id) # returns true if a project with given id is active, raises an error otherwise
  rescue ActivationCheck::Error => exc
    render("activation_check/error", message: exc.message)
    false
  end
end
```

and you API controller looks like this:

```ruby
class ProjectsController
  include ActivationCheck
  
  def show
    project = Project.find(params[:id])
    if check_active(project.id)
      render json: project
    end
  end
end      
```

The problem with using the library in your controller is that when the `check_active` method returns `false`, it also means the HTML template with `200 OK` status will also be rendered in the response. 
You can always create some JSON template to overwrite the default HTML template provided by your library, but this will still return `200 OK` status (and you should not return successful status code if your response is not successful). In order to handle this, let's just modify your response status directly later in the flow:

```ruby
class ProjectsController
  include ActivationCheck
  
  def show
    project = Project.find(params[:id])
    if check_active(project.id)
      render json: project
    else # in this branch ActivationCheck has already rendered a template
      response.status = :bad_request
    end
  end
end      
```

Now, as long as you create a JSON template to overwrite the default one (e.g. `app/views/activation_check/error.json.erb`), you will return the JSON response with proper status code in your controller without modifying the original library.
