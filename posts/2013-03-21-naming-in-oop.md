---
title: "Naming in OOP"
created_at: 2013-03-21 11:52:19 +0100
kind: article
publish: true
author: Jan Filipowski
tags: [ 'OOP', 'OOD', 'mostly obvious' ]
newsletter: arkency_form
---

There is a well known cite on naming in our industry:

> "There are only two hard things in Computer Science: cache invalidation and naming things." Phil Karlton

To be honest it's not Computer Science specific issue, but common problem for whole science. History of science is composed of discoveries and evolution of definitions. Every math theorem is based on some definitions - I would call it "theorem dictionary". There is also huge branch of philosophy aiming to figure out how our language influence on our thoughts. So I asked myself - how naming can influence my design. What can I learn from bad names?

<!-- more -->

## Good name

Let's have a look at most important constraints of good name:

1. meaningful
2. proper for given abstraction level / context
3. consistent
4. short
5. pure English - without prefixes or suffixes that encodes metadata

Now it's time to figure out what each constraint really mean and what's more important - how can we validate it and what can we learn about our code from breaking the rule.

### Meaningful

Name has to inform about object's or method's reponsibility. It should be easy to use in sentence and easy to understand solution behind it. If name break this rule it may mean, that you have incorrect abstraction - not only on given entity's level. Maybe this object / method has more responsibilities than one?

### Proper for given abstraction level

It's about being meaningful in given context - you should be able to use given name in one sentence with it's parent name. If this rule is broken then you probably missed at least one abstraction.

### Consistent

If you represent similar concepts you should use same name. It can help you extract common responsibility, but of course it will also make your code easier to understand. Breaking this rule should trigger following questions: Am I missing any abstraction? Isn't that module or project too big?

### Short

It's easier to think about something when it's short. It's also easier to talk about it. But this rule is not only about name's length, but also about using "or" or "and" in class or method's name. If your name contains these conjunctions you may have problem with many responsibilities in given entity. It may be also just wrong name for given abstraction.

### Pure English - avoid metadata

Avoid using [Hungarian Notation](http://en.wikipedia.org/wiki/Hungarian_notation) or any other that informs about type or other metadata. You should trust your coworkers, that they'll look for object's type and they'll construct meaningful interfaces of their objects or methods. So breaking this rule is a sign of lack of trust in your team.

## My personal naming framework

1. If you can't find perfect name use good one. Maybe some day you or your coworker will discover something better.
2. If you can't find good name refactor / redesign your solution or talk aloud about given solution - maybe you need a time to find given name natural.
3. If you find improper name - change it.

## Conclusion

I'm aware of writing incomplete set of naming smells and their impact on OOD, but I think it's a great subject for further research. So if you feel that you have something to add don't hesitate - write a comment.
