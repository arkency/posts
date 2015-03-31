---
title: "Implementing Game Dashboard With React.js"
created_at: 2015-03-30 20:00:00 +0100
kind: article
publish: false
author: Wiktor Mociun
tags: [ 'javascript', 'eventbus', 'reactjs' ]
newsletter: :react_book
img: "/assets/images/game-dashboard-react/front-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/game-dashboard-react/front-fit.jpg" width="100%">
    <details>
      Source: <a href="https://www.flickr.com/photos/36877266@N08/">412 digital</a>
    </details>
  </figure>
</p>

Many developers starting their adventure with React.js ask me about one thing. How to mount many independent React.js components on single page? I'll show you my approach to handle this problem.

<!-- more -->

## What's the problem?

We have some JavaScript applications showing user information using React.js components. We are good developers, so each one of them handles separate responsibility.

We have applications, but now we need to put them all together on screen.

## Case Study - game dashboard

Some time ago I was working on simple game inspired by [CivClicker](http://dhmholley.co.uk/civclicker.html). I wanted to have *one big screen with primary information about my virtual city*. I developed applications responsible for game control and city management: resources, society and infrastructure.

<p>
  <figure align="center">
    <img src="/assets/images/game-dashboard-react/dashboard-fit.png">
    <figcaption>
      Each rectangle represents separate app
    </figcaption>
  </figure>
</p>

I knew I could do it much simpler, but I will need to add some logic here soon.

## Getting stuff done

### 1. Let backend handle that - quick and easy approach

We can *use Rails views* to solve our problem. Only thing we need is to expose empty HTML elements.

```
#!html

<!-- app/views/dashboard/dashboard.index.html.erb -->
<div id="game">
    <div data-app="gameHeader"></div>
    <div class="left-column">
        <div data-app="cityResources"></div>
        <div data-app="citySociety"></div>
    </div>    
    <div class="right-column">
        <div data-app="cityInfrastructure"></div>        
    </div>
</div>
```

And now in each of our application would need code like this:

```
#!coffeescript

App = require('city_infrastructure/app')

$(document).ready ->
  node = document.querySelector('[data-app="cityInfrastructure"]')
  app = new App()
  app.start(node) 
```

We got basic HTML structure covered and empty divs for React to plug-in. It works great, but what if we would want to add some logic here?

Example: we want to show `City Infrastructure` widget after player reached level 2. We can change our code.

```
#!html

<!-- app/views/dashboard/dashboard.index.html.erb -->
<div id="game">
    <div data-app="gameHeader"></div>
    <div class="left-column">
        <div data-app="cityResources"></div>
        <div data-app="citySociety"></div>
    </div>    
    <div class="right-column">
        <%% if @player.level > 1 %>
          <div data-app="cityInfrastructure"></div>        
        <%% end %>
    </div>
</div>
```

Our view isn't dead simple anymore. Controller responsible for rendering this view needs to pass `player` object to template engine. Our code just got more complex. In future development it may get worse as it grows.

It's a good solution for start. Let's move on. We will use React.js and some event bus to help us with this issue.

### 2. JavaScript app - more dynamic and elastic approach

Let's make simple JavaScript application that will render empty HTML elements for other applications.

Here's the main idea. When all elements get rendered, global event bus tells all applications about this fact. We will use `componentDidMount` method from React component's API to achieve this.

```
#!coffeescript

{div} = React.DOM
EventBus = require('modules/event_bus')
CurrentPlayer = require('modules/current_player')

DashboardSkeleton = React.createClass
  displayName: 'DashboardSkeleton'
  
  # It is launched after React view is rendered
  componentDidMount: ->
    @props.eventBus.publish 'cityHeaderDivRendered'
    @props.eventBus.publish 'cityResourcesDivRendered'
    @props.eventBus.publish 'citySocietyDivRendered'
    @props.eventBus.publish 'cityInfrastructureDivRendered' if @showCityInfrastructure()

  showCityInfrastructure: -> @props.currentPlayer.level > 1
    
  render: ->
    div
      id: 'game'
      @header()
      @leftColumn()  
      @rightColumn()
   
  header: ->
    div dataApp: 'gameHeader'    
      
  leftColumn: ->
    div className: 'left-column'
      div dataApp: 'cityResources'
      div dataApp: 'citySociety'
      
  rightColumn: ->      
    div className: 'right-column'
      div dataApp: 'cityInfrastructure' if @showCityInfrastructure()

Gui = React.createFactory DashboardSkeleton

class DashboardApp
  constructor: ->
    @eventBus = EventBus
    @startupGui = Gui(eventBus: @eventBus)

  start: (node) ->
    React.render(@gui, node)
```
    
Only thing left to do are event handlers for all applications.

```
#!coffeescript
class CityInfrastructureApp
  constructor: ->
    # ...
    @registerGuiStartup()

  registerGuiStartup: ->
    @eventBus.on 'cityInfrastructureDivRendered', =>
      node = document.querySelector('[data-app="cityInfrastructure"]')
      React.render(node, @gui)
```
 
This simple solution gives us flexibility for further changes. We can use all benefits of dynamic front-end without introducing new libraries. Moreover, using this approach we gained new feature for free. We can render any app anytime during application life cycle. We just need to publish an event.

Often, first solution is good enough. Yet, it gets problematic when we need to add some logic to the application. We can move this logic to front-end and simplify our Rails backend.
