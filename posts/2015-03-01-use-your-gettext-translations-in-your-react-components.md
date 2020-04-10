---
title: "Use your gettext translations in your React components"
created_at: 2015-03-01 21:46:01 +0100
publish: true
author: Jakub Kosiński
tags: [ 'i18n', 'i18next', 'translations', 'react', 'rails', 'gettext' ]
img: "use-your-gettext-translations-in-your-react-components/flags.jpg"
newsletter: react_books
---

<p>
  <figure>
    <img src="<%= src_fit("use-your-gettext-translations-in-your-react-components/flags.jpg") %>" width="100%">
    <details>
      <a href="https://www.flickr.com/photos/mig/15964697">Photo</a> 
      remix available thanks to the courtesy of
      <a href="https://www.flickr.com/photos/mig/">miguelb</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

In one of our projects, we are using gettext for i18n. We were putting Handlebars `x-handlebars-template` templates directly in Haml templates to provide translated views for frontend part - all translations were made on backend. Recently we have rewritten our frontend to React and decided not to use ruby for translations anymore. 

<!-- more -->

## Transitioning from backend to frontend
During rewrite, we created an simple API endpoint on backend that was returning translation for given key and locale and mixed it with React component that was asynchronously getting translations. The code was pretty simple and was using [jQuery promises](https://blog.arkency.com/2015/02/the-beginners-guide-to-jquery-deferred-and-promises-for-ruby-programmers/):

```coffeescript
React = require('react')
{span} = React.DOM

cache = {}

lookupCache = (key, locale) ->
  cache[locale] ||= {}
  cache[locale][key]
  
updateCache = (key, locale, translation) ->
  cache[locale] ||= {}
  cache[locale][key] = translation
  
translate = (key, locale) ->
  if translation = lookupCache(key, locale)
    new $.Deferred()
      .resolve(translation)
      .promise()
  else
    $.ajax
      url: '/api/gettext'
      data:
        key: key
        locale: locale
      dataType: 'JSON'
      type: 'GET'
    .then (response) ->
      updateCache(key, locale, response.translation)
    .fail ->
      key
      
Translation = React.createClass
  displayName: 'translation'
  
  getInitialState: ->
    translation: null

  componentDidMount: ->
    translate(@props.key, @props.locale)
      .always (translation) =>
        if @isMounted()
          @setState(translation: translation)
          
  render: ->
    if @state.translation
      span(null, @state.translation)
    else
      span(null, '...')
      
module.exports = (key, locale) ->
  React.createElement(Translation, key: key, locale: locale)
```

## i18next - move your gettext to frontend
This approach was good for quick start but did not scale - it required multiple ajax calls to backend on each page render, so we decided to find something better. After some research we have chosen [i18next](http://i18next.com/) - full-featured i18n JS library that have pretty good compatibility with gettext (including pluralization rules). With i18next you can easily return translations using almost the same API as in gettext:

```coffeescript
# {"key": "translation"}
i18n.t('key') # => translation for key
```

This library also supports variables inside translation keys:

```coffeescript
# {"key with __variable__": "translation with __variable__"}
i18n.t('key with __variable__', {variable: 'value'}) # => translation with value
```

It has also sprintf support:

```coffeescript
# {"Some text with string %s and number %d": "Hello %s! You're number %d!"}
i18n.t('Some text with string %s and number %d', {postProcess: 'sprintf', sprintf: ['world', 1]}) # => Hello world! You're number 1!
```

And supports plurar forms (even for languages with multiple plural forms):

```coffeescript
# {"key": "__count__ banana", "key_plural": "__count__ bananas"}
i18n.t("key", {count: 0}) # => 0 bananas
i18n.t("key", {count: 1}) # => 1 banana
i18n.t("key", {count: 5}) # => 5 bananas
```

There are much more configuration options and features in i18next library so you'd better look at their [docs](http://i18next.com/pages/doc_features.html).

To convert our gettext `.po` files to json format readable by i18next, we're using [i18next-conv](http://i18next.com/pages/ext_i18next-conv.html) tool and store generated json in `public/locale` directory of our Rails app. Here's a simple script we're using during deploy to compile JS translations (`script/compile_js_i18n`):

```bash
#!/bin/bash
npm install .
for locale in de en fr pl; do
    for file in acme.po support.po tags.po; do
        ./node_modules/.bin/i18next-conv -l $locale -s locale/$locale/$file -t public/locale/$locale/${file/.po/.json}
    done
done
```

To use it, just run `script/compile_js_i18n` in your app's root directory (but make sure you have node & npm installed and `"i18next-conv": "~> 0.1.4"` line in your `package.json` file before). What's great about i18next-conv, it has [built-in plural forms](https://github.com/i18next/i18next-gettext-converter/blob/master/lib/plurals.js) for many languages.

i18next has also a bunch of [initialization options](http://i18next.com/pages/doc_init.html). Here's our setup that works in our app:

```coffeescript
i18n.init
  ns: 
    defaultNs: 'acme'
    namespaces: ['acme', 'support', 'tags']
  lngWhiteList: ['de', 'en', 'fr', 'pl']
  fallbackLng: 'en'
  resGetPath: '/locale/%{lng}/%{ns}.json'
  interpolationPrefix: '%{'
  interpolationSuffix: '}'
  keyseparator: '<'
  nsseparator: '>'
```

Some of those initialization options need more explanation. First, we're using variable interpolation in our gettext translations. They have format different than i18next defaults (`%{variable_name}` instead of `__variable_name__`) so we had to set `interpolationPrefix` and `interpolationSuffix`. Second, since we're using english translations as gettext msgids (usually full sentences), we need to change key and namespace separator (`keyseparator` and `nsseparator` options). The default key separator in i18next is a dot (`.`) and namespace separator is a colon (`:`) and that was making most of our translations useless, since they were not translated at all when translation key contained `.` or `:`. We also had to change `resGetPath` since we decided to store our json in `public/locale` (e.g. `public/locale/en/acme.json` for acme namespace). 
In our app, we wrapped initialization code in `i18n` CommonJS module for easier use:

```coffeescript
i18n = require('i18next')
i18n.init(
  ns: 
    defaultNs: 'acme'
    namespaces: ['acme', 'support', 'tags']
  lngWhiteList: ['de', 'en', 'fr', 'pl']
  fallbackLng: 'en'
  resGetPath: '/locale/%{lng}/%{ns}.json'
  interpolationPrefix: '%{'
  interpolationSuffix: '}'
  keyseparator: '<'
  nsseparator: '>'
})

module.exports = i18n
```

With this helper, you don't need to initialize library each time you use it, it would be initialized only once, on first use.

By default, i18next retrieves translations asynchronously, using ajax get requests to the endpoint set in `resGetPath` when you set locale using `i18n.setLng` method. `setLng` method accepts locale as first parameter and optional callback that would be fired after loading translations. You can make use of it in your's app bootstrap code:

```coffeescript
React = require('react')
i18n = require('i18n')
Gui = React.createFactory(require('gui'))

class App
  constructor: (locale, node) ->
    i18n.setLng locale, =>
      # ...
      React.render(Gui(), node)
      # ...
      
# ...

new App(window.locale, document.body)
```

Having this setup we can just use regular i18next API in our React components:

```coffeescript
i18n = require('i18n')

module.exports = React.createClass
  displayName: 'Foo'
  
  render: ->
    React.DOM.span(null, i18n.t('Hello world!'))
  
```

i18next has much more features and integrations, including localStorage caching, jQuery integration and [ruby gem](https://github.com/gcko/guard-i18next) that can automatically rebuild your javascript translations from YAML files. Have a look at [their docs](http://i18next.com/pages/doc_features.html) for further information.
