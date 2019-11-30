---
title: "OOP Refactoring: from a god class to smaller objects"
created_at: 2019-11-30 15:41:49 +0100
kind: article
publish: true
author: Andrzej Krzywda
newsletter: :skip
---

In the early years of my programming career, I got infected by the OOP thinking. It made (and still does) sense to model the problem in terms of objects and methods operating on that object.

However, at the beginning, my OOP code resulted in a god class - a class that knows almost everything.

<!-- more -->

Just a short note, before we start. Over time, as Arkency, we were documenting our Ruby/OOP lessons in the form of ebooks and video classes. Only during this weekend, you can buy 8 books and 2 videos classes for $99 instead of $900.
[Buy here](https://arkency.dpdcart.com/cart/add?product_id=188891&method_id=204500)

Let’s say I work on a Project Management app. Usually my User class and Project class would be big, like this:

```ruby
class Project

  def initialize
    @tasks = []
    @members = []
    @budget = Budget.new
  end

  def add_task(task)
    raise Duplicate if @tasks.include?(task)
    @tasks << task
  end

  def tasks
    @tasks
  end

  def assign(developer)
    @members << developer
  end

  def assign_task(task, developer)
    raise AlreadyAssigned if task.assigned?
    task.assign_developer
  end

  def members
    @members
  end

  def current_backlog
    @tasks.select{|task| task.assigned?}
  end

  def increase_budget
    raise ProjectFinished if finished?
    budget.increase
  end
end

```

The Project class plays too many roles - it serves like a proxy/facade to other objects (developer or tasks). It has business rules (Duplicate, AlreadyAssignedTask). It also has query methods - tasks, members, backlog.

Over time, I learnt some additional techniques which helped me reduce the size of the god class.

The first technique is CQRS - in short, it allows me to extract the queries outside of this object.

```ruby
class TasksList
  def initialize(event_bus)
    event_bus.subscribe(TaskAdded, add_task)
    event_bus.subscribe(TaskAssignedToDeveloper, assign_task_to_developer)
    event
  end

  def add_task(event)
    Task.create
  end

  def list
    Task.all
  end

  class Developer < ActiveRecord::Base
    has_many :tasks
  end

  class Task < ActiveRecord::Base
  end
end
```

This is an example query object, or as we call it in CQRS - it’s a read model. Its only purpose is to show data. There is no logic here, just a declaration what events are needed and then simple CRUD (ActiveRecord calls).

OK, but if we need events here, then they must be published somewhere, right?

Let’s start with publishing them in the Project object.


```ruby
class Project

  def initialize(event_bus)
    @tasks = []
    @members = []
    @budget = Budget.new
    @event_bus = event_bus
  end

  def add_task(task)
    raise Duplicate if @tasks.include?(task)
    @tasks << task
    @event_bus.publish(TaskAdded)
  end

  def assign(developer)
    @members << developer
  end

  def assign_task(task, developer)
    raise AlreadyAssigned if task.assigned?
    task.assign_developer
    @event_bus.publish(TaskAssigned.new(developer.id, task.id))
  end

end

```

What has changed?

The constructor now accepts `event_bus` as a dependency. We need to publish the events somewhere, to a bus.
Then, it those methods which serve as commands (change something), we publish the events.
While, the object grabbed a new responsibility - it also reduced its roles. We no longer have the query methods. All the accessors disappeared. Thanks to the fact that we have the event_bus which connects our object (via event) with the read models, the read models are totally separated and decoupled.

Are we happy now?
It’s better, but still feels like a god class.

What else can we do?

First, let’s get rid of `event_bus`.
While we need to have events being published - it doesn’t have to be part of the class. This object is called from somewhere, right? Why not move this event publishing code to the callers?

Usually in Rails apps, we have the `service objects` layer or as we call it in CQRS - command handlers.

```ruby
class AssignTaskHandler
  def initialize(event_bus, project_id, task_id, developer_id)
    project = ProjectRepo.load(project_id, event_bus)
    begin
      project.assign_task(Task.new(task_id), Developer.new(developer_id))
    rescue AlreadyAssigned => e
      return Error(e)
    end
    return Success.new
  end
end
```

Currently it passes the event_bus to the Project, but in many cases it doesn’t have to. Let’s change it to:

```ruby
class AssignTaskHandler
  def initialize(event_bus, project_id, task_id, developer_id)
    project = ProjectRepo.load(project_id)
    begin
      project.assign_task(Task.new(task_id), Developer.new(developer_id))
    rescue AlreadyAssigned => e
      return Error(e)
    end
    @event_bus.publish(TaskAssigned.new(developer_id, task_id))
    return Success.new
  end
end
```

Now, we publish the event as part of the command handler, so we no longer need this in the Project class, which now looks like this:

```ruby
class Project

  def initialize
    @tasks = []
    @members = []
    @budget = Budget.new
  end

  def add_task(task)
    raise Duplicate if @tasks.include?(task)
    @tasks << task
  end

  def assign(developer)
    @members << developer
  end

  def assign_task(task, developer)
    raise AlreadyAssigned if task.assigned?
    task.assign_developer
  end

end
```

Feels better now, doesn’t it?

Still, this is just an example. It contains only 3 business logic methods. In practice, there would be more, each of them somehow connected to the current instance variables - tasks, members, budget.

Previously, it was useful to have those ivars together, as for some queries we may want to display a report which contains all of them. Now that we extracted read models, they can handle this and we no longer need such place to connect.

Also, this is where my lessons from Domain-Driven Design arrived. In short, DDD is about “a language in a context”. 
The important part is that there’s no one, dominant language or vocabulary for the whole of our system. In fact, we can (and should) have many models, many languages to describe different parts.

In our case, the code screams to us, that it’s actually at least 3 contexts:

- Budgeting
- Tasks
- Human Resources

and apologies for suggesting that someone may call Developers as Resources…


In each of them, the concept of a Project means something different. In fact, some of them may not even use the term Project to describe what they need. For example, maybe for Budgeting, a Project is just an Account?

Let’s try to split this code then. we will create a module for each context:

```ruby
module Budgeting

  class Account
    def initialize
      @amount = Money.new(0.0)
   end

    def increase(amount)
      @amount += amount
    end
  end
end
```

```ruby
module Tasks
  class Project
    def initialize
      @tasks = []
    end

    def add_task(task)
      raise Duplicate if @tasks.include?(task)
      @tasks << task
    end
  end
end
```

```ruby
module HumanResources
  class Project
    def initialize
      @resources = []
    end

    def assign(resource)
      @resources << resource
    end
  end
end
```

Does it look better now? 
To my taste it’s better. Apart from the offensive `Resource` part, but hey, that’s the language they use to describe us.

There are techniques which may help us even further, but for the scope of this article, I think that’s enough. 

Did you like this?

You will find dozens if not hundreds of such techniques in our books and courses. Only now, we have a huge discount. Instead of paying ~$900, you can buy our 8 books and 2 video classes for just $99.

[Buy here](https://arkency.dpdcart.com/cart/add?product_id=188891&method_id=204500)