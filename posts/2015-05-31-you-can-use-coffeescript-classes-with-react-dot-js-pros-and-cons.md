---
title: "You can use CoffeeScript classes with React - pros and cons"
created_at: 2015-05-31 18:37:00 +0200
publish: true
author: Marcin Grzywaczewski
tags: [ 'react', 'front end', 'coffeescript' ]
newsletter: react_books
---

One of the big advantages of React components is that they are easy to write. You create an [object literal](http://blog.arkency.com/2012/10/javascript-objects-philosophy) and provide functions as fields of your object. They you pass this object to a `React.createClass` function.

In the past `React.createClass` was a smart piece of code. It was responsible for creating a component's constructor and instantiating all fields necessary to make your plain object renderable using `React.renderComponent`. It was not an idiomatic JavaScript at all. Not to mention it broke the basic SRP principles.

It changed with a 0.12 version of React. React developers took a lot of effort to improve this situation. A new terminology was introduced. `React.createClass` now does a lot less.

One of the most important change for me is that now you can use CoffeeScript classes to create React components. Apart from the nicer syntax, it makes your code more idiomatic. It emphasizes the fact that your components are not a 'magic' React thing, but just CoffeeScript objects. I want to show you how you can use the new syntax - and what are pros and cons of this new approach.

<!-- more -->

## A bit of theory - new terminology explained 

Starting from React 0.12 the new terminology is introduced. There are now *elements* - they are an intermediary step between *component classes* and *components*. Since before 0.12 `children` type was not formally specified, we have a new term for that - it is a *node* now.

There is also a *fragment* concept introduced, but it is beyond the scope of this blogpost - you can read more about it [here](http://facebook.github.io/react/docs/create-fragment.html).

As I said before, previously `React.createClass` made a lot of things. It made your object renderable by adding private fields to an object passed. It made a constructor to allow passing `props` and `children` to create a component.

Now all this functionality is gone. `React.createClass` now just adds some utility functions to your class, autobinds your functions and checks invariants - like whether you defined a `render` function or not.

That means your component classes are not renderable as they are. Now you must turn them into 'renderable' form by creating an *element*. Previously you passed `props` and `children` to a component class itself and it created an element behind the scenes. This constructor created by `React.createClass` now needs to be called by you explicitly. You can do it calling `React.createElement` function.

```coffeescript

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

> React elements can be passed to render a component. Component classes can't be rendered. You create elements from your component classes.

This is a signature of the `React.createElement` function:

```coffeescript

React.createElement(type, props, children)
```

Where `type` can be a string for basic HTML tags (`"div"`, `"span"`) or a component (like in the example above). `props` is a plain object, and `children` is a *node*.

A *node* can be:

* an *element* (`div(...)`)
* array of *node*s (`[div(...), 42, "foo!"]`)
* a number (`42`)
* a text (`"foo!"`)

> Node is just a new fancy name for arguments for `children` you know from previous versions of React. 

This is a bit verbose way to create elements from your component classes. It also prevents you from an easy upgrade to 0.13 if you are not using JSX (we got this process covered [in our book](http://blog.arkency.com/rails-react/)). Fortunately, with a little trick you can use your old `Component(props, children)` style of creating elements.

React provides us `React.createFactory` function which returns a factory for creating elements from a given component class. It basically allows you to use the 'old' syntax of passing `props` and `children` to your component classes:

```coffeescript

Component = React.createClass
  displayName: 'Component'

  render: ->
    React.DOM.div("Hello #{@props.name}!")

component = React.createFactory(Component)
React.render(component(name: "World"), realNode)
```

Notice that you can still use `React.DOM` like you've used before in React. It is because all `React.DOM` component classes are wrapped within a factory. Now it makes sense, isn't it?

Also, JSX does the all hard work for you. It creates elements under the hood so you don't need to bother.

```
<MyComponent /> # equivalent to React.createElement(MyComponent)
```

> There is a trend in the React development team to put backwards compatibility into the JSX layer. 

All those changes made possible to have your component classes defined using a simple CoffeeScript class. Moving the responsibility of "renderable" parts to `createElement` function allowed React devs to make it happen.

## React component class syntax

If you want to use class syntax for your React component classes in ES6, it is simple.

Your old component:

```coffeescript

ExampleComponent = React.createClass
  getInitialState: ->
    test: 123

  getDefaultProps: ->
    bar: 'baz'

  render: ->
    render body 
```

Becomes:

```coffeescript
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
* There is no way to pass mixins to component classes - this is a huge drawback. Since there is no idiomatic way to work with mixins in classes (both ES6 and CoffeeScript ones), React developers decided to not support mixins at all. There are interesting alternatives to mixins in ECMAScript 7 - like [decorators](https://github.com/wycats/javascript-decorators), but they are not used so far.
* it handles `propTypes` and `getDefaultProps` differently - `propTypes` and `getDefaultProps` are passed as a class methods of your component class (as in the example above).
* component functions are not auto-binded - in `createClass` React performs auto-binding for all component's functions. Since now we're working with a plain CoffeeScript, you got a full control over `this` binding. You can use fat arrows (`=>`) to auto-bind to `this`.

As you can see, this approach is more 'CoffeeScript'-y than `React.createClass`. First of all, there is an explicit constructor you write by yourself. This is a real plain CoffeeScript class. You can bind your methods by yourself. Syntax aligns well with a style of typical CoffeeScript codebase.

Notice that you are not constructing these objects by yourself - you always pass a component class to `createElement` function and `React.render` creates component objects from elements.

## Pros:

* It's a plain CoffeeScript class - it is a clear indication that your components are not 'special' in any means.
* It uses common idioms of CoffeeScript.
* You got more control - you control binding of your methods and you are not relying on auto-biding React performs with the `createClass` approach.
* Interesting idioms are getting created - CoffeeScript in React is not as common as we'd like, but ECMAScript 6 enthusiasts are creating new interesting idioms. For example things like [higher-order components](https://gist.github.com/sebmarkbage/ef0bf1f338a7182b6775).

## Cons:

* Some features are not available now - React developers priority with 0.13 version was to allow common language idioms be used in creating React component classes. They dropped mixins support since they can't see a suitable idiomatic solution. You can expect they will be reintroduced somehow in later versions of React.
* Developer needs to know more about JS/Coffee - since React does not auto-bind methods in a class approach, you need to be more careful with it. A good understanding of how JavaScript/CoffeeScript works can be necessary to avoid bugs in your components.
* No `getDOMNode` can be a surprise - I believe it'll be an exception, but you need to be careful using available API. Now in `React.createClass` you can use `getDOMNode`, but not in a component class. I believe APIs will get aligned in next versions of React.

## Summary:

Pure classes approach brings React closer to the world of idiomatic Coffee and JavaScript. It is an indication that React developers does not want to do 'magic' with React component classes. I'm a big fan of this approach - I favor this kind of explicitness in my tools. The best part is that you can try it out without changing your current code - and see whether you like it or not. It opens a way for new idioms being introduced - idioms that can benefit your React codebase.

## "Rails meets React.js" gets an update!

<img src="<%= src_fit("react-for-rails/cover.png") %>" width="50%" style="float: left; margin-right: 1.5em;" />

**We are going to release a "Rails meets React.js" update with all code in the book updated to React 0.13 this Friday**. All people who bought the book already will get this update (and all further updates) for free. It is aimed for Rails developers wanting to learn React.js by example. 

<div style="clear: both; padding-bottom: 1.5em;"></div>

**For the price of $49 you get:**

* 150~ pages of hands-on examples, basic theorethical background, tips for testing and best practices;
* 50~ pages of bonus content - examples of React in action, more advanced topics and interesting worldviews about creating rich frontends;
* a **FREE repository of code examples** bundled with the book, so you can take examples from the book and fiddle with them;

Interested? Grab [a free chapter](http://blog.arkency.com/assets/misc/rails-meets-react/rails-meets-react-sample.pdf) or [watch a quick, 3-minute overview of it](https://www.youtube.com/watch?v=bFt-7P6ZiYo) now. You can [buy the book](http://bit.ly/buy-rails-meets-reactjs) here. Use **V13UPDATE** code to **get a 25% discount**!

Join the group of 350+ happy customers who learned how to build dynamic user interfaces with React and Rails!
