---
title: "Create, run and manage your background processes"
created_at: 2014-06-29 16:21:01 +0200
kind: article
publish: false
author: Kamil Lelonek
newsletter: :arkency_form
tags: [ 'upstart', 'background', 'process' ]
---

<p>
  <figure align="center">
    <img src="http://upstart.ubuntu.com/img/upstart80.png" width="50%">
  </figure>
</p>

Have you ever wanted to run some of your **ruby program as a background service**? There are a couple ways to do that starting from simple `&`, through `runit` to complex services.

This tutorial is intended to give you a quick overview of `upstart`, which is one of the possible solutions to run and manage your background processes.

<!-- more -->

## What is upstart?
According to [upstart homepage](http://upstart.ubuntu.com/index.html):

> Upstart is an event-based replacement for the /sbin/init daemon which handles starting of tasks and services during boot, stopping them during shutdown and supervising them while the system is running.

> It was originally developed for the Ubuntu distribution, but is intended to be suitable for deployment in all Linux distributions as a replacement for the venerable System-V init.

## How to use it?

[In properly set up production environment there is no ruby version manager](http://blog.arkency.com/2012/11/one-app-one-user-one-ruby/). Using **one ruby per user** makes your script extremely easy to run and there's no need to provide any special configuration here.

Unfortunately, there are still some environments, which use `rvm` or `rbenv` so, to make this article comprehensive, we need to show how to configure at least one of them.

Let's choose `rvm` for managing rubies. You'll need to create [wrapper](https://rvm.io/integration/init-d) for ruby executable to be accessible from `my_program.conf`.

According to [rvm website](https://rvm.io/rubies/alias) it can be done via simple command:


```
#!ruby
rvm alias create my_program ruby-2.0.0-p247
```

Now your ruby bin can be found under:

```
#!ruby
/usr/local/rvm/wrappers/my_program/ruby
```	

Then, create configuration file that contains script to be executed in a background job:

```
#!ruby
vim /etc/init/my_program.conf
```

It's time to start writing your script.
	
  a) You have to tell your script when to run and `start on` command is used for that. The syntax looks like:

```
#!ruby
start on <your_command>
```


`<your_command>` can be for example:


```
#!ruby
	- startup				# start a job as early as possible
	- filesystem 			# start after all filesystems are mounted
	- started networking 	# start after network is connected
	- custom_command 		# start job only on demand after explicitly run by user
```

  b) In the same way you can define `stop on` command.
	
  c) The very next command is `respawn` which tells your process to run after being killed.
	
  d) You can execute your program right now, and there are two way of doing so. `execute` is one-liner keyword to run simple script, block


```
#!ruby		
		script
		# ...
		end script
```
		
is for multiline code.
	
  e) our `conf` file might look like:


```
#!ruby	
		start on my_event
		respawn
		script
			cd /home/my_program/
			/usr/local/rvm/wrappers/my_program/ruby my_program
		end script
```
		
How to run our program? As you might have guessed, there a couple ways to do that.

  a) when we run our script on custom event you can run it like

```
#!ruby	
sudo initctl emit my_event
```

  b) if you want use old service syntax you can do:

```
#!ruby	
sudo service my_program start
```
		
  c) you can do also:

```
#!ruby	
sudo initctl start my_program
```

I recommend you to use [initctl](http://manpages.ubuntu.com/manpages/quantal/en/man8/initctl.8.html), which offers quite nice helpers like:

```
#!ruby
		list 		# lists registered services and their state
		restart		# restarts our script
		stop 		# stops script
		status		# displays job status
```

If you want to see execution logs (to check whether everything goes correctly) there's a handy way to display them:

```
#!ruby
		sudo tail -f /var/log/upstart/my_program.log
```

## Summary
On the very end I'd like to recommend you a bunch of resources containing many examples and explanations of what we've done here. This article only scratches the surface of powerful `upstart` tool. Please dive into following links to get more information about it.

## Resources:
- http://upstart.ubuntu.com/wiki/Stanzas
- http://upstart.ubuntu.com/cookbook/
- http://upstart.ubuntu.com/getting-started.html
- https://help.ubuntu.com/community/UbuntuBootupHowto
- https://help.ubuntu.com/community/UpstartHowto
- http://manpages.ubuntu.com/manpages/trusty/en/man8/runlevel.8.html