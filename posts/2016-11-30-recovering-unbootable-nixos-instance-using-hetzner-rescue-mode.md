---
title: "Recovering unbootable NixOS instance using Hetzner rescue mode"
created_at: 2016-11-30 19:37:19 +0100
kind: article
publish: true
author: Rafał Łasocha
tags: [ 'nixos', 'hetzner', 'devops' ]
newsletter: arkency_form
---

Some time ago we had a small fuckup with one of our CI build machines. One of the devs was changing sizes of the file system partitions and he forgot to commit new NixOS configuration to the git repository where we synchronize it. After some time, I've uploaded NixOS config from git repo (which had, like I said, outdated configuration) to the machine and run `nixos-rebuild --switch` which essentialy made system into unbootable state because of wrong UUIDs in `/etc/fstab`.

<!-- more -->

It was only a one of our build machines (nothing extremely critical to fix) and thankfully we had good scripts for provisioning new build machine, so if I wanted to, I could easily just run a bunch of scripts and create new build machine from scratch. **I was curious however, whether NixOS could deliver what it is promising and give me a way to easily rollback to previous, correct configuration of our system.**

Firstly we've enabled Hetzner's rescue mode for that machine and logged in through SSH. I've mounted root and boot partitions of our build machines. Then my plan was to chroot into system and run NixOS rollback configuration command to restore the previous configuration. There are a few links on the Internet explaining that it is possible to chroot into NixOS root partiton but with neither of them I was able to run `nixos-rebuild` command - mostly it was errors about dbus or other services not running in chroot environment.

In the end it turned out that **I've forgotten about one of the NixOS core sales-pitch features: each system configuration is a separate entry in the GRUB config**. I quickly forgot that, because for me it looked like a feature which is useless in server environment - in the end, you don't have access to GRUB menu when booting a server machine, right? Not quite. There's at least one useful command you can use, `grub-reboot`, which basic functionality is _"During next boot, instead of entry X, use entry Y as a default"_. **Thus, the only thing I need was to execute one command and reboot the machine:**

```
grub-reboot --boot-directory=/mnt/boot "NixOS - Configuration 4 (2016-09-10 - 16.03.git.2ed3eee)"
```

After reboot I had my old, working configuration (`configuration 4`) so I was able to upload the correct `/etc/nixos/configuration.nix` file and rerun `nixos-rebuild --switch` to create new, working configuration (`configuration 6`) as a default one, instead of invalid one (`configuration 5`).

It was my first opportunity to fix broken NixOS system. What are your experiences with such situations? Let me know if you know better ways of handling such cases.

_During working on this task I was looking for a blogpost like that and I've found none. So now, there's at least one :)_
