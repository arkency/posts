---
title: "Why we use React.js in our Rails projects"
created_at: 2014-07-17 12:01:00 +0200
publish: true
author: Wiktor Mociun
tags: [ 'front end', 'react', 'javascript' ]
newsletter: react_books
---

<p>
  <figure>
    <img src="<%= src_fit("react/cover.jpg") %>" width="100%">
    <details>
      Source: <a href="https://www.flickr.com/photos/subpra/">Subramanya Prasad</a>
    </details>
  </figure>
</p>

Programming interactive user interfaces using JavaScript might be a tough task. User calls some action and we need to update his view - manipulating DOM using tool like jQuery. It just doesn't feel *good enough* to modify document's elements by hand. It is also really hard to re-use already written parts of UI and compose them with each other.

Imagine if there was one tool, that would solve all these problems and **help you deliver your front-end much faster**. What if you didn't have to worry about this whole DOM stuff when you just want to update the view?

How would you feel being as efficient as when developing your Rails backend, when it comes to user interface?

Here comes React.js!

<!-- more -->

## Our experience with React
Recently in Arkency, we were experimenting with Facebook's library called React.js. Its only responsibility is to build composable and reactive user interfaces. The power of this tool comes from its simplicity. Learning curve of React is very low, so any new developer comming to project based on React, had no problems with jumping in.

In projects, where we adopted React, we noticed good things happening.
The first and the most important, **We shipped our front-end significantly faster**. We could write really complex UI parts and easily compose with each other.
Second, as our apps grew, we improved our code maintainability. Spending less time on maintaining code means more time spent on delivering business value for our customers.

## A little bit of theory
React objects are called *components*. Each of them may contain data and renders view in a declarative way - based only on current data state.

Each React component has 2 inputs:

 * props - shortcut of *properties*, these are mean to be **immutable**
 * state - **mutable**

After changing the state, React will automatically re-render the component to answer a new input.

In addition, all React components must implement *render* method, which must return another React object or null (from version 0.11).

## See it in action!
Assume that we got to create a list of books with a dynamic search.

<p>
  <figure align="center">
    <img src="/assets/images/react/box.png">
  </figure>
</p>

First, we should create a simple book component that represent single book on a list.

```coffeescript

BooksListItem = React.createClass
  render: ->
    React.DOM.li({}, @props.book.name)
```

To build HTML structure I used built-in React.DOM components, which corresponds to standard HTML elements. In first argument, I pass the empty **props object**, the second one is just the content of my &lt;li&gt; tag.

Moving on to the full list of Book items


```coffeescript

BooksList = React.createClass
  render: ->
    React.DOM.ul({className: 'book-list'}, [
      for book in @props.books
        BooksListItem({book: book})
    ])
```

Ok, we are able to display list of books. Now it is high time to implement search. Let's modify our *BooksList* component. We need to add form input and handle its changes.

```coffeescript

BooksList = React.createClass
  #Component's API method
  getInitialState: ->
    search: ''

  setSearch: (event) ->
    @setState search: event.target.value

  books: ->
    @props.books.filter(
      (book) => book.name.indexOf(@state.search) > -1
    )

  render: ->
    # Wrapper that contains another components
    React.DOM.div({},
      @searchInput()
      @booksList()
    )

  searchInput: ->
    React.DOM.input({
      name: 'search'
      onChange: @setSearch
      placeholder: 'Search...'
    })

  booksList: ->
    React.DOM.ul({}, [
      for book in @books()
        BooksListItem({book: book})
      ])
```

Summing it up, you can see the result in a frame below

<iframe style="margin-bottom: 20px;" width="100%" height="190" src="https://jsfiddle.net/E62BD/1/embedded/result,js,html" frameborder="0"></iframe>

That's all you need. After you type something into search input, React will automatically re-render the book list to contain only filtered items.

## Getting to an end

Compared to another solutions, you won't spend much time learning React. You should really **give it a shot** in your project.

If you look for more information on React, check out [official docs](http://facebook.github.io/react/docs/getting-started.html) and sign-up for our newsletter below. We are going to write more about React.js
