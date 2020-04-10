---
title: "Why Smalltalk instead of Ruby"
created_at: 2017-01-20 23:16:16 +0100
publish: true
author: Richard Eng
tags: [ 'ruby', 'smalltalk' ]
img: "smalltalk-ruby/smalltalk-ruby.jpg"
---

Hello, it's Andrzej Krzywda from Arkency here. Today we have a special guest post from Richard Eng, the man who is behind the Smalltalk Renaissance.

I've been fascinated with Smalltalk since my University. In a way, my Ruby code is Smalltalk-infected all the time. Many of the great things in programming come from Smalltalk, like MVC, IDE, refactoring. 

Smalltalk has its history, but it's also still in use in huge, production systems. As Ruby developers we often look at the new, shiny languages. Maybe we can also look at something less new? Maybe we can get inspired with Smalltalk?

I'll leave you with Richard and his strong arguments for Smalltalk, enjoy! :)

<!-- more -->

<p>
  <figure align="center">
    <img src="<%= src_fit("smalltalk-ruby/smalltalk-ruby.jpg") %>">
  </figure>
</p>

*****

Ruby is a popular language, largely because of Rails. Ruby borrows OOP from
Smalltalk, but otherwise is a very much different language. I’m going to argue
that Smalltalk is still technically a better choice than Ruby.

Ruby appeals to programmers because of its clean, simpler syntax. However,
Smalltalk is the ultimate in clean, simple, and minimalist. [Its syntax can be
summarized on a
postcard!](http://stackoverflow.com/questions/25320090/pharo-smalltalk-quick-reference-card)
It has three principal features: objects, lambdas (closures), and reflection.
The language is exceptionally easy to understand. Ruby, not so much.

That’s why I always recommend Smalltalk to beginners. It was designed for
teaching programming *to children*. Alan Kay et al. had the right idea.

Despite its simplicity, Smalltalk loses nothing in terms of programming power.
It was used by the U.S. joint military to write a *million-line* battle
simulation program called JWARS (which incidentally outperformed a similar
simulation called STORM written in C++ by the U.S. Air Force). Smalltalk is
powerful enough that [it has served the commercial industry for over three
decades!](https://medium.com/smalltalk-talk/who-uses-smalltalk-c6fdaa6319a)

Powerful languages do not need all kinds of special features, which is the kind
of thinking that went into C++, Scala, Rust, Swift, and yes, Python and Ruby,
too. This is why I’m also a fan of Scheme, Forth, and Go…small, simple,
minimalist.

Smalltalk is synonymous with its “live coding and debugging” IDE, which is the
main reason for [its incredible
productivity](https://medium.com/smalltalk-talk/smalltalk-s-proven-productivity-fe7cbd99c061).
Twice as productive as Ruby. More than three times as productive as JavaScript!

Smalltalk’s “image” persistence is also a huge timesaver: you can save the
entire execution state of an application and resume execution at a later time.
This is awfully convenient for maintaining the continuity of your workflow.

[Smalltalk has a fabulous facility for Domain-Specific
Languages](https://medium.com/smalltalk-talk/getting-the-message-667d77ff78d).
It’s easier and more pleasant than Lisp macros or Ruby’s approach.

Compared to Smalltalk, Ruby’s handling of blocks is also a bit wonky. Citing
[Lambda the Ultimate](http://lambda-the-ultimate.org/node/2606):

> In Smalltalk, there is easy syntax for constructing a closure and passing it as
> an ordinary argument and picking up that argument with an ordinary parameter and
then for invoking the closure and/or passing it on. Ruby, semantically, has the
same capabilities for constructing, passing, and using closures. However, Ruby
uses oddball syntax for these things, for no benefit that I can discern. There
is a specially distinguished argument position available in a call, specifically
for passing a closure. If you are going to construct a closure in that position,
the syntax is simple. But the closure in its simplest syntax is not an
expression. It only goes in that special position in the syntax, or has to have
a word put in front of it, “lambda”, to be turned into an expression that could
be put in an ordinary argument position or any other expression context (e. g.,
right side of assignment). If a method is expecting to receive a block as an
argument, the designer has to choose between having it take the block as an
ordinary argument or as the special block argument (either can be chosen, in the
monomorphic case). And if the method needs to take two blocks, at least one of
them has to be passed as an ordinary argument, so the decision has to be made
whether to pass one as the special argument and if so, which one. Conversion in
both directions is available in all contexts where it makes sense, between the
special argument or parameter and an ordinary expression. I think this
exceptionalism in Ruby’s syntax imposes significant extra conceptual load to
understanding the syntax. Smalltalk’s treatment of blocks is plenty economical,
whether they are being passed as arguments right at the point of construction or
not.

> I guess I can see why this exceptionalism arose; it avoids having the closing
> parenthesis of the argument list coming right after the end of a block, which I
can see would look ugly. But, so much twisting and turning and squirming for a
tiny increment of beauty.

No programming language is perfect, of course. Of all the complaints I’ve ever
heard about Smalltalk, only a small handful are even remotely valid, in my
opinion. [Most are based on
ignorance.](https://medium.com/smalltalk-talk/why-aren-t-people-using-smalltalk-80de31b6e3f4)

Ruby is mostly famous for its Rails framework. Smalltalk has its own “Rails,”
too. It’s called [Seaside](http://www.seaside.st/) (aka the “[Heretic Web
Framework](https://smalltalkrenaissance.wordpress.com/2015/01/24/the-heretic-web-framework/)”).
Seaside is based on reusable, stateful components. The key feature that supports
this is called a *continuation*. A continuation is a snapshot of a program’s
current control state. It allows you to “jump” to another execution and when you
return, the current state is restored. This provides a conventional
“call/return” mechanism for your web application. It can help resolve issues
such as the double request and back button problems.

If you’ve never used Seaside, I urge you to try it. You just might find a real
gem of a web framework (ahem).

Ruby and Python are often hailed as great solutions for startups. [I argue that
Smalltalk is just as good if not
better.](https://medium.com/smalltalk-talk/why-choose-smalltalk-over-python-for-startups-21aefeafb83e)
For rapid prototyping, Smalltalk is unmatched; using Smalltalk is a Zen-like
experience. I hear that a lot from Smalltalkers.

> All of the above wouldn’t be possible if Smalltalk wasn’t a nice, simple
> language, IDE, and runtime all rolled into one and tightly coupled.

Bret Victor in his wonderful talk, “The Future of Programming,” points to
Smalltalk as a harbinger of how software creation will evolve four decades in
the future (from 1973):

<iframe width="420" height="315" src="https://www.youtube.com/embed/8pTEmbeENF4" frameborder="0" allowfullscreen></iframe>

> Why are we still using file-based tools??? Are we Neanderthals?

To be sure, Smalltalk isn’t as popular as Ruby. [This is the reason for my
Smalltalk
evangelism.](https://hackernoon.com/why-are-you-a-smalltalk-evangelist-edaaa4c670a2)
However, popularity should not blind you to other possibilities, to other
*better* ways to write software.

Read my seminal article on Smalltalk (which has been viewed by over 25,000
people around the world!): [How learning Smalltalk can make you a better
developer](https://techbeacon.com/how-learning-smalltalk-can-make-you-better-developer).

**You** can make software creation easier, more productive, less stressful.
**You** can remake the future of software engineering. The remedy to the malaise
of today’s antediluvian style of programming using loosely-integrated,
file-based tools is very, very simple: [give Smalltalk a
chance](https://medium.com/p/how-to-make-smalltalk-great-again-aae2081a4464).

### [Richard Eng](https://medium.com/@richardeng)

Mr. Smalltalk:
[https://medium.com/p/domo-arigato-mr-smalltalk-aa84e245beb9](https://medium.com/p/domo-arigato-mr-smalltalk-aa84e245beb9)


