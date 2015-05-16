---
title: "Start using ES6 with Rails today"
created_at: 2015-05-16 16:00:00 +0100
kind: article
publish: false
author: Wiktor Mociun
tags: [ 'es6', 'frontend', 'javascript' ]
newsletter: :react_book
img: "/assets/images/start-using-es6/lead-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/start-using-es6/lead-fit.jpg" width="100%">
    <details>
      Source: <a href="https://www.flickr.com/photos/asif_salman/">Asif Salman</a>
    </details>
  </figure>
</p>

The thing that made me fond of writing front-end code was CoffeeScript. It didn't drastically change syntax. Coffee introduced many features that made my life as a web developer much easier (e.g. destruction and existential operators). That was a real game changer for Rails developers. We can write our front-end in language that is similar to Ruby and defends us from quirks of JavaScript.

<!-- more -->

Fortunately the TC39 committee is working hard on sixth version of ECMAScript. You can think about it as an improved JavaScript. It added many features, many of which you may have already seen on CoffeeScript. You can read about some goodies added to ES6 in [this blogpost](http://tech.namshi.com/blog/2014/10/19/welcome-es6-javascript-is-not-fancy-anymore/).

The best part of ES6 is that **you can use it, despite the fact it hasn't been finished yet**. See how you can bring ES6 to Rails.

# How can I use ES6 in my web browser?

New features of ES6 can be emulated in JavaScript (used in our web browsers) using [Babel](https://babeljs.io/). It provides full compatibility. However one of the features may require some extra work.

One of most exciting features of ES6 are built-in modules. Before ES6 we used solutions like CommonJS or RequireJS. By default Babel uses CommonJS modules as a fallback. If you didn't use any type of packaging and want to use one, you would need to setup one.


# Bringing ES6 to Rails

Sprockets 4.x promise to bring ES6 transpiling out of the box. This release doesn't seem to come up soon, so **we need to find some way around**.

### Using Sprockets with `sprockets-es6` gem

On babel website we can find link to `sprockets-es6` gem, which enables ES6 transpiling for sprockets. Unfortunately it does not come without problems - the gem requires `sprockets` in version `>= 3.0.0`. By default babel converts ES6 modules to CommonJS modules. Two gems providing CommonJS (`browserify-rails` and `sprockets-commonjs`) requires `sprockets` to be in version lower than 3.0.0.

You can try using other gem to get JavaScript packaging like [requirejs-rails gem](https://rubygems.org/gems/requirejs-rails/versions/0.9.5). Remember to register ES6 transformer with valid option in Sprockets. See this [test file](https://github.com/josh/sprockets-es6/blob/master/test/test_es6.rb) for example usage.

### Using Node.JS with Gulp
Marcin [wrote](http://blog.arkency.com/2015/03/gulp-modern-approach-to-asset-pipeline-for-rails-developers/) some time ago about unusual approach for asset serving in Rails applications. We can completely remove sprockets and do it on our own with simple Node.js application. 

We want to remove any dependencies on Sprockets or any other Ruby gem, when it comes to asset serving. Moreover, using this method, we get the **faster overall asset compiling** than with Sprockets.

With Gulp, we can use `babelify` and `browserify` node packages in our asset processing process. It let us to use all ES6 features without any inconvenience. You can see example Gulpfile.js with ES6 transpiling and SASS compiling on gist: [Gulpfile.js](https://gist.github.com/voter101/9c824a30f712e7724cad)

# Conclusions

There are many more workarounds to get ES6 in Rails environment that doesn't require discarding Sprockets. Unfortunately none of them are good enough to mention. I strongly recommend going with Gulp. It's simple, powerful and provides native environment to work with assets. If you don't want to switch from Sprockets, you can try-out `sprockets-es6` gem.
