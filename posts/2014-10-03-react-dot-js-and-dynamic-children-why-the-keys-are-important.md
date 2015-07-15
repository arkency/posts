---
title: "React.js and Dynamic Children - Why the Keys are Important"
created_at: 2014-10-03 10:55:02 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'react.js', 'dynamic children', 'keys', 'state', 'getinitialstate' ]
newsletter: :skip
newsletter_inside: :kung_fu
---

<p>
  <figure>
    <img src="/assets/images/react-keys-getinitial-state/react_children_keys-fit.jpg" width="100%">
  </figure>
</p>

Recently I've been building a pretty dynamic interface based on
google analytics data for one of our customers. There was a bug that
I couldn't quite figure out because of my wrong understanding of
how react works. In the end it turned out to be a **very easy fix
and very important lesson on understanding _react.js_**.

It is even pretty accurately **described in react documentation** however
without showing what will go wrong and what kind of bugs you can
expect if you don't adhere to it. In other words, **the documentation
explains the right way but without going much into details about why**.

<!-- more -->

## Problem: Component doesn't have initial state defined but the previous one

Let's see the **simplified** version of my problem in action. I have
two components. One is a list of countries and one is a list of cities
in the country. **When you click the country it becomes active and
and the list of cities is refreshed as well to show only cities from this
country.** In real life there is much more data presented based on selected
city and country but that's enough for our demo.

The problem is however that **when you select a second city and switch
between the countries, the second city remain selected (on another list).
We would like to always have first city on the list selected when country
was switched**. Here is a little demo:

<style>
#reactExampleGoesHere a, #reactExampleGoesHere2 a {
  border: 1px solid;
  margin-right: 10px;
  text-decoration: none;
  background-color: #2bbb5b;
  color: white;
  padding: 10px;
}
#reactExampleGoesHere a.excited, #reactExampleGoesHere2 a.excited {
  background-color: #2bbb5b;
}
#reactExampleGoesHere a.neutral, #reactExampleGoesHere2 a.neutral {
  background-color: #39a5de;
}
#reactExampleGoesHere div.list, #reactExampleGoesHere2 div.list {
  height: 70px;
}
</style>
<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/react/0.11.2/react.min.js"></script>
<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
<script type="text/javascript">
var blogpostJQuery = $.noConflict(true);

var CountriesComponent = React.createClass({
  getInitialState: function () {
    return { currentCountry: this.props.countries[0] };
  },
  handleClick: function(country, index, event){
    this.setState({currentCountry: country});
    event.preventDefault();
  },
  render: function(){
    return React.DOM.div({},
      TabList({
        elements: this.props.countries,
        clickHandler: this.handleClick
      }),
      TabList({
        elements: this.props.citiesPerCountry[this.state.currentCountry],
        clickHandler: function(city, index, event){ event.preventDefault(); }
      })
    );
  }
});

var TabList = React.createClass({
  getInitialState: function () {
    return { active: 0 };
  },
  render: function(){
    var tabs = [];
    for (var i = 0; i < this.props.elements.length; i++) {
      var className;
      if (i == this.state.active){
        className = "excited"
      } else {
        className = "neutral"
      }
      var tab = React.DOM.a({
        key: i,
        className: className,
        onClick: (function(a, event){
          this.setState({active: a});
          this.props.clickHandler(this.props.elements[a], a, event);
        }).bind(this, i),
        href: "#"
      }, this.props.elements[i]);
      tabs.push( tab );
    }
    return React.DOM.div({className:"list"}, tabs);
  }
});

blogpostJQuery(function() {
  React.renderComponent( CountriesComponent({
    countries: ["Canada", "Poland"],
    citiesPerCountry: {
      Canada: ["Ottawa", "Quebec"],
      Poland: ["Warsaw", "Wroclaw"]
    }
  }), document.getElementById("reactExampleGoesHere"));
});
</script>

<div id="reactExampleGoesHere"></div>

Here is my code:

```
#!javascript
var CountriesComponent = React.createClass({
  getInitialState: function () {
    return { currentCountry: this.props.countries[0] };
  },
  handleClick: function(country, index, event){
    this.setState({currentCountry: country});
    event.preventDefault();
  },
  render: function(){
    return React.DOM.div({},
      TabList({
        elements: this.props.countries,
        clickHandler: this.handleClick
      }),
      TabList({
        elements: this.props.citiesPerCountry[this.state.currentCountry],
        clickHandler: function(city, index, event){ event.preventDefault(); }
      })
    );
  }
});

var TabList = React.createClass({
  getInitialState: function () {
    return { active: 0 };
  },
  render: function(){
    var tabs = [];
    for (var i = 0; i < this.props.elements.length; i++) {
      var className;
      if (i == this.state.active){
        className = "excited"
      } else {
        className = "neutral"
      }
      var tab = React.DOM.a({
        key: i,
        className: className,
        href: "#",
        onClick: (function(a, event){
          this.setState({active: a});
          this.props.clickHandler(this.props.elements[a], a, event);
        }).bind(this, i)
      }, this.props.elements[i]);
      tabs.push( tab );
    }
    return React.DOM.div({className:"list"}, tabs);
  }
});
```

Here is what I (unexperienced react padawan) was thinking:

_Properties are immutable, state is mutable therefore if I change
the properties of a component react will figure out it is a new
component, create it and call getInitialState_.

That was about this part of code:

```
#!javascript
  TabList({
    elements: this.props.citiesPerCountry[this.state.currentCountry],
    clickHandler: function(city, index, event){ event.preventDefault(); }
  })
```

I imagined that because I was changing properties (the `elements` key), then after changing
the countries react was rendering a new cities list and a new city list
should have first item selected because of my [`getInitialState`](http://facebook.github.io/react/docs/component-specs.html#getinitialstate):

```
#!javascript
var TabList = React.createClass({
  getInitialState: function () {
    return { active: 0 };
  }
});
```

**But I was wrong**. Wrong. Wrong...

## React will determine whether it is the same component or not based on key

And when the key is not provided? Well... React will automatically use an
increasing integer number; I suspect based on the `data-reactid` attribute in DOM.

<img src="/assets/images/react-keys-getinitial-state/react_initial_state_with_bug-fit.png" width="100%">

So I was thinking that I am rendering conceptually a new component and
react was actually rendering the old one. The fact that I changed `props`
doesn't matter. Immutability of `props` is just a convention, not a
requirement. And react doesn't care. Because it was the same component
`getInitialState` was not called and the component remembered its old state.

## New component on the same level as old one? Would you kindly change a key?

**The fix is easy**. Change the component key and react will know that it is a
different component and not the same one. You can try it below. When you
select a new country, the city is always the first one.

<script type="text/javascript">
var CountriesComponent2 = React.createClass({
  getInitialState: function () {
    return { currentCountry: this.props.countries[0] };
  },
  handleClick: function(country, index, event){
    this.setState({currentCountry: country});
    event.preventDefault();
  },
  render: function(){
    return React.DOM.div({},
      TabList2({
        key: "countriesList",
        elements: this.props.countries,
        clickHandler: this.handleClick
      }),
      TabList2({
        key: this.state.currentCountry,
        elements: this.props.citiesPerCountry[this.state.currentCountry],
        clickHandler: function(city, index, event){ event.preventDefault(); }
      })
    );
  }
});

var TabList2 = React.createClass({
  getInitialState: function () {
    return { active: 0 };
  },
  render: function(){
    var tabs = [];
    for (var i = 0; i < this.props.elements.length; i++) {
      var className;
      if (i == this.state.active){
        className = "excited"
      } else {
        className = "neutral"
      }
      var tab = React.DOM.a({
        key: i,
        className: className,
        onClick: (function(a, event){
          this.setState({active: a});
          this.props.clickHandler(this.props.elements[a], a, event);
        }).bind(this, i),
        href: "#"
      }, this.props.elements[i]);
      tabs.push( tab );
    }
    return React.DOM.div({className:"list"}, tabs);
  }
});

blogpostJQuery(function() {
  React.renderComponent( CountriesComponent2({
    countries: ["Canada", "Poland"],
    citiesPerCountry: {
      Canada: ["Ottawa", "Quebec"],
      Poland: ["Warsaw", "Wroclaw"]
    }
  }), document.getElementById("reactExampleGoesHere2"));
});
</script>

<div id="reactExampleGoesHere2"></div>

And the code:

```
#!javascript
var CountriesComponent = React.createClass({
  getInitialState: function () {
    return { currentCountry: this.props.countries[0] };
  },
  handleClick: function(country, index, event){
    this.setState({currentCountry: country});
    event.preventDefault();
  },
  render: function(){
    return React.DOM.div({},
      TabList({
        key: "countriesList",
        elements: this.props.countries,
        clickHandler: this.handleClick
      }),
      TabList({
        key: this.state.currentCountry,
        elements: this.props.citiesPerCountry[this.state.currentCountry],
        clickHandler: function(city, index, event){ event.preventDefault(); }
      })
    );
  }
});
```

The important part is the key for second list:

```
#!javascript
TabList({
  key: this.state.currentCountry,
  elements: this.props.citiesPerCountry[this.state.currentCountry],
  clickHandler: function(city, index, event){ event.preventDefault(); }
})
```

You can see in DOM a different `data-reactid` attribute
value now based on the provided key.

<img src="/assets/images/react-keys-getinitial-state/react_initial_state_without_bug-fit.png" width="100%">

## What did I just learn?

Now the I've actually been hit by this and I understood the
problem few more things makes sense...

* [React documentation on dynamic children](http://facebook.github.io/react/docs/multiple-components.html#dynamic-children)

    _The situation gets more complicated when the children are shuffled around (as in search results) or if new components are added onto the front of the list (as in streams). In these cases where the identity and state of each child must be maintained across render passes, you can uniquely identify each child by assigning it a `key`_

* [Props in getInitialState Is an Anti-Pattern](http://facebook.github.io/react/tips/props-in-getInitialState-as-anti-pattern.html)

    OK, guilty as charged... _Using props, passed down from parent, to generate state in `getInitialState` often leads to duplication of "source of truth", i.e. where the real data is. Whenever possible, compute values on-the-fly to ensure that they don't get out of sync later on and cause maintenance trouble._

    In this example I remember in top-level `CountriesComponent` currently
    selected country because it is used to provide list of cities for the second list.
    But I also keep this as `active` state in the first list.

* _You wouldn't have this problem if you didn't keep state in this component_

    This is what my coworkers said to me when I described my problem to them.

    It appears that **it is often easier and wiser to move the state higher in component hierarchy**.
    Maybe the list itself does not need to keep the state itself. Why? Because the
    parent component is interested that the list element was clicked. Something new was
    selected and not only the list must change and rerender but also another parts
    of parent component must change. If parent component knows about list status, then it
    can render the list with new status, new currently select item.

    Notice that in my example I only need to change the `key` of cities list when country
    is changed because I keep state in that list. If I didn't I wouldn't have to and I
    wouldn't care.

## Now go home and...

* give keys to your children
* keep the state in one place
* remember: **dynamic stateless components are easier and can live fine without key
(althought it is best practice to provide them and react will warn you when you don't);
for stateful components proper key is a must have!**

## One more thing

If you liked this blogpost you might consider signing up to our newsletter about React.js.

<%= inner_newsletter(item[:newsletter_inside]) %>
