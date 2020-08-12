---
created_at: 2015-03-02 17:15:52 +0100
publish: true 
author: Marcin Grzywaczewski
tags: [ 'front end', 'architecture' ]
img: "you-dont-need-to-wait-for-backend-decisions-and-consequences/img.jpg"
newsletter: react_books
---

# You don't need to wait for your backend: Decisions and Consequences

<p>
  <figure>
    <img src="<%= src_fit("you-dont-need-to-wait-for-backend-decisions-and-consequences/img.jpg") %>" width="100%">
    <details>
      <a href="https://www.flickr.com/photos/56218409@N03/15071173824">Photo</a> 
      remix available thanks to the courtesy of
      <a href="https://www.flickr.com/photos/56218409@N03">mripp</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

**As front-end developer your part is often to provide the best possible experience for your application’s end-users**. In standard Rails application everything is rather easy - user clicks on the submit button and waits for an update. User then sees fully updated data. **Due to async nature of dynamic front-ends it is often missed what happens in the ‘mid-time’ of your user’s transaction** - button is clicked and user waits for some kind of notification that his task is completed. What should be displayed? What if a failure occurs? There are at least two decisions you can take to answer those questions.

<!-- more -->

## Decision #1: Wait for backend, then update.

The most common solution is to **update your front-end if and only if backend notifies us that particular user action is successful**.

It is often the only choice to solve consistency problem - there are actions that have effects we unable to compute on front-end due to lack of required information. Consider sign in form - we can’t be sure user signed in or not before the backend finishes its logic.

Implementation often is rather straightforward - we just make some AJAX call, wait until a promise is resolved (you can read about it in more detail [here](http://blog.arkency.com/2015/02/the-beginners-guide-to-jquery-deferred-and-promises-for-ruby-programmers/)) and then perform an update to your views.

### Example:

Imagine you have a simple to-do list application - one of its functions is that users can add a task to it. There is an event bus where you can subscribe to events published by your view. Your data is stored within the `ReadModel` object - you can ask it to return current list of tasks and update it via `addTask` method. Such updates automatically updates the view.

Your `Dispatcher` (`Glue`) class can look like this:

```coffeescript

class Dispatcher
  constructor: (@eventBus, @commands, @readModel, @flashMessages) ->
    @eventBus.on('addTask', (taskText) ->
      response = @commands.addTask(taskText)
      response
        .success((json) => @readModel.addTask(json.id, taskText))
        .fail(=> @flashMessages.error("Failed to add a task."))
    )
```

Here you wait for your `addTask` command to finish - it basically makes a POST request to your Rails backend and the task data is returned via JSON. You definitely saw this pattern many times - it is the most ‘common’ way to handle updates.

### Pros:

* **Implementation is simple** - there are no special patterns you’d need to introduce.
* **It aligns well with Rails conventions** - let’s take a small part of the code introduced above:

    ```coffeescript
    (json) =>  @readModel.addTask(json.id, taskText)
    ```
  
    As you may see, ID of the given task is returned inside JSON response. Basically such pattern is provided by convention in a typical Rails app - primary keys are given from your database and such knowledge must be propagated from a backend to a frontend. Handling such use cases in “Wait for backend, then update” method requires no change in Rails conventions at all.

* **All front-end data is persisted** - there is no problem with ‘bogus’ data that may be introduced only on front-end. That means you can only have fewer data than on backend at any time.

### Cons:

* **Feedback for the user is delayed** - an user is still forced to wait for completion of his task before a proper feedback is provided. This solution makes our front-end a less responsive.
* **Developers are forced to provide and maintain different kind of visual feedback** - waiting without a visual feedback is not enough. If completing an action needs a considerate amount of time, providing no visual feedback would force an user to repeat his requests (usually by hitting button twice or more) because such time would be misinterpreted as “app doesn’t work”.

    That means we need to implement yet another solution - the most common “hacks” here is disabling inputs, changing value of the button to something like “Submitting…”, providing some kind of “Loading” visual indicator etc. Such ‘temporal’ solution must be cleaned up after failure or success. Errors with not cleaning up such ‘temporal’ visual feedbacks is something that users directly see and it is often very annoying for them - they just see that something “is broken” here!
* **It is hard to go with ‘eventual consistency’ with this approach** -  and with today requirements it’s a big chance you’d want to do so. If you implement your code with “wait for backend, then update” it can be hard to make architecture ready for “offline mode”, or to defer synchronisation (like with auto-save feature).


### Tips:

* You can use [Reflux stores](https://github.com/spoike/refluxjs) to easily “bind” read model updates to your React components.
* Promises help if one business action involves many processes which needs to be consulted with back-end or some external tool. You can use `$.when` to wait for many promises at once.
* If you structure your code using store approach encouraged by Flux, it is good to provide some kind of `UserMessageStore` and `IntermediateStateStore` to centralize your visual feedbacks.
* You can listen for `ajaxSend` “events” to provide the simplest visual feedback that something is being processed on backend. This is a simple snippet of code you may use to your needs (using jQuery):

    ```coffeescript
    UPDATE_TYPES = ['PUT', 'POST', 'DELETE']
    $.activeTransforms = 0

    $(document).ajaxSend (e, xhr, settings) ->
        return unless settings.type?.toUpperCase() in UPDATE_TYPES
        $.activeTransforms += 1

    $(document).ajaxComplete (e, xhr, settings) ->
        return unless settings.type?.toUpperCase() in UPDATE_TYPES
        $.activeTransforms -= 1
    ```

    We bind to `ajaxSend` and `ajaxComplete` “events” to keep track of number of active AJAX transactions. You can then query this variable to provide some kind of visual feedback. One of the simplest is to provide an alert when the user wants to leave a page:

    ```coffeescript
      $(window).on 'beforeunload', ->
        if $.activeTransforms
          '''There are some pending network requests which
             means closing the page may lose unsaved data.'''
    ```

## Decision #2: Update, then wait for backend.

You can take the another approach to provide as fast feedback for an end-user as possible. **You can update your front-end and then wait for backend to see whether an action succeeds or not**. This way your users get the most immediate feedback as possible - at the cost of more complex implementation.

This approach allows you to totally decouple the concern of *doing* an action from *preserving* its effects. It allows you a set of very interesting ways your front-end can operate - you can defer the backend synchronisation as long as you like or make your application ‘offline friendly’, where an user can take actions even if there is no internet connection. That’s the way many mobile applications work - for example I can add my task in [Wunderlist](https://www.wunderlist.com/) app and it’ll be synced if there will be an internet connection available - but I have my task stored and can review it any time I’d like.

There is also a hidden effect of this decision - if you want to be consistent with this approach you’re going to put more and more emphasis on front-end, making it richer. **There is a lot of things you can do without even consulting backend - and most Rails programmers forget about it.** With this approach moving your logic from backend to front-end comes naturally.

### Example:

In this simple example there is little you have to do to make implementation with this approach:

```coffeescript
class Dispatcher
  constructor: (@eventBus, @commands, @readModel, @flashMessages, @uuidGenerator) ->
    @eventBus.on('addTask', (taskText) ->
      uuid = @uuidGenerator.nextUUID()
      @readModel.addTask(uuid, taskText)
      @commands.addTask(uuid, taskText)
        .fail(=> 
          @readModel.removeTask(uuid)
          @flashMessages.error("Failed to add a task.")
        )
    )
``` 

As you can see, there are little changes with this approach:

* There is a new dependency called `uuidGenerator`. Since we’re adding a task as fast as possible we can’t wait for an ID to be generated on backend - now the front-end assigns primary keys to our objects.
* Since when something went wrong we need to *compensate* our action now, there is a new method called `removeTask` added to our read model. It is not a problem when there is also a feature of removing tasks - but when you add such method only for compensating an action I’d consider it a code smell.

The most interesting thing is that you can take `@commands` call and move it to completely different layer. You can add it to a queue of ‘to sync’ commands or do something more sophisticated - but since there is immediate feedback for an user you can make it whenever you like.

### Pros:

* **It makes your front-end as responsive as possible** - your clients will be happy with this solution. It makes your users having more ’desktop-like’ experience while working with your front-end.
* **It makes communication with backend more flexible** - you can make a decision to communicate with backend immediately or defer it as long as you’d like.
* **It is easy to make your app working offline** - since we’re taking  an action immediately already the all you need is turning off external services while working in offline mode and add it to some queue to make this communication when you come online again.
* **It makes your front-end code richer** - if it is your goal to move your logic to a front-end, making this decision *forces* you to move all required logic and data to a frontend while implementing an user interaction.
* **It’s easier to make your commands ‘pure’** - if you are refactoring your backend to [CQRS architecture](http://martinfowler.com/bliki/CQRS.html) there is a requirement that your commands should return no output at all. With updating on a front-end and removing a necessity of consulting each action effect with backend (generating UUID on a front-end is one of major steps towards it) you can easily refactor your POST/PUT/PATCH/DELETE requests to return only an HTTP header and no data at all.
* **You can reduce overhead of your backend code** - since you are not making a request immediately, you may implement some kind of batching or provide another way to reduce number of requests made by an user to your service. This way you can increase throughput of your backend, which can be beneficial if you are experiencing performance issues.

### Cons:
* **It can be hard to compute an effect of an action on front-end** - there are some types of actions which can be hard to do without consulting backend - like authentication. **Everywhere where data needed to compute a result is confidential it’s much easier to implement a code which consults with backend first**.
* **Implementation is harder** - you need to implement compensation of an user action which can be hard. There is also a non-trivial problem of handling many actions in sequence - if something in the middle of such ‘transaction’ fails, what you should do? Also there can be situations where implementing compensation without proper patterns can make your code less maintainable.
* **It’s harder to achieve data consistency this way** - in the first approach there is no way that you can have an ‘additional’ data on the front-end which is out of sync with your backend - you can only have less data than on backend. In this approach it is harder - you may have data which are not on a backend, but they exist on your frontend. **It is your job to make your code eventually consistent - and it is harder to do so in this approach**.
* **You need to modify your backend** - solutions needed to implement this approach well, like UUID generation needs to go against Rails conventions - you’ll need to write some backend code to support it.

### Tips:

* You can benefit greatly with backtracking that immutable data structures provide. Since each mutation returns new collection in this approach, if you make your state immutable it is easier to track “history” of your state and rollback accordingly if something fails. There is a library called [ImmutableJS](https://github.com/facebook/immutable-js) which helps you with implementing such pattern.
* To avoid a code smell with creating methods just to compensate failures, you can refactor your commands to a [Command pattern](http://en.wikipedia.org/wiki/Command_pattern). You can instantiate it with data it needs and provide an `undo` method you call to compensate an effect of such command.

    Here is a little example of this approach:

    ```coffeescript
    class Commands
      constructor: (@readModel) ->

      addTask: (uuid, taskText) ->
        new AddTaskCommand(@readModel, uuid, taskText)

    class AddTaskCommand
      constructor: (@readModel, @uuid, @taskText) ->

      call: ->
        # put your addTask method body here.

      undo: ->
        # logic of compensation

     # in our dispatcher:
      @eventBus.on('addTask', (taskText) ->
        uuid = @uuidGenerator.nextUUID()
        @readModel.addTask(uuid, taskText)
        command = @commands.addTask(uuid, taskText)
        command.call().fail(command.undo)
      )
    ```

    That way you ‘enhance’ a command with knowledge about ‘undoing’ itself. It can be beneficial if logic you need to implement is valid only to compensate an event - this way your other code can expose interface usable only for doing real business actions, not reversing them.
* In sophisticated frontends it is a good step to build your domain object state from domain events. This technique is called “event sourcing” and it aligns well with idea of ‘reactive programming’. I just want to signal it is possible - [RxJS](https://github.com/Reactive-Extensions/RxJS) is a library which can help you with it.

## Conclusion

**Decisions you can make to handle effects of user actions can have major consequences with your overall code design**. Knowing those consequences is a first step to make your front-end maintainable and more usable for your users. Unfortunately, there is no silver bullet. **If you are planning to make your front-end richer and want to decouple it from backend as much as possible it is great to try to go with “update first” approach** - it has many consequences which “pushes” us towards this goal. But it all depends on your domain and features. I hope this post will help you with making those decisions in a more conscious way.

Do you have some interesting experience on this field? Or you have a question? Don’t forget to leave a comment - I’ll be more than happy to discuss with you!
