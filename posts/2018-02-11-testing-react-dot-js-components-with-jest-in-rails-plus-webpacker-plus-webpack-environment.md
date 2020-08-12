---
created_at: 2018-02-11 12:34:04 +0100
publish: true
author: Robert Pankowecki
tags: [ 'react', 'jest', 'rails', 'webpack', 'webpacker' ]
newsletter: arkency_form
---

# Testing React.js components with Jest in Rails+Webpacker+Webpack environment

Around a month ago, I worked on a task, which required a more dynamic frontend behavior. I worked on a component with 2 selects and 2 date pickers and depending on what was selected where the other pickers or select inputs had to be updated based on some relatively simple business rules. I decided to implement it using React.js and it was fun and pretty straight-forward to finish it. Also, working with http://airbnb.io/react-dates/ turned out to be a very pleasureful experience. But that's not what this post is about.

<!-- more -->

I wanted to test my component. The integration between Rails asset pipeline (which you can find in almost all legacy Rails apps) and Webpack (which is what anyone wants to use nowadays) is called [Webpacker](https://github.com/rails/webpacker). Thanks to it you can organize, manage, compile your new JavaScript code with Webpack and have it nicely integrated into whole Rails app deployment process. For testing, I wanted to use Jest, which I prefer more than its alternatives.

There are [already guides on how to achieve that](https://medium.com/@kylefox/how-to-setup-javascript-testing-in-rails-5-1-with-webpacker-and-jest-ef7130a4c08e) and that's what I started with. But it was not good enough for me to end up with a working solution. I had to do much more manual work and googling than I expected. So I decided to document the process hoping that it will make other people's life a bit easier.

BTW. I don't have a PhD in Webpack so forgive me if all of that is obvious to you. 

## Preconditions

* You have Rails 5 app
* You have webpacker installed in that Rails 5 app with React.js integration
  * https://github.com/rails/webpacker#installation
  
      Add to your `Gemfile` 
   
        gem 'webpacker', '~> 3.2'
      
      Run:
      
        bundle install
        bundle exec rails webpacker:install
  
  * https://github.com/rails/webpacker#react 
  
      Run:
      
        bundle exec rails webpacker:install:react
      
## Install Jest

```
yarn add --dev jest
```

Now we can configure commands for running `jest` and tell where we keep our test files by adding those lines to `package.json`.

```
  "scripts": {
    "test": "jest",
    "test-watch": "jest --watch"
  },
  "jest": {
    "roots": [
      "test/javascript"
    ]
  }
```

This project uses MiniTest and `test/*` directories for Ruby tests and I decided to add my tests in similar `test/javascript` location.

I added a very simple check in `test/javascript/sum.test.js` to verify that this step of the configuration is working correctly.

```js
test('1 + 1 equals 2', () => {
  expect(1 + 1).toBe(2);
});
```

Run `yarn test` and you should that it works.

It doesn't mean much but at least I knew I had `jest` installed and working for most simple cases. That's something.

## Setup Babel

This step is required to have `import` directives working.

Run:

```
yarn add --dev babel-jest regenerator-runtime
```

Now, here is something other tutorials did not mention, but which is mentioned in https://github.com/facebook/jest#additional-configuration

> If you've turned off transpilation of ES modules with the option { "modules": false }, you have to make sure to turn this on in your test environment.

And indeed. Webpacker initially creates a `.babelrc` configuration:

```
  "presets": [
    [
      "env",
      {
        "modules": false,
        "targets": {
          "browsers": "> 1%",
          "uglify": true
        },
        "useBuiltIns": true
      }
    ],
    "react"
  ],
```

which disables transpilation of ES modules. So we need to overwrite the configuration for `test` env:

```js
{
  "env": {
    "test": {
      "presets": [["env"], "react"]
    }
  }
}
```

Why by default (webpacker's default) does the configuration say `"modules": false` and what does it mean? That's a really long story... It is necessary for tree shaking, webpack 2 can do it only with ES6 modules syntax. What is tree shaking? It's [eliminating unused code that is not imported](http://2ality.com/2015/12/webpack-tree-shaking.html). Wait, there are many modules syntaxes? Yes, [there are](http://2ality.com/2015/12/babel-commonjs.html) and only some of them are statically analyzable. I guess you know that and it is obvious if you come from JS community but coming from Ruby community I really needed to educate myself as to what and why to understand what I am doing here. 

Also, there is no need to use `babel-preset-es2015` as recommended in some articles.

Without any configuration options, `babel-preset-env` (which we have in config) behaves exactly the same as `babel-preset-latest` (or `babel-preset-es2015`,
`babel-preset-es2016`, and `babel-preset-es2017` together). For more information on that check out: https://babeljs.io/docs/plugins/preset-env/

To verify that I could use `import` I used `test/javascript/sum.test.js`:

```js
import _ from 'lodash';
import moment from 'moment';

test('1 + 1 equals 2', () => {
  expect(1 + 1).toBe(2);
  console.log(moment());
});
```

And it worked. Bear in mind that I already had `lodash` and `moment.js` installed with `yarn`.

P.S.

```
"presets": [["env",
```

have nothing to do with 

```
  "env": {
    "test":
``` 

These two `env`s have 2 different meanings. That's confusing when you see:

```
{
  "presets": [["env", {"modules": false}], "react"],
  "env": {
    "test": {
      "presets": [["env"], "react"]
    }
  }
}
```

`"presets": [["env"]` is about https://babeljs.io/docs/plugins/preset-env/ and `"env":{"test":` (which can overwrite _presets_) is about https://babeljs.io/docs/usage/babelrc/#env-option (supporting `BABEL_ENV` and `NODE_ENV` environment variable for overwriting configuration).

## Configure Jest to find modules

The `moduleDirectories` setting can be used to tell Jest where to look for modules.

I configured it to use like that:

```js
  "jest": {
    "moduleDirectories": [
      "node_modules",
      "app/javascript/packs"
    ]
  }
}
```

I verified that I can use JSX syntax in `test/javascript/sum.test.js` with:

```jsx
import _ from 'lodash';
import moment from 'moment';
 
import React from 'react';
import ReactDOM from 'react-dom';

test('1 + 1 equals 2', () => {
  expect(1 + 1).toBe(2);
  console.log(moment());
  const asd = <div>asd</div>;
});
```

and it worked. Nothing crashed.

## Enzyme

For testing react components I like to use Enzyme

```
yarn -add enzyme enzyme-adapter-react-16 jest-enzyme
```

More on that in http://airbnb.io/enzyme/docs/installation/ and https://github.com/airbnb/enzyme/blob/master/docs/guides/jest.md and https://github.com/FormidableLabs/enzyme-matchers/tree/master/packages/jest-enzyme#setup

In `package.json` I added

```js
{
  "jest": {
    "setupTestFrameworkScriptFile": "./node_modules/jest-enzyme/lib/index.js",
  }
}
```

No idea, why this line is needed.

That was not enough yet for testing my React components though. I still had some failures.

## Handle CSS in testing React component

Based on [webpack instructions](https://facebook.github.io/jest/docs/en/webpack.html#handling-static-assets) instructions. I didn't go with [Mocking CSS modules](https://facebook.github.io/jest/docs/en/webpack.html#mocking-css-module). That was not necessary for me.

Let's configure Jest to gracefully handle asset files such as stylesheets and images. Usually, these files aren't particularly useful in tests so we can safely mock them out.

In `package.json` we add:

```js
{   
  "jest": {
    "moduleNameMapper": {
      "\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$":
      "<rootDir>/test/javascript/__mocks__/fileMock.js",
      "\\.(css|less)$": "<rootDir>/test/javascript/__mocks__/styleMock.js"
    }
  }
}
```

I created: `test/javascript/__mocks__/fileMock.js` with:

```js
module.exports = 'test-file-stub';
```

and `test/javascript/__mocks__/styleMock.js` 

with

```js
module.exports = {};
```

I seriously did not expect that such configs will be necessary...

## React+JSX+Enzyme test

With that I could finally test my first component:

```jsx
import React from 'react';
import ReactDOM from 'react-dom';
 
import { shallow, configure } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
configure({ adapter: new Adapter() });

import 'react-dates/initialize';
import AdvancedSearchSeasonOptions from 'advances_search_season_options/component';

test('rendered component', () => {
  const wrapper = shallow(<AdvancedSearchSeasonOptions
    season_available={null}
    year_available={null}
    release_on_from={null}
    release_on_to={null}
    seasons={[
      {"year":2018,
       "season":"spring",
       "yearSeason":"2018-spring",
       "begin":"2017-12-15",
       "end":"2018-07-31",
       "name":"Spring 2018"
      },
    ]}
    years={[
      {"year":2018,"begin":"2017-12-15","end":"2018-12-14"},
    ]}
  />);
  expect(wrapper.find('div.half.first')).toHaveLength(2);
});
```

Notice that I needed `import 'react-dates/initialize';` only because I am using `react-dates` component. Your first component will most likely not need it. 

## Summary

That's more or less how started testing our React.js components with Jest in Rails apps that use Webpacker to integrate with Webpack. I definitely thought more of those things would work out of the box and without me having to understand all of that details.

## Current status

Let me show you full `.babelrc`:

```js
{
  "presets": [
    [
      "env",
      {
        "modules": false,
        "targets": {
          "browsers": "> 1%",
          "uglify": true
        },
        "useBuiltIns": true
      }
    ],
    "react"
  ],
  "env": {
    "test": {
      "presets": [
        [
          "env"
        ],
        "react"
      ],
      "plugins": [
        "syntax-dynamic-import",
        "transform-object-rest-spread",
        [
          "transform-class-properties",
          {
            "spec": true
          }
        ]
      ]
    }
  },
  "plugins": [
    "syntax-dynamic-import",
    "transform-object-rest-spread",
    [
      "transform-class-properties",
      {
        "spec": true
      }
    ]
  ]
}
```

and almost full `package.json`: 

```js
{
  "dependencies": {
    "@rails/webpacker": "^3.2.1",
    "babel-preset-react": "^6.24.1",
    "camelize": "^1.0.0",
    "classnames": "^2.2.5",
    "lodash": "^4.17.4",
    "mailcheck": "^1.1.1",
    "prop-types": "^15.6.0",
    "react": "^16.2.0",
    "react-async-script": "^0.9.1",
    "react-dom": "^16.2.0",
  },
  "devDependencies": {
    "babel-jest": "^22.1.0",
    "babel-plugin-transform-es2015-arrow-functions": "^6.22.0",
    "enzyme": "^3.3.0",
    "enzyme-adapter-react-16": "^1.1.1",
    "jest": "^22.1.1",
    "jest-enzyme": "^4.0.2",
    "regenerator-runtime": "^0.11.1",
    "webpack-dev-server": "^2.11.1"
  },
  "scripts": {
    "test": "jest",
    "test-watch": "jest --watch"
  },
  "jest": {
    "setupTestFrameworkScriptFile": "./node_modules/jest-enzyme/lib/index.js",
    "moduleNameMapper": {
      "\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$": "<rootDir>/test/javascript/__mocks__/fileMock.js",
      "\\.(css|scss|less)$": "<rootDir>/test/javascript/__mocks__/styleMock.js"
    },
    "roots": [
      "app/javascript/packs",
      "test/javascript"
    ],
    "moduleDirectories": [
      "node_modules",
      "app/javascript/packs"
    ]
  }
}
```

after a couple of other problems that we discovered later and had to handle as well.

## Bonus - running JS tests on CircleCI 2.0

This also turned out to be a bit more tricky than I expected. The reason for that is that running assets pre-compilation (asset pipeline+webpack via webpacker integration) or running tests uninstalled `devDependencies` and then we could not run `jest` because there was no such binary. Rails probably called `yarn` with some options which lead to uninstalling `jest`. I totally did not expect that behavior.

Here is our current config:

```yaml
version: 2
jobs:
  build:
    docker:
      - image: circleci/ruby:2.2.7-node
        environment:
          RAILS_ENV: test
      - image: circleci/mysql:5.5
        environment:
          - MYSQL_ROOT_PASSWORD=ubuntu
          - MYSQL_DATABASE=myapp-test
      - image: elasticsearch:1.4.5

    working_directory: ~/repo

    steps:
      - checkout
      - run: mkdir -p tmp/
      - run: mkdir -p ~/ftp/

      - restore_cache:
          keys:
          - v2-project-{{ checksum "Gemfile.lock" }}
          - v2-project-

      - run:
          name: install dependencies
          command: |
            bundle install --jobs=4 --retry=3 --path bundled-gems

      - save_cache:
          paths:
            - bundled-gems
          key: v2-project-{{ checksum "Gemfile.lock" }}

      - run: bundle exec rake db:create
      - run: bundle exec rake db:schema:load
      - run: bundle exec rake assets:precompile

      - run:
          name: run tests
          command: |
            ./bin/rails t

      - restore_cache:
          keys:
          - yarn-npm-packages-2-{{ checksum "yarn.lock" }}
          - yarn-npm-packages-2-

      - run:
          name: install js dependencies
          command: |
            yarn install --cache-folder ~/.cache/yarn --production=false

      - save_cache:
          paths:
            - ~/.cache/yarn
          key: yarn-npm-packages-2-{{ checksum "yarn.lock" }}

      - run:
          name: run js tests
          command: |
            yarn test
```

I think eventually I will either move JS testing before assets pre-compilation and rails testing. Alternatively, I am going to split this one long job into a workflow with two separate jobs. Especially considering that 90% of commands (some not listed for clarity) do not affect JS testing at all.

Another thing that trolled me a little was setting `NODE_ENV` globally to `production`, which I tried in the beginning. This caused more issues than problems that it solved. Do no do it 😉

That's it folks. Please **test your JavaScript**.

P.S. I hope at least some of those configs won't be necessary with [Webpack 4 more configless approach](https://twitter.com/jdalton/status/951250082791227392).

## Read more

If you enjoyed that story, [subscribe to our newsletter](http://arkency.com/newsletter). We share our everyday struggles and solutions for building maintainable Rails and React apps which don't surprise you.

Also worth reading:

* [How we've updated React by Example from React 0.13 to 16.0](http://reactkungfu.com/2017/11/how-weve-updated-react-by-example-from-react-0-dot-13-to-16-dot-0/) - React by Example as a book is focused on 12 different examples of UI widgets. Every chapter is a walkthrough on implementing such component, whether it’s a password strength meter or article list with voting. Some time ago we updated its code to React 16.
* [Diving into ant-design internals: Button](http://reactkungfu.com/2017/03/diving-into-ant-design-internals-button/) - Check out how ant, one of the biggest collection of cohesive React components, implemented interesting features in their buttons.
* [Dynamic JSX tags](http://reactkungfu.com/2016/11/dynamic-jsx-tags/) - very quick protip how to achieve conditional JSX tags with much shorter syntax.
* [Mapping declarative React components to imperative external API.](http://reactkungfu.com/2016/02/mapping-declarative-react-components-to-imperative-external-api/) - Did you like Netflix article on _Integrating imperative APIs into a React application_? Check out our similar approach to a similar problem.

And don't forget to check out our React books [Rails meets React](https://blog.arkency.com/rails-react/) and [React.js by example](http://reactkungfu.com/react-by-example/). Both helped thousands of React and Rails developers.
