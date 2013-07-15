---
title: "Decouple our code even more: embrace AOP!"
created_at: 2013-07-13 17:16:03 +0200
kind: article
publish: true
author: Marcin Grzywaczewski
newsletter: :spa1product
tags: [ 'ruby', 'aop' ]
---

As programmers, we greatly care about design of our applications. We can spend
hours, arguing about solutions that we dislike and refactoring our code to
loose coupling and weaken dependencies between our objects.

Unfortunately, there are the Dark Parts in our apps. Like persistence,
networking, logging, notifications... that parts are scattered in our code - 
we have to explicitly specify dependencies to them in domain objects.

Is there something that can be done about it? 
Or we have to live in this purist's nighmare?
Fortunately, a solution exists. 
Ladies and gentlemans, we present an aspect-oriented programming!

<!-- more -->

## A bit of theory

Before we dive into fascinating world of AOP, we need to grasp some concepts
which are crucial to this paradigm.

When we look at our app, we can split it in to two parts: <strong>aspects</strong>
and <strong>components</strong>. Basically, components are parts we can easily
encapsulate into some kind of code abstraction - a method, object or procedure.
Application's logic is a great example of component. 
Aspects, on the other hand, can not be simply isolated in code - they're things 
like our Dark Parts, or somehow more abstract things - like 'coupling', 'efficiency'. 
Aspects cross-cut our application - when we're using some kind of persistence (like a database), or network communication (like ZMQ sockets) 
we have to create a dependency with them when we need to use it in our components.

Aspect-oriented programming is an approach to get rid of cross-cuts by separating
<i>aspect code</i> from <i>component code</i> and inject our aspects in certain <i>join points</i>
in our component code. An idea comes from Java community and it may sound a bit scary at first,
but [before you start hating](http://andrzejonsoftware.blogspot.com/2011/07/stop-hating-java.html/) - 
read an example and everything should be more clear.

## Let's start it simple

Imagine: You build an application which stores code snippets. You can start one of the usecases like that:

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

    logger.error "Failed to push our snippet: #{pushing.error}"
  end
end
```

Here, we have a simple usecase of inserting our snippets to our application.
We can ask ourselves, to perform some kind of SRP check: <i>For what this object is responsible for?</i>. The answer can be: <i>It's responsible for pushing snippets scenario.</i>. So it's a good, SRP-conformant object.

But the context of this class is somehow broad and we have dependencies - very weak, but still dependencies:

* Some kind of repository object, which provides <strong>persistance</strong> to our snippets.
* Logger, which <strong>helps us to track activity</strong>.

Use case is a kind of a class which belongs to our logic. But it knows about <strong>aspects</strong> in our app - and we have to get rid of it, to ease our pain!

## Introducing advices

I told you about join points. It's a simple, yet abstract idea - and how we can turn it into something specific? What are our join points in Ruby?
A good example of join point and used in [aquarium](http://aquarium.rubyforge.org/) gem is an <strong>invocation of method</strong>. We specify how we inject our aspect code using <strong>advices</strong>.

What are advices? When we encounter a certain join point, we can connect it with an advice, which can be one of the following:

* Evaluate code <strong>after</strong> given join-point
* Evaluate code <strong>before</strong> given join-point
* Evaluate code <strong>around</strong> given join-point

When after and before advices are rather straightforward, around advice is cryptic - what does it mean "evaluate code around" something?

In our case, it means: <i>Don't run this method. Take it and push to my advice as an argument, and evaluate this advice</i>. In most cases after and before advices are sufficient.

## Fix our code

We'll refactor our code to embrace aspect-oriented programming techniques. You'll see how easy it is.

Our first step is to remove dependencies from our usecase. So, we delete constructor arguments and our usecase code looks like this after this change:

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

Notice the empty method `user_pushed `- it's perfectly fine, we're maintaining it only to provide a join point for our solution. You'll often see empty methods in code written in AOP paradigm. In my code, with a bit of metaprogramming I turn it into helper, so it becomes something like:

```
#!ruby
join_point :user_pushed
```

Now we can test this unit class <strong>without any stubbing or mocking</strong>. Extremely convenient, isn't it?

Afterwards, we have to provide aspect code to link it with our use case. So, we create `SnippetsUseCaseGlue` class:

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

Inside advice block, we have a lot of info - including very broad info about join point context (`jp`), called object and all arguments of invoked method.

After that, we can use it in application like this:

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

And that's it. Now our use case is a pure domain object, without even knowing he's connected with some kind of persistance and logging layer. We eliminated aspects knowledge from this class.

## Further read:

Of course, it's a very basic use case of aspect oriented programming. You can be interested in expanding your knowledge about it and that's my proposals:

* [Ports and adapters (hexagonal) design](http://alistair.cockburn.us/Hexagonal+architecture) - one of the most useful usecases of using AOP to structure your code wisely. Use of AOP here is not a need, but it's very convenient and in Arkency we favor to glue things up with advices against evented model, which have its pains.
* [aquarium gem homepage](http://aquarium.rubyforge.org/) - aquarium is quite powerful (for example, you can create your own join points) library and you can learn about more advanced topics here.
* [YouAreDaBomb](https://github.com/gameboxed/YouAreDaBomb) - aop library that Arkency uses for JavaScript code. Extremely simple and useful for web developers.
* [AOP inventor paper about it, with a extremely shocking use case](http://www2.parc.com/csl/groups/sda/publications/papers/Kiczales-ECOOP97/for-web.pdf) - Kiczales' academic paper about AOP. His use case of AOP to improve efficiency of his app without making it unmaintainable is... interesting.

## Summary
Aspect-oriented programming is fixing our pain with polluting pure logic objects with technical context of our applications. Its usecases are far more broader - one of the most fascinating usecase of AOP with a gigantic 'wow factor' is linked in a 'Further Read' section. Be sure to check it out! 

We're using AOP to separate this aspects in [chillout](http://chillout.io) - and we're very happy about it. Also, when developing single-page apps in Arkency we embrace AOP when designing in [hexagonal architecture](http://hexagonaljs.com/). It performing very nice - just try it, and your application design will improve.

Someone can argue: <i>It's not an improvement at all. You pushed the knowledge about logger and persistance to another object. I can achieve it without AOP!</i>

Sure you can. It's a very simple usecase of AOP. But we treat our glues as a <strong>configuration part</strong>, not the <strong>logic part</strong> of our apps. The first further refactor I would do in this code is to abstract persistance and logging objects in some kind of adapter thing - making our code a bit more 'hexagonal' ;). Glues should not contain any logic at all.

I'm very interested about your thoughts about AOP. Have you done any projects embracing AOP? What was your use cases? Do you think it's a good idea at all?

