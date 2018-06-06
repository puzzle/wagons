module ActiveRecord
  class Migration
    class << self

      # Extend maintain_test_schema! to include migrations of the current wagon to test
      # or to make sure no wagon migrations are loaded when testing the main application.
      def maintain_test_schema_with_wagons!
        if Base.maintain_test_schema
          # set migrations paths to core only, wagon migrations are loaded separately
          Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
          if app_needs_migration?
            suppress_messages { load_wagon_schema! }
          end
        end
      end
      alias maintain_test_schema_without_wagons! maintain_test_schema!
      alias maintain_test_schema! maintain_test_schema_with_wagons!

      private

      def load_wagon_schema!
        Base.clear_all_connections!

        # Contrary to the original rails approach (#load_schema_if_pending!),
        # purge the database first to get rid of all wagon tables.
        config = Base.configurations['test']
        Tasks::DatabaseTasks.purge(config)

        Base.establish_connection(config)
        load_app_schema(config)

        Wagons.current_wagon.prepare_test_db if Wagons.current_wagon
      end

      def load_app_schema(config)
        if Tasks::DatabaseTasks.respond_to?(:load_schema_for)
          Tasks::DatabaseTasks.load_schema_for(config)
        else
          Tasks::DatabaseTasks.load_schema(config)
        end
        check_pending!
      end

      def app_needs_migration?
        Wagons.current_wagon ||
          defined_app_migration_versions != migration_versions_in_db
      end

      def defined_app_migration_versions
        if defined?(MigrationContext)
          migration_context.migrations.collect(&:version).to_set
        else
          Migrator.migrations(Migrator.migrations_paths).collect(&:version).to_set
        end
      end

      def migration_versions_in_db
        if Base.connection.table_exists?(SchemaMigration.table_name)
          if defined?(MigrationContext)
            migration_context.get_all_versions.to_set
          else
            Migrator.get_all_versions.to_set
          end
        else
          [].to_set
        end
      end

      def migration_context
        MigrationContext.new(Migrator.migrations_paths)
      end

    end
  end
end