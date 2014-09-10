class ActiveRecord::Migration
  class << self

    # Extend maintain_test_schema! to include migrations of the current wagon to test
    # or to make sure no wagon migrations are loaded when testing the main application.
    def maintain_test_schema_with_wagons!
      if ActiveRecord::Base.maintain_test_schema
        # set migrations paths to core only, wagon migrations are loaded separately
        ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
        if app_needs_migration?
          suppress_messages { load_wagon_schema! }
        end
      end
    end
    alias_method_chain :maintain_test_schema!, :wagons

    private

    def load_wagon_schema!
      config = ActiveRecord::Base.configurations['test']
      # Contrary to the original rails approach (#load_schema_if_pending!),
      # purge the database first to get rid of all wagon tables.
      ActiveRecord::Tasks::DatabaseTasks.purge(config)

      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Tasks::DatabaseTasks.load_schema
      check_pending!

      Wagons.current_wagon.prepare_test_db if Wagons.current_wagon
    end

    def app_needs_migration?
      Wagons.current_wagon ||
      defined_app_migration_versions.to_set !=  ActiveRecord::Migrator.get_all_versions.to_set
    end

    def defined_app_migration_versions
      ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths).collect(&:version)
    end

  end
end