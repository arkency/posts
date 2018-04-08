---
title: "All the ways to generate routing paths in Rails"
created_at: 2017-09-18 10:17:05 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'rails', 'routing' ]
newsletter: :arkency_form
---

Have you ever considered how many ways there are to generate a routing path in Rails? Plenty. Let's see.

<!-- more -->

Imagine that your `config/routes.rb` contains:

```ruby
Rails.application.routes.draw do
  namespace :admin do
    resources :exercises
    get '/' => redirect("/admin/exercises")
  end
```

So the generated routes are:

```
> rake routes

             Prefix Verb  URI Pattern                         Controller#Action
    admin_exercises GET   /admin/exercises(.:format)          admin/exercises#index
                    POST  /admin/exercises(.:format)          admin/exercises#create
 new_admin_exercise GET   /admin/exercises/new(.:format)      admin/exercises#new
edit_admin_exercise GET   /admin/exercises/:id/edit(.:format) admin/exercises#edit
     admin_exercise PATCH /admin/exercises/:id(.:format)      admin/exercises#update
                    PUT   /admin/exercises/:id(.:format)      admin/exercises#update

              admin GET   /admin(.:format)                    redirect(301, /admin/exercises)
```

And in the admin panel, on the list of exercises (`Admin::ExercisesController#index` action which renders `admin/exercises/index.html.erb`) you want to link to a single exercise.

What are your options? There are some obvious ones and less obvious ones.

### `edit_admin_exercise_path`

You can just use `edit_admin_exercise_path(exercise)` or `edit_admin_exercise_path(exercise.id)` or `edit_admin_exercise_path(id: exercise.id)`. If I recall correctly, all of them are going to work.

I think this is the most often used option.

Of course instead of `_path` sometimes you are going to need `_url`.

### `[:edit, :admin, exercise]`

You can use `[:edit, :admin, exercise]`. In some places I've seen developers using `[:admin, exercise]` for `admin_exercises` route, but I've never seen this syntax being used for `edit_admin_exercise` routes and similar ones.

I don't expect my coworkers to use this version and during refactorings I most likely won't find this usage.

### `{action: :edit, controller: "admin/exercises", id: exercise.id, }`

You don't see this version used very much since Rails introduced named routes. But that will work as well. It probably accepts strings and symbols as values for action/controller keys.

### `{action: :edit, id: exercise.id }`

If you are linking between actions in the same controller you can omit the `controller` parameter. I always liked this syntax for one reason. It does not include controller's name.

That means if you ever decide to rename `Admin::ExercisesController` to `Moderator::ExercisesController` or `Admin::PublicExercisesController` and make some changes in your `config/routes.rb` so that the routes and controllers follow the same naming convention, at leas you would not need to change the links that go between views in the same controller. One less thing to worry about when doing refactorings.

### `/admin/exercise/5/edit`

You can always provide a hand-crafted String as the path. LOL 😋 . I would rather not do it, ever :)

## Summary

Usually we use named routes such as `edit_admin_exercise` which are available via methods. But the other options are worth knowing about and they can be useful when you need to generate URLs to various actions or controllers more dynamically.

Did you like this article? You will find [our Rails books interesting as well](/products).

<a href="http://rails-refactoring.com"><img src="<%= src_fit("fearless-refactoring.png") %>" width="35%" />