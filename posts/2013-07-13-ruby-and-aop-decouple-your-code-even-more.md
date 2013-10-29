---
title: "Ruby and AOP: Decouple your code even more"
created_at: 2013-07-13 17:16:03 +0200
kind: article
publish: true
newsletter: :aar
author: Marcin Grzywaczewski
tags: [ 'ruby', 'AOP' ]
---

We, programmers, care for our applications' design greatly. We can spend
hours arguing about solutions that we dislike and refactoring our code to
loose coupling and weaken dependencies between our objects.

Unfortunately, there are Dark Parts in our apps - persistence,
networking, logging, notifications... these parts are scattered in our code - 
we have to specify explicit dependencies between them and domain objects.

Is there anything that can be done about it or is the real world a nightmare for purists?
Fortunately, a solution exists.
Ladies and gentlemen, we present aspect-oriented programming!

<!-- more -->

## A bit of theory

Before we dive into the fascinating world of AOP, we need to grasp some concepts
which are crucial to this paradigm.

When we look at our app we can split it into two parts: <strong>aspects</strong>
and <strong>components</strong>. Basically, components are parts we can easily
encapsulate into some kind of code abstraction - a methods, objects or procedures.
The application's logic is a great example of a component. 
Aspects, on the other hand, can't be simply isolated in code - they're things
like our Dark Parts or even more abstract concepts - such as 'coupling' or 'efficiency'. 
Aspects cross-cut our application - when we use some kind of persistence (e.g. a database) or network communication (such as ZMQ sockets) 
our components need to know about it.

Aspect-oriented programming aims to get rid of cross-cuts by separating
<i>aspect code</i> from <i>component code</i> using injections of our aspects in certain <i>join points</i>
in our component code. The idea comes from Java community and it may sound a bit scary at first
but [before you start hating](http://andrzejonsoftware.blogspot.com/2011/07/stop-hating-java.html) - 
read an example and everything should get clearer.

## Let's start it simple

Imagine: You build an application which stores code snippets. You can start one of the usecases this way:

```
#!ruby
class SnippetsUseCase
  attr_reader :repository, :logger, :snippets

  def initialize(snippets_repository = SnippetsRepository.new, logger = Logger.new)
    @repository = snippets_repository
    @logger = logger

    @snippets = []
  end

  def user_pushes(snippet)
    snippets << snippet

    repository.push(snippet, 
                    success: self.method(:user_pushed),
                    failure: self.method(:user_fails_to_push))
  end

  def user_pushed(snippet)
    logger.info "Successfully pushed: #{snippet.name} (#{snippet.language})"
  end

  def user_fails_to_push(snippet, pushing)
    snippets.delete(snippet)

    logger.error "Failed to push the snippet: #{pushing.error}"
  end
end
```

Here we have a simple usecase of inserting snippets to the application.
To perform some kind of SRP check, we can ask ourselves: <i>What's the responsibility of this object?</i> The answer can be: <i>It's responsible for pushing snippets scenario.</i> So it's a good, SRP-conformant object.

However, the context of this class is broad and we have dependencies - very weak, but still dependencies:

* Repository object which provides <strong>persistence</strong> to our snippets.
* Logger which <strong>helps us track activity</strong>.

Use case is a kind of a class which belongs to our logic. But it knows about <strong>aspects</strong> in our app - and we have to get rid of it to ease our pain!

## Introducing advice

I have told you about join points. It's a simple, yet abstract idea - and how can we turn it into something specific? What are the join points in Ruby?
A good example of join point (used in the [aquarium](http://aquarium.rubyforge.org/) gem) is an <strong>invocation of method</strong>. We specify how we inject our aspect code using <strong>advice</strong>.

What are advice? When we encounter a certain join point, we can connect it with an advice, which can be one of the following:

* Evaluate code <strong>after</strong> given join-point.
* Evaluate code <strong>before</strong> given join-point.
* Evaluate code <strong>around</strong> given join-point.

While after and before advice are rather straightforward, around advice is cryptic - what does it mean to "evaluate code around" something?

In our case it means: <i>Don't run this method. Take it and push to my advice as an argument and evaluate this advice</i>. In most cases after and before advice are sufficient.

## Fix our code

We'll refactor our code to embrace aspect-oriented programming techniques. You'll see how easy it is.

Our first step is to remove dependencies from our usecase. So, we delete constructor arguments and our usecase code after the change looks like this:

```
#!ruby
class SnippetsUseCase
  attr_reader :snippets

  def initialize
    @snippets = []
  end

  def user_pushes(snippet)
    snippets << snippet
  end

  def user_pushed(snippet); end

  def user_fails_to_push(snippet, pushing)
    snippets.delete(snippet)
  end
end
```

Notice the empty method `user_pushed `- it's perfectly fine, we're maintaining it only to provide a join point for our solution. You'll often see empty methods in code written in AOP paradigm. In my code, with a bit of metaprogramming, I turn it into a helper, so it becomes something like:

```
#!ruby
join_point :user_pushed
```

Now we can test this unit class <strong>without any stubbing or mocking</strong>. Extremely convenient, isn't it?

Afterwards, we have to provide aspect code to link with our use case. So, we create `SnippetsUseCaseGlue` class:

```
#!ruby
require 'aquarium'

class SnippetsUseCaseGlue
  attr_reader :usecase, :repository, :logger

  include Aquarium::Aspects

  def initialize(usecase, repository, logger)
    @usecase = usecase
    @repository = repository
    @logger = logger
  end

  def inject!
    Aspect.new(:after, object: usecase, calls_to: :user_pushes) do |jp, obj, snippet|
      repository.push(snippet, 
                      success: usecase.method(:user_pushed),
                      failure: usecase.method(:user_fails_to_push))
    end

    Aspect.new(:after, object: usecase, calls_to: :user_pushed) do |jp, object, snippet|
      logger.info("Successfully pushed: #{snippet.name} (#{snippet.language})")
    end

    Aspect.new(:after, object: usecase, calls_to: :user_fails_to_push) do |jp, object, snippet, pushing|
      logger.error "Failed to push our snippet: #{pushing.error}"
    end
  end
end
```

Inside the advice block, we have a lot of info - including very broad info about join point context (`jp`), called object and all arguments of the invoked method.

After that, we can use it in an application like this:

```
#!ruby
class Application
  def initialize
    @snippets            = SnippetsUseCase.new
    @snippets_repository = SnippetsRepository.new
    @logger              = Logger.new
    @snippets_glue       = SnippetsUseCaseGlue.new(@snippets, 
                                                   @snippets_repository, 
                                                   @logger)

    @snippets_glue.inject!

    # rest of logic
  end
end
```

And that's it. Now our use case is a pure domain object, without even knowing it's connected with some kind of persistence and logging layer. We've eliminated aspects knowledge from this object.

## Further read:

Of course, it's a very basic use case of aspect oriented programming. You can be interested in expanding your knowledge about it and these are my suggestions:

* [Ports and adapters (hexagonal) design](http://alistair.cockburn.us/Hexagonal+architecture) - one of the most useful usecases of using AOP to structure your code wisely. Use of AOP here is not needed, but it's very convenient and in Arkency we favor to glue things up with advice instead of evented model, where we push and receive events.
* [aquarium gem homepage](http://aquarium.rubyforge.org/) - aquarium is a quite powerful (for example, you can create your own join points) library and you can learn about more advanced topics here. It might be worth noting, though, that aquarium [doesn't work well with threads](https://github.com/deanwampler/Aquarium/issues/39).
* [YouAreDaBomb](https://github.com/gameboxed/YouAreDaBomb) - AOP library that Arkency uses for JavaScript code. Extremely simple and useful for web developers.
* [AOP inventor paper about it, with a extremely shocking use case](http://www2.parc.com/csl/groups/sda/publications/papers/Kiczales-ECOOP97/for-web.pdf) - Kiczales' academic paper about AOP. His use case of AOP to improve efficiency of his app without making it unmaintainable is... interesting.

## Summary
Aspect-oriented programming is fixing the problem with polluting pure logic objects with technical context of our applications. Its usecases are far broader - one of the most fascinating usecase of AOP with a huge 'wow factor' is linked in the 'Further Read' section. Be sure to check it out! 

We're using AOP to separate these aspects in [chillout](http://chillout.io) - and we're very happy about it. What's more, when developing single-page apps in Arkency we embrace AOP when designing in [hexagonal architecture](http://hexagonaljs.com/). It performing very nice - just try it and your application design will improve.

Someone can argue: 

> It's not an improvement at all. You pushed the knowledge about logger and persistence to another object. I can achieve it without AOP!

Sure you can. It's a very simple usecase of AOP. But we treat our glues as a <strong>configuration part</strong>, not the <strong>logic part</strong> of our apps. The next refactor I would do in this code is to abstract persistence and logging objects in some kind of adapter thing - making our code a bit more 'hexagonal' ;). Glues should not contain any logic at all.

I'm very interested in your thoughts on AOP. Have you done any projects embracing AOP? What were your use cases? Do you think it's a good idea at all?

