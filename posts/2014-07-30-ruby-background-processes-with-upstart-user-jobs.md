---
title: "Ruby background processes with upstart user jobs"
created_at: 2014-07-30 12:43:28 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :arkency_form
tags: [ 'upstart', 'background', 'process' ]
---

<p>
  <figure align="center">
    <img src="http://upstart.ubuntu.com/img/upstart80.png" width="50%">
  </figure>
</p>

Recently, my colleague at Arkency [Paweł Pacana](https://twitter.com/pawelpacana) wanted to manage application process with upstart. He started with [the previous article about upstart](http://blog.arkency.com/2014/06/create-run-and-manage-your-background-processes-with-upstart/) and finished with robust deployment configuration with reliable setup using... runit. He summarised upstart briefly: *"so sudo"* so I decided to extend my latest blogpost with some information about **upstart user jobs**.

<!-- more -->

Although I am glad that my article was inspiring, it turned out not to be comprehensive enough. I decided to extend it, so that anyone can use `upstart` in every environment.

## Where's the problem?

Last time we managed to run our job in a way that the `deployer` required `sudo` privileges to manage the application. However the user should be able to do all that without the root permissions. The whole reason for having the deployer user is to manage his own application without any additional requirements.

## Services directory

In regular way upstart keeps all of the `.conf` files in `/etc/init/`.

We need to change it now to user own (home) directory,

```
mkdir ~/.init
mv /etc/init/my_application.conf ~/.init
```

## Enabling user jobs

We have to modify upstart configuration to be able to run user jobs. Open it with your favourite text editor: `/etc/dbus-1/system.d/Upstart.conf`.

To support fully functionality it should look like:

```
<policy context="default">
  <allow send_destination="com.ubuntu.Upstart"
      send_interface="org.freedesktop.DBus.Introspectable" />
  <allow send_destination="com.ubuntu.Upstart"
      send_interface="org.freedesktop.DBus.Properties" />
  <allow send_destination="com.ubuntu.Upstart"
      send_interface="com.ubuntu.Upstart0_6" />
  <allow send_destination="com.ubuntu.Upstart"
      send_interface="com.ubuntu.Upstart0_6.Job" />
  <allow send_destination="com.ubuntu.Upstart"
      send_interface="com.ubuntu.Upstart0_6.Instance" />
</policy>
```

Once you've modified your upstart job you need to restart dbus the last time using `sudo` privileges:

```
sudo service dbus restart
```

## Configuring user `.conf` file

When we move `my_program.conf` into `~/.init`, upstart will no longer log its output, so you won't be able to see any errors, we need to modify `my_program.conf` now.

So there are a few changes we need to add to get `my_program.conf` working right:

```
#~/.init/my_program.conf

# append path to your other executables:
env PATH=/var/www/myprogram.com/current/bin:/usr/local/rvm/wrappers/my_program/

setuid deployer

chdir /var/www/myprogram.com

pre-start script
  exec >/home/deployer/my_program.log 2>&1
end script
```

Remember to update your `$PATH` from `my_program.conf`, forward output to `.log` file and set user name before process run.

**Note**

If you have user belonging to some group, you'll have to define this group in `my_program.conf` too as `setgid GROUP_NAME`. See more about that:
- http://bit.ly/upstart-need-setgid
- http://bit.ly/upstart-set-user-and-group

## That's all!

Now you will be able to `start my_program` without appending `sudo` anymore.

**Reference**

- http://upstart.ubuntu.com/cookbook/#user-job
- http://askubuntu.com/questions/153064/user-upstart-job-in-init-is-not-found
- https://bazaar.launchpad.net/~upstart-devel/upstart/trunk/view/head:/dbus/Upstart.conf
- http://superuser.com/a/471957/171767