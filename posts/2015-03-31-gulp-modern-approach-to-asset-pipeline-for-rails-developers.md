---
title: "Gulp - a modern approach to asset pipeline for Rails developers"
created_at: 2015-03-31 16:20:02 +0200
kind: article
publish: true
author: Marcin Grzywaczewski
tags: [ 'javascript', 'frontend', 'sprockets', 'assets' ]
newsletter: :react_book
img: "/assets/images/gulp-replacement-sprockets/gulp.png"
---

<p>
  <figure>
    <img src="/assets/images/gulp-replacement-sprockets/gulp.png" width="100%" />
  </figure>
</p>

**Rails asset pipeline is one of things that makes Rails great for creating simple applications fast**. It solves a big problem of serving our assets efficiently in both development and production environment.

**While being very useful, Sprockets has its age**. There is a rapid growth of technologies around JavaScript. A growth which often cannot be used in an easy way by Rails developers. There are good technologies for code modularization, languages transpiled to JS, CSS preprocessors and  much, much more. Those technologies are easy to use in Node.js-based stacks, but not in Rails.

**Rails asset pipeline have a big advantage of being painless to use**. We do not need to configure anything to have our assets served or precompiled. There is a built-in file require system to help us split our code into files. **In bigger frontend codebases we’d live happier with more sophisticated solutions - and we cannot throw away a legacy that Sprockets have.** How to live with both CommonJS and Sprockets require system? How to optimize our compilation steps? **Sprockets is implicitly doing its job - and that’s great until you want to have something more**.

**Fortunately, asset serving is a low-hanging fruit when it comes to decoupling parts from Rails**. You can easily remove all asset serving responsibilities from Rails and use a modern build system like [Gulp](http://gulpjs.com) to compile your assets. 

**In this blogpost I’d like to show you how to replicate major part of Sprockets responsibilities in 82 lines of JavaScript code**, with ability to use CommonJS and modern technologies straight from `npm`. As a bonus this 82 lines will also generate source maps for your CoffeeScript and Sass.

<!-- more -->

## Why Gulp?

There are many Node.js-based build systems we can use to replace Sprockets. But after long consideration Gulp seems to be the best candidate:

* **It’s simple**. Gulp operates on [streams](https://nodejs.org/api/stream.html) - your job is to create tasks which takes your assets as an input and pipes them through a set of transformations to create their compiled form. It is the same idea that Sprockets have with ‘chopping off’ extensions of your asset files.
* **It’s fast**. Thanks to Gulp design there are no intermediate writes to disk (tempfiles) which could slow down the whole process. Node.js created streams to improve performance of this kind of workflow - so it’s a right tool for a right job.
* **You have the full control.** You write tasks - and you can choose what do you want and how do you structurize it. This way you can open your `Gulpfile` and see how your assets are treated - and change whatever you want.
* **You can easily write your asset compilation steps by yourself.** With a little knowledge of JavaScript you can easily create your new transformation. It is basically a stream which takes files as the input and returns them as the output. There are many supportive technologies for it - like [vinyl-transform](https://www.npmjs.com/package/vinyl-transform), [vinyl-buffer](https://www.npmjs.com/package/vinyl-buffer), [gulp-streamify](https://github.com/nfroidure/gulp-streamify) and so on.
* **You can use npm**. A common practice in Rails’ world is to install gems for providing front-end libraries - like `react-rails` or most gems from [Rails-Assets](https://rails-assets.org). It is good when there are Rails-specific features like server-side rendering - but it is an overkill when it only provides minified-or-not version of JS files! The other problem is that you are dependent on the maintainer of a gem AND the creator of a library you want to use. With Gulp you can download your libraries straight from NPM.

## Let's start: CoffeeScript with Browserify and Sass

CoffeeScript and Sass are two gems which ships by default with all modern versions of Rails. As a starting point it is wise to provide features of compiling CoffeeScript and Sass via Gulp. Since you won’t have Sprockets require system, a proper replacement is needed. CommonJS is a standard in Node.js world and it is easier to use than AMD. It has some nice features: it’s easy to grasp, provides a proper modularization of your code via `require`’s and looks quite similar to what we had with `#= require` syntax before. **We’ve used CommonJS recently to make a painless upgrade from React 0.11 to 0.13 in our projects - this process is covered in details [in our book](http://blog.arkency.com/beginners-guide-to-starting-with-react-in-rails/)**.

To provide CommonJS, [Browserify](http://browserify.org) will be used.

## Creating the Rails app without Sprockets

You can use this command to create a brand-new rails project without Sprockets and ‘default’ JavaScript assets:

```
rails new -J -S --skip-turbolinks projectName
```

Here `-J` option removes JavaScript and `-S` option removes Sprockets. Turbolinks option is self-explanatory ;).

You need to have [Node.js installed](https://docs.npmjs.com/getting-started/installing-node) to use `npm`. Follow this link for more info.

You need to create a package:

```
npm init
```

After providing info, a `package.json` will be created. This is an equivalent of `Gemfile` for Node.js apps.

To use Gulp you need to have it installed. It is advised to install it globally (to be able to run `gulp` by convenient `gulp` command) and locally:

```
npm install -g gulp # on some OSes it may need the root access
npm install --save-dev gulp
```

`--save-dev` option will add `gulp` as a [dev dependency](http://stackoverflow.com/questions/18875674/whats-the-difference-between-dependencies-devdependencies-and-peerdependencies) to your `package.json` file.

## Gulpfile.js

There is an equivalent of `Rakefile` for Gulp, called `Gulpfile`. You need to create it manually:

```
touch Gulpfile.js # in a root directory of your project
```

Gulp operates on tasks. Task can be a function or an array of tasks to be performed sequentially. You can run `gulp` without arguments and it will perform a `default` task, and `gulp <taskName>` to run a particular task.

Let’s create a first task which does nothing:

```
#!javascript
var gulp;

gulp = require('gulp');

gulp.task('task', function() {
  // Yep. Nothing.
});
```

You can now run it with `gulp task`:

```
$ gulp task

[14:33:08] Using gulpfile ~/projectName/Gulpfile.js
[14:33:08] Starting ‘task’…
[14:33:08] Finished ‘task’ after 61 μs
```

You can now add it to be ran by default by running just `gulp`:

```
#!javascript

var gulp;

gulp = require('gulp');

gulp.task('default', ['task']);

gulp.task('task', function() {
  // Yep. Nothing.
});
```

Then:

```
$ gulp
[14:35:50] Using gulpfile ~/projectName/Gulpfile.js
[14:35:50] Starting ‘task’…
[14:35:50] Finished ‘task’ after 56 μs
[14:35:50] Starting ‘default’…
[14:35:50] Finished ‘default’ after 9.94 μs
```

It would not be so interesting if you can’t do something with it. Let’s make Gulp compile our Sass assets!

## Compiling Sass

There are lots of ready-to-use gulp transformations that you can use by just installing them. We’ll use [gulp-sass](https://www.npmjs.com/package/gulp-sass) to compile Sass assets.

Let’s install it:

```
npm install --save-dev gulp-sass
```

It can be done by creating two tasks - `compile-sass` and `compile-scss` to compile both `sass` and `scss` files:

```
#!javascript

var gulp, sass;

gulp = require('gulp');
sass = require('gulp-sass');

gulp.task('default', ['compile-sass', 'compile-scss']);

gulp.task('compile-sass', function() {
  gulp.src('app/assets/stylesheets/**/*.sass')
      .pipe(sass({ indentedSyntax: true, errLogToConsole: true }))
      .pipe(gulp.dest('public/assets'));
});

gulp.task('compile-scss', function() {
  gulp.src('app/assets/stylesheets/**/*.scss')
      .pipe(sass({ indentedSyntax: false, errLogToConsole: true }))
      .pipe(gulp.dest('public/assets'));
});
```

Let’s stop and understand what happened here.

## A note about streams

**The whole build system of Gulp is based on a streams concept**. Gulp provides a ‘starting stream’, which you create via `gulp.src`. It takes a path as an input and returns a stream of (virtual) files as an output. All you do then is passing this output as an input of a transformation, which takes a stream of virtual files as an input and returns transformed virtual files as an output.

On the ‘end’ side of this transformation is `gulp.dest` - it takes a stream of virtual files as an input and writes a real ones as the output in a directory specified as parameter of this transformation.

That means **each task should consist of a sequence of stream transformations ended with a final `gulp.dest` transformation**. In this example all files matching `app/assets/stylesheets/**/*.sass` are passed to a `sass` transformation. This transformation compiles those files using `node-sass` implementation of Sass.

## Adding source maps

There is a [gulp-sourcemaps](https://www.npmjs.com/package/gulp-sourcemaps) transformation which is responsible for creating source maps from transformations compatible with it. Fortunately, [`gulp-sass` is one of these transformations](https://github.com/floridoo/gulp-sourcemaps/wiki/Plugins-with-gulp-sourcemaps-support). What you should do is you should pass `sourcemaps.init()` transformation before `sass` transformation and `sourcemaps.write()` transformation after you finish your sequence of transformations you’d like to be source mapped. In this case there is only one transformation - `sass`.

First, install `gulp-sourcemaps`:

```
npm install --save-dev gulp-sourcemaps
```

Then modify your tasks:

```
#!javascript

var gulp, sass, sourcemaps;

gulp = require('gulp');
sass = require('gulp-sass');
sourcemaps = require('gulp-sourcemaps');

gulp.task('default', ['compile-sass', 'compile-scss']);

gulp.task('compile-sass', function() {
  gulp.src('app/assets/stylesheets/**/*.sass')
      .pipe(sourcemaps.init())
      .pipe(sass({ indentedSyntax: true, errLogToConsole: true }))
      .pipe(sourcemaps.write())
      .pipe(gulp.dest('public/assets'));
});

gulp.task('compile-scss', function() {
  gulp.src('app/assets/stylesheets/**/*.scss')
      .pipe(sourcemaps.init())
      .pipe(sass({ indentedSyntax: false, errLogToConsole: true }))
      .pipe(sourcemaps.write())
      .pipe(gulp.dest('public/assets'));
});
```

Now change your `app/assets/stylesheets/application.css` to `app/assets/stylesheets/application.sass`. For this example:

```
#!sass
body
  backgroundColor: red
```

I received this output after running `gulp`:

```
$ gulp
[15:16:03] Using gulpfile ~/projectName/Gulpfile.js
[15:16:03] Starting ‘compile-sass’…
[15:16:03] Finished ‘compile-sass’ after 11 ms
[15:16:03] Starting ‘compile-scss’…
[15:16:03] Finished ‘compile-scss’ after 2.72 ms
[15:16:03] Starting ‘default’…
[15:16:03] Finished ‘default’ after 5.01 μs
$ cat public/assets/application.css
body {
  backgroundColor: red; }


/*# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbImFwcGxpY2F0aW9uLnNhc3MiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7RUFDRSxBQUFpQiIsImZpbGUiOiJhcHBsaWNhdGlvbi5jc3MiLCJzb3VyY2VzQ29udGVudCI6WyJib2R5XG4gIGJhY2tncm91bmRDb2xvcjogcmVkXG4iXSwic291cmNlUm9vdCI6Ii9zb3VyY2UvIn0= */
```

That means this task works and generates source maps as intended!

## Compiling CoffeeScript

Gulp is not the first application which uses streams to work with inputs. Browserify which will be used also have a stream API that will be used in this example. **This is a preferred way to work with Browserify and Gulp**. [gulp-browserify](https://www.npmjs.com/package/gulp-browserify) package is no longer maintained and is blacklisted - you can’t use it.

The rationale of this decision is that creating a separate gulp packages for Browserify is wrong because it is already using streams and have its own ecosystem of ‘transforms’. We’ll use one of these transformations - one called ‘coffeeify’ which compiles our CoffeeScript files if needed.

There is one problem to solve, though. Browserify by default takes a file path or an array of file paths and outputs a **text stream** with compiled bundle. This is not the way gulp works - each transformation needs a virtual file as input, not a text. But there is a simple solution: a [vinyl-source-stream](https://www.npmjs.com/package/vinyl-source-stream) package is a stream transformation which takes text stream as an input and returns a virtual file with name passed as a transformation parameter as an output. Ideal solution for this problem!

Let’s install browserify, coffeeify and vinyl-source-stream:

```
npm install --save-dev browserify coffeeify vinyl-source-stream
```

Then, create a `compile-coffee` task and add it to default list:

```
#!javascript

var gulp, sass, sourcemaps, browserify, coffeeify, source;

gulp = require('gulp');
sass = require('gulp-sass');
sourcemaps = require('gulp-sourcemaps');
browserify = require('browserify');
coffeeify = require('coffeeify');
source = require('vinyl-source-stream');

gulp.task('default', ['compile-sass', 'compile-scss', 'compile-coffee']);

gulp.task('compile-sass', function() {
  gulp.src('app/assets/stylesheets/**/*.sass')
      .pipe(sourcemaps.init())
      .pipe(sass({ indentedSyntax: true, errLogToConsole: true }))
      .pipe(sourcemaps.write())
      .pipe(gulp.dest('public/assets'));
});

gulp.task('compile-scss', function() {
  gulp.src('app/assets/stylesheets/**/*.scss')
      .pipe(sourcemaps.init())
      .pipe(sass({ indentedSyntax: false, errLogToConsole: true }))
      .pipe(sourcemaps.write())
      .pipe(gulp.dest('public/assets'));

gulp.task('compile-coffee', function() {
  var stream = browserify('./app/assets/javascripts/application.coffee',
    { debug: true /* enables source maps */, 
      extensions: ['.js', '.coffee'] }
  )
  .transform('coffeeify')
   .bundle();

  stream.pipe(source('bundle.js'))
        .pipe(gulp.dest('public/assets'));
});
```

This will take your `app/assets/javascripts/application.coffee`, compile it and all of its dependencies if needed and create a source maps for the whole bundle, saved in `public/assets/bundle.js`. If you want to use an external library, like jQuery, you can install it via npm:

```
npm install --save-dev jquery
```

And then in code:

```
#!coffeescript

$ = require('jquery')
```

That’s how Browserify manages your dependencies. You can read more about it in a [Browserify site](http://browserify.org/).

## Watching for changes

Ok, so basic compilation of assets is done. But we also need to watch for changes - a feature which sprockets provides us in development and is super useful. Fortunately, it’s easy in Gulp!

Gulp provides a `gulp.watch` method, which takes a glob path (with `*`) and a task to perform if files change. So here’s how watching for scss/sass change can be made:

```
#!javascript

gulp.task('watch', ['watch-sass', 'watch-scss']);

gulp.task('watch-sass', function() {
  gulp.watch('app/assets/stylesheets/**/*.sass', ['compile-sass']);
});

gulp.task('watch-scss', function() {
  gulp.watch('app/assets/stylesheets/**/*.scss', ['compile-scss']);
});
```

Watching for Browserify changes can be made in a similar way, but it is not efficient. There is a special package called [watchify](https://github.com/substack/watchify)
which will recompile only when changes to dependencies or a module itself are made. It is advisable to install [gulp-util](https://www.npmjs.com/package/gulp-util) package for easy logging. In this example also [lodash](https://lodash.com) will be used for a `assign` utility function.

You can read more about working with watchify on its home page. Here, a full Gulpfile after changes will be shown.

First, install required dependencies:

```
npm install --save-dev watchify lodash gulp-util
```

Then, modify your `Gulpfile`:

```
#!javascript
var gulp, sass, sourcemaps, browserify, coffeeify, source, util, watchify, _;

gulp = require('gulp');
util = require('gulp-util');
watchify = require('watchify');
sass = require('gulp-sass');
sourcemaps = require('gulp-sourcemaps');
browserify = require('browserify');
coffeeify = require('coffeeify');
source = require('vinyl-source-stream');
_ = require('lodash');

function browserifyInstance(fileName, userOpts) {
  if(!userOpts) {
    userOpts = {};
  }

  var defaultOpts = {
    extensions: ['.coffee', '.js']
  };

  return browserify(fileName, _.assign(defaultOpts, userOpts))
}

gulp.task('watch', ['watch-sass', 'watch-scss', 'watch-coffee']);

gulp.task('watch-sass', function() {
  gulp.watch('app/assets/stylesheets/**/*.sass', ['compile-sass']);
});

gulp.task('watch-scss', function() {
  gulp.watch('app/assets/stylesheets/**/*.scss', ['compile-scss']);
});

gulp.task('watch-coffee', function() {
  var watchBrowserify = watchify(browserifyInstance('./app/assets/javascripts/application.coffee', _.assign(watchify.args, { debug: true })));

  var updateOnChange = function() {
    return watchBrowserify
     .bundle()
     .on('error', util.log.bind(util, 'Browserify Error'))
     .pipe(source('bundle.js'))
     .pipe(gulp.dest('public/assets'));
  };

  watchBrowserify
    .transform('coffeeify')
    .on('log', util.log)
    .on('update', updateOnChange)
  updateOnChange();
});

gulp.task('default', ['compile-sass', 'compile-scss', 'compile-coffee']);

gulp.task('compile-sass', function() {
  gulp.src('app/assets/stylesheets/**/*.sass')
      .pipe(sourcemaps.init())
      .pipe(sass({ indentedSyntax: true, errLogToConsole: true }))
      .pipe(sourcemaps.write())
      .pipe(gulp.dest('public/assets'));
});

gulp.task('compile-scss', function() {
  gulp.src('app/assets/stylesheets/**/*.scss')
      .pipe(sourcemaps.init())
      .pipe(sass({ indentedSyntax: false, errLogToConsole: true }))
      .pipe(sourcemaps.write())
      .pipe(gulp.dest('public/assets'));
});

gulp.task('compile-coffee', function() {
  var stream = browserifyInstance('./app/assets/javascripts/application.coffee',
    { debug: true /* enables source maps */ }
  )
  .transform('coffeeify')
   .bundle();

  stream.pipe(source('bundle.js'))
        .pipe(gulp.dest('public/assets'));
});
```

Now you can run `gulp watch` and watch for changes of your Sass and CoffeeScript files. Each time you change it, they’ll compile automatically.

## More?

In this 82 line JS code snippet we actually rewritten a major part of default Rails Sprockets configuration. But of course you can provide more features:

* [gulp-rev](https://github.com/sindresorhus/gulp-rev) - for appending hashes to your compiled assets like sprockets does.
* [gulp-uglify](https://www.npmjs.com/package/gulp-uglify) - for minifying assets
* [gulp-livereload](https://github.com/vohof/gulp-livereload) - for autoreloading
* Using `process.env` to configure your transform sequences (you can introduce env’s this way like `RAILS_ENV`)

There is a lot to do beyond standard workflow of Rails. Now, when you have full control you can do a lot things you cannot with Sprockets.

## Summary

Using Gulp as a replacement of Sprockets seems to be a natural way to easily grasp all modern JavaScript techniques and technologies. Explicit asset pipeline is a thing that can be beneficial both in terms of debugging and easily adding new parts to your frontend.



