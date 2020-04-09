---
title: "Loading all data when starting Flux SPA"
created_at: 2016-01-22 13:39:27 +0200
kind: article
publish: true
author: Rafał Łasocha
tags: [ 'react', 'flux', 'altjs' ]
newsletter: react_books
img: "loading-all-data-when-starting-flux-spa/header.jpg"
---

<p>
  <figure>
    <img src="<%= src_fit("loading-all-data-when-starting-flux-spa/header.jpg") %>" width="100%">
  </figure>
</p>

Recently we've been working on an application which is a typical SPA which uses the Flux approach.

After some time we had a problem that besides our frontend being SPA, **each time we clicked on link leading to some "page", we're loading data again, even if this data was loaded before**. We've decided that the simplest solution would be to load all data in the beginning and display an animation when it's loading.

In the future when necessity to hit refresh each time we want fresh data would become troublesome we could simply add Pusher-like solution to update data in real-time.

In this post I want to present you solution how our implementation looked like. In our application we are using ES6 (using Babel) and [alt.js](http://alt.js.org/) as a library delivering Flux features.

<!-- more -->

We can assume that this is the application for managing blog, so we have only two resources: posts and comments.

## The Store

Firstly we will define a store, which will keep information which data we've already loaded.

```javascript

class InitialStateStore {
  constructor() {
    this.bindListeners({
      postsLoaded:    PostsActions.allMyPostsFetchedSuccessfully,
      commentsLoaded: CommentsActions.allMyCommentsFetchedSuccessfully,
    })
    this.on('init', () => {
      this.reset()
    })
  }

  postsLoaded(response) {
  }

  commentsLoaded(response) {
  }

  reset() {
    this.loadedData = Immutable.Map({
      posts:    false,
      comments: false,
    })
  }
}

export default alt.createStore(InitialStateStore);
```

Code above is a sketch of our alt.js Store. Here we only say, that when an action `PostsActions.allMyPostsFetchedSuccessfully` will be triggered, our Store has to call `postsLoaded` method. **This action will be triggered already when response with posts' data arrive from the server.**

Moreover a `reset` method is defined. It's called in `init` callback, so just after our Store will initialize. We want only to set default state here. `loadedData` Map will keep information which resources are already loaded. Our flow will look like this:

* We send somewhere (we'll cover it later) two requests to our backend, one of them fetches all posts, second one fetches all comments.
* When response from server come, it calls `PostsActions.allMyPostsFetchedSuccessfully` action. Similar one for comments.
* We "mark" that we've already loaded this data in our Store by setting `posts` key of `loadedData` Map to `true`. (Similarly with comments)
* If all values in `loadedData` are `true` it means we've loaded all data and we can do something with it - for example turn off loading animation turned on before.

Here's the code where we set corresponding keys after receiving responses from the server:

```javascript

class InitialStateStore {
  //...

  postsLoaded(response) {
    this.setState({
      loadedData: this.loadedData.set('posts', true),
    })
    this.checkIfDataLoaded()
  }

  commentsLoaded(response) {
    this.setState({
      loadedData: this.loadedData.set('comments', true),
    })
    this.checkIfDataLoaded()
  }
  
  //...
}
```

Now the last one, the `checkIfDataLoaded()` function. As I've said before **when all data are loaded we want to trigger something - in this case it will be an action which will in result hide loading animation**. Note our action is called `finishedLoading` - we'll define it in a while.

```javascript

class InitialStateStore {
  // ...

  checkIfDataLoaded() {
    let loadedDataAllTrue = this.loadedData.valueSeq().every((v) => { return v; })
    if (loadedDataAllTrue) {
      setTimeout(() => {
        InitialStateActions.finishedLoading()
      })
    }
  }
  
  //...
}
```

<%= show_product_inline(:kung_fu) %>

## The Actions

Here we've implementation of our actions.

* `startLoading` is an action called somewhere in code. It means "start loading all this initial data". I'll not cover implementation of `Api` as it's fairy simple class returning [Promises](http://blog.arkency.com/2015/02/the-beginners-guide-to-jquery-deferred-and-promises-for-ruby-programmers/).
* `finishedLoading` is an action called after all data is loaded.

```javascript

class InitialStateActions {
  startLoading() {
    Api.fetchAllPosts().then((response) => {
      PostsActions.allMyPostsFetchedSuccessfully(response)
    })
    Api.fetchAllComments().then((response) => {
      CommentsActions.allMyCommentsFetchedSuccessfully(response)
    })
    this.dispatch()
  }

  finishedLoading() {
    this.dispatch()
  }
}

export default alt.createActions(InitialStateActions);
```

As you can see declaring actions in alt.js is pretty easy, it's just ES6 class. Actions are methods but only methods containing `this.dispatch()` will be dispatched.

## Missing details

Now you can ask where to call `InitialStateActions.startLoading()` action?
I'll not cover it with code here, as it belongs more to the topic about authentication. In our application, there are two cases which trigger this action:

* After we receive response from server, that our login is successful - so we have authentication token and may safely download data from server
* When we load login data (user id and authentication token) from cookies - because we've authenticated before

Other missing piece is a loading spinner - thanks to Flux we can also pretty much decouple it from the initial state loader. In our case, we've a `LoaderStore` which solely purpose is managing loading spinner. It's so short and simple I can even include it whole below:

```javascript

class LoaderStore {
  constructor() {
    this.bindListeners({
      show: InitialStateActions.startLoading,
      hide: InitialStateActions.finishedLoading,
    })
    this.on('init', () => {
      this.loading = false;
    })
  }

  show() { this.setState({loading: true}); }
  hide() { this.setState({loading: false}); }
}
```

## Summary

Now, it's pretty much it. As I said above, only things you need to customize is when you call the `InitialStateActions.startLoading()` action in your application and how you display the loading spinner.

As you can see, this solution is pretty generic. It doesn't interfere with other stores, which makes our application easier to reason about. It follows flux-way of doing things, introducing `InitialStateStore` allowed us to remove all `fetchFoo` methods scattered around our React components. This in the end lead to the simpler design of the overall app.
