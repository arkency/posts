---
title: "Porting a Rails frontend from CoffeeScript to ES6 and JSX - examples"
created_at: 2016-06-09 00:08:29 +0200
kind: article
publish: true
author: "Tomasz Patrzek"
tags: [ 'react', 'frontend', 'es6', 'jsx', 'refactoring', 'porting' ]
newsletter: :react_books
---

We are working on a new version of our bestseller book - [Rails meets React.js](http://blog.arkency.com/rails-react/). Currently, the book is based in CoffeeScript and we want to port it to ES6. The update will be free for everyone, who bought the CoffeeScript version

Here are some examples showing a process of porting from CoffeeScript to ES6 and JSX.

<!-- more -->

## JSX

In our previous version of this book, we didn't use JSX because it does not fit well with CoffeScript.
With ES6 it is different, JSX fits here very well.

**Before:**

```coffeescript
  Stats = React.createClass
    contextTypes:
      user: React.PropTypes.object
    render: ->
      React.DOM.div null,
        "Won: #{@context.user.won}"
        React.DOM.br null
        "Lost: #{@context.user.lost}"
        React.DOM.br null
        React.DOM.a
          href: "http://www.example.org/stats/#{@context.user.id}",
          "(see the whole stats of #{@context.user.name})"

  stats = React.createFactory(Stats)
```

**After:**

```jsx
class Stats extends React.Component {
  render() {
    return (
      <div>
        Won {this.context.user.won}
        <br />
        Lost {this.context.user.lost}
        <br />
        <a href={`http://www.example.org/stats/${this.context.user.id}`} >
          (see the whole stats of {this.context.user.name})
        </a>
      </div>
    );
  }
}
```

_Note_ ES6 template literal `` ` ``` http://www.example.org/stats/${this.context.user.id}``` ` `` which we are using to construct string url.


##ES6 classes

Instead of using `React.createClass` we are now using ES6 class syntax:

**Before:**

```coffeescript
OneTimeClickLink = React.createClass
  render: ->
    React.DOM.div(
      {id: "one-time-click-link"},
      React.DOM.a(
        {href:"javascript:void(0)"},
        "Click me"
      )
    )
```

**After:**

```coffeescript
class OneTimeClickLink extends React.Component {
  render() {
    return (<div id="one-time-click-link">
      <a href="javascript:void(0)">
        Click me
      </a>
    </div>);
  }
```

## State initialization

Since `getInitialState` does not work with classes syntax, we are initializing `state` in a constructor. Like in this example:

**Before:**

```coffeescript
DateWithLabel = React.createClass
  getInitialState: ->
    date: new Date()
  render: ->
    DOM.div
```
 
**After:**

```jsx
class DateWithLabel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      date: new Date()
    };
  }

  render() {
    return (<div></div>);
  }
}
```

## Bind instance methods

In class syntax, React doesn't bind all methods automatically. So, we are binding them in our constructor.

**Before:**

```coffeescript
  OnOffCheckbox = React.createClass
    getInitialState: ->
      toggled: false

    toggle: ->
      @setState toggled: !@state.toggled

    render: ->
      React.DOM.input
        key: 'checkbox'
        type: 'checkbox'
        id: @props.id
        checked: @state.toggled
        onChange: @toggle

```

**After:**

```jsx
  class OnOffCheckbox extends React.Component {
    constructor(props) {
      super(props);
      this.state = {
        toggled: false
      };
      this.toggle = this.toggle.bind(this);
    }

    toggle() {
      this.setState({ toggled: !this.state.toggled });
    }

    render() {
      return (
        <input
          key="checkbox"
          type="checkbox"
          id={this.props.id}
          checked={this.state.toggled}
          onChange={this.toggle}
        />
      );
    }
  }

```
## Default props and validations

`defaultProps` , `propTypes` and `contextTypes` must be defined outside the class body. Here are some examples:

**Before:**

```coffeescript
  OnOffCheckbox = React.createClass
    getDefaultProps: ->
      initiallyToggled: false

    getInitialState: ->
      toggled: @props.initiallyToggled

    toggle: ->
      @setState toggled: !@state.toggled

    render: ->
      React.DOM.input
        key: 'checkbox'
        type: 'checkbox'
        id: @props.id
        checked: @state.toggled
        onChange: @toggle
```

**After:**

```jsx
  class OnOffCheckbox extends React.Component {
    constructor(props) {
      super(props);
      this.state = {
        toggled: props.initiallyToggled
      };
      this.toggle = this.toggle.bind(this);
    }

    toggle() {
      this.setState({ toggled: !this.state.toggled });
    }

    render() {
      return (
        <input
          key="checkbox"
          type="checkbox"
          id={this.props.id}
          checked={this.state.toggled}
          onChange={this.toggle}
        />
      );
    }
  }
  OnOffCheckboxWithLabel.defaultProps = {
    initiallyToggled: false
  };

```

The same goes for `propTypes`:

**Before:**

```coffeescript
Blogpost = React.createClass
  propTypes:
    name: React.PropTypes.string.isRequired

  # ...
```

**After:**

```jsx
class Blogpost extends React.Component {
  // ...
}
Blogpost.propTypes = {
  name: React.PropTypes.string.isRequired
};
```

## Summary

Code written in ES6 with JSX can be pretty clean.
I've used [ESLint](http://eslint.org/) which helped me to keep syntax clean and free of errors. [Here](https://medium.com/planet-arkency/catch-mistakes-before-you-run-you-javascript-code-6e524c36f0c8#.d94ni2r78) you can find a Blogpost how correctly configure it for your editor.

If you are interested in learning how to use React with Rails, with the ES6 syntax, we are working on a new version of [Rails meets React.js](http://blog.arkency.com/rails-react/). It will be free for everyone who bought previous CoffeeScript version.
