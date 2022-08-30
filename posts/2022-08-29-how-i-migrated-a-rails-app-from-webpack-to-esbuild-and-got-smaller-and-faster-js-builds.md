---
title: How I migrated a Rails app from Webpack to esbuild and got smaller and faster JS builds
created_at: 2022-08-29T20:36:04.830Z
author: Jakub Kosiński
tags: ["js", "webpack", "esbuild"]
publish: true
---

In the last week, I have been responsible for migrating a pretty big (300k+ lines of JS code) project from [Webpack 4](https://webpack.js.org) to [esbuild](https://esbuild.github.io). In our Rails project, we were using [Webpacker](https://github.com/rails/webpacker) to integrate our JS stack with the main application. For the last months, we were struggling with very long builds and also were locked into Webpack 4 as Webpacker became a deprecated library. When a few Webpack 4 dependencies received their CVE, we decided it was time to switch to some other bundler.

After short investigation, we decided to use esbuild to prepare our JS entries. And as time has passed and we have finally said goodbye to IE 11, there was also an opportunity to improve the stack by switching to ECMAScript modules - [almost 95%](https://caniuse.com/es6-module) of web users can understand them and there is no point in not using them today. And few years after we looked at our JS stack for the last time, it turned out that we don't need Babel and some polyfills anymore as most features we are using are already built in modern browsers.

In this post, I am describing and discussing the current configuration of our JavaScript setup.

## esbuild configuration

Our current esbuild options look like this:

```js
const glob = require("glob");
const esbuild = require("esbuild");
const {lessLoader} = require("esbuild-plugin-less");
const isProduction = ["production", "staging"].includes(
  process.env.WEBPACK_ENV
);

const config = {
  entryPoints: glob.sync("app/javascript/packs/*.js"),
  bundle: true,
  assetNames: "[name]-[hash].digested",
  chunkNames: "[name]-[hash].digested",
  logLevel: "info",
  outdir: "app/assets/builds",
  publicPath: `${process.env.CDN_HOST ?? ""}/assets`,
  plugins: [lessLoader({javascriptEnabled: true})],
  tsconfig: "tsconfig.json",
  format: "esm",
  splitting: true,
  inject: ["./react-shim.js"],
  mainFields: ["browser", "module", "main"],
  loader: {
    ".js": "jsx",
    ".locale.json": "file",
    ".json": "json",
    ".png": "file",
    ".jpeg": "file",
    ".jpg": "file",
    ".svg": "file",
  },
  define: {
    global: "window",
    RAILS_ENV: JSON.stringify(process.env.RAILS_ENV || "development"),
    VERSION: JSON.stringify(process.env.IMAGE_TAG || "beta"),
    COMMITHASH: JSON.stringify(process.env.GIT_COMMIT || ""),
  },
  incremental: process.argv.includes("--watch"),
  sourcemap: true,
  minify: isProduction,
  metafile: true,
  target: ["safari12", "ios12", "chrome92", "firefox88"],
};
```

Let's start from `entryPoints` list - as we were using Webpacker, we had a pretty standard location for our entries (packs) - `app/javascript/packs`. I didn't want to list all entries that we were creating (and remember to add any new entries manually) so I used the `glob` package to generate the list of all files matching the given pattern. This way I can add any new entries to `app/javascript/packs` directory and they will be automatically built on the next run. We do want to inline all imported dependencies into created entries so we're using `bundle: true` setting.

The next two settings: `assetNames` and `chunkNames` are set to properly handle the asset pipeline managed by sprockets and prevent digesting chunks and assets twice. Note the `-[hash].digested` part - this is required in order not to digest generated files once again in sprockets. Without these settings, all dynamic imports or imports of files handled by the file loader won't work after the assets compilation.

As we're building more than one entry, the `outdir` property is needed. It's set to `app/assets/builds` so that we can integrate it with the Rails asset pipeline later.

In most of tutorials I found, the `publicPath` was set to `assets`. But this setting won't work properly when `splitting` option is enabled - imported chunks will have a relative path so they won't work on most pages. This will also not work with any CDN. We're prepending the `publicPath` with the CDN host set by the env variable so that we don't need to serve assets through the Rails app server (`CDN_HOST` is equal to `config.asset_host` value).

We are using one plugin for LESS support - we're going to move all CSS out of the JS stack, but not all stylesheets have been moved out yet and some of them are using LESS. This plugin will be removed soon.

With Webpacker, we were using a resolve alias. It allowed us to not use relative paths in imports, we could use `import foo from "~/foo"` instead. esbuild doesn't support such aliases by default, but it has support for `tsconfig.json` files. The `tsconfig` option allows specifying the path for the `tsconfig.json` file. This works also when you're not using TypeScript in your application. Our `tsconfig.json` file looks like this:


```json
{
  "compilerOptions": {
    "target": "es6",
    "baseUrl": ".",
    "paths": {
      "~/*": [
        "./app/javascript/src/*"
      ]
    }
  },
  "include": [
    "app/javascript/src/**/*"
  ],
}
```

`compilerOptions.path` object allows us to preserve imports from Webpacker and resolve the `~/` prefix properly.

The next options (`format` & `splitting`) enable ESM format and support for chunk splitting with dynamic imports. As we are using dynamic imports and have multiple lazy-loaded pages in our single-page application, we needed this option to optimize the size of JS files needed for the initial render. To properly handle React components we needed a shim that is injected into every file generated by esbuild (`inject` option). Our `react-shim.js` file is very simple and looks like this:

```js
import * as React from "react";
export {React};
```

We also needed to change the default `mainFields` setting as one or two libraries we were using were not exporting code for the browser correctly. That resulted in errors during the build as node packages were not available. You can refer to the [`mainFields` documentation](https://esbuild.github.io/api/#main-fields) to read more about this.

There is another story with loaders. In our project, we're using [i18next](https://www.i18next.com/) with custom backend to handle i18n. We store translations in JSON files and load them via dynamic imports. To make it work with digested assets we needed to use the file loader so that we can get the digested URL in our i18n init module. But after using just `{".json": "file"}` loader, it turned out that we started getting other errors from one of our dependencies. After a brief investigation, it turned out that requiring one of our dependencies have a side effect of importing a JSON file. As a result we couldn't just use the file loader for all JSON files. We ended up with using `.locale.json` suffix for our translation files and using the file loader only for `.locale.json` extension while leaving the `json` loader for `.json` suffix. We don't use `.jsx` extension so we just enabled JSX loader for all `.js` files and left the file loader for images.

With Webpack, we were using the define plugin to inject env variables into the code. With esbuild, we don't need any plugins to handle that as there is already a [`define`](https://esbuild.github.io/api/#define) option to handle that.

The last options are used mostly for development mode or production optimization. The `incremental` option allows us to speed up rebuilding assets in the development environment. We're not using the built-in `watch` setting as it didn't work with our setup. We decided to use a custom file watcher that is using `chokidar` package to watch our JS directory and rebuild entries after detecting any changes:

```js
/* ... */
const fs = require("fs");

const config = { /* see above */ };

if (process.argv.includes("--watch")) {
  (async () => {
    const result = await esbuild.build(config);
    chokidar.watch("./app/javascript/**/*.js").on("all", async (event, path) => {
      if (event === "change") {
        console.log(`[esbuild] Rebuilding ${path}`);
        console.time("[esbuild] Done");
        await result.rebuild();
        console.timeEnd("[esbuild] Done");
      }
    });
  })();
} else {
  const result = await esbuild.build(config);
  fs.writeFileSync(
    path.join(__dirname, "metafile.json"),
    JSON.stringify(result.metafile)
  );
}
```

At the moment we're generating the source maps in all environments and minifying the code for production environments. The metafile is stored in `metafile.json` when the file watcher is not used.

The last option: [`target`](https://esbuild.github.io/api/#target) specifies the target environment for the generated JS code.

We store our esbuild config in the `esbuild.config.js` file and use the following scripts in our `package.json` file to build/rebuild all JS files:

```json
{
  "scripts": {
    "build:js": "node esbuild.config.js",
    "watch:js": "node esbuild.config.js --watch",
  }
}
```

## Rails integration

After inspecting `jsbundling-rails` sources we have decided not to use that library and just add one rake task that is doing the same as that gem. Integrating esbuild with Rails is very easy and the only thing that's needed is to make sure you add this line to your  `app/assets/config/manifest.js` file:

```js
//= link_tree ../builds
```

You should also enhance a few Rake tasks to make sure your esbuild assets are generated before the asset precompilation. We are using this code to make it work:


```ruby
namespace :javascript do
  desc "Build your JavaScript bundle"
  task :build do
    system "yarn install" or raise
    system "yarn run build:js" or raise
  end

  desc "Remove JavaScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/**/[^.]*.{js,js.map}"], verbose: false
  end
end

Rake::Task["assets:precompile"].enhance(["javascript:build"])
Rake::Task["test:prepare"].enhance(["javascript:build"])
Rake::Task["assets:clobber"].enhance(["javascript:clobber"])
```

Now each time you run `rails assets:precompile` the Yarn package manager will install all dependencies and then build your JS files into `app/assets/build`. If you want to set the file watcher while developing your app, you can just run `yarn run watch:js` in your terminal and start your dev server.

## Possible improvements

This configuration works perfectly for us at the moment and resulted in smaller and faster builds. With Webpack we needed from 6 to 15 minutes to build our assets, depending on the load. With esbuild, we can build minified assets in less than a minute. And it's even faster in development - the initial build with the file watcher enabled takes less than 5 seconds on my 2019 iMac and rebuilds are even faster. However, there are still some things we are going to improve in the future. When developing your JS files locally, if you change files that are used in many other modules often, the number of files generated in `app/assets/builds` may grow very fast. That can make your Rails server very slow on the first request. To resolve this issue you can clean the `app/assets/builds` directory before running `yarn run watch:js` script and restart that script from time to time. This could be probably improved with an esbuild plugin that will read the metafile after each build and remove all files that are not listed in that file.

Another issue is with the `app/assets/builds` itself. If you start the `watch:js` script and there would be any error during the rebuild, esbuild process will be killed but the assets directory won't be cleaned so your assets will still be served by Rails and you might wonder why you can't see changes in your modules after refreshing the page. In order to fix this we'll probably need another process that will manage esbuild process state and restart it or at least send a notification on error. If you know how to resolve this issue, feel free to share your knowledge.
