---
created_at: 2020-04-21T11:52:48.259Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Why commenting code is evil

Less inflammatory title: **Hidden costs of putting adding comments to code**.

I bet you've seen such codebases. Comments all over the place. You've got no idea which ones are still relevant. Most of them hard to understand or too obvious. Big chunks of code commented out: _Saved for later_. _Disabled for now_.

While I agree that comments sometimes help, here's my list of costs they impose which should be kept in mind when considering the helpfullness of adding comments. That's why I try to avoid comments at all as a rule. Of course the extent to which they affect your work is variable and subjective, but I believe it's helpful to be aware of all this aspects.

### 1. Comments rot, mislead and lie -- the deception cost

One of the problems with comments is that it's too easy too write them.

In a perfect world, the comments should be only helpful and truthful, but in reality they rot (they're not kept up to date), comments can mislead or outrightly lie. 

It might happen that the original commenter was wrong since the beginning. Code, in turn, never lies (although method names can :)).

It might happen that the comment was originally right, but the future commiters failed to keep it in sync when the code changed.


### 2. Comments leave you wondering -- the attention cost

Here's a post from [Classic Programmer Paintings](https://classicprogrammerpaintings.com) which I like to link occasionally and which is my go-to resource when arguing about comments:

<div class="tumblr-post" data-href="https://embed.tumblr.com/embed/post/9NYQOutKOEXi4aopdzCr9A/143319675260" data-did="a3fbf2de0fdc7813870b144667c226566dd2e2ac"><a href="https://classicprogrammerpaintings.com/post/143319675260/experienced-engineer-examines-comments-in-a-legacy">https://classicprogrammerpaintings.com/post/143319675260/experienced-engineer-examines-comments-in-a-legacy</a></div>
<script async src="https://assets.tumblr.com/post.js"></script>

Let's say you stumble upon a comment in a unfamiliar area of the code. You feel like the knight on above picture. You now wonder - is this comment still relevant? Should I care about it? Or is it just the one that states something obviuous? Should I break my flow now, focus and try to understand what the commenter meant? Good bye deep work. It leaves you with worries and guilt. It's like dead code, but worse - you cannot easily establish if it's still relevant. All this thinking and potential action impose a cost on the visiting programmer.

### 3. Comments make you feel better when you shouldn't

Let's say you write a piece of code in a non-optimal way. I'm often tempted to leave a comment like:

```
# This should be done in a better way, but...
```

The reason is that I wrote some crappy code because I either didn't know better or didn't have enough time. If someone finds out that I did this, I'd like the reader to know that I was aware of this piece's deficiences, i.e. I wasn't that stupid to overlook it, I just couldn't fix it.

It makes me feel so much better when writing crappy code, but it's such a bad thing -- it doesn't actually make anything better. 

If you forbid yourself comments like this, perhaps you're going to leave less crappy code around on average -- now that you cannot make yourself look smarter by leaving a cheap comment.

An interesting excerpt from a [paper on production failures in distributed systems](https://www.usenix.org/conference/osdi14/technical-sessions/presentation/yuan):

> Specifically, we found that almost all (92%) of the catastrophic system failures are the result of incorrect handling of non-fatal errors explicitly signaled in software. (...) In fact, in 35% of the catastrophic failures, the faults in the error handling code fall into three trivial patterns: (i) the error handler is simply empty or only contains a log printing statement, (ii) the error handler aborts the cluster on an overly-general exception, and (iii) **the error handler contains expressions like “FIXME” or “TODO” in the comments**.  

<!-- virtue signaling? -->

### 4. Comments invite more comments

Even if you try hard to make your comments always helpful, your teammates won't necessarily apply the same amount of discipline. Other teammates, seeing that comments are tolerated in this codebase might feel free to use them for whatever reason.

### 5. Comments are ugly

That's definitely subjective, but I wouldn't overlook this factor. Developers care a lot about code formatting etc., how code comments turn out in this matter?

## Alternatives to commenting code

### 1. Self-explanatory code, obviously

OH: a piece of code is like a joke — if you have to explain it, it's bad.

If you're tempted to write a comment to explain what the piece of code does, you try refactoring the code so that it no longer needs a comment.

Here's the good part of forbidding yourself writing comments at all — when I know I cannot do it, I'm more likely to find a way to make the code more clear. Often it's very easy. In the worst case I can give a really long name to the method in question, like:

```ruby
def this_method_will_catapult_you_if_you_call_it_with_an_even_number(number)
  catapult if number.even?
end
```

One could argue it's not that different from a comment. A method name can also lie. But still, it's less likely to ignore a method name or keep it out of sync with the actual code.

I always appreciated the naming of `dangerouslySetInnerHtml` in React. In my codebase, I'd rather add the `dangerous` prefix instead of going with a `// warning: dangerous` comment.

### 2. Commit messages

### 3. Test cases

An example. Suppose you discover a bug in a library you're using. Not a big deal, you can easily work it around on your side. But you also believe the library's going to get a proper fix soon too. You wouldn't like the work around to stay here forever. You're thinking about adding a comment:

```
# TODO: remove this workaround once the library gets a proper fix
```

Not perfect. In most of the projects I worked on, no one would ever get into that again. The comment and the work around would stay there forever. What can you do instead?
How about you write a test case against the library code, that will expect the bug to be there and fail when the bug is fixed on library's side?

```
def test_library_x_has_buggy_behavior_in_method_foo
  assert_equal "wrong", Library.foo, "the bug seems to be fixed - you can now remove the work around"
end
```

I prefer the latter. When the test case fails, it's much more likely that someone does something about it. And also there's no comment making the production code ugly!

### Raise an exception

### Issue tracker

## Caveats

* The rule may not be 100% but still you're far better off if you stick to it 100%, because you never wonder "should I write a comment".
* Ok, you work on a public api, library - documentation.

<!-- is it the velocity that matters? -->

Got better reasons for commenting code?

<!-- code never lies comments do often -->

<!-- reasons to comment: there's an issue, something is not obvious, there's a pitfall... -->


<!-- 

I've talked with people outraged at this position. _What if there's a pitfall in that piece of code? Wouldn't you rather wanna know about that?_ If there really is a pitfall, there are so many ways you can do better than a code comment. Actually, why would you leave a pitfall in the code in the first place? Why not fix it instead? Putting a comment makes you feel justified - for a wrong reason, because you haven't improved anything. If it needs fixing, but you cannot do it at the moment - create a ticket for it. 

Do you wanna make sure that an assumption is valid? Write a test for it.


-->


