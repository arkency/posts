---
created_at: 2023-08-31 19:04:08 +0200
author: Szymon Fiedler
tags: [value object, ruby, rails event store]
publish: false
---

# The most underused pattern in Ruby

Recently one of the RailsEventStore users posted an [issue](https://github.com/RailsEventStore/rails_event_store/issues/1650) that one wanted to use RES on a Postgres database with [PostGIS](https://postgis.net) extension. Migration generator used to setup tables for events and streams was failing with `UnsupportedAdapter` error.

<!-- more -->

In RailsEventStore we supported to date _PostgreSQL_, _MySQL2_ and _SQLite_ adapters. But if you want to make use of mentioned _PostGIS_ extension, you need install additional `activerecord-postgis-adapter` and set `adapter: postgis` in `database.yml`. Our code relied on value returned by: 

```ruby
ActiveRecord::Base.connection.adapter_name.downcase
=> "postgis"
```

I thought — _Ok, that's an easy fix_, _PostGIS_ is just an extension, we need to treat it like Postgres internally when generating migration. Same data types should be allowed. 

## Easy fix, requiring a lot of changes

This easy fix required me to change 8 files (4 with implementation and 4 with tests). _Something is not ok here_ — I thought. So let's look through each of them:

I had to add `postgis` to the list of `SUPPORTED_ADAPTERS` in `VerifyAdapter` class

```ruby
# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    UnsupportedAdapter = Class.new(StandardError)

    class VerifyAdapter
      SUPPORTED_ADAPTERS = %w[mysql2 postgresql postgis sqlite].freeze

      def call(adapter)
        raise UnsupportedAdapter, "Unsupported adapter" unless supported?(adapter)
      end

      private

      private_constant :SUPPORTED_ADAPTERS

      def supported?(adapter)
        SUPPORTED_ADAPTERS.include?(adapter.downcase)
      end
    end
  end
end
```

Then I had to extend case statement in `ForeignKeyOnEventIdMigrationGenerator#each_migration` method

```ruby
# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class ForeignKeyOnEventIdMigrationGenerator
      def call(database_adapter, migration_path)
        VerifyAdapter.new.call(database_adapter)
        each_migration(database_adapter) do |migration_name|
          path = build_path(migration_path, migration_name)
          write_to_file(path, migration_code(database_adapter, migration_name))
        end
      end

      private

      def each_migration(database_adapter, &block)
        case database_adapter
        when "postgresql", "postgis"
          [
            'add_foreign_key_on_event_id_to_event_store_events_in_streams',
            'validate_add_foreign_key_on_event_id_to_event_store_events_in_streams'
          ]
        else
          ['add_foreign_key_on_event_id_to_event_store_events_in_streams']
        end.each(&block)
      end

      def absolute_path(path)
        File.expand_path(path, __dir__)
      end

      def migration_code(database_adapter, migration_name)
        migration_template(template_root(database_adapter), migration_name).result_with_hash(migration_version: migration_version)
      end

      def migration_template(template_root, name)
        ERB.new(File.read(File.join(template_root, "#{name}_template.erb")))
      end

      def template_root(database_adapter)
        absolute_path("./templates/#{template_directory(database_adapter)}")
      end

      def template_directory(database_adapter)
        TemplateDirectory.for_adapter(database_adapter)
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def write_to_file(path, migration_code)
        File.write(path, migration_code)
      end

      def build_path(migration_path, migration_name)
        File.join("#{migration_path}", "#{timestamp}_#{migration_name}.rb")
      end
    end
  end
end
```

Same goes for Rails version of migration generator

```ruby
# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module ActiveRecord
      class RailsForeignKeyOnEventIdMigrationGenerator < Rails::Generators::Base
        class Error < Thor::Error
        end

        namespace "rails_event_store_active_record:migration_for_foreign_key_on_event_id"

        source_root File.expand_path(File.join(File.dirname(__FILE__), "../generators/templates"))

        def initialize(*args)
          super

          VerifyAdapter.new.call(adapter)
        rescue UnsupportedAdapter => e
          raise Error, e.message
        end

        def create_migration
          case adapter
          when "postgresql", "postgis"
            template "#{template_directory}add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{timestamp}_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
            template "#{template_directory}validate_add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{timestamp}_validate_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
          else
            template "#{template_directory}add_foreign_key_on_event_id_to_event_store_events_in_streams_template.erb",
                     "db/migrate/#{timestamp}_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"
          end
        end

        private

        def adapter
          ::ActiveRecord::Base.connection.adapter_name.downcase
        end

        def migration_version
          ::ActiveRecord::Migration.current_version
        end

        def timestamp
          Time.now.strftime("%Y%m%d%H%M%S")
        end

        def template_directory
          TemplateDirectory.for_adapter(adapter)
        end
      end
    end
  end
end
```

What is important, both of the migrators used `VerifyAdapter` class (and two other migrators too).

`TemplateDirectory` class also suffered from primitive obsession and it was used by both of the migrators too.

```ruby
# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class TemplateDirectory
      def self.for_adapter(database_adapter)
        case database_adapter.downcase
        when "postgresql", "postgis"
          "postgres/"
        when "mysql2"
          "mysql/"
        end
      end
    end
  end
end
```

There was also one more place — `VerifyDataTypeForAdapter` which was composed of `VerifyAdapter`, adding verification of data types available to given database engine.

Here we go again, another checks of string values, but in a more specific context:

```ruby
# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    InvalidDataTypeForAdapter = Class.new(StandardError)

    class VerifyDataTypeForAdapter
      SUPPORTED_POSTGRES_DATA_TYPES = %w[binary json jsonb].freeze
      SUPPORTED_MYSQL_DATA_TYPES = %w[binary json].freeze
      SUPPORTED_SQLITE_DATA_TYPES = %w[binary].freeze

      def call(adapter, data_type)
        VerifyAdapter.new.call(adapter)
        raise InvalidDataTypeForAdapter, "MySQL2 doesn't support #{data_type}" if is_mysql2?(adapter) && !SUPPORTED_MYSQL_DATA_TYPES.include?(data_type)
        raise InvalidDataTypeForAdapter, "sqlite doesn't support #{data_type}" if is_sqlite?(adapter) && supported_by_sqlite?(data_type)
        raise InvalidDataTypeForAdapter, "PostgreSQL doesn't support #{data_type}" unless supported_by_postgres?(data_type)
      end

      private

      private_constant :SUPPORTED_POSTGRES_DATA_TYPES, :SUPPORTED_MYSQL_DATA_TYPES, :SUPPORTED_SQLITE_DATA_TYPES

      def is_sqlite?(adapter)
        adapter.downcase.eql?("sqlite")
      end

      def is_mysql2?(adapter)
        adapter.downcase.eql?("mysql2")
      end

      def supported_by_sqlite?(data_type)
        !SUPPORTED_SQLITE_DATA_TYPES.include?(data_type)
      end

      def supported_by_postgres?(data_type)
        SUPPORTED_POSTGRES_DATA_TYPES.include?(data_type)
      end
    end
  end
end
```

# I saw the pattern

* at start we need to check whether given adapter is allowed
* we need to verify certain data types for given adapters to be aligned with db engines
* then we have to made a decision to generate specific migration for given data type
* migration template directory is a consequence of adapter type

Having all this within a dedicated [Value Object](https://blog.arkency.com/tags/value-object/) would allow reducing number of decision trees in the code, checking the same primitives on and on.

Something like: 

```ruby
DatabaseAdapter.from_string("postgres")
=> DatabaseAdapter::PostgreSQL.new

DatabaseAdapter.from_string("bazinga")
=> UnsupportedAdapter: "bazinga" (RubyEventStore::ActiveRecord::UnsupportedAdapter)

DatabaseAdapter.from_string("sqlite", "jsonb")
=> SQLite doesn't support "jsonb". Supported types are: binary. (RubyEventStore::ActiveRecord::InvalidDataTypeForAdapter)
```

After few iterations we ended up with the implementation below:

```ruby
# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    UnsupportedAdapter = Class.new(StandardError)
    InvalidDataTypeForAdapter = Class.new(StandardError)

    class DatabaseAdapter
      NOT_SET = Object.new.freeze

      class PostgreSQL < self
        SUPPORTED_DATA_TYPES = %w[binary json jsonb].freeze

        def initialize(data_type = NOT_SET)
          super("postgresql", data_type)
        end

        def template_directory
          "postgres/"
        end
      end

      class MySQL < self
        SUPPORTED_DATA_TYPES = %w[binary json].freeze

        def initialize(data_type = NOT_SET)
          super("mysql2", data_type)
        end

        def template_directory
          "mysql/"
        end
      end

      class SQLite < self
        SUPPORTED_DATA_TYPES = %w[binary].freeze

        def initialize(data_type = NOT_SET)
          super("sqlite", data_type)
        end
      end

      def initialize(adapter_name, data_type)
        raise UnsupportedAdapter if instance_of?(DatabaseAdapter)

        validate_data_type!(data_type)

        @adapter_name = adapter_name
        @data_type = data_type
      end

      attr_reader :adapter_name, :data_type

      def supported_data_types
        self.class::SUPPORTED_DATA_TYPES
      end

      def eql?(other)
        other.is_a?(DatabaseAdapter) && adapter_name.eql?(other.adapter_name)
      end

      alias == eql?

      def hash
        DatabaseAdapter.hash ^ adapter_name.hash
      end

      def template_directory
      end

      def self.from_string(adapter_name, data_type = NOT_SET)
        raise NoMethodError unless eql?(DatabaseAdapter)

        case adapter_name.to_s.downcase
        when "postgresql", "postgis"
          PostgreSQL.new(data_type)
        when "mysql2"
          MySQL.new(data_type)
        when "sqlite"
          SQLite.new(data_type)
        else
          raise UnsupportedAdapter, "Unsupported adapter: #{adapter_name.inspect}"
        end
      end

      private

      def validate_data_type!(data_type)
        if !data_type.eql?(NOT_SET) && !supported_data_types.include?(data_type)
          raise InvalidDataTypeForAdapter,
                "#{class_name} doesn't support #{data_type.inspect}. Supported types are: #{supported_data_types.join(", ")}."
        end
      end

      def class_name
        self.class.name.split("::").last
      end
    end
  end
end
```

`DatabaseAdadpter` acts like a parent class to all the specific adapters.
Specific adapters contain lists of `supported_data_types` to access those by client classes and render informative error messages if selected data is not supported by given database engine. They can also tell how the `template_directory` should be named.

We have a single entry with `DatabaseAdapter.from_string` which accepts `adapter_name` and optionally `data_type` which are both validated when creating an instance of specific adapter.

## What's the outcome?

We could remove three utility classes:

* `VerifyAdapter`
* `VerifyDataTypeForAdapter`
* `TemplateDirectory`

Four classes and one rake tasks simplified since the Value Object carriers all the necessary information for them to proceed:

* `ForeignKeyOnEventIdMigrationGenerator`
* `RailsForeignKeyOnEventIdMigrationGenerator`
* `MigrationGenerator`
* `RailsMigrationGenerator`
* `db:migrations:copy`

We could reduce branching and remove various private methods. 

The tests of above classes simplified a lot and are now focused on core responsibilities of the classes rather than checking which data types are compatible with given adapter.

## New adapter, not a big deal

Soon, there will be new default MySQL adapter in Rails 7.1 called [Trilogy](https://github.blog/2022-08-25-introducing-trilogy-a-new-database-adapter-for-ruby-on-rails/). It would be cool to cover this case already. 

The only thing which we had to do in this case, was to change one line of code and add single line of test — since we already owned a good abstraction:

```ruby
module RubyEventStore
  module ActiveRecord
    class DatabaseAdapter
      def self.from_string(adapter_name, data_type = NOT_SET)
        raise NoMethodError unless eql?(DatabaseAdapter)
        case adapter_name.to_s.downcase
        when "postgresql", "postgis"
          PostgreSQL.new(data_type)
        when "mysql2", "trilogy"
          MySQL.new(data_type)
        when "sqlite"
          SQLite.new(data_type)
        else
          raise UnsupportedAdapter, "Unsupported adapter: #{adapter_name.inspect}"
        end
      end
    end
  end
end


expect(DatabaseAdapter.from_string("Trilogy")).to eql(DatabaseAdapter::MySQL.new)
```

_Trilogy_ is an adapter for _MySQL_, there's no difference from our perspective, we want to treat it as such. 

## Summary

If you're curious on the full process, here's the [PR](https://github.com/RailsEventStore/rails_event_store/pull/1671/files) with the introduction of `DatabaseAdapter` value object. The code is 100% covered with mutation testing thanks to [mutant](https://github.com/mbj/mutant). 

I believe that Value Object is a totally underused pattern in Ruby ecosystem. That's why I wanted to provide [yet another example](https://blog.arkency.com/which-one-to-use-eql-vs-equals-vs-double-equal-mutant-driven-developpment-for-country-value-object/) which differs from typical `Money` one you usually see.

