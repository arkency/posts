---
title: "You can use CoffeeScript classes with React - pros and cons"
created_at: 2015-05-15 15:25:53 +0200
kind: article
publish: false
author: Marcin Grzywaczewski
tags: [ 'react', 'frontend', 'coffeescript' ]
newsletter: :react_book
---

One of the big advantages of React components is that they are easy to write. You create an [object literal](http://blog.arkency.com/2012/10/javascript-objects-philosophy) and provide functions as fields of your object. They you pass this object to a `React.createClass` function.

In the past `React.createClass` was a smart piece of code. It was responsible for creating a component's constructor and instantiating all fields necessary to make your plain object renderable using `React.renderComponent`. It was not an idiomatic JavaScript at all. Not to mention it broke the basic SRP principles.

It changed with a 0.12 version of React. React developers took a lot of effort to improve this situation. A new terminology was introduced. `React.createClass` now does a lot less.

One of the most important change for me is that now you can use CoffeeScript classes to create React components. Apart from the nicer syntax, it makes your code more idiomatic. It emphasizes the fact that your components are not a 'magic' React thing, but just CoffeeScript objects. I want to show you how you can use the new syntax - and what are pros and cons of this new approach.

<!-- more -->

## A bit of theory - new terminology explained 

Starting from React 0.12 the new terminology is introduced. The *component* concept was splitted into a *component* and an *element*. Also, a *node* concept was introduced. There is also a *fragment* concept, but it is beyond the scope of this blogpost - you can read more about it [here](http://facebook.github.io/react/docs/create-fragment.html).

As I said before, previously `React.createClass` made a lot of things. It made your object renderable by adding private fields to an object passed. It made a constructor to allow passing `props` and `children` to your component.

Now all this functionality is gone. `React.createClass` now just adds some utility functions to your object, autobinds your functions to `this` and checks invariants - like whether you defined `render` function or not.

That means your components are not renderable as-is. That's why React developers introduced the *element* concept. The constructor that `React.createClass` created for you now needs to be called by you explicitly. That's what you do when you call `React.createElement` function.

```
#!coffeescript

{div, h1} = React.DOM

GreetBox = React.createClass
  displayName: 'GreetBox'

  render: ->
    div null,
      h1(key: 'header', @props.children)
      children

React.render(GreetBox(name: "World", "Lorem ipsum"), realNode) # Error!
element = React.createElement(GreetBox, name: "World", "Lorem ipsum")
React.render(element, realNode) 
``` 

> React elements can be rendered. Components can't be rendered. You create elements from your components.

This is a signature of the `React.createElement` function:

```
#!coffeescript

React.createElement(type, props, children)
```

Where `type` can be a string for basic HTML tags (`"div"`, `"span"`) or a component (like in the example above). `props` is a plain object, and `children` is a *node*.

A *node* can be:

* an *element* (`div(...)`)
* array of *node*s (`[div(...), 42, "foo!"]`)
* a number (`42`)
* a text (`"foo!"`)

> Node is just a new fancy name for arguments for `children` you know from previous versions of React. 

This is a bit verbose way to create elements from your components. It also prevents you from an easy upgrade to 0.13 if you are not using JSX (we got this process covered [in our book](http://blog.arkency.com/rails-react/). Fortunately, with a little trick you can use your old `Component(props, children)` style of creating elements.

React provides us `React.createFactory` function which returns a factory for creating elements from a given component. It basically allows you to use the 'old' syntax of passing `props` and `children` to your components:

```
#!coffeescript

Component = React.createClass
  displayName: 'Component'

  render: ->
    React.DOM.div("Hello #{@props.name}!")

component = React.createFactory(Component)
React.render(component(name: "World"), realNode)
```

Notice that you can still use `React.DOM` like you've used before in React. It is because all `React.DOM` components are wrapped within a factory. Now it makes sense, isn't it?

Also, JSX does the all hard work for you. It creates elements under the hood so you don't need to bother.

```
<MyComponent /> # equivalent to React.createElement(MyComponent)
```

> There is a trend in the React development team to put backwards compatibility into the JSX layer. 

All those changes made possible to have your components defined using a simple CoffeeScript class. Moving the responsibility of "renderable" parts to `createElement` function allowed React devs to make it happen.

## React component class syntax

If you want to use class syntax for your React components in ES6, it is simple.

Your old component:

```
#!coffeescript

ExampleComponent = React.createClass
  getInitialState: ->
    test: 123

  getDefaultProps: ->
    bar: 'baz'

  render: ->
    render body 
```

Becomes:

```
#!coffeescript
class ExampleComponent extends React.Component
  constructor: (props) ->
    super props
    @state =
      test: 123

  @defaultProps: ->
    bar: 'baz'

  render: ->
    render body
```

Notice that `getInitialState` and `getDefaultProps` functions are gone. Now you set initial state directly in a constructor and pass default props as the class method of the component class. There are more subtle differences like that in class approach:

* `getDOMNode` is no more - if you're using `getDOMNode` in your component's code it's no longer available with component classes. You need to use new `React.findDOMNode` function. `getDOMNode` is deprecated, so you shouldn't use it regardless of using the class syntax or not.
* There is no way to pass mixins to component classes - this is a huge deal. Since there is no idiomatic way to work with mixins in classes (both ES6 and CoffeeScript ones), React developers decided to not support mixins at all. There are interesting alternatives to mixins in ECMAScript 7 - like [decorators](https://github.com/wycats/javascript-decorators), but they are not used so far.
* it handles `propTypes` and `getDefaultProps` differently - `propTypes` and `getDefaultProps` are passed as a class methods of your component class (as in the example above).
* component functions are not auto-binded - in `createClass` React performs auto-binding for all component's functions. Since now we're working with a plain CoffeeScript, you got a full control over `this` binding. You can use fat arrows (`=>`) to auto-bind to `this`, for example.

As you can see, this approach is more 'CoffeeScript'-y than `React.createClass` approach used before. First of all, there is an explicit constructor you write by yourself. This is a real plain CoffeeScript class. You can bind your methods by yourself. Syntax is less custom and aligns well with a style of typical CoffeeScript codebase.

Notice that you are not constructing these objects by yourself - you always pass a component class to `createElement` function.

## Pros:

* It's a plain CoffeeScript class - it is a clear indication that your components are not 'special' in any means - they are objects like the rest of your application.
* It uses common idioms of CoffeeScript
* You got more control - you control binding of your methods and you are not relying on auto-biding React performs with the `createClass` approach.
* Interesting idioms are getting created - CoffeeScript in React is not as common as we'd like, but ECMAScript 6 enthusiasts are creating new interesting idioms. For example things like [higher-order components](https://gist.github.com/sebmarkbage/ef0bf1f338a7182b6775) are interesting directions.
* It leverages built-in language features - `React.createClass` seems to be duplicating semantics that CoffeeScript already has. Thanks to ES6 getting more and more popular the class semantics CoffeeScript already has can be used with React as well.

## Cons:

* Some features are not available now - React developers priority with 0.13 version was to allow common language idioms be used in creating React components. They dropped mixins support since they can't see a suitable idiomatic solution. You can expect they will be reintroduced somehow in later versions of React.
* Developer needs to know more about JS/Coffee - since React does not auto-bind methods in a class approach, you need to be more careful with it. A good understanding of how JavaScript/CoffeeScript works can be necessary to avoid hard to track bugs in your components.
* No `getDOMNode` can be a surprise - I believe it'll be an exception, but you need to be careful about an available API. Now in `React.createClass` you can use `getDOMNode`, but not in a component class. I believe APIs will get aligned in next versions of React. Right now you need to be careful about it.

## Summary:

Component classes approach brings React closer to the world of idiomatic Coffee and JavaScript. It is an indication that React developers does not want to do 'magic' with React components. I'm a big fan of this approach - I favor this kind of explicitness in my tools. The best part is that you can try it out without changing your current code - and see whether you like it or not. It opens a way for new idioms being introduced - idioms that can benefit your React codebase.
