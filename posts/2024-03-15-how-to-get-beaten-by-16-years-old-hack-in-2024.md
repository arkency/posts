---
title: How to get beaten by 16 years old hack in 2024
created_at: 2024-03-15T10:37:05.835Z
author: Paweł Pacana
tags: []
publish: false
---

There's a project I'm consulting on where programmers develop predominantly in cloud environment. This setup simplifies a lot of moving parts and has the benefit of providing everyone homogenous containers to run code. If it runs on my box — it will run on everyone's box. In that case, that box is Linux-based. It has the drawback of having greater latency and being more resource-constrained than a beefy local machine a developer is equipped with, i.e. MacBook Pro running on Apple Silicon.

Recently we've upgraded this development environment from Ruby 3.2.2 to Ruby 3.0.0. The process was smooth and predictable in the cloud environment. It worked on my box and by definition on everyone's boxes. However this wasn't always the case for local machines. The developers who chose to upgrade Ruby on their Macs early, experienced no trouble either. On the other hand, those who procrastinated a bit...

The developers who procrastinated with Ruby upgrade got caught by the new release of Apple's Command Line Tools. If you're curious that version was:

```
$ pkgutil --pkg-info=com.apple.pkg.CLTools_Executables

package-id: com.apple.pkg.CLTools_Executables
version: 15.3.0.0.1.1708646388
volume: /
location: /
install-time: 1710339117
```

Why would a new release of system tooling introduce a burden to run Ruby application on a newer version of Ruby VM? It's the gems! Specifically the gems with C-extensions, that rely on the system tooling to compile its binaries from source.

Among the lines in `Gemfile` one could find these two responsible for remote debugging in cloud development boxes:

```ruby
group :development do
  gem 'ruby-debug-ide', '0.7.3'
  gem 'debase', '0.2.5.beta2'
end
```

The culprit was in the debase gem, which did not build on new Command Line Tools. 

```
msg
```

The build error message suggested the workaround to make it work again. If the gem was built with error condition turned off, it succeeded:

```
gem install debase -v '0.2.5.beta2' 
```

Translating this to bundler configuration, so that bundle install` picks it up, seemed straightforward:

```
bundle config build.debase --with
```

But it did not work. Why? 

## The 12-year old hack

Looking again at the error message made me realise something. While the compiler could not build the debase gem, despite bundler having the right flags to instruct the compiler, it was the `ruby-debug-ide` gem which initiated the trouble.

This gem has no dependencies in its gemspec:
```
$ gem dependency -r ruby-debug-ide -v '0.7.3'
Gem ruby-debug-ide-0.7.3
  rake (>= 0.8.1)
```

Yet it initiates the build of the debase gem. A quick look into `ruby-debug-ide` source code revealed this gem ships a C-extension:

```ruby
Gem::Specification.new do |spec|
  spec.name = "ruby-debug-ide"
  ...
  spec.extensions << "ext/mkrf_conf.rb" unless ENV['NO_EXT']
end
```

And this C-extension is a fake one:

```
install_dir = File.expand_path("../../../..", __FILE__)

if !defined?(RUBY_ENGINE) || RUBY_ENGINE == 'ruby'
  require 'rubygems'
  require 'rubygems/command.rb'
  require 'rubygems/dependency.rb'
  require 'rubygems/dependency_installer.rb'

  begin
    Gem::Command.build_args = ARGV
  rescue NoMethodError
  end

  if RUBY_VERSION < "1.9"
    dep = Gem::Dependency.new("ruby-debug-base", '>=0.10.4')
  elsif RUBY_VERSION < '2.0'
    dep = Gem::Dependency.new("ruby-debug-base19x", '>=0.11.30.pre15')
  else
    dep = Gem::Dependency.new("debase", '> 0')
  end

  begin
    puts "Installing base gem"
    inst = Gem::DependencyInstaller.new(:prerelease => dep.prerelease?, :install_dir => install_dir)
    inst.install dep
  rescue
    begin
      inst = Gem::DependencyInstaller.new(:prerelease => true, :install_dir => install_dir)
      inst.install dep
    rescue Exception => e
      puts e
      puts e.backtrace.join "\n  "
      exit(1)
    end
  end unless dep.nil? || dep.matching_specs.any?
end

# create dummy rakefile to indicate success
f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w")
f.write("task :default\n")
f.close
```

I've accidentally learned about `Gem::DependencyInstaller`, which does not honor bundler config and its build flags for gems. 

The comment of _dummy rakefile to indicate success_ made me explore this more and I've found [180 similar results in gemspecs on github](https://github.com/search?q=path%3A*.gemspec+ext%2Fmkrf_conf.rb&type=code&ref=advsearch).

Eventually I've found the pattern described on a wiki:
[How to install different versions of gems depending on which version of ruby the installee is using](https://en.wikibooks.org/wiki/Ruby_Programming/RubyGems#How_to_install_different_versions_of_gems_depending_on_which_version_of_ruby_the_installee_is_using)

Why does this pattern exist? Let's zoom into to this conditional:

```ruby
  if RUBY_VERSION < "1.9"
    dep = Gem::Dependency.new("ruby-debug-base", '>=0.10.4')
  elsif RUBY_VERSION < '2.0'
    dep = Gem::Dependency.new("ruby-debug-base19x", '>=0.11.30.pre15')
  else
    dep = Gem::Dependency.new("debase", '> 0')
  end
  
  Gem::DependencyInstaller.new(:prerelease => dep.prerelease?, :install_dir => install_dir).install(dep)
```

This pattern was supposed dynamically add dependencies, based on which Ruby VM version we're installing this gem on. Perhaps by the time it was introduced it was the only possible solution.

Nowadays nn application developer could take advantage of [Bundler platforms](https://bundler.io/v2.5/man/gemfile.5.html#PLATFORMS) in `Gemfile`:

```ruby
gem "weakling",   platforms: :jruby
gem "ruby-debug", platforms: :mri_31
gem "nokogiri",   platforms: [:windows_31, :jruby]
```

On the other hand a library developer distributing gems via rubygems.org can use a [platform specification](https://guides.rubygems.org/specification-reference/#platform=). This allows building different gems for different runtimes. 
A good example of this is `google-protobuf` gem shipping 10 different packages (with pre-built binaries for each platform) for the same library release.

```
4.26.0 - March 12, 2024 (255 KB)
4.26.0 - March 12, 2024 x86_64-darwin (916 KB)
4.26.0 - March 12, 2024 aarch64-linux (879 KB)
4.26.0 - March 12, 2024 x64-mingw-ucrt (698 KB)
4.26.0 - March 12, 2024 x64-mingw32 (532 KB)
4.26.0 - March 12, 2024 x86_64-linux (887 KB)
4.26.0 - March 12, 2024 x86-linux (915 KB)
4.26.0 - March 12, 2024 java (4.92 MB)
4.26.0 - March 12, 2024 arm64-darwin (876 KB)
4.26.0 - March 12, 2024 x86-mingw32 (901 KB)
```

Normally the gemspec Ruby-like specification is transformed into a more static one. The conditionals inside gemspec would not work. With `platform` we're instructing to provide several specifications — each for the desired runtime.

```ruby
 if RUBY_PLATFORM == "java"
    s.platform  = "java"
    s.files     += ["lib/google/protobuf_java.jar"] +
      Dir.glob('ext/**/*').reject do |file|
        File.basename(file) =~ /^((convert|defs|map|repeated_field)\.[ch]|
                                   BUILD\.bazel|extconf\.rb|wrap_memcpy\.c)$/x
      end
    s.extensions = ["ext/google/protobuf_c/Rakefile"]
    s.add_dependency "ffi", "~>1"
    s.add_dependency "ffi-compiler", "~>1"
  else
    s.files     += Dir.glob('ext/**/*').reject do |file|
      File.basename(file) =~ /^(BUILD\.bazel)$/
    end
    s.extensions = %w[
      ext/google/protobuf_c/extconf.rb
      ext/google/protobuf_c/Rakefile
    ]
    s.add_development_dependency "rake-compiler-dock", "= 1.2.1"
  end
```


What did we do in our project? We're not building Ruby IDEs for living. We do not need to support Ruby < 3.3.0.

Thus we've:

* remained on stated explicit dependencies in `Gemfile`
* opted out from conditional dependencies — removed `spec.extensions=` line in `ruby-debug-ide` fork, along with `ext/mkrf_conf.rb`
* enjoyed not seeing developers distracted by accidental complexity in the stack — without needig Bundler to support this pattern
