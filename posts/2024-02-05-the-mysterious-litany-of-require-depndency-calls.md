---
created_at: 2024-02-05 16:33:07 +0100
author: Piotr Jurewicz
tags: [ rails zeitwerk ]
publish: false
---

# The mysterious litany of `require_dependecy` calls

One of the challenges we faced when working on a huge legacy app tech stack upgrade was switching the autoloader
to [Zeitwerk](https://github.com/fxn/zeitwerk).

It is optional starting from Rails 6 but gets mandatory in Rails 7.

Once, we were on Rails 6 and managed to apply most of the new framework defaults, we decided it was high time to switch
to
Zeitwerk.

#### ...This is where the story begins...

Spending a lot of time with this codebase we came across one very large initializer with above 300
of `require_dependency` calls.

The first red flag was that all the files listed in the initializer were located under autoloaded directories.

[The official Rails documentation](https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html#delete-require-dependency-calls)
clearly states:
> All known use cases of require_dependency have been eliminated with Zeitwerk. You should grep the project and delete
> them.

But first, we wanted to make sure that we understood why this file was even there and what is the story behind it.
It started with an ominous comment:

```ruby
# Pre-loading all the Rating Engine modules, otherwise we
# might get uninitialized constant errors (typically on rake tasks)
```

Pretty scary, right? Yeah, I thought so too. Who wants to introduce NameErrors in production? Not me, for sure.

In fact, we managed to find some traces of those errors in Sentry, but couldn't reproduce them locally. We started
digging deeper and looked at the differences between these environments.

- In `production.rb` we had eager loading enabled which is totally standard for performance-oriented environments.
  However, it was found out
  that [this setting does not affect rake tasks](https://www.codegram.com/blog/rake-ignores-eager-loading-rails-config/).
  Rake tasks, even though run in a production environment, similarly to the development environment, do not eager-load
  the codebase.

- Production pods were run on some Debian-based Linux distribution, while our local development environment was macOS.
  We found out that the file system on macOS is case-insensitive by default, while on Linux it is case-sensitive.

We have also noticed that files listed in the mysterious initializer had unusual capitalization in their paths.
Example: `lib/raport/PL/X123/products`

## Classic autoloader

With a classic autoloader, and eager loading disabled, it goes from a const name to a file name by
calling `Raport::PL::X123.to_s.underscore` which results in `raport/pl/x123/products`.

This magic happens in the `Module#const_missing` method invoked when a reference is made to an undefined constant.
Standard Ruby implementation of this method raises an error, but Rails overrides it and tries to locate the file in one
of the autoloaded directories.

However, there was no such file like `raport/pl/x123/products.rb` from the case-sensitive file system perspective and
that's the clue why NameErrors were spotted in production unless we eagerly loaded the whole codebase at boot time.

### case-insensitive file system (development - macOS)

```
❯ ls lib/raport/PL/X123/products.rb
lib/raport/PL/X123/products.rb

❯ ls lib/raport/pl/x123/products.rb
lib/raport/pl/x123/products.rb
```

### case-sensitive file system (production - linux)

```
$ ls lib/raport/PL/X123/products.rb
lib/raport/PL/X123/products.rb

$ ls lib/raport/pl/x123/products.rb
ls: cannot access 'lib/raport/pl/x123/products.rb': No such file or directory
```

## How things changed with Zeitwerk

Zeitwerk autoloader works in the opposite way.

It goes from a file name to a const name by listing all files from the
autoloaded directories and calling `.delete_suffix!(".rb").camelize` on each of them.
It takes [inflection](https://github.com/fxn/zeitwerk?tab=readme-ov-file#inflection) rules into account, resulting
in `Raport::PL::X123::Products` no matter whether file system is case-sensitive or not.

It utilizes `Module#autoload` built-in Ruby feature to specify the file where the constant should be loaded from:

```ruby
# at boot time
autoload :Raport, Rails.root.join('lib/raport')
# on first Raport reference
Raport.autoload :PL, Rails.root.join('lib/raport/pl')
# on first Raport::PL reference
Raport::PL.autoload :X123, Rails.root.join('lib/raport/PL/x123')
# on first Raport::PL::X123 reference
Raport::PL::X123.autoload :Products, Rails.root.join('lib/raport/PL/X123/products.rb')
```

It simply says:
> When you encounter `Raport::PL::X123::Products` and it will be missed in a constant table,
> load `lib/raport/PL/X123/products.rb`.

Knowing that we felt fully confident to remove the initializer with its mysterious `require_dependency` litany and
switch to Zeitwerk. It went smoothly.
___
Anyway, from now on, I will always be suspicious when I see capitalized file names in the codebase.