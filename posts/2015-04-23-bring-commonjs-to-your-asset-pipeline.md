---
title: "Bring CommonJS to your asset pipeline"
created_at: 2015-04-23 10:15:12 +0200
kind: article
publish: false
author: Jakub Kosiński
tags: [ 'rails', 'browserify', 'commonjs', 'browserify-rails', 'sprockets', 'assets', 'javascript' ]
newsletter: :react_book
img: "/assets/images/bring-commonjs-to-your-asset-pipeline/browserify-rails-fit.png"
---

<p>
  <figure align="center">
    <img src="/assets/images/bring-commonjs-to-your-asset-pipeline/browserify-rails-fit.png">
  </figure>
</p>

A few weeks ago, [Marcin](https://twitter.com/killavus) recommended [Gulp as the Rails asset pipeline replacement](/2015/03/gulp-modern-approach-to-asset-pipeline-for-rails-developers/). Today I am going to tell you how you can benefit from CommonJS modules in your Rails application with asset pipeline enabled.

<!-- more -->

You don't have to disable asset pipeline in your Rails application in order to use CommonJS module loading in your JavaScripts. One of tools that allows you to do so is [Browserify](http://browserify.org/) and a nice gem called [`browserify-rails`](https://github.com/browserify-rails/browserify-rails). It lets you mix and match `//= require` directives from Sprockets with `require()` calls in your JavaScript (CoffeeScript) assets. You can manage your JS modules with `npm`, so you can use a wide variety of existing node modules, including [React](https://facebook.github.io/react/) directly in your Rails assets.

# Getting started

To get started, you need to have `node` and `npm` installed on your development machine and include `browserify-rails` gem in your `Gemfile`.

    gem 'browserify-rails'

Then you should initialize your `package.json` file using

    $ npm init

in your's application root directory and add the following packages to your dependencies:

    $ npm install --save 'browserify@~>6.3'
    $ npm install --save 'browserify-incremental@^1.4.0'

That's all! You can now start writing your CommonJS modules and use it in your Rails application.

    // add.js
    module.exports = function (a, b) { return a + b }
    
    // application.js
    var add = require('add');
    console.log(add(1, 2)); # => 3

You can also install more node modules and require them in your assets:

    $ npm install --save react

    // application.js
    var React = require('react');
    React.render(React.DOM.h1(null, 'Hello world!'), document.body);

BTW, in our [Rails meets React](http://blog.arkency.com/rails-react/) book, we're also using asset pipeline to use React components in Rails.

Using `browserify-rails` does not force you to use only CommonJS-compatible libraries. You can still use `//= require` directive to load arbitrary JavaScript assets.

# Configuration options

After installing `browserify-rails` you are starting with default configuration that makes some assumptions:

* you store your JS modules only in `/app/assets/javascripts` and `/node_modules` directories
* you don't want to generate source maps
* modules from `node_modules` should not be re-evaluated on page load
* browserify is run only on JS files that have defined modules via `module.exports` or require some other modules with `require`
* `NODE_ENV` is equal to your `Rails.env`

You may tune up your config if you need. I would recommend enabling source maps generation in development environment for easier debugging. To do so you need to add the following line to your `config/application.rb` file:

    module MyApplication
      class Application < Rails::Application
        # ...
        config.browserify_rails.source_map_environments << 'development'
      end
    end

If you are using CoffeeScript, you should follow `.js.coffee` naming convention, install `coffeeify` plugin:

    $ npm install --save 'coffeeify@~>0.6'

and enable this plugin by adding the following line to your `config/application.rb`:

    config.browserify_rails.commandline_options = '-t coffeeify --extension=".js.coffee"'

Now you should just restart your server and write your assets in CoffeeScript flavour.

`browserify-rails` supports the same features as `node-browserify`, e.g. you can have [multiple bundles](https://github.com/substack/node-browserify#multiple-bundles). You can read about all possible configuration options on [`browserify-rails` github page](https://github.com/browserify-rails/browserify-rails#configuration).

# Deployment

In order to deploy your assets to production server, you don't need anything but running `rake assets:compile` task. If you're running that task on your production server during deployment (e.g. when using `capistrano`), you also need to make sure you have `node` & `npm` installed on your production. You should also install all npm dependencies before compiling your assets. You may use rake tasks provided by `browserify-rails` gem to do so:

* `rake npm:clean` - this task would clean all installed node modules (it performs `rm -rf ./node_modules`)
* `rake npm:install` - this installs all dependencies by running `npm install`
* `rake npm:install:clean` - this combines two previous tasks by running `npm:clean` and `npm:install`

# Final words

Using `browserify-rails` can significantly increase modularity of your JavaScript assets, but have also some disadvantages.

**Pros:**

* you can use almost any node package directly in your Rails application through your asset pipeline
* you don't have to stop using `//= require` directive for non-modularized assets
* you can have [multiple bundles](https://github.com/browserify-rails/browserify-rails#multiple-bundles) and mark some libraries shared between bundles with `--require` or `--external` - this helps you to reduce size of the bundle, because you don't need to include the same library more than once

**Cons:**

* you have to install `node` and `npm` on your development machine and on your production (if you are compiling your assets during deploy)
* browserify compiles only JS assets, so you cannot use stylesheets from node packages

# Summary

Using `browserify-rails` may be a good option when you want to use asset pipeline and improve modularity of your JS assets. I think you may definitely give it a try!

# Bonus: Heroku support for Browserify

Heroku is a very popular platform for deploying Rails applications. By default, it automatically determines how to build your app during deploy by using some heuristics (e.g. it assumes you have Ruby application if your root directory contain `Gemfile`). In order to use `browserify-rails` and run `bundle` along with `npm install` on target machine, you need to use a custom [buildpack](http://devcenter.heroku.com/articles/buildpacks) - [`heroku-buildpack-multi`](https://github.com/heroku/heroku-buildpack-multi). To use it, you will first need to set it as your custom buildpack by running the following command:

    $ heroku buildpack:set https://github.com/heroku/heroku-buildpack-multi.git

Then you should create special file `.buildpacks` in your application's root directory that contains the list of all (ordered) buildpacks you would like to run when you deploy. In our case it would contain the following buildpacks:

    $ cat .buildpacks
    https://github.com/heroku/heroku-buildpack-nodejs
    https://github.com/heroku/heroku-buildpack-ruby


