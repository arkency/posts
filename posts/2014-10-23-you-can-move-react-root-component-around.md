---
title: "You can move React root component around"
created_at: 2014-10-23 21:59:29 +0200
kind: article
publish: false
author: anonymous
tags: [ 'foo', 'bar', 'baz' ]
---

My recent challeng with react was to integrate it
with [Magnific Popup](http://dimsemenov.com/plugins/magnific-popup/)
library. I knew there was going to be a problem because the library
is moving DOM elements around. But I had two interesting insights
while solving this problem that I think are worth sharing.

<!-- more -->

## Confirming the problem


<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/react/0.11.2/react.js"></script>
<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
<script type="text/javascript" src="/assets/javascripts/move-react-around/jquery.js"></script>
<style>
/* Magnific Popup CSS */
.mfp-bg {
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1042;
  overflow: hidden;
  position: fixed;
  background: #0b0b0b;
  opacity: 0.8;
  filter: alpha(opacity=80); }

.mfp-wrap {
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1043;
  position: fixed;
  outline: none !important;
  -webkit-backface-visibility: hidden; }

.mfp-container {
  text-align: center;
  position: absolute;
  width: 100%;
  height: 100%;
  left: 0;
  top: 0;
  padding: 0 8px;
  -webkit-box-sizing: border-box;
  -moz-box-sizing: border-box;
  box-sizing: border-box; }

.mfp-container:before {
  content: '';
  display: inline-block;
  height: 100%;
  vertical-align: middle; }

.mfp-align-top .mfp-container:before {
  display: none; }

.mfp-content {
  position: relative;
  display: inline-block;
  vertical-align: middle;
  margin: 0 auto;
  text-align: left;
  z-index: 1045; }

.mfp-inline-holder .mfp-content, .mfp-ajax-holder .mfp-content {
  width: 100%;
  cursor: auto; }

.mfp-ajax-cur {
  cursor: progress; }

.mfp-zoom-out-cur, .mfp-zoom-out-cur .mfp-image-holder .mfp-close {
  cursor: -moz-zoom-out;
  cursor: -webkit-zoom-out;
  cursor: zoom-out; }

.mfp-zoom {
  cursor: pointer;
  cursor: -webkit-zoom-in;
  cursor: -moz-zoom-in;
  cursor: zoom-in; }

.mfp-auto-cursor .mfp-content {
  cursor: auto; }

.mfp-close, .mfp-arrow, .mfp-preloader, .mfp-counter {
  -webkit-user-select: none;
  -moz-user-select: none;
  user-select: none; }

.mfp-loading.mfp-figure {
  display: none; }

.mfp-hide {
  display: none !important; }

.mfp-preloader {
  color: #cccccc;
  position: absolute;
  top: 50%;
  width: auto;
  text-align: center;
  margin-top: -0.8em;
  left: 8px;
  right: 8px;
  z-index: 1044; }
  .mfp-preloader a {
    color: #cccccc; }
    .mfp-preloader a:hover {
      color: white; }

.mfp-s-ready .mfp-preloader {
  display: none; }

.mfp-s-error .mfp-content {
  display: none; }

button.mfp-close, button.mfp-arrow {
  overflow: visible;
  cursor: pointer;
  background: transparent;
  border: 0;
  -webkit-appearance: none;
  display: block;
  outline: none;
  padding: 0;
  z-index: 1046;
  -webkit-box-shadow: none;
  box-shadow: none; }
button::-moz-focus-inner {
  padding: 0;
  border: 0; }

.mfp-close {
  width: 44px;
  height: 44px;
  line-height: 44px;
  position: absolute;
  right: 0;
  top: 0;
  text-decoration: none;
  text-align: center;
  opacity: 0.65;
  padding: 0 0 18px 10px;
  color: white;
  font-style: normal;
  font-size: 28px;
  font-family: Arial, Baskerville, monospace; }
  .mfp-close:hover, .mfp-close:focus {
    opacity: 1; }
  .mfp-close:active {
    top: 1px; }

.mfp-close-btn-in .mfp-close {
  color: #333333; }

.mfp-image-holder .mfp-close, .mfp-iframe-holder .mfp-close {
  color: white;
  right: -6px;
  text-align: right;
  padding-right: 6px;
  width: 100%; }

.mfp-counter {
  position: absolute;
  top: 0;
  right: 0;
  color: #cccccc;
  font-size: 12px;
  line-height: 18px; }

.mfp-arrow {
  position: absolute;
  opacity: 0.65;
  margin: 0;
  top: 50%;
  margin-top: -55px;
  padding: 0;
  width: 90px;
  height: 110px;
  -webkit-tap-highlight-color: rgba(0, 0, 0, 0); }
  .mfp-arrow:active {
    margin-top: -54px; }
  .mfp-arrow:hover, .mfp-arrow:focus {
    opacity: 1; }
  .mfp-arrow:before, .mfp-arrow:after, .mfp-arrow .mfp-b, .mfp-arrow .mfp-a {
    content: '';
    display: block;
    width: 0;
    height: 0;
    position: absolute;
    left: 0;
    top: 0;
    margin-top: 35px;
    margin-left: 35px;
    border: medium inset transparent; }
  .mfp-arrow:after, .mfp-arrow .mfp-a {
    border-top-width: 13px;
    border-bottom-width: 13px;
    top: 8px; }
  .mfp-arrow:before, .mfp-arrow .mfp-b {
    border-top-width: 21px;
    border-bottom-width: 21px; }

.mfp-arrow-left {
  left: 0; }
  .mfp-arrow-left:after, .mfp-arrow-left .mfp-a {
    border-right: 17px solid white;
    margin-left: 31px; }
  .mfp-arrow-left:before, .mfp-arrow-left .mfp-b {
    margin-left: 25px;
    border-right: 27px solid #3f3f3f; }

.mfp-arrow-right {
  right: 0; }
  .mfp-arrow-right:after, .mfp-arrow-right .mfp-a {
    border-left: 17px solid white;
    margin-left: 39px; }
  .mfp-arrow-right:before, .mfp-arrow-right .mfp-b {
    border-left: 27px solid #3f3f3f; }

.mfp-iframe-holder {
  padding-top: 40px;
  padding-bottom: 40px; }
  .mfp-iframe-holder .mfp-content {
    line-height: 0;
    width: 100%;
    max-width: 900px; }
  .mfp-iframe-holder .mfp-close {
    top: -40px; }

.mfp-iframe-scaler {
  width: 100%;
  height: 0;
  overflow: hidden;
  padding-top: 56.25%; }
  .mfp-iframe-scaler iframe {
    position: absolute;
    display: block;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    box-shadow: 0 0 8px rgba(0, 0, 0, 0.6);
    background: black; }

/* Main image in popup */
img.mfp-img {
  width: auto;
  max-width: 100%;
  height: auto;
  display: block;
  line-height: 0;
  -webkit-box-sizing: border-box;
  -moz-box-sizing: border-box;
  box-sizing: border-box;
  padding: 40px 0 40px;
  margin: 0 auto; }

/* The shadow behind the image */
.mfp-figure {
  line-height: 0; }
  .mfp-figure:after {
    content: '';
    position: absolute;
    left: 0;
    top: 40px;
    bottom: 40px;
    display: block;
    right: 0;
    width: auto;
    height: auto;
    z-index: -1;
    box-shadow: 0 0 8px rgba(0, 0, 0, 0.6);
    background: #444444; }
  .mfp-figure small {
    color: #bdbdbd;
    display: block;
    font-size: 12px;
    line-height: 14px; }

.mfp-bottom-bar {
  margin-top: -36px;
  position: absolute;
  top: 100%;
  left: 0;
  width: 100%;
  cursor: auto; }

.mfp-title {
  text-align: left;
  line-height: 18px;
  color: #f3f3f3;
  word-wrap: break-word;
  padding-right: 36px; }

.mfp-image-holder .mfp-content {
  max-width: 100%; }

.mfp-gallery .mfp-image-holder .mfp-figure {
  cursor: pointer; }

@media screen and (max-width: 800px) and (orientation: landscape), screen and (max-height: 300px) {
  /**
       * Remove all paddings around the image on small screen
       */
  .mfp-img-mobile .mfp-image-holder {
    padding-left: 0;
    padding-right: 0; }
  .mfp-img-mobile img.mfp-img {
    padding: 0; }
  .mfp-img-mobile .mfp-figure {
    /* The shadow behind the image */ }
    .mfp-img-mobile .mfp-figure:after {
      top: 0;
      bottom: 0; }
    .mfp-img-mobile .mfp-figure small {
      display: inline;
      margin-left: 5px; }
  .mfp-img-mobile .mfp-bottom-bar {
    background: rgba(0, 0, 0, 0.6);
    bottom: 0;
    margin: 0;
    top: auto;
    padding: 3px 5px;
    position: fixed;
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;
    box-sizing: border-box; }
    .mfp-img-mobile .mfp-bottom-bar:empty {
      padding: 0; }
  .mfp-img-mobile .mfp-counter {
    right: 5px;
    top: 3px; }
  .mfp-img-mobile .mfp-close {
    top: 0;
    right: 0;
    width: 35px;
    height: 35px;
    line-height: 35px;
    background: rgba(0, 0, 0, 0.6);
    position: fixed;
    text-align: center;
    padding: 0; } }

@media all and (max-width: 900px) {
  .mfp-arrow {
    -webkit-transform: scale(0.75);
    transform: scale(0.75); }
  .mfp-arrow-left {
    -webkit-transform-origin: 0;
    transform-origin: 0; }
  .mfp-arrow-right {
    -webkit-transform-origin: 100%;
    transform-origin: 100%; }
  .mfp-container {
    padding-left: 6px;
    padding-right: 6px; } }

.mfp-ie7 .mfp-img {
  padding: 0; }
.mfp-ie7 .mfp-bottom-bar {
  width: 600px;
  left: 50%;
  margin-left: -300px;
  margin-top: 5px;
  padding-bottom: 5px; }
.mfp-ie7 .mfp-container {
  padding: 0; }
.mfp-ie7 .mfp-content {
  padding-top: 44px; }
.mfp-ie7 .mfp-close {
  top: 0;
  right: 0;
  padding-top: 0; }
</style>

<script type="text/javascript">
var blogpostJQuery = $.noConflict(true);
var clicked = function(){
  var node = mountedComponent.refs.popup.getDOMNode();
  blogpostJQuery.magnificPopup.open({
    items: {
      src: node,
      type: 'inline'
    },
    removalDelay: 30,
    callbacks: {
      close: function() {
      }
    }
  });
}

var popupClicked = function(){ mountedComponent.setState({pretendStateChanged: Date.now() }) };

var Component = React.createClass({
  getInitialState: function() {
    return {pretendStateChanged: Date.now() };
  },
  render: function(){
    return React.DOM.div(null,
      React.DOM.a({onClick: clicked, href: "javascript:void(0);"}, "Show popup"),
      React.DOM.br(null),
      React.DOM.span(null, "State: " + this.state.pretendStateChanged),
      Popup({ref: "popup", onClickHandler: popupClicked})
    );
  }
});

var Popup = React.createClass({
  render: function(){
    return React.DOM.div(null,
      React.DOM.a({
        onClick: this.props.onClickHandler,
        href: "javascript:void(0);"
      }, "Button inside popup")
    );
  }
});

var mountedComponent;
blogpostJQuery(function() {
  mountedComponent = React.renderComponent(
    Component(),
    document.getElementById("reactExampleGoesHere")
  );
});
</script>

Here is completely oversimplified version of my problem.
You can press "Button inside popup" to change state.
When you press "Show popup" the Magnificent Popup
library however will move the popup content into different
DOM element. When you try change the state one more time
by pressing "Button inside popup" (this time actually
inside popup) it will break with `Invariant Violation:
findComponentRoot(..., .0.1.0): Unable to find element. This probably
means the DOM was unexpectedly mutated`. Go ahead. Try
for yourself. Open Developer Console to see the error.

<div id="reactExampleGoesHere"></div>

Here is the code for this example:

```
#!js
var clicked = function(){
  var node = mountedComponent.refs.popup.getDOMNode();
  blogpostJQuery.magnificPopup.open({
    items: {
      src: node,
      type: 'inline'
    },
    removalDelay: 30,
    callbacks: {
      close: function() {
      }
    }
  });
}

var popupClicked = function(){
  mountedComponent.setState({pretendStateChanged: Date.now() }) 
};

var Component = React.createClass({
  getInitialState: function() {
    return {pretendStateChanged: Date.now() };
  },
  render: function(){
    return React.DOM.div(null,
      React.DOM.a({onClick: clicked, href: "javascript:void(0);"}, "Show popup"),
      React.DOM.br(null),
      React.DOM.span(null, "State: " + this.state.pretendStateChanged),
      Popup({ref: "popup", onClickHandler: popupClicked})
    );
  }
});

var Popup = React.createClass({
  render: function(){
    return React.DOM.div(null,
      React.DOM.a({
        onClick: this.props.onClickHandler,
        href: "javascript:void(0);"
      }, "Button inside popup")
    );
  }
});

mountedComponent = React.renderComponent(
  Component(),
  document.getElementById("reactExampleGoesHere")
);
```

So I did some research and found this interesting
[React JS > What if the dom changes?](https://groups.google.com/forum/#!msg/reactjs/mHfBGI3Qwz4/6s-eHGEpccwJ)
thread that included some really nice hint: _I think React won't get confused if
jQuery moves the root around_.

## Moving React component

So I decoupled in my little application the Popup
component from my top-level Component and started
rendering them separately.

If you show popup and click inside it you will change
state of both components. But even though the component
rendered insided popup (handled by magnificPopup library)
was moved around in DOM, we no longer expierience our
problem. Because moving top-level react component around
DOM works fine (here I am actually moving one elemnt
above the react root node but the concept stays the same).

<script type="text/javascript">
var clicked2 = function(){
  var node = mountedPopup2.getDOMNode().parentNode;
  blogpostJQuery.magnificPopup.open({
    items: {
      src: node,
      type: 'inline'
    },
    removalDelay: 30,
    callbacks: {
      close: function() {
      }
    }
  });
}

var popupClicked2 = function(){
  mountedComponent2.setState({pretendStateChanged: Date.now() }) ;
  mountedPopup2.setState({pretendStateChanged: Date.now() });
};

var Component2 = React.createClass({
  getInitialState: function() {
    return {pretendStateChanged: Date.now() };
  },
  render: function(){
    return React.DOM.div(null,
      React.DOM.a({onClick: clicked2, href: "javascript:void(0);"}, "Show popup"),
      React.DOM.br(null),
      React.DOM.span(null, "State: " + this.state.pretendStateChanged)
    );
  }
});

var Popup2 = React.createClass({
  getInitialState: function() {
    return {pretendStateChanged: Date.now() };
  },
  render: function(){
    return React.DOM.div(null,
      React.DOM.a({
        onClick: this.props.onClickHandler,
        href: "javascript:void(0);"
      }, "Button inside popup"),
      React.DOM.br(null),
      React.DOM.span(null, "State: " + this.state.pretendStateChanged)
    );
  }
});

var mountedComponent2;
var mountedPopup2;

blogpostJQuery(function() {
  mountedComponent2 = React.renderComponent(
    Component2(),
    document.getElementById("reactExampleGoesHere2").childNodes[1]
  );

  mountedPopup2 = React.renderComponent(
    Popup2({onClickHandler: popupClicked2}),
    document.getElementById("reactExampleGoesHere2").childNodes[3]
  );
});
</script>

<div id="reactExampleGoesHere2">
  <div></div>
  <div class="mfp-hide"></div>
</div>

Here is the code for this example...

## Avoide imperative coding

TODO: Move the component behavior of popup
inside popup. And let it decide when to show
and hide.
