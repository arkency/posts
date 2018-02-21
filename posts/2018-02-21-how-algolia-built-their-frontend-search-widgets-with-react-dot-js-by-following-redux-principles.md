---
title: "How Algolia built their frontend search widgets with React.js by following redux principles"
created_at: 2018-02-21 17:00:00 +0200
kind: article
publish: true
author: Robert Pankowecki
tags: [ 'search', 'algolia', 'rails', 'react' ]
newsletter: :arkency_form
---

When Algolia built their first version of Frontend Search Component called Instantsearch.js I was not particularly fond of this solution.

<!-- more -->

Some parts of our integration looked like this:

```javascript
this.search.addWidget(
  DateRangeFilter({
    container: '#start_date_filter',
    attributeName: 'starts_at',
  })
);

this.search.addWidget(
  InstantSearch.widgets.pagination({
    container: '#pagination',
    cssClasses: {
      root: 'pagination pagination-centered'
    }
  })
);

this.search.addWidget(
  InstantSearch.widgets.searchBox({
    container: '#new_search',
    autofocus: false,
  })
);

this.search.addWidget(new GaIntegration());

this.search.addWidget(
  new WhenFilter({
    container: '.menu_filter_date'
  })
);
```
Or this:

```javascript
this.search = InstantSearch({
  appId: options.app_id,
  apiKey: options.api_key,
  indexName: options.index_name,
  urlSync: {
    mapping: {
      q:   'text',
      p:   'page',
      hFR: 'filter',
    },
    trackedParameters: [
      'query',
      'page',
      'attribute:category',
      'attribute:date',
      'attribute:minPrice',
      'aroundLatLng',
      'aroundRadius'
    ],
  },
  searchFunction: (helper) => {
    this.queries += 1;
    if (!window.location.pathname.includes("newfrontpage") && this.queries > 1) {
      history.pushState({}, "Search", `/newfrontpage${window.location.search}`);
    }
    if (this.isNonEmptySearch(helper.state)) {
      this.queries += 1;
    }
    helper.search();
    this.timeSearchToGoogle()
  },
  searchParameters: {
    disjunctiveFacetsRefinements: {
      country: [this.country],
    },
    filters: 'public:true',
    facetsRefinements: this.facetsRefinements,
    facets: ['country'],
  }
});
this.setup();
}
```

I found it very hard to follow what's going on and to build a mental model on how the solution works. The more custom logic search logic and custom components you wanted to add the more slippery it felt. Those available components were good, but extending the solution felt hard. On the good side, these components and APIs still work properly years after we've built them so that's nice.

However, sometime later when I wanted to implement a new search solution for another customer, I was pleasantly surprised with what they did with their 3rd generator of components called (no surprise) react-instantsearch .

I believe they learned their lesson on how much state they need to juggle from having all those components and that when their customers want to extend the search with even more components it would be nice to keep the state in the same place and unify the solution. Also, every time the state changes it's likely that some HTTP requests need to be made to get a fresh list of search results. Not to mention that some component's state needs to be updated when the new results come (ie to display the number of available results, or refresh pagination or list of available categories and so on).

It's no wonder to me that they decided to use react and follow the redux principles to implement the new solution. You can see that when browsing the code of react-instantsearch package.

```bash
$ pwd
node_modules/react-instantsearch/src

$ ls -1
components
connectors
core
widgets
```
The whole solution is based on `core` which contains ie `createStore.js` and `InstantSearch.js` and `createInstantSearchManager.js` etc, and then you have `components` which are just presentational components without the logic.

```bash
$ ls -1 components/

Breadcrumb.js
ClearAll.js
Configure.js
CurrentRefinements.js
HierarchicalMenu.js
Highlight.js
Highlighter.js
Hits.js
HitsPerPage.js
InfiniteHits.js
Link.js
LinkList.js
List.js
Menu.js
MultiRange.js
Pagination.js
Panel.js
PoweredBy.js
RangeInput.js
RefinementList.js
ScrollTo.js
SearchBox.js
Select.js
Snippet.js
SortBy.js
StarRating.js
Stats.js
Toggle.js
classNames.js
index.js
```

I bet that even if you look at _compiled_ sources of those files you can still pretty much understand how they look like and what they display. Here is an extract from `Stats.js` file. `Stats` component displays how many results were found and how quickly.

```javascript
_createClass(Stats, [{
  key: 'render',
  value: function render() {
    var _props = this.props,
        translate = _props.translate,
        nbHits = _props.nbHits,
        processingTimeMS = _props.processingTimeMS;

    return _react2.default.createElement(
      'span',
      cx('root'),
      translate('stats', nbHits, processingTimeMS)
    );
  }
}]);
```

Then there are `connectors`.

```bash
$ ls -1 connectors/
connectAutoComplete.js
connectBreadcrumb.js
connectConfigure.js
connectCurrentRefinements.js
connectHierarchicalMenu.js
connectHighlight.js
connectHits.js
connectHitsPerPage.js
connectInfiniteHits.js
connectMenu.js
connectMultiRange.js
connectPagination.js
connectPoweredBy.js
connectRange.js
connectRefinementList.js
connectScrollTo.js
connectSearchBox.js
connectSortBy.js
connectStateResults.js
connectStats.js
connectToggle.js
```

Connectors are higher order components. They encapsulate the logic for a specific search concept and they provide a way to interact with the whole Instantsearch solution.

You can use them when you want to customize the UI or display some components using a different toolkit or library like [Material UI](http://www.material-ui.com/#/) or [Antd](https://ant.design/docs/react/introduce). For example if you you don't like that fact that `<Hits>` widget creates a `<div>` tag to wrap all results into, you can create a custom component to render the search results which uses `<ul>` tag and use the `customHits` connector to subscribe for data changes to update when there are new search results available.

```jsx
const CustomHits = connectHits(({ hits }) =>
<ul>
  {hits.map(hit =>
    <li key={hit.objectID}>
      <Highlight attributeName="description" hit={hit} />
    </li>
  )}
</ul>
```

You can find this connectors documented at https://community.algolia.com/react-instantsearch/connectors/connectHits.html and also check out the others.

And then there are `widgets`.

```bash
$ ls -1 widgets/

Breadcrumb.js
ClearAll.js
Configure.js
CurrentRefinements.js
HierarchicalMenu.js
Highlight.js
Hits.js
HitsPerPage.js
InfiniteHits.js
Menu.js
MultiRange.js
Pagination.js
Panel.js
PoweredBy.js
RangeInput.js
RangeSlider.js
RefinementList.js
ScrollTo.js
SearchBox.js
Snippet.js
SortBy.js
StarRating.js
Stats.js
Toggle.js
```

Widgets are container components (presentational components connected using the connectors). They provide the out of box working experience that makes building the search page so fast.

Here is for example a Menu widget which can be used to filter categories etc https://community.algolia.com/react-instantsearch/widgets/Menu.html and you can have a look how it works at https://community.algolia.com/react-instantsearch/storybook/?selectedKind=Menu&selectedStory=default&full=0&addons=1&stories=1&panelRight=1&addonPanel=storybooks%2Fstorybook-addon-knobs

Now that's something I can understand much more easily then what they had in their first solution :) It's a really flexible solution which provides a lot of out of box working functionality but also allows you to change some of the gears without reimplementing everything.

And if you ever feel the need to implement a custom component because those provided are not good enough you can do it too. You basically need to implement 3 methods:

* one for updating the state when someone clicks your component,
* one for defining how the state of your component affects the search query,
* and the last one for mapping a part of the state to the props of your custom component.

That's just React and Redux you already know and like.

And all together the code looks this way at the end:

```jsx
const App = ({indexName}) => {
  return <InstantSearch
    appId="..."
    apiKey="..."
    indexName={indexName}
  >
    <SearchBox />
    <Configure
      hitsPerPage={12}
    />
    <SortBy
      items={[
        {value: indexName, label: 'Best match'},
        {value: startsAtAscIndexName, label: 'Show earliest'},
      ]}
      defaultRefinement={indexName}
    />
    <When />
    <RefinementList attributeName="category" />
    <EventHits />
    <Pagination/>
  </InstantSearch>
};
```
