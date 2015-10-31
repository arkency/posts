---
title: "Creating custom Heroku buildpack for Webpack and Ruby on Rails integration"
created_at: 2015-10-27 19:01:22 +0100
kind: article
publish: true
author: Marcin Grzywaczewski
tags: [ 'frontend', 'assets', 'sprockets' ]
newsletter: :react_books
img: "/assets/images/creating-custom-heroku-buildpack-for-webpack-and-ruby-on-rails-integration/header-fit.png"
---

<figure>
  <img src="/assets/images/creating-custom-heroku-buildpack-for-webpack-and-ruby-on-rails-integration/header-fit.png" width="100%" alt="" />
</figure>

Heroku and Rails loves each other from long time - and this combo is still widely used both by beginners and experts to build and host their web applications. It's easy and it's fast to host an app - and those two factors are very important in early stages of the project's lifecycle.

In modern web applications backends and frontends are often equally sophisticated - and unfortunately solutions that Sprockets offers by default are suboptimal choice. Using **ECMAScript 2015 features, modern modularization tools and keeping track of dependencies are hard to achieve in typical Rails asset pipeline**. That's why [modern JavaScript tooling](http://reactkungfu.com/2015/07/the-hitchhikers-guide-to-modern-javascript-tooling/) is used more and more often to deliver those features.

In Arkency **we use [Webpack](https://webpack.github.io/) and [Babel.js](http://babeljs.io/) to manage and compile code written in modern dialects of JavaScript**. Apart from configuration and Rails integration problems there is also a problem of deployment and configuring the deploy machinery to wire everything together. **In this article I'd like to show you how you can deploy Rails + Webpack combo to Heroku**. This is the thing that is expected from us by our clients from time to time.

<!-- more -->

## Assumptions

Of course to deploy Rails together with Heroku we need to have both tools configured and working. In this article the goal is to **make Webpack compile the bundle that can be used by Rails to serve this bundle**.

In the described configuration Webpack only provides modularization and ES2015 compilation using [babel-loader](https://github.com/babel/babel-loader). It doesn't minify files - the assumption is that Rails' asset pipeline can do this just fine during precompilation phase.

The assumption is that the stack is configured as follows:

* The Node.js `package.json` resides under `app/assets` within the Rails application root.
* Source files are stored under `app/assets/source`.
* Webpack compiles the bundle into `app/assets/javascripts` directory and this bundle is `required` within application manifest (`application.js`)
* Webpack, Babel and loaders are installed as `devDependencies` so they are not installed if Node.js environment is set to _production_.
* All JavaScript dependencies of the codebase are installed on the Node.js side as regular dependencies.
* There is a [npm script](https://docs.npmjs.com/cli/run-script) named `build-production` that creates the production-ready bundle (by production-ready I mean - [deduped one](https://github.com/webpack/docs/wiki/optimization#deduplication))

So from the Rails point of view there is only another JavaScript file to include - and this JavaScript file is a bundle emitted by Webpack. The rest (serving pages and serving the compiled JavaScript) is done on the Rails side.

That configuration implies that the whole process of bundle compilation can be done in a total separation from Rails - and that will be important later. To understand how to deploy such configuration, you need to understand how Heroku deployment process works - and fortunately it is relatively simple.

## Buildpacks

Heroku is using so-called [_slug compiler_](https://devcenter.heroku.com/articles/slug-compiler) to create a version of an app that is suitable for being served in the Heroku dyno infrastructure. This tool is using so-called _buildpacks_ to perform necessary steps to deploy your application. There are many buildpacks for many technologies - like [Ruby buildpack](https://github.com/heroku/heroku-buildpack-ruby) for deploying Ruby (and Rails) apps or [Node.js buildpack](https://github.com/heroku/heroku-buildpack-nodejs) to deploy and serve Node.js-based apps. By default Heroku is guessing which buildpack to use by doing heuristics built into the buildpacks.

In their essence buildpacks are simple bash scripts that are splitted into three parts:

* `detect` part checking whether buildpack should be ran to compile this particular application. Heroku uses it to guess which buildpack is used if none is specified explicitly. 
* `compile` part is responsible for all necessary preparations needed to run the app. In this step dependencies are installed, assets precompiled and necessary caches filled.
* `release` part is responsible for running the app after it has been built.

You can see it by yourself - these three bash scripts are always included in buildpacks under `bin/` directory.

In the case of described configuration there are _two_ applications in Heroku terms - one is the Ruby app and it is seamlessly prepared for being run on Heroku (no steps needed) and the other is a Node.js app residing under `app/assets` directory. It would be ideal to use those two buildpacks - Ruby one and Node.js one and call it a day. Unfortnately, it's not that simple.

## The Problem

Node.js buildpack has almost everything that you need - it installs all necessary dependencies, caches them, downloads Node.js and so on. But unfortunately there are things that it can't do out-of-the-box:

* Since `package.json` is not located under the root directory of the app it won't get `detect`ed correctly. Also during compilation build directories will be invalid.
* Node.js package is unaware of the npm script you'd like to run.
* By default Node.js buildpack is running in the `development` Node.js environment so webpack won't be installed at all.

To address those three issues you'd need to fork and modify heroku Node.js buildpack.

## Modifying Node.js Heroku Buildpack

First of all, you need to have Node.js buildpack forked or cloned and published in a repo. It is important because while configuring buildpacks you'd need to provide a Git repository from which buildpack is going to be fetched.

After having source files, it is needed to modify four files:

* `bin/detect` to change directory where `package.json` will be searched.
* `bin/compile` to change directories where Node.js will be built and to add your npm runscript to be ran.
* `bin/release` to make it a no-op operation.
* 'lib/environment.sh' to change defaults of node.js environment

Let's start with `bin/detect` script. It looks like this:

```
#!bash
# bin/detect <build-dir>

if [ -f $1/package.json ]; then
  echo "Node.js"
  exit 0
fi

exit 1
```

Since `package.json` resides under `app/assets` of the build directory, you need to change this test:

```
#!bash

[ -f $1/package.json ];
```

To:

```
#!bash

[ -f $1/app/assets/package.json ];
```

After this change everything will work as planned.

The next step would be to change build directory in `bin/compile`. You need to look after:

```
#!bash

BUILD_DIR=${1:-}
```

And change it to:

```
#!bash

BUILD_DIR=$(cd ${1:-}; cd app/assets; pwd)
```

This way the build directory of your builpack will change to `X/app/assets` where X is the argument passed to this script. BTW. You can test this script by calling `bin/compile <your-app-path> /tmp` to see what happens and troubleshoot if any problems arise with using this buildpack. The same with rest of the scripts inside `bin/`. At the top of the file there is a comment describing the usage of these scripts.

So far, so good. Build directory is set correctly, now you need to run your npm script. After:

```
#!bash

header "Building dependencies"
build_dependencies | output "$LOG_FILE"
```

You need to have:

```
#!bash

npm run build-production
```

So the compilation step is reconfigured correctly. Unfortunately it still doesn't work. It is because devDependencies are not installed. By default they are not installed if `NODE_ENV` variable is set to `production`. It is a default in this buildpack and it needs to be changed.

That's why `lib/environment.sh` needs to be modified. You're interested in the `create_default_env()` procedure:

```
#!bash

create_default_env() {
  export NPM_CONFIG_PRODUCTION=${NPM_CONFIG_PRODUCTION:-true}
  export NPM_CONFIG_LOGLEVEL=${NPM_CONFIG_LOGLEVEL:-error}
  export NODE_MODULES_CACHE=${NODE_MODULES_CACHE:-true}
  export NODE_ENV=${NODE_ENV:-production}
}
```

It needs to be changed to:

```
create_default_env() {
  export NPM_CONFIG_PRODUCTION=${NPM_CONFIG_PRODUCTION:-false}
  export NPM_CONFIG_LOGLEVEL=${NPM_CONFIG_LOGLEVEL:-error}
  export NODE_MODULES_CACHE=${NODE_MODULES_CACHE:-true}
  export NODE_ENV=${NODE_ENV:-development}
}
```

You can also omit this step and set corresponding environment variables using [Heroku Toolbelt](https://toolbelt.heroku.com). Since this Node.js buildpack is used for development tasks I find it sane to change defaults - it is not _default_ way to use Node.js buildpack after all.

The last part is about disabling any 'releasing' behaviour in this buildpack. Modify `bin/release` to be:

```
#!bash

exit 0
```

That's it. Commit and push your changes - the buildpack is ready to use!

## Wiring buildpacks together

Since you want to use multiple buildpacks you need to explicitly tell heroku which buildpacks will be used. By default Heroku guesses it and sets only one buildpack. Here two are used.

To configure buildpacks used by an app you need to use [Heroku Toolbelt](https://toolbelt.heroku.com). There is handy command called `heroku buildpacks:add` that will be used here.

First of all, you need to add Ruby buildpack. `heroku buildpacks:add` accepts URL of the repository as an argument. So the command you need to issue in your app directory is:

```
#!bash
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-ruby
```

Then, you need to have _your repository_ URL. You need to add it as the **first** buildpack that is executed. There is a `--index 1` option which does exactly this - setting the buildpack as _first_ to be executed. So the next command you need to issue is:

```
#!bash
heroku buildpacks:add <YOUR-REPO-URL> --index 1
```

Your repo must be in HTTP format, not the SSH one (so not `git@github.com:heroku/heroku-buildpack-ruby.git` for example, but `https://github.com/heroku/heroku-buildpack-ruby`). It is also need to be accessible by Heroku.

If you make a mistake during typing those values there is a `heroku buildpacks:remove` command that accepts URL or index to be removed.

## How it works now?

This is a lot of knowledge here. So to make a quick recap let's enumerate how Heroku will behave now after you issue `git push`:

1. The slug compiler will invoke.
2. Then, the first buildpack from the list will be invoked. This is _your_ buildpack. After `compile` there will be your bundle compiled and placed in `app/assets/javascripts` directory.
3. Then, the second buildpack starts. It is a Ruby buildpack. It installs your Rails app and precompiles assets.
4. Then, `release` scripts are invoked. Custom buildpack `release` does nothing and Ruby buildpack runs Rails app.

So your app should be deployed with all compiled Webpack scripts, just as planned.

## Summary

As you can see, integration of Rails and Webpack on Heroku can still be done in a relatively easy way. Unfortunately it is not as straightforward as the typical Rails-only process, but it's still manageable. I think being able to work with modern JavaScript tooling is worth the effort.

