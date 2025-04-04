---
created_at: 2025-04-04 09:27:12 +0200
author: Szymon Fiedler
tags: [ruby, rails, bundler, legacy]
publish: false
---

# Installing Precompiled Native Gems with bundle lock --add-platform

There's a great chance that your Ruby app occasionally explodes during bundle install because of native extensions. There's an even greater chance that it happens with `nokogiri`, `ffi` or some other notorious gem with C extensions. The problem gets worse when you're working across different operating systems or upgrading Ruby versions. Let's fix this once and for all.

<!-- more -->

## My problem with native gems

As we perform a ton of [Ruby and Rails upgrades](https://arkency.com/ruby-on-rails-upgrades/) across different projects at arkency, we were struck by those issues many times.

My main concern with native gems is that they create unnecessary friction in your development and deployment workflow:

* Every single `bundle install` takes ages if compilation has to occur
* Ruby version upgrades? Prepare to recompile everything
* Different OS than your teammates? Enjoy your unique set of errors
* CI pipeline running slow? Blame those C extensions
* YJIT performance gains are limited with C extensions

This last point is often overlooked. Ruby’s YJIT (Yet Another Just–In–Time compiler) can significantly speed up your application, but it works best with pure Ruby code. C extensions bypass the Ruby VM, which means YJIT can’t optimize them. The more your app relies on native extensions, the fewer benefits you’ll see from YJIT. With Ruby 3.3, YJIT can be enabled with the `--yjit` flag, so you’re potentially missing out on free performance gains, but [Rails will do it for you](https://github.com/rails/rails/pull/49947). 

Btw. here’s excellent [article on speeding up Ruby by rewriting C... in Ruby](https://jpcamara.com/2024/12/01/speeding-up-ruby.html).

It’s particularly frustrating on deployment. You’ve built a beautiful containerized setup, but still need to install build dependencies just to compile the same gems over and over. Your Docker images are bloated with compilers and dev headers that serve no purpose in production.

## It’s not a new problem
What inspired me to share this solution with you is a [recent chat with my friend](/rails-when-nothing-changed-is-the-best-feature/), especially this part:

> Recently I had to implement a tiny backend app. I dusted off Rails and everything was the same. Same commands, same gems, even nokogiri crashed the same way during bundle install like 10 years ago...

It doesn’t have to be that way, I thought.

## Bundler, the hero we need

Here it comes: `bundle lock --add-platform`.

This command tells Bundler to resolve dependencies for platforms other than your current one and store that information in your `Gemfile.lock`. When these platforms provide precompiled versions, Bundler will use them instead of trying to compile from source.

The `--add-platform` option has been available since Bundler `2.2.0`, so make sure you’re running a recent version . This can be easily checked with `bundle -v`.

If for some reason your `Gemfile.lock` is lacking `PLATFORMS` section, e.g. you’re upgrading good’ol app, you should follow next steps.

If your `Gemfile.lock` has `PLATFORMS` present, but it’s lacking the specific platform you run your app on, you should follow my article.


## What are the PLATFORMS?

The answer is simple and lives on your machine:

```
➜  gem help platform
RubyGems platforms are composed of three parts, a CPU, an OS, and a
version.  These values are taken from values in rbconfig.rb.  You can view
your current platform by running `gem environment`.

RubyGems matches platforms as follows:

  * The CPU must match exactly unless one of the platforms has
    "universal" as the CPU or the local CPU starts with "arm" and the gem's
    CPU is exactly "arm" (for gems that support generic ARM architecture).
  * The OS must match exactly.
  * The versions must match exactly unless one of the versions is nil.

For commands that install, uninstall and list gems, you can override what
RubyGems thinks your platform is with the --platform option.  The platform
you pass must match "#{cpu}-#{os}" or "#{cpu}-#{os}-#{version}".  On mswin
platforms, the version is the compiler version, not the OS version.  (Ruby
compiled with VC6 uses "60" as the compiler version, VC8 uses "80".)

For the ARM architecture, gems with a platform of "arm-linux" should run on a
reasonable set of ARM CPUs and not depend on instructions present on a limited
subset of the architecture.  For example, the binary should run on platforms
armv5, armv6hf, armv6l, armv7, etc.  If you use the "arm-linux" platform
please test your gem on a variety of ARM hardware before release to ensure it
functions correctly.

Example platforms:

  x86-freebsd        # Any FreeBSD version on an x86 CPU
  universal-darwin-8 # Darwin 8 only gems that run on any CPU
  x86-mswin32-80     # Windows gems compiled with VC8
  armv7-linux        # Gem complied for an ARMv7 CPU running linux
  arm-linux          # Gem compiled for any ARM CPU running linux

When building platform gems, set the platform in the gem specification to
Gem::Platform::CURRENT.  This will correctly mark the gem with your ruby's
platform.
```

## Prerequisites

### Modern tooling

Make sure you have recent Bundler and Rubygems, just to avoid hiccups and benefit from improvements:

```
gem install bundler
gem update --system
```

If new version of bundler has been installed, make sure to let your `Gemfile.lock` to be aware of it:

```
bundle update --bundler

git add Gemfile.lock
git commit -m "Updated bundler"
```

### Precompiled gem versions available for your platform

I recommend going to [Rubygems](https://rubygems.org) page and checking versions page of a desired gem, let’s use [nokogiri](https://rubygems.org/gems/nokogiri/versions) as an example.

For the day of writing this post, `1.18.7` is the most recent version. You’ll see raw version (compiled on your machine):

```
1.18.7 March 31, 2025 (4.16 MB)
```

along with precompiled ones:

```
1.18.7 March 31, 2025 x86_64-linux-gnu (3.88 MB)
1.18.7 March 31, 2025 arm-linux-gnu (3.25 MB)
1.18.7 March 31, 2025 aarch64-linux-gnu (3.8 MB)
1.18.7 March 31, 2025 arm-linux-musl (3.44 MB)
1.18.7 March 31, 2025 x86_64-linux-musl (3.87 MB)
1.18.7 March 31, 2025 arm64-darwin (6.23 MB)
1.18.7 March 31, 2025 x86_64-darwin (6.4 MB)
1.18.7 March 31, 2025 aarch64-linux-musl (3.77 MB)
1.18.7 March 31, 2025 java (9.88 MB)
1.18.7 March 31, 2025 x64-mingw-ucrt (6.02 MB)
```


### Updated `Gemfile.lock` with platform–specific dependencies

The rule of thumb for me is adding platforms below:

```shell
bundle lock --add-platform arm64-darwin
Writing lockfile to /Users/fidel/code/Gemfile.lock
bundle lock --add-platform x86_64-darwin
Writing lockfile to /Users/fidel/code/Gemfile.lock
bundle lock --add-platform x86_64-linux
Writing lockfile to /Users/fidel/code/Gemfile.lock

bundle install

git add Gemfile.lock
git commit -m "Use precompiled gems for all the platforms"
```

The example above covers the most common platforms for Rails development:

* Intel/AMD Linux (most servers)
* Apple Silicon (M1/M2/M3/M4 and counting Macs)
* Intel Macs — as not everyone is running cutting–edge hardware

Obviously, you can add any other platform that you need.

Enjoy no surprises during deployment or next Ruby upgrade.

## Forget everything I’ve told you so far

If you’re running a modern Bundler, it will do the platform job for you:

```
➜  cat Gemfile
source "http://rubygems.org"

gem "nokogiri"

➜  bundle
Fetching gem metadata from http://rubygems.org/.......
Resolving dependencies...
Fetching nokogiri 1.18.7 (arm64-darwin)
Installing nokogiri 1.18.7 (arm64-darwin)
Bundle complete! 1 Gemfile dependency, 3 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

➜  cat Gemfile.lock
GEM
  remote: http://rubygems.org/
  specs:
    nokogiri (1.18.7-aarch64-linux-gnu)
      racc (~> 1.4)
    nokogiri (1.18.7-aarch64-linux-musl)
      racc (~> 1.4)
    nokogiri (1.18.7-arm-linux-gnu)
      racc (~> 1.4)
    nokogiri (1.18.7-arm-linux-musl)
      racc (~> 1.4)
    nokogiri (1.18.7-arm64-darwin)
      racc (~> 1.4)
    nokogiri (1.18.7-x86_64-darwin)
      racc (~> 1.4)
    nokogiri (1.18.7-x86_64-linux-gnu)
      racc (~> 1.4)
    nokogiri (1.18.7-x86_64-linux-musl)
      racc (~> 1.4)
    racc (1.8.1)

PLATFORMS
  aarch64-linux-gnu
  aarch64-linux-musl
  arm-linux-gnu
  arm-linux-musl
  arm64-darwin
  x86_64-darwin
  x86_64-linux-gnu
  x86_64-linux-musl

DEPENDENCIES
  nokogiri

BUNDLED WITH
   2.6.5
```

See, I didn’t even need to lock platforms manually. However, it added all the platforms this particular gem is available for. Except Windows and Java ones — coincidence? ;)

But I think that less is more and I prefer keeping `Gemfile.lock` as minimal as possible. And yes, there’s a command for that:

```
bundle lock --remove-platform x86_64-linux-musl
Writing lockfile to /Users/fidel/code/Gemfile.lock
bundle lock --remove-platform aarch64-linux-gnu
Writing lockfile to /Users/fidel/code/Gemfile.lock
bundle lock --remove-platform aarch64-linux-musl
Writing lockfile to /Users/fidel/code/Gemfile.lock
bundle lock --remove-platform arm-linux-musl
Writing lockfile to /Users/fidel/code/Gemfile.lock
bundle lock --remove-platform arm-linux-gnu
Writing lockfile to /Users/fidel/code/Gemfile.lock

➜  cat Gemfile.lock
GEM
  remote: http://rubygems.org/
  specs:
    nokogiri (1.18.7-arm64-darwin)
      racc (~> 1.4)
    nokogiri (1.18.7-x86_64-darwin)
      racc (~> 1.4)
    nokogiri (1.18.7-x86_64-linux-gnu)
      racc (~> 1.4)
    racc (1.8.1)

PLATFORMS
  arm64-darwin
  x86_64-darwin
  x86_64-linux-gnu

DEPENDENCIES
  nokogiri

BUNDLED WITH
   2.6.5
```

It removed `PLATFORMS` entries and sufficient gems specifications we aren’t planning on using.

Enjoy your fast and predictable builds 🖖