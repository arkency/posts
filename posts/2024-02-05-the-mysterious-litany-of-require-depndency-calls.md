---
created_at: 2024-02-05 16:33:07 +0100
author: Piotr Jurewicz
tags: [ 'rails', 'zeitwerk', 'autoload' ]
publish: true
---

# The mysterious litany of `require_dependecy` calls

One of the challenges we faced when working on a huge legacy app tech stack upgrade was switching from the obsolete
classic autoloader to the modern one, [Zeitwerk](https://github.com/fxn/zeitwerk).

It is optional starting from Rails 6 but gets mandatory in Rails 7.

Once, we were on Rails 6 and managed to apply most of the new framework defaults, we decided it was high time to switch
to __Zeitwerk__.

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
# Pre-loading all the Reporting modules, otherwise we
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
Example: `lib/report/PL/X123/products`

## Classic autoloader

With a classic autoloader, and eager loading disabled, it goes from a const name to a file name by
calling `Report::PL::X123.to_s.underscore` which results in `report/pl/x123/products`.

This magic happens in the `Module#const_missing` method invoked each time a reference is made to an undefined constant
_(analogous to the well-known_ `method_missing` _callback)_.
Standard Ruby implementation of this method raises an error, but Rails overrides it and tries to locate the file in one
of the autoloaded directories.

However, there was no such file like `report/pl/x123/products.rb` from the case-sensitive file system perspective and
that's the clue why NameErrors were spotted in production unless we eagerly loaded the whole codebase at boot time _(in
case of eager loading being enabled, Rails loads all files in the_ `eager_load_paths` _during boot)_.

### case-insensitive file system (development - macOS)

```
❯ ls lib/report/PL/X123/products.rb
lib/report/PL/X123/products.rb

❯ ls lib/report/pl/x123/products.rb
lib/report/pl/x123/products.rb
```

### case-sensitive file system (production - linux)

```
$ ls lib/report/PL/X123/products.rb
lib/report/PL/X123/products.rb

$ ls lib/report/pl/x123/products.rb
ls: cannot access 'lib/report/pl/x123/products.rb': No such file or directory
```

## How things changed with Zeitwerk

Zeitwerk autoloader works in the opposite way.

It goes from a file name to a const name by listing files from the autoloaded directories and
calling `.delete_suffix!(".rb").camelize` on each of them.
It takes [inflection](https://github.com/fxn/zeitwerk?tab=readme-ov-file#inflection) rules into account, resulting
in `Report::PL::X123::Products` no matter whether file system is case-sensitive or not.

It utilizes `Module#autoload` built-in Ruby feature to specify the file where the constant should be loaded from:

```ruby
# at boot time
autoload :Report, Rails.root.join('lib/report')
# on first Report reference
Report.autoload :PL, Rails.root.join('lib/report/pl')
# on first Report::PL reference
Report::PL.autoload :X123, Rails.root.join('lib/report/PL/x123')
# on first Report::PL::X123 reference
Report::PL::X123.autoload :Products, Rails.root.join('lib/report/PL/X123/products.rb')
```

It simply says:
> When you encounter `Report::PL::X123::Products` and it will be missed in a constant table,
> load `lib/report/PL/X123/products.rb`

Knowing that we felt fully confident to remove the initializer with its mysterious `require_dependency` litany and
switch to Zeitwerk. It went very smoothly and NameErrors never appeared again.
___
Anyway, from now on, I will always be suspicious when I see capitalized file names in the project tree.