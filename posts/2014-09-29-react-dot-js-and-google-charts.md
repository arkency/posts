---
title: "react.js and google charts"
created_at: 2014-09-29 21:40:19 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'foo', 'bar', 'baz' ]
newsletter: :skip
newsletter_inside: :kung_fu
---

<p>
  <figure>
    <img src="/assets/images/react-js-google-charts/react-js-logo-fit.png" width="100%">
  </figure>
</p>

So today I was integrating [Google Charts](https://developers.google.com/chart/)
into a frontend app created with [react.js](http://facebook.github.io/react/).
As it always is when you want to integrate a 3rd party solution with react
components you need a little bit of manual work. But fortunatelly react gives us
an easy way to combine those two things together.

<!-- more -->

```
#!javascript
var GoogleLineChart = React.createClass({
  render: function(){
    return React.DOM.div({id: this.props.graphName, style: {height: "500px"}});
  },
  componentDidMount: function(){
    this.drawCharts();
  },
  componentDidUpdate: function(){
    this.drawCharts();
  },
  drawCharts: function(){
    var data = google.visualization.arrayToDataTable(this.props.data);
    var options = {
      title: 'ABC',
    };

    var chart = new google.visualization.LineChart(
      document.getElementById(this.props.graphName)
    );
    chart.draw(data, options);
  }
});
```

As you can see all you need to do is to hook code responsibile for drawing charts
(which comes from another library and is not done in react-way) into the proper
lifecycle methods of the react componenet. In our case it is:

* [componentDidMount](http://facebook.github.io/react/docs/component-specs.html#mounting-componentdidmount)
* [componentDidUpdate](http://facebook.github.io/react/docs/component-specs.html#updating-componentdidupdate)

One more thing. Make sure you start rendering components only after the javascript for
google charts have been fully loaded.

```
#!javascript
InsightApp.prototype.start = function() {
  that = this;

  var options = {
    dataType: "script",
    cache: true,
    url: "https://www.google.com/jsapi",
  };
  jQuery.ajax(options).done(function(){
    google.load("visualization", "1", {
      packages:["corechart"],
      callback: function() {
        that.startRenderingComponents();
      }
    });
  });
};
```

You can see the effect here:

<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/react/0.11.2/react.min.js"></script>
<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
<script type="text/javascript">
  var blogpostJQuery = $.noConflict(true);
  var GoogleLineChart = React.createClass({
    render: function(){
      return React.DOM.div({id: this.props.graphName, style: {height: "300px"}});
    },
    componentDidMount: function(){
      this.drawCharts();
    },
    componentDidUpdate: function(){
      this.drawCharts();
    },
    drawCharts: function(){
      var data = google.visualization.arrayToDataTable(this.props.data);
      var options = {
        title: 'Sales per year',
      };

      var chart = new google.visualization.LineChart(
        document.getElementById(this.props.graphName)
      );
      chart.draw(data, options);
    }
  });

  var options = {
    dataType: "script",
    cache: true,
    url: "https://www.google.com/jsapi",
  };

  blogpostJQuery(function() {
    blogpostJQuery.ajax(options).done(function(){
      google.load("visualization", "1", {
        packages:["corechart"],
        callback: function() {
          React.renderComponent( GoogleLineChart({
            graphName: "lineGraph",
            data: [
              ['Year', 'Items Sold'],
              ['2004',  20],
              ['2005',  35],
              ['2006',  25],
              ['2007',  50]
            ]
          }), document.getElementById("reactExampleGoesHere"));
        }
      });
    });
  });
</script>

<div id="reactExampleGoesHere"></div>

These are the things that I learnt today while integrating our code with Google Charts.
In my next blogpost I would like to share how we dealt with a similar problem when using
Twitter Bloodhound library for autocomplete.

If you liked this blogpost you might consider signing up to our frontend course.

<%= inner_newsletter(item[:newsletter_inside]) %>
