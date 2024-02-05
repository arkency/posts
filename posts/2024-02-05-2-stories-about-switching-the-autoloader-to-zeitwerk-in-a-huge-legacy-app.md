---
created_at: 2024-02-05 16:33:07 +0100
author: Piotr Jurewicz
tags: [ ]
publish: false
---

# 2 stories about switching the autoloader to Zeitwerk in a huge legacy app

One of the challenges we faced when working on a huge legacy app tech stack upgrade was switching the autoloader
to [Zeitwerk](https://github.com/fxn/zeitwerk).
It is optional in Rails 6, but gets mandatory in Rails 7.
Once, we were on Rails 6 and manged to apply most of new framework defaults, we decided it's high time to switch to
Zeitwerk.

# Story 1: The mysterious litany of `require_dependecy` calls

Spending a lot of time with this codebase we came across one very large initializer with above 300
of `require_dependency` calls.

It was pointing to a source files which all were located under autoloaded directories. The first red flag.

[The official Rails documentation](https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html#delete-require-dependency-calls)
clearly states:
<blockquote>
All known use cases of require_dependency have been eliminated with Zeitwerk. You should grep the project and delete them.
</blockquote>
But first, we wanted to make sure that we understand why this file was even there and what is the story behind it.
It started with an ominous comment:

```ruby
# Pre-loading all the Rating Engine modules, otherwise we
# might get uninitialized constant errors (typically on rake tasks)
```

Pretty scary, right? Yeah, I thought so too. Who wants to introduce NameErrors in production? Not me, for sure.

In fact, we managed to find some traces of those errors in Sentry, but couldn't reproduce them locally. We started digging deeper and looked at the differences between theses environments.

- In `production.rb` we had eager loading enabled which is totally standard for performance-oriented environments. However, it found out that [this setting do not affect rake tasks](https://www.codegram.com/blog/rake-ignores-eager-loading-rails-config/).
Rake tasks, even though run in production environment, simmilarly to development environment, did not eager load the codebase.

- Production pods were run on some Debian-based Linux distribution, while our local development environment was macOS. We found out that the file system on macOS is case-insensitive by default, while on Linux it is case-sensitive.

# Story 2: Lack of consistency in using acronyms