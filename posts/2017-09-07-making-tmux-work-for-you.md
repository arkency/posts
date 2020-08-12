---
created_at: 2017-09-07 09:44:03 +0200
publish: true
author: Tomasz Wróbel
tags: [ 'tmux', 'microservices', 'tools', 'workflow', 'productivity' ]
newsletter: arkency_form
---

# Making tmux work for you

<%= img_fit("making-tmux-work-for-you/niv-rozenberg-356666.jpg") %>

When it comes to my developer toolset, **I like solutions that I can easily understand and tweak**. I guess I'm not the only one. I believe that for a lot of people one of the (many) reasons to join the Ruby bandwagon was that you could do virtually everything without a big, fat IDE, that I never know what it's doing and how. Just your editor and console. First class citizens.

<!-- more -->

### Boring introduction

And I still like this kind of workflows. But, let's be honest, sometimes there are moments, that you wish your tools did a little better when it comes to helping you with **tedious tasks**.

You can often find an editor plugin that does what you need. And it's fine. But sometimes you're like: **do I really need to pull another plugin to do this simple thing?**. After all, we're programmers. We can program basically anything, why not our developer environments.

It seems to me, that often what we need are just the proper building blocks.

`tmux` is one of such building blocks, that can really help you a lot when it comes to automating your developer workflows. Generally one could say it's a `screen` on steroids. It let's you manage terminal sessions and interact with them programmatically.

On Mac OS you can install it with `brew install tmux`.

It's a powerful and versatile tool - a lot of people us it for a lot of different things. I'm neither a heavy, nor a longtime tmux user, but let me present a couple problems where it paid off for me. I'm not encouraging you to adopt "full tmux workflow", whathever that means, but maybe it'll show how you can easily solve a specific problem yourself.

## Solution 1 - launching gazzillion servers locally

<%= img_fit("making-tmux-work-for-you/tmux_screenshot.png") %>

Sometimes you work on a project with one rails server and probably a background worker. Not a big deal to launch when you start your work in the morning. But what when you have **10 microservices**? You don't want to do it by hand.

Of course, there are so many tools that can help you with that, pow, puma-dev, docker, whatever. But you don't always wanna learn and employ **a new tool to do a dead simple thing** like launching a server. You wanna keep it simple, and not spend a day on configuring a specific solution.

How did tmux help me with that? I simply wanted something that will just "prepare" terminal windows for me, so that I can later interact with them in a "typical" way, like `^C` to kill the process, then press up and enter to start it again, rather that running the processes in the background, etc. I often want to tweak my workflow step by step, rather than by revolution.

So `tmux` has this nice command "send-keys". What does it do? Yup, **it sends a particular key sequence to the terminal session**. As simple as that. Let's have a look at this sample tmux invocation:

```
tmux \
  new-session -s your_session_name                                       \; \
  send-keys -t :0 "cd ~/app_1" Enter "bundle exec rails s -p 5000" Enter \; \
  new-window                                                             \; \
  send-keys -t :1 "cd ~/app_2" Enter "bundle exec rails s -p 6000" Enter \; \
  new-window                                                             \; \
  send-keys -t :2 "cd ~/app_3" Enter "bundle exec rails s -p 7000" Enter 

```

One `tmux` binary invocation let's you specify multiple tmux-commands:

* `new-session` starts a new session with given name, that you can later identify it with in `-t` options
* `new-window` opens another window within a session. They're identified with numbers like this: `-t :1`
* `send-keys` - tmux tries to make it easy for you and guess whether you meant a key or literal sequence: `Enter` does what you'd (not) expect


### Basic usage

Once you launch your script, you can:

* press `ctrl+b` followed by window number to **switch window** 
* press `ctrl+b` followed by `d` to **detach** from the session - now everything is in the background (`ctrl+b` prefixes all tmux hotkeys; people often sometimes it to `ctrl+a`)
* run `tmux a` to **attach** to it again. Add `-t your_session_name` if you have more of them
* run `tmux kill-session -t your_session_name` to **quit** everything. Same as exiting every terminal window one by one.
* run `tmux ls` to see all the sessions

### Tweaking the config

You'll find your tmux config in `~/.tmux.conf`:

* remap alt+left & alt+right to easily switch to the **left/right window**:

```
bind -n M-Left select-window -p
bind -n M-Right select-window -n
``` 
* start **window numbers from 1** to match keyboard ordering

```
set -g base-index 1
set-window-option -g pane-base-index 1
```

### More goodies

* give your **windows specific names** to show up on the status bar: just do this `new-window -n app_1_bg_worker` in the launching snippet
* start the session **initially detached**: `new-session -d`
* put it all in a handy script in you PATH - so that you can later just type `myproject start|quit` from any directory
* if you use **iterm** on Mac OS, you can enable tmux integration and attach to the session like this: `tmux -CC a` - this way your tmux session will appear **as a normal iterm session** and you can use all your hotkeys as you normally do

### Working with multiple repos?

By the way, if you sometimes happen to work with multiple repos, you might wanna have a look at this shell-one-liner: [multigit](https://github.com/arkency/multigit) - it lets you run (git) commands on all "sibling" repos.

## Solution 2 - spinning off builds/tests in a terminal session

...to come in another blogpost - but the building blocks are the same, no additional magic needed :)

