---
created_at: 2021-04-21T00:34:14.769Z
author: Paweł Pacana
tags: []
publish: false
---

# How to speed up Netlify build, twice

Netlify is a platform to build and deploy static sites (i.e. [nanoc](https://nanoc.app) or jekyll). We use it extensively for many of our sites at Arkency, like this [blog](https://blog.arkency.com). 

The platform acts both as a Continuous Deployment pipeline and a hosting for generated HTML files, with Content Delivery Network. That is quite convenient combination of features.

The workflow to publish changes on a site starts from a push into a git repository. That triggers the build process for a given revision of the repository. That build process runs within a sort of stateless container. That is pretty typical model if you've ever had anything to do with a CI/CD in a cloud.

The container is stateless itself, but it needs some state in order to make build process quicker. That state is cache, which can be:
* restored before starting such build process
* saved when build process completes

Netlify is smart enough to figure out that our Nanoc or Jekyll sites have runtime dependencies:
* Ruby gems as defined in `Gemfile`
* npm packages as defined in `package.json`
Those dependencies are automatically cached in order to save us much time fetching them over and over again on each build. That is pretty typical too, when setting up CI/CD and it is great to have it working out of the box.

Netlify as a platform goes "wide", to attract many developers and provide great initial experience for most of us (there's far more "jamstacks" than just Nanoc or Jekyll). 

In order to squeeze performance to the very last drop, you have to go "deep" instead. For example nanoc is very good at [avoiding unnecessary recompilation](https://nanoc.app/doc/internals/#outdatedness-checking) and will only recompile an item if it is deemed to be outdated. For this to work, it maintains a set of files:

```
blog.arkency.com master [1] tree -L 2 tmp/nanoc/
tmp/nanoc/
└── df597f7007938
    ├── binary_content
    ├── binary_content_data
    ├── checksums
    ├── compiled_content
    ├── dependencies
    ├── outdatedness
    └── rule_memory
```

Netlify has no idea that these, along with generated output from previous builds, are crucial for nanoc to work its best. 

Same goes with [parceljs](https://parceljs.org) — a very pleasant-to-work-with asset bundler with blazing fast bundle rebuilds. In order to achieve it, this tool maintains its own cache in `.cache` directory of the project. Again, it is too niche and specific for Netlify to optimize for, they go "wide".

Luckily Netlify [left the door open](https://www.youtube.com/watch?v=w9yrrQBBKos) for developers to augment their build process and let them go "deep". This is done with [build plugins](https://docs.netlify.com/configure-builds/build-plugins/).

Building such plugin is rather straightforward:
* there a [starter repository](https://github.com/netlify/build-plugin-template), which acts as a template to fork with test suite and linter
* the plugin is event-driven, you handle only the events relevant to you
* plugin has access to site configuration, input parameters and some bits of environment
* you're able to interrupt the build, interact with cache, retrieve changes from git and finally run commands and processes

Pretty sweet balance of possibilities yet without overly verbose API. Here's an overview of build events:

| hook | description | 
| ---  | --- |
| onPreBuild | runs before the build command is executed |
| onBuild | runs directly after the build command is executed |
| onPostBuild | runs after the build command completes, can be used to prevent a build from being deployed |
| onError | runs when an error occurs in the build or deploy stage, failing the build |
| onSuccess | runs when the deploy succeeds
| onEnd | runs after completion of the deploy stage, regardless of build error or success |

It turned out that plugins to take the most of nanoc and parceljs were quite simplistic:

```javascript
const NANOC_TMP = 'tmp/nanoc'

module.exports = {
  async onPreBuild({ constants, utils: { cache } }) {
    await cache.restore([constants.PUBLISH_DIR, NANOC_TMP])
  },
  async onPostBuild({ constants, utils: { cache } }) {
    await cache.save([constants.PUBLISH_DIR, NANOC_TMP])
  },
}
```


```javascript
const PARCEL_CACHE = '.cache'

module.exports = {
  async onPreBuild({ utils: { cache } }) {
    await cache.restore(PARCEL_CACHE)
  },
  async onPostBuild({ utils: { cache } }) {
    await cache.save(PARCEL_CACHE)
  },
}
```

Don't be mistaken — those several lines of code were quite powerful and have **cut the build time in half**. 

If you're on nanoc or parceljs, perhaps with a [starter-kit for static sites](https://github.com/arkency/nanoc-parcel-tailwind-starter) that we use in arkency, check these out:

* https://github.com/pawelpacana/netlify-plugin-nanoc-cache
* https://github.com/pawelpacana/netlify-plugin-parcel-cache
* https://github.com/arkency/nanoc-parcel-tailwind-starter

