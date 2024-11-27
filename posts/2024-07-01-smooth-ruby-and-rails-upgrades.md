---
created_at: 2024-07-01 13:30:20 +0200
author: Piotr Jurewicz
tags: ['ruby', 'rails', 'ruby upgrade', 'rails upgrade']
publish: true
---

# Smooth Ruby and Rails upgrades

Recently, we were consulting and performing updates for several different outdated projects.
Those were production-running, keeping the business alive, but they haven't been upgraded for a long time.

With the experience from those projects, I'm ready to share some insights on how to make the upgrade process smooth.

## Before you start

### Reduce dependencies
To make the whole process simpler, I always start with auditing the Gemfile.

I check if there are any gems that are not supposed to be there anymore, and usually, find some of them.
Especially, I look for:
- Gems that are not referenced in the code.

However, you should be careful with this one, because sometimes gems may be used in a non-obvious way. They can extend or patch some Ruby or Rails classes. We had such a hard experience with `active_model_serializers` gem for example.
- Gems that are trivial to inline.

For example, if you use a single 5-line method from a huge unmaintained gem, it's better to copy-paste it to your codebase. You won't encounter any problems with this gem's requirements later in the upgrade process.
- Gems that duplicate the functionality of the framework.

`activerecord-import` is a good example. It was super useful prior to Rails 6, but if you're on Rails 6 or newer, you can use built-in functions instead.

Another example is `aasm` gem. Recently, Szymon wrote a [great blog post](https://blog.arkency.com/replace-aasm-with-rails-enum-today/) on how to replace it with Rails' built-in enum feature.

### Mitigate security issues
Another thing I always check in the very beginning is common vulnerabilities and exposures ([CVE](https://www.cve.org)s).

I use `bundler-audit` gem to check if there are any known security issues with the gems present in the Gemfile.
Running `bundle audit`, you obtain a list of vulnerabilities with criticality levels and recommendations on how to fix them. If I see some important ones, I tackle them before the other upgrades.

### Make sure you collect deprecation warnings
It’s quite common to handle deprecation warnings coming from Rails, but, I rarely see projects configured properly to handle deprecation warnings coming from Ruby itself.

I've written a whole blog post on how to handle Ruby deprecation warnings, you can check it out [here](https://blog.arkency.com/do-you-tune-out-ruby-deprecation-warnings/).

## The upgrade map

### Semantic versioning
The entity providing the software usually follows the rules of [Semantic Versioning (SemVer)](https://semver.org):
> Given a version number MAJOR.MINOR.PATCH, increment the:
> - MAJOR version when you make incompatible API changes
> - MINOR version when you add functionality in a backward compatible manner
> - PATCH version when you make backward compatible bug fixes

In effect, you should know what to expect from the upgrade process based on the version you're upgrading to.

### Semantic versioning in the Rails way
Unfortunately, in practice, different entities implement it in their way.

Rails, for example, follows a [shifted version of SemVer](https://guides.rubyonrails.org/maintenance_policy.html) where minor versions may contain API changes. They are accompanied by deprecation notices in the previous minor or major release.
The difference between Rails' minor and major releases is the magnitude of breaking changes.

Starting with [Rails 4.0.11.1](https://rubyonrails.org/2014/11/19/Rails-4-0-11-1-and-4-1-7-1-have-been-released), the Rails team occasionally releases a version with four components in version numbers.
The story behind this first release is that version 4.0.12 was released with an important security fix.
However, it incorporated additional changes beyond those necessary to resolve the security issue.
To ensure everyone can patch without fear of regressions, the Rails team provided an additional release, which contains only the security fix.

### High-level plan
Consider a scenario that you are on Rails 6.0.2 and aiming for 7.1.3.4 which is the newest version at the time of writing.

That's 94 releases between your current version and the target one.
Would you upgrade in one step? Or would you prefer to do 94 atomic steps for maximum safety?

None of these options sounds good to me. The strategy that works for us is to move by each minor version, always applying the latest patch version.
For this example, there would be 4 steps to take:
- 6.0.2 -> 6.0.6.1 - just to apply the latest patch before moving to the next minor version
- 6.0.6.1 -> 6.1.7.7 - minor version upgrade (to the latest patch version available)
- 6.1.7.7 -> 7.0.8.1 - major version upgrade (to the latest patch version available)
- 7.0.8.1 -> 7.1.3.4 - minor version upgrade (to the latest patch version available)

After taking each step, monitor the application for new issues, collect deprecation warnings, and fix them before moving to the next step.

### Low-level plan
In practice, the upgrade process is more complex than simply transitioning from one version to another. The necessary steps are often unclear until you begin.

Consider you are making a Rails upgrade. So far, you've bumped the version in the Gemfile, run `bundle install` and it failed.
It turned out that you have to update gem `x` first. Then you ran `bundle install` for the second time but it failed again. 
Gem `y` must be updated first to unlock gem `x`. But you can't simply update `y` without adjusting the code first...

Finally, you end up with a `bump-rails` branch with dozens of commits. The actual Rails version change is the last one. What would you do next? Are you bold enough to merge it into the main branch?

At Arkency, we are not. Our approach is to backport all the preparatory commits to the `main` branch one by one, with deployment being done after each significant change.
Once all the required changes are on the `main` branch, you are ready to rebase the `bump-rails` branch on top of it.
It should be reduced to 1-3 commits, which are easy to review and merge. We always strive to make small, easily reversible changes.

### Standard Ruby gems
When upgrading Ruby, there is also a way to split the scope of the upgrade into smaller steps.

Ruby comes with a set of standard libraries that are bundled with the interpreter.
You probably won't find them in the Gemfile, but it's highly likely that your application relies heavily on their specific behavior.

Each Ruby version comes with a different set of standard libraries. Some of them are removed, some are added, and some are updated. Hopefully, you can easily verify which libraries are impacted by the upgrade.
I use the [stdgems.org](https://stdgems.org) website for that purpose.

If you notice any important changes to libraries in the next Ruby version, start by updating them first.
This will require explicit specification in the Gemfile, but it's worth it. Doing so will help make the actual Ruby version change smoother.

## Need help?

If you're struggling with upgrading your Ruby or Rails application, don't hesitate to [contact us](https://arkency.com/hire-us/).

We have experience in upgrading applications of various sizes and complexity levels. We can help you make the process smooth and painless.

## Prefer video?

<iframe style="width:100%; height: 400px;" src="https://www.youtube.com/embed/di4Z2cc12ak?si=v4kEGN_nvpzJ8Wlj" frameborder="0" allowfullscreen></iframe>
