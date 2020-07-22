---
title: "Big events vs Small events — from the perspective of refactoring"
created_at: 2018-09-10 08:10:49 +0200
publish: true
author: Andrzej Krzywda
tags: [ 'ddd' ]
---

Today I’d like to write a few words about big events versus small events. This topic usually leads to very heated discussions. At the beginning, I was mostly keen on big events, but now, after working for several years in an event sourced system, I notice many problems connected with big events. And that is why now I am all for smaller events.

<!-- more -->

To give you a sense of what I mean, here’s one example of a problem that I find very painful to deal with, namely the refactoring of our codebase. The thing is that when you publish events and you usually do it from an aggregate, then the aggregate contains some state related to the event or to the information needed to make the decision to publish the event.
 
# Big aggregates result in big events

```ruby
class EmployeeRegistered < Event
    def self.schema
      { 
        company_id:    STRING_ID,
        employee_id:   STRING_ID,
        first_name:    String,
        last_name:     String,
        department_id: STRING_ID
        manager_id:    STRING_ID
        resume_id:     STRING_ID
      }  
    end
end
```
 
Quite often, usually at the beginning when you are still new to aggregates, you make them too big and they contain much more state than they need. They contain information that could actually be split in two aggregates. And with aggregates slightly bigger than necessary, you may end up enriching the original event with useful information that happens to be in the state of the aggregate.

So at this time it seems to be a no-brainer because you simply append new properties. It can be some kind of an association. For example, you registered a new employee and you attach information on the department she was assigned to or you publish her manager_id and may also want to embedded the employee resume.  (BTW, see how the different Bounded Contexts are coupled here?) So you keep on enriching the event with whatever you have, which at the beginning sounds great because for some reasons you may find it very useful to have all or most of the information in one event, as it makes it easy to build a projection or a read model and saves you the trouble of reacting  to several smaller events.

# Splitting an aggregate

On the other hand, when you feel the need to do a refactoring of the original aggregate,  you need to split it into two parts. The events are a kind of a public interface, so other consumers rely on it. If you want to split an aggregate, suddenly you face a problem of not having all the information in one place, making the refactoring a bit more complicated. So you either try to keep the original event published somehow and build a projection only to publish the old event, just to stay with the old consumers without having to change them, or you change all the consumers or create event versions. All this is a bit problematic.

# Big events postpone refactorings

To me the most important thing is that all this can make you want to postpone the refactoring. And I think that one of the most important thing about programming is that we should never worry about refactoring. If I see a better design, then I  should be able to do it quickly without any doubts or worries. And big events can be a source of worry.

On the other hand, when events are small and you move logic from one aggregate to another, and the event comprises just an ID and one or maybe two attributes, then it's much easier. Even if you move it from one aggregate to another, it doesn't really change the semantics of the event and so the event stays untouched. It is just  published from a different place now, which makes it much easier to deal with.

```ruby
class EmployeeRegistered < Event
    def self.schema
      { 
        company_id:   STRING_ID,
        employee_id:    STRING_ID,
      }  
    end
end

class EmployeeMovedToDepartment < Event
end

class EmployeeNameProvided < Event
end

class EmployeeAssignedToManager < Event
end

class EmployeeResumeProvided < Event
end
```

That's the lesson I learned from my own mistakes made while working in event sourced systems or event-driven architecture. Based on my experience, I much prefer smaller events because they make refactoring a whole lot easier. Thanks for reading! 

