require 'active_support/concern'

module Wagons
  # A wagon is an extension to your application train running on Rails.
  #
  # Wagons are built on Rails Engines. To change an engine to a wagon,
  # simply include this module into your own Engine.
  module Wagon
    extend ActiveSupport::Concern

    # Version from the gemspec.
    def version
      gemspec.version
    end

    # Human readable name.
    def label
      gemspec.summary
    end

    # Simple system name, without application prefix.
    def wagon_name
      gem_name.sub(/^#{Wagons.app_name}_/, '')
    end

    # Name of the gem.
    def gem_name
      class_name = self.class.name.demodulize.underscore
      engine_name.sub(/_#{class_name}$/, '')
    end

    # Description from the gemspec.
    def description
      gemspec.description
    end

    # Direct dependencies on other wagons.
    def dependencies
      gemspec.dependencies.map(&:name).
                           select { |dep| dep =~ /\A#{Wagons.app_name}_/ }.
                           map { |dep| Wagons.find(dep) || fail("No wagon #{dep} found") }
    end

    # Recursive depdencies on other wagons.
    def all_dependencies
      dependencies.map { |dep| dep.all_dependencies + [dep] }.flatten.uniq
    end

    # Gem Specification.
    def gemspec
      Gem::Specification.find_by_name(gem_name)
    end

    # If true, this wagon may not be removed. Override as required.
    # May return a string with a message, why the wagon must not be removed.
    def protect?
      false
    end

    # Run the migrations.
    def migrate(version = nil)
      migrate_to(version)
    end

    # Revert the migrations.
    def revert
      migrate_to(0)
    end

    # Load seed data in db/fixtures.
    def load_seed
      SeedFu.seed seed_fixtures
    end

    # Unload seed data in db/fixtures.
    def unload_seed
      SeedFuNdo.unseed seed_fixtures
    end

    # Hash of the seed models to their existing records.
    def existing_seeds
      SeedFuNdo.existing_seeds seed_fixtures
    end

    # Loads the migrations and seeds of this wagon and its dependencies.
    def prepare_test_db
      depts = all_dependencies + [self]

      # migrate
      depts.each { |d| d.migrate }

      # seed
      SeedFu.quiet = true unless ENV['VERBOSE']
      SeedFu.seed([ Rails.root.join('db/fixtures').to_s,
                    Rails.root.join('db/fixtures/test').to_s ])
      depts.each { |d| d.load_seed }
    end

    # The version requirement for the main application.
    def app_requirement
      self.class.app_requirement
    end

    # Paths for migration files.
    def migrations_paths
      paths['db/migrate'].existent
    end

    # Loads tasks into the main Rails application.
    # Overwritten to only load own rake tasks, without install:migrations task from Rails::Engine
    def load_tasks(app = self)
      extend Rake::DSL if defined? Rake::DSL
      self.class.rake_tasks.each { |block| instance_exec(app, &block) }
      paths['lib/tasks'].existent.sort.each { |ext| load(ext) }
      self
    end

    private

    def seed_fixtures
      fixtures = root.join('db', 'fixtures')
      ENV['NO_ENV'] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end

    def migrate_to(version)
      migration_context.migrate(version)
    end

    def migration_context
      if Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new('7.1.0')
        ActiveRecord::MigrationContext.new(migrations_paths, ActiveRecord::SchemaMigration)
      else
        ActiveRecord::MigrationContext.new(migrations_paths)
      end
    end

    module ClassMethods
      # Get or set a version requirement for the main application.
      # Set the application version in config/initializers/wagon_app_version.rb.
      # Gem::Requirement syntax is supported.
      def app_requirement(requirement = nil)
        if requirement
          @app_requirement = Gem::Requirement.new(requirement)
        else
          @app_requirement ||= Gem::Requirement.new
        end
      end
    end
  end
end
