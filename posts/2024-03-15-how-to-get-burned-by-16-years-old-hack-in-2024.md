---
title: How to get burned by 16 years old hack in 2024
created_at: 2024-03-15T10:37:05.835Z
author: Paweł Pacana
tags: ['ruby', 'gems', 'macos']
publish: true
---

There's a project I'm consulting on where programmers develop predominantly in cloud environment. This setup simplifies a lot of moving parts and has the benefit of providing everyone homogenous containers to run code. If it runs on my box — it will run on everyone's box. In that case, that box is Linux-based. It has the drawback of having greater latency and being more resource-constrained than a beefy local machine a developer is equipped with, i.e. MacBook Pro running on Apple Silicon.

Recently we've upgraded this development environment from Ruby 3.2.2 to Ruby 3.3.0. The process was smooth and predictable in the cloud environment. It worked on my box and by definition on everyone's boxes. However this wasn't always the case for local machines. The developers who chose to upgrade Ruby on their Macs early, experienced no trouble either. On the other hand, those who procrastinated a bit...

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
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

    current directory: /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/gems/ruby-debug-ide-b671a1cbb6d8/ext
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/bin/ruby mkrf_conf.rb
Installing base gem
Building native extensions. This could take a while...
Building native extensions. This could take a while...
ERROR: Failed to build gem native extension.

    current directory: /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/gems/debase-0.2.5.beta2/ext
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/bin/ruby extconf.rb
checking for vm_core.h... yes
checking for iseq.h... yes
checking for version.h... yes
creating Makefile

current directory: /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/gems/debase-0.2.5.beta2/ext
make DESTDIR\= sitearchdir\=./.gem.20240311-43199-d198st sitelibdir\=./.gem.20240311-43199-d198st clean

current directory: /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/gems/debase-0.2.5.beta2/ext
make DESTDIR\= sitearchdir\=./.gem.20240311-43199-d198st sitelibdir\=./.gem.20240311-43199-d198st
compiling breakpoint.c
compiling context.c
compiling debase_internals.c
debase_internals.c:319:25: warning: initializing 'rb_control_frame_t *' (aka 'struct rb_control_frame_struct *') with an expression of type 'const
rb_control_frame_t *' (aka 'const struct rb_control_frame_struct *') discards qualifiers [-Wincompatible-pointer-types-discards-qualifiers]
    rb_control_frame_t *start_cfp = RUBY_VM_END_CONTROL_FRAME(TH_INFO(thread));
                        ^           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
debase_internals.c:770:3: error: incompatible function pointer types passing 'void (VALUE, VALUE)' (aka 'void (unsigned long, unsigned long)') to parameter
of type 'VALUE (*)(VALUE, VALUE)' (aka 'unsigned long (*)(unsigned long, unsigned long)') [-Wincompatible-function-pointer-types]
  rb_define_module_function(mDebase, "set_trace_flag_to_iseq", Debase_set_trace_flag_to_iseq, 1);
  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/include/ruby-3.3.0/ruby/internal/anyargs.h:338:142: note: expanded from macro 'rb_define_module_function'
#define rb_define_module_function(mod, mid, func, arity)    RBIMPL_ANYARGS_DISPATCH_rb_define_module_function((arity), (func))((mod), (mid), (func),
(arity))
                                                                                                                                             ^~~~~~
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/include/ruby-3.3.0/ruby/internal/anyargs.h:274:1: note: passing argument to parameter here
RBIMPL_ANYARGS_DECL(rb_define_module_function, VALUE, const char *)
^
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/include/ruby-3.3.0/ruby/internal/anyargs.h:256:72: note: expanded from macro 'RBIMPL_ANYARGS_DECL'
RBIMPL_ANYARGS_ATTRSET(sym) static void sym ## _01(__VA_ARGS__, VALUE(*)(VALUE, VALUE), int); \
                                                                       ^
debase_internals.c:773:3: error: incompatible function pointer types passing 'void (VALUE, VALUE)' (aka 'void (unsigned long, unsigned long)') to parameter
of type 'VALUE (*)(VALUE, VALUE)' (aka 'unsigned long (*)(unsigned long, unsigned long)') [-Wincompatible-function-pointer-types]
  rb_define_module_function(mDebase, "unset_iseq_flags", Debase_unset_trace_flags, 1);
  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/include/ruby-3.3.0/ruby/internal/anyargs.h:338:142: note: expanded from macro 'rb_define_module_function'
#define rb_define_module_function(mod, mid, func, arity)    RBIMPL_ANYARGS_DISPATCH_rb_define_module_function((arity), (func))((mod), (mid), (func),
(arity))
                                                                                                                                             ^~~~~~
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/include/ruby-3.3.0/ruby/internal/anyargs.h:274:1: note: passing argument to parameter here
RBIMPL_ANYARGS_DECL(rb_define_module_function, VALUE, const char *)
^
/Users/kakadudu/.rvm/rubies/ruby-3.3.0/include/ruby-3.3.0/ruby/internal/anyargs.h:256:72: note: expanded from macro 'RBIMPL_ANYARGS_DECL'
RBIMPL_ANYARGS_ATTRSET(sym) static void sym ## _01(__VA_ARGS__, VALUE(*)(VALUE, VALUE), int); \
                                                                       ^
1 warning and 2 errors generated.
make: *** [debase_internals.o] Error 1

make failed, exit code 2

Gem files will remain installed in /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/gems/debase-0.2.5.beta2 for inspection.
Results logged to /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/extensions/x86_64-darwin-23/3.3.0/debase-0.2.5.beta2/gem_make.out
...
  /Users/kakadudu/.rvm/rubies/ruby-3.3.0/lib/ruby/3.3.0/rubygems/dependency_installer.rb:250:in `install'
  mkrf_conf.rb:31:in `rescue in <main>'
  mkrf_conf.rb:24:in `<main>'

rake failed, exit code 1

Gem files will remain installed in /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/gems/ruby-debug-ide-b671a1cbb6d8 for inspection.
Results logged to /Users/kakadudu/.rvm/gems/ruby-3.3.0/bundler/gems/extensions/x86_64-darwin-23/3.3.0/ruby-debug-ide-b671a1cbb6d8/gem_make.out

...

An error occurred while installing ruby-debug-ide (0.7.3), and Bundler cannot continue.

In Gemfile:
  ruby-debug-ide
```

The build error message suggested the workaround to make it work again. If the gem was built with error condition turned off, it succeeded:

```
gem install debase -v '0.2.5.beta2' -- --with-cflags=-Wno-error=incompatible-function-pointer-types
```

Translating this to bundler configuration, so that `bundle install` picks it up, seemed straightforward:

```
bundle config build.debase --with-cflags=-Wno-error=incompatible-function-pointer-types
```

But it did not work. Why? 

## The 16 years old hack

Looking again at the error message made me realise something. While the compiler could not build the `debase` gem, despite bundler having the right flags to instruct the compiler, it was the `ruby-debug-ide` gem which initiated the trouble.

This gem has no dependencies in its gemspec:
```
$ gem dependency -r ruby-debug-ide -v '0.7.3'
Gem ruby-debug-ide-0.7.3
  rake (>= 0.8.1)
```

Yet it initiates the build of the `debase` gem. A quick look into `ruby-debug-ide` source code revealed this gem ships a C-extension:

```ruby
Gem::Specification.new do |spec|
  spec.name = "ruby-debug-ide"
  ...
  spec.extensions << "ext/mkrf_conf.rb" unless ENV['NO_EXT']
end
```

And this C-extension is a fake one:

```ruby
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

I've accidentally learned about `Gem::DependencyInstaller`, which does not honor Bundler config and its build flags for gems. 

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

This pattern is supposed to dynamically add dependencies, based on which Ruby VM version we're installing this gem on. Perhaps by the time it was introduced it was the only possible solution.

Nowadays an application developer could take advantage of [Bundler platforms](https://bundler.io/v2.5/man/gemfile.5.html#PLATFORMS) in `Gemfile`:

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


What did we do in our project? We're not building Ruby IDEs for living. We do not need to support Ruby older than 3.3.0.

Thus we've:

* remained on stated explicit dependencies in `Gemfile`
* opted out from conditional dependencies — removed `spec.extensions=` line in `ruby-debug-ide` fork along with `ext/mkrf_conf.rb` file
* enjoyed not seeing developers distracted by accidental complexity in the stack — without needing Bundler to support this pattern
