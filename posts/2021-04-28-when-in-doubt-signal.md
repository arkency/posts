---
title: When in doubt, signal!
created_at: 2021-04-28T22:14:57.836Z
author: Jakub Kosiński
tags: ["javascript", "react", "fetch", "hooks"]
publish: true
---

When you are writing frontend applications you often need to fetch some data. Sometimes, especially when you're working with a single-page app, some requests could be cancelled as you would not use the response anywhere, e.g. when your visitor clicks on some link and changes the page during the pending request that would no longer be needed on the next page.
If you are using `fetch` to perform AJAX requests, you can use [`AbortController`](https://developer.mozilla.org/en-US/docs/Web/API/AbortController) to cancel pending requests in such situations.

`AbortController` and `AbortSignal` are features [available in most modern browsers](https://caniuse.com/?search=AbortController), there are also some [polyfills](https://www.npmjs.com/package/abortcontroller-polyfill) 
available for those unfortunates who need to support IE.

# Usage

Using `AbortController` to cancel `fetch` requests is easy. You just need to create a controller instance and pass it's `signal` property to `fetch`. Then, when you need to abort a request, you just need to call the `abort()` method:

```js
const controller = new AbortController();
const request = fetch("/api/something", {signal: controller.signal});

// ...

controller.abort()
```

Once you call `controller.abort()`, the signal passed to the `fetch` call will cancel the request and throw an `AbortError`. You can catch it using regular `try {} catch (e) {}` block:

```js
try {
  performCancellableRequest()
} catch (error) {
  if (error.name === "AbortError") return; // ignore cancelled requests
  errorReporting.notify(error);
}
```

# React hook

If you are using React in your application, you can write a simple hook that will encapsulate all logic related with `AbortController` for easier request handling:

```js
import {useEffect} from "react";

export default function useSignal(dependencies = []) {
  const controller = new AbortController();
  useEffect(() => () => controller.abort(), dependencies);
  return controller.signal;
}
```

This hook could be used in your function component that is fetching some data. When such component is unmounted, all pending requests will be cancelled. You should remember to handle the `AbortError` in your state management so that you won't update the state when your component is unmounted. An example component might look like this:

```js
import {useCallback, useEffect, useState} from "react";
import useSignal from "./useSignal";

export default function Profile() {
  const [profile, setProfile] = useState(null);
  const signal = useSignal();
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch("/api/profile", {signal});
      setProfile(await response.json());
    } catch (error) {
      if (error.name !== "AbortError") throw error;
    }
  }, [])
  useEffect(() => {
    fetchData();
  }, []);
  
  if (!profile) return <div>Loading...</div>;
  
  return <div>Your name: {profile.name}</div>;
}
```

With such implementation you'll fetch the data on initial render and call `setProfile` only if the request was successful. If you unmount the component, the request will be cancelled an `AbortError` will be catched and ignored (so you won't try to update the state of an already unmounted component). As we are throwing all errors other than `AbortError`, you should wrap your component with an [Error Boundary](https://reactjs.org/docs/error-boundaries.html)
to prevent crashes in case of any other error that might occur during fetching the data.
