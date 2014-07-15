---
title: "Code style matters"
created_at: 2014-07-14 06:18:38 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :skip
newsletter_inside: :fearless_refactoring_1
tags: [ 'code', 'style', 'clean', 'syntax' ]
---

<p>
  <figure align="center">
    <img src="/assets/images/clean-code/clean-code.jpg" width="100%">
  </figure>
</p>

Have you ever wondered **how your code looks?** Exactly - no *what it does* or even *how it is organized*, but actually *how it looks*. One may think here *"oh screw it"*, but I want to present that **it can matter** and show you my various thoughts about that topic.

<!-- more -->

Recently [Andrzej Krzywda](http://andrzejonsoftware.blogspot.com/) raised a sensitive issue about code refactoring in [Rails Refactoring Book](http://rails-refactoring.com/). It provides a brief understanding about existing pains, possible solutions and gives us an opportunity to discuss it more detailed here. This article is intended to be a supplement for that book to show that not only architecture is important.

## Why does it matter?

In the beginning I'll start with some examples in Ruby, that may lead to inconsistency in one project. That's not a comprehensive example but an overview to introduce this problem.


```
#!ruby
:key => 'value' vs. key: 'value'
```
If you decide to use new ruby `(>= 1.9)`, use also a new hash syntax, or if you are so used to the old one, keep it everywhere in your project, independent of your current mood.

```
#!ruby
'some string' vs. "some string"
```
Why to use double quotes when not interpolating anything?

```
#!ruby
result = nil
if some_condition
	result = something
else
	result = something_else
end

vs.

result = if some_condition then something else something_else end

vs. 

result = some_condition ? something : something_else
```
Here ternary operator is less verbose than `if`, `then`, `else`, `end`, which are used rather in complex (multiline) cases.

```
#!ruby
or, and vs. &&, ||

```
They can be [really tricky](http://devblog.avdi.org/2010/08/02/using-and-and-or-in-ruby/) so it is [not recommended](https://github.com/bbatsov/ruby-style-guide/commit/5920497452c1f6f604742a735f5684e86d4c0003).

```
#!ruby
['a', 'b', 'c'] and [:a, :b, :c]

vs. 

w%(a b c) and %i(a b c)
```
Much nicer and no `'` everywhere.

I chose these, because I see them the most often. I hope they show that problem exists.

Why I'm pointing on that? Because I'm working in many projects with many devs at one time. I'm using *up to* 6 different languages every day so sometimes it's kinda overwhelming. To easily dive into one project from another, switch contexts, jump between environments and work with other people, some guidelines must be respected.

Moreover I'm developing in [JetBrains](http://www.jetbrains.com/) tools (RubyMine, IntelliJ, AppCode, AndroidStudio), which have really nice syntax check inspired by *official* guidelines like e.g. "[Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide#syntax)" and they help me to keep my code clean and coherent across files.

## What is important?

In my opinion, the most important thing about our code is **readability**. Why? Because we don't usually have time to read and parse others code. We need to use it. If we are using the same style, we can just take a look and understand everything.

It's much tougher to understand

```
#!ruby
unless condition
	something
else
	something_else
end
```
rather than

```
#!ruby
if condition
	something
else
	something_else
end
```

Isn't it? So the in the first example `something` will be executed if `condition` is not `true` so if it `false`, yep? Even if _parsing_ takes only a couple milliseconds, when we have a lot of places like that, it may cause wasting more time to refactor code inside our minds.

The other important thing is **communication** between developers which is done mostly through our code. When we don't understand what they did and have to reinterpret their code, it means that communication fails. When everyone writes code that have the same look, it's super-easy to make our work faster.  
How may times did you have to rewrite a part of code that someone wrote and now you have to implement a new feature? How many times did you complain on others work, because you would do it better?

## Where's the problem?
The main problem is that the **taste is *sooo* subjective**. There may be pedants, some that like "artistic mess" or people that don't care at all. It might be hard to have each of them in one project working on the same code.

**Tastes differ**. That's why some writes `key: value` and some `key : value`. Some leaves empty lines (one or more) between methods, some don't do that at all. Some take care of architecture and code separation, but don't take care of their syntax. Small things, but can be annoying for those that pay attention to such issues.

Of course there are developers which deal with legacy code very well. They easily understand the most tenebrous code, they have huge experience and great skills to interpret any part of existing software. If you are one of them, you may see this blogpost useless, but beware — not everyone is like you. Some learn slower and bad code may discouraged them permanently from the very beginning.

## How to solve it?
We cannot have a silver bullet here. Unfortunately **code style is really personal and usually hard to change**. It's like old behavior or routine repeated all the time so do not expect immediate switch just like that. So where to begin? A very good start can be guidelines or best practices defined by community or language authors. That may be easy to begin with, **learn and improve your code style**. There are tons of them for nearly every language. Sometimes even [companies define their own guidelines](https://github.com/monterail/guidelines/blob/master/rails.md) to make it easier and keep concise code across many projects.

How to use them? It might be hard just to remember and use this new code style or guidelines so let's **configure your favorite IDE**, find suitable package for Sublime, bundle for TextMate or plugin for VIM that will let you auto-reformat your code. They are usually called `YOUR_LANGUAGE-[prettifier | beautifier | formatter]` and are available for probably every tool you use to write the code.

**Some examples of these guidelines:**

- [GitHub All-in-one](https://github.com/styleguide)
- [Ruby](https://github.com/bbatsov/ruby-style-guide)
- [Rails](https://github.com/bbatsov/rails-style-guide)
- [RSpec](http://betterspecs.org/)
- [HTML](http://google-styleguide.googlecode.com/svn/trunk/htmlcssguide.xml)
- [CSS](https://github.com/csswizardry/CSS-Guidelines)
- [jQuery](http://contribute.jquery.org/style-guide/js/)
- [JavaScript](http://google-styleguide.googlecode.com/svn/trunk/javascriptguide.xml)
- [CoffeeScript](https://github.com/polarmobile/coffeescript-style-guide)

## Summary

If you think that it's important topic in your daily work and you are willing to improve your code style I'd recommend you to start from some useful resources guiding you by small steps that will make your code better. **Start with small steps**, not with everything together. Make a **little changes continuously** introducing more and more new elements. You're probably using a few languages at one time so pick one you want to improve and focus on it to avoid too much changes together and decrease new things to remember. Finally, if you want to know our opinion, take the most from Rails Refactoring book.

<%= inner_newsletter(item[:newsletter_inside]) %>

### More useful books that will help you keep your code clean:
1. [Clean code](http://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
2. [Clean coder](http://www.amazon.com/Clean-Coder-Conduct-Professional-Programmers/dp/0137081073/)
3. [Beautiful code](http://www.amazon.com/exec/obidos/ASIN/0596510047/)
4. [The productive programmer](http://www.amazon.com/exec/obidos/ASIN/0596519788)
5. [Pragmatic programmer](http://www.amazon.com/Pragmatic-Programmer-Journeyman-Master/dp/020161622X/)


<p>
  <figure align="center">
    <img src="/assets/images/clean-code/keep-calm-and-code-clean.png" width="100%">
  </figure>
</p>