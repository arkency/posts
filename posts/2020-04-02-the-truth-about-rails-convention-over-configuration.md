---
created_at: 2020-04-02 10:24:17 +0200
author: Andrzej Krzywda
tags: [ 'rails', 'architecture' ]
publish: false
---

# The truth about Rails Convention over Configuration

This blogpost is a work in progress. It's also a call for collaboration to Arkency friends (via pull requests - [https://github.com/arkency/posts/edit/master/posts/2020-04-02-the-truth-about-rails-convention-over-configuration.md](https://github.com/arkency/posts/edit/master/posts/2020-04-02-the-truth-about-rails-convention-over-configuration.md) ) if the goal of this blogpost resonates with you.

The goal of this post is to:

* show definition of the word "convention"
* remind what configuration meant before Rails appeared (maybe examples from Struts XML?)
* provide as many examples of Rails conventions as possible
* summarize/group those conventions - it's likely that many of those are just metaprogramming or "magic"
* explain why those conventions optimize for the first N days of developing the Rails app
* explain, provide examples - how some of the conventions introduce coupling at the design level
* conclude that Rails Convention over Configuration may lead and often leads to technical debt
* explain ideas behind Architecture over Convention
* provide alternative solutions to the listed Rails conventions - link to other blogposts/resources, including Arkency ones, but not limited to them

Feel free to help with any of the points here, just create a section and contribute. Probably the easiest contributions (but helpful!) would be listing more examples of Rails conventions.

Once the goals are accomplished, this blogpost will be published, linked from Arkency blog index and linked from the sitemap. Before it happens, it has its own URL which you can send to other potential collaborators - [https://blog.arkency.com/the-truth-about-rails-convention-over-configuration](https://blog.arkency.com/the-truth-about-rails-convention-over-configuration)
 
<!-- more -->

## Convention - the definitions

## The old days of XML Configuration hell

## Examples

* copying controller instance variables into views 
* automatic mapping from column names to ActiveRecord attributes

## How the conventions help

## Coupling - examples

## Convention over Configration leading to a Technical debt

## Architecture over Convention

## Alternative solutions to typical Rails conventions

# Meaningful path helpers

I was a rails dev for a few years but haven't touched it in a while, and since being locked down I've had a chance to make a quiz app that I've been putting off for a while. I made a route structure that looked like this:

```
Rails.application.routes.draw do
  get "/", to: "application#index"

  resources :logins
  resources :games do
    resources :submissions
  end

  namespace :admin do
    get "/", to: "admin#index"
    resources :quizzes do
      resources :questions do
        resources :choices
      end

      resources :games
    end
  end
end
```

This gave me the URL structure I wanted, which also gave me a useful folder structure too:

- controllers
  - admin
    - admin_controller.rb
    - games_controller.rb
    - logins_controller.rb
    - questions_controller.rb
    - quizzes_controller.rb
  - games_controller.rb
  - submissions_controller.rb

Note that the use of `namespace` gives us a new directory for our controllers to live under, while the `resources` directive doesn't nest - this makes sense to me. The views directory does something similar

- views
  - admin
    - admin
    - games
    - logins
    - questions
    - quizzes
  - games

Then it comes time to start adding forms and links that navigate these routes. We'll make a landing page that links to all of the Game models:

```
<div>
  <ol>
    <% Game.find_each do |game| %>
    <li><%= link_to game.title, game %></li>
    <% end %>
  </ol>
</div>
```

Note that the link_to helper can take a model and infer what to do - it knows that there are routes for Game on the base level, so these convert to `games/:id`. What happens on the game pages?

```
<div>
  <%= form_with(model: [@game, @submission]) do %>
    <ul>
      <% @question.choices.each do |choice| %>
        <ol><%= radio_button_tag :choice_id, choice.id %> <%= label_tag :choice_id, choice.description %></ol>
      <% end %>
    </ul>
    <%= submit_tag %>
  <% end %>
</div>
```

Again, we haven't called the path helper directly, we've passed an array to the `form_with` method that knows to traverse the route structure of Game->Submission, and creates a POST form to `games/submissions`

Let's see how this looks in the admin screen. It's in the admin namespace, so links get prefixed with `admin/`

```
<%= link_to "Quizzes", admin_quizzes_path %>
```

Makes sense to me! Now inside this index page, how do we create and link to individual quizzes?

```
<div><%= link_to "Admin", admin_path %></div>
<div><%= link_to "Create quiz", new_admin_quiz_path %></div>
<div>
  Quizzes:
  <ol>
    <% Quiz.find_each do |quiz| %>
    <li><%= link_to quiz.name, [:admin, quiz] %></li>
    <% end %>
  </ol>
</div>
```

So we can see both ways of linking in Rails:

- With an array of models - this calls the path helper internally, finds the right route and generates an appropriate URL
- With the path helpers - we can use language to decide which method will be used in the route; compare `game_path`, `games_path`, and `new_games_path`

How do Rails conventions help us here?

- The only configuration is in the `routes.rb` file. Everything else is dictated from there.
- Using a namespace alters the URL and implies a nested directory for controllers/views
- Using nested resources alters the URL but doesn't change the directory structure
- Passing arrays of models implies a path_helper call which implies a route which implies a resourceful URL
- The model names are intrinsically linked to the controller names and route names
- Subtle things like plurals change the meaning of our routes (plural = index, singular = show)

