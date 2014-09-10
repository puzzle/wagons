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
      alias_method_chain :maintain_test_schema!, :wagons

      private

      def load_wagon_schema!
        config = Base.configurations['test']
        # Contrary to the original rails approach (#load_schema_if_pending!),
        # purge the database first to get rid of all wagon tables.
        Tasks::DatabaseTasks.purge(config)

        Base.establish_connection(config)
        Tasks::DatabaseTasks.load_schema
        check_pending!

        Wagons.current_wagon.prepare_test_db if Wagons.current_wagon
      end

      def app_needs_migration?
        Wagons.current_wagon ||
        defined_app_migration_versions != migration_versions_in_db
      end

      def defined_app_migration_versions
        Migrator.migrations(Migrator.migrations_paths).collect(&:version).to_set
      end

      def migration_versions_in_db
        if Base.connection.table_exists?(SchemaMigration.table_name)
          Migrator.get_all_versions.to_set
        else
          [].to_set
        end
      end

    end
  end
end