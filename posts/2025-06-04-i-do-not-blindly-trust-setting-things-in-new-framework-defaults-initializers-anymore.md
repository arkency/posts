---
created_at: 2025-06-09 17:20:07 +0200
author: Piotr Jurewicz
tags: ['rails', 'rails upgrade']
publish: false
---

# I do not blindly trust setting things in new_framework_defaults initializers anymore

> **TL;DR:** When upgrading Rails, don’t blindly assume settings in `new_framework_defaults_*.rb` are applied in time to affect the framework’s internals. Test it by your own, or move uncommented settings to `application.rb` after `config.load_defaults`.

Upgrading a Rails application to a new version involves reviewing the `new_framework_defaults_*.rb` initializer and uncommenting them one by one. It *feels* like a safe and incremental way to adopt changes.

But in practice, that assumption can be misleading — and even dangerous.

In this post, I want to share a subtle configuration pitfall I ran into while upgrading to **Rails 7.1**, when things did not work as I've expected.

## When expectations break

After upgrading a project to **Rails 7.1**, I uncommented:

```ruby
# config.active_record.default_column_serializer = nil
```
from `config/initializers/new_framework_defaults_7_1.rb`, without any further changes, expecting it to raise errors. But it didn’t. Everything worked as before.

I opened the Rails console and performed following check:

```ruby
irb(main):001> Rails.application.config.active_record.default_column_serializer
=> nil
irb(main):002> ActiveRecord::Base.default_column_serializer
=> ActiveRecord::Coders::YAMLColumn
```

At first, I thought the setting might be obsolete or missdocumented. But I started digging — and discovered something surprising.

## What is going on under the neath?

Rails has several initializers that run on startup that are all defined by using the initializer method from `Rails::Railtie`.
They are responsible for setting up the framework and its components.

```
active_support.deprecator
action_dispatch.deprecator
active_model.deprecator
active_job.deprecator
action_controller.deprecator
active_record.deprecator
action_mailer.deprecator
action_view.deprecator
active_storage.deprecator
action_mailbox.deprecator
action_text.deprecator
action_cable.deprecator
load_environment_config
load_environment_hook
load_active_support
set_eager_load
initialize_logger
initialize_cache
action_mailer.logger
action_mailer.set_configs
action_mailer.set_autoload_paths
set_load_path
set_autoload_paths
set_eager_load_paths
setup_once_autoloader
bootstrap_hook
set_secrets_root
active_support.isolation_level
active_support.raise_on_invalid_cache_expiration_time
active_support.set_authenticated_message_encryption
active_support.reset_execution_context
active_support.reset_all_current_attributes_instances
active_support.deprecation_behavior
active_support.initialize_time_zone
active_support.initialize_beginning_of_week
active_support.require_master_key
active_support.set_configs
active_support.set_hash_digest_class
active_support.set_key_generator_hash_digest_class
active_support.set_default_message_serializer
active_support.set_use_message_serializer_for_metadata
action_dispatch.configure
active_model.secure_password
active_model.i18n_customize_full_message
global_id
web_console.deprecator
active_job.logger
active_job.custom_serializers
active_job.set_configs
active_job.set_reloader_hook
active_job.query_log_tags
active_job.backtrace_cleaner
action_controller.assets_config
action_controller.set_helpers_path
action_controller.parameters_config
action_controller.set_configs
action_controller.compile_config_methods
action_controller.request_forgery_protection
action_controller.query_log_tags
action_controller.test_case
active_record.initialize_timezone
active_record.postgresql_time_zone_aware_types
active_record.logger
active_record.backtrace_cleaner
active_record.migration_error
active_record.cache_versioning_support
active_record.use_schema_cache_dump
active_record.check_schema_cache_dump
active_record.define_attribute_methods
active_record.warn_on_records_fetched_greater_than
active_record.sqlite3_production_warning
active_record.sqlite3_adapter_strict_strings_by_default
active_record.set_configs
active_record.initialize_database
active_record.log_runtime
active_record.set_reloader_hooks
active_record.set_executor_hooks
active_record.add_watchable_files
active_record.clear_active_connections
active_record.set_filter_attributes
active_record.set_signed_id_verifier_secret
active_record.generated_token_verifier
active_record_encryption.configuration
active_record.query_log_tags_config
active_record.unregister_current_scopes_on_unload
active_record.message_pack
action_mailer.compile_config_methods
test_unit.line_filtering
set_default_precompile
quiet_assets
asset_url_processor
asset_sourcemap_url_processor
sprockets-rails.deprecator
add_routing_paths
add_locales
add_view_paths
add_mailer_preview_paths
add_fixture_paths
prepend_helpers_path
load_config_initializers
wrap_executor_around_load_seed
engines_blank_point
append_assets_path
action_view.logger
action_view.caching
action_view.setup_action_pack
action_view.collection_caching
active_storage.configs
active_storage.attached
active_storage.verifier
active_storage.services
active_storage.queues
active_storage.reflection
action_view.configuration
active_storage.asset
active_storage.fixture_set
action_mailbox.config
action_text.attribute
action_text.asset
action_text.attachable
action_text.helper
action_text.renderer
action_text.system_test_helper
action_text.configure
action_cable.helpers
action_cable.logger
action_cable.health_check_application
action_cable.asset
action_cable.set_configs
action_cable.routes
action_cable.set_work_hooks
add_generator_templates
setup_main_autoloader
setup_default_session_store
build_middleware_stack
define_main_app_helper
add_to_prepare_blocks
run_prepare_callbacks
eager_load!
finisher_hook
configure_executor_for_concurrency
add_internal_routes
set_routes_reloader_hook
set_clear_dependencies_hook
```
These initializers are executed in a specific order.

`active_record.set_configs` is the one which sets up Active Record by using the settings in `Rails.application.config.active_record` and sending the method names as setters to `ActiveRecord::Base` and passing the values through.

To be precise, the `ActiveSupport.on_load(:active_record)` callback gets registered there. I inserted a breakpoint inside the callback block and verified it was executed immediately after registering it - which means the `ActiveRecord::Base` class was already loaded.

It happened before the `load_config_initializers` initializer was executed, which is responsible for loading initializers from `config/initializers`, including `new_framework_defaults_*.rb`.

The backtrace pointed to `rails_event_store_active_record` gem, the `require "active_record"` line in the `event.rb` file.

The issue with `rails_event_store` was already fixed by Paweł (give kudos to him, this change would be released in RES 2.17.0 soon), and he also found that this is not an isolated case. See these issues with other popular gems:

- [friendly_id](https://github.com/norman/friendly_id/issues/823)
- [globalize](https://github.com/globalize/globalize/issues/786)
- [pg_hero](https://github.com/ankane/pghero/issues/232)

If any gem explicitly does `require "active_record"` or other configurable Rails module — the `ActiveSupport.on_load` callbacks is triggered prematurely, and some settings from `new_framework_defaults_*.rb` may not be honored!

## Detecting the problem

To detect if this your scenario, I created a simple script that hooks into `ActiveSupport.on_load` for configurable Rails modules and records if they are loaded prematurely by any gem from your Gemfile.

```ruby
# premature_load_check.rb
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("Gemfile", __dir__)

require 'active_support'
require "bundler/setup"

early_load = false

[:action_cable, :action_mailer, :action_controller, :active_job, :active_record].each do |rails_module|
  ActiveSupport.on_load(rails_module) do
    early_load = true
    warn <<~MSG
      ⚠️  #{rails_module} is already loaded at boot.
      This can prevent Rails.application.config.#{rails_module} settings in `new_framework_defaults.rb` from working.
      Trace:
      #{caller.join("\\n")}
    MSG
  end
end

Bundler.require

unless early_load
  puts "✅  Rails modules were not loaded prematurely."
end
```
This script can be copied to your app directory and run manually via `bundle exec ruby premature_load_check.rb` to ensure none of your gems load Rails components too early.

## A safer upgrade path

If you find that a gem loads a Rails module prematurely, you have to be super careful with the settings in `new_framework_defaults_*.rb`.

The safe approach is to move each uncommented setting to `config/application.rb` after calling `config.load_defaults`. This way, you ensure that the proper configuration settings are set before other gems gets loaded, and before the Rails internals gets configured.

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.load_defaults "7.0"
    config.active_record.default_column_serializer = nil
  end
end
```
Btw, it's just what `config.load_defaults` does internally, when it loads the defaults for a specific Rails version.

## Final thoughts

Rails gives us powerful configuration over framework defaults via `new_framework_defaults_*.rb`, but you have to be careful with them.

Remember, that there are some known issues. Test your assumptions, especially when you rely on many other gems.

Use tools — like the script above — to keep your app safe when switching to a new Rails version defaults.

Move what want you want to enable from `new_framework_defaults_*.rb` to `application.rb`.

Always enable one setting at a time, and test your app thoroughly after each change.